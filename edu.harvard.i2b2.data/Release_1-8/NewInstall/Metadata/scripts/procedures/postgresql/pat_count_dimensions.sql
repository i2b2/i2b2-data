-- By Mike Mendis, Partners Healthcare
-- Performance improvements by Jeff Green, Prognosis Data Corp; Jeff Klann, PhD; and Griffin Weber, MD, PhD
-- Based on code from Dan Vianello, Center for Biomedical Informatics, Washington University in St. Louis
-- Usage example:
--     select PAT_COUNT_DIMENSIONS( 'I2B2' ,'public' , 'observation_fact' ,  'concept_cd', 'concept_dimension', 'concept_path'  )
--   (replace 'public' by the schema name for the fact table)


-- Requires trusted metadata values for table/column identifiers.
CREATE OR REPLACE PROCEDURE pat_count_dimensions(
    IN metadataTable VARCHAR,
    IN schemaName VARCHAR,
    IN observationTable VARCHAR,
    IN facttablecolumn VARCHAR,
    IN tablename VARCHAR,
    IN columnname VARCHAR,
    INOUT errorMsg VARCHAR
)
LANGUAGE plpgsql
AS $procedure$
DECLARE
    v_metadata TEXT;
    v_observation TEXT;
    v_fact_column TEXT;
    v_startime TIMESTAMPTZ;
    v_duration NUMERIC;
    v_fact_filter TEXT;
BEGIN
    errorMsg := NULL;
    v_startime := clock_timestamp();

    -- Resolve table identifiers without interpolating untrusted SQL.
    IF strpos(metadataTable, '.') > 0 THEN
        v_metadata := format('%I.%I', split_part(metadataTable,'.',1), split_part(metadataTable,'.',2));
    ELSE
        v_metadata := format('%I.%I', schemaName, metadataTable);
    END IF;
    IF strpos(observationTable, '.') > 0 THEN
        v_observation := format('%I.%I', split_part(observationTable,'.',1), split_part(observationTable,'.',2));
    ELSE
        v_observation := format('%I.%I', schemaName, observationTable);
    END IF;

    -- Classic wrapper may supply observationTable.concept_cd (or %.concept_cd).
    -- The physical fact table column is the last identifier component.
    v_fact_column := split_part(facttablecolumn, '.', array_length(string_to_array(facttablecolumn, '.'), 1));
    IF v_fact_column NOT IN ('concept_cd', 'provider_id', 'modifier_cd') THEN
        RAISE EXCEPTION 'Unsupported facttablecolumn: %', facttablecolumn;
    END IF;
    v_fact_filter := '%' || lower(facttablecolumn);

    DROP TABLE IF EXISTS pg_temp.dimcountont;
    DROP TABLE IF EXISTS pg_temp.dimontwithfolders;
    DROP TABLE IF EXISTS pg_temp.path2num;
    DROP TABLE IF EXISTS pg_temp.conceptpath;
    DROP TABLE IF EXISTS pg_temp.pathcounts;
    DROP TABLE IF EXISTS pg_temp.finaldimcounts;

    EXECUTE format($sql$
        CREATE TEMP TABLE dimcountont ON COMMIT PRESERVE ROWS AS
        SELECT o.c_fullname, o.c_basecode, o.c_hlevel
        FROM %s o
        LEFT JOIN (SELECT DISTINCT %I AS fact_cd FROM %s) f
          ON f.fact_cd = o.c_basecode
        WHERE trim(lower(o.c_facttablecolumn)) LIKE %L
          AND trim(lower(o.c_tablename)) = lower(%L)
          AND trim(lower(o.c_columnname)) = lower(%L)
          AND trim(lower(o.c_synonym_cd)) = 'n'
          AND trim(lower(o.c_columndatatype)) = 't'
          AND trim(lower(o.c_operator)) = 'like'
          AND trim(o.m_applied_path) = '@'
          AND o.c_fullname IS NOT NULL
          AND (o.c_visualattributes NOT LIKE 'L%%' OR f.fact_cd IS NOT NULL)
    $sql$, v_metadata, v_fact_column, v_observation,
          v_fact_filter, tablename, columnname);

    CREATE INDEX dim_fullname ON pg_temp.dimcountont (c_fullname);

    -- Recursive hierarchy: strip the final path component, preserving the
    -- trailing backslash of each ancestor, until the root is reached.
    CREATE TEMP TABLE dimontwithfolders ON COMMIT PRESERVE ROWS AS
    WITH RECURSIVE concepts(c_fullname, c_hlevel, c_basecode) AS (
        SELECT c_fullname::text, c_hlevel::integer, c_basecode
        FROM pg_temp.dimcountont
        UNION ALL
        SELECT left(c_fullname,
                    length(c_fullname) - strpos(reverse(left(c_fullname, length(c_fullname)-1)), E'\\')
                   )::text,
               c_hlevel - 1,
               c_basecode
        FROM concepts
        WHERE c_hlevel >= 0
          AND length(c_fullname) > 1
          AND strpos(reverse(left(c_fullname, length(c_fullname)-1)), E'\\') > 0
    )
    SELECT DISTINCT c_fullname, c_basecode FROM concepts;

    CREATE INDEX dimfldbasecode ON pg_temp.dimontwithfolders(c_basecode);
    v_duration := round((extract(epoch FROM clock_timestamp() - v_startime) * 1000)::numeric, 0);
    RAISE NOTICE '(BENCH) %,collected ontology,% ms', metadataTable, v_duration;
    v_startime := clock_timestamp();

    CREATE TEMP TABLE path2num ON COMMIT PRESERVE ROWS AS
    SELECT c_fullname, row_number() OVER (ORDER BY c_fullname) AS path_num
    FROM (SELECT DISTINCT c_fullname FROM pg_temp.dimontwithfolders) t;
    CREATE INDEX path2num_idx ON pg_temp.path2num(c_fullname);

    CREATE TEMP TABLE conceptpath ON COMMIT PRESERVE ROWS AS
    SELECT DISTINCT n.path_num, o.c_basecode
    FROM pg_temp.path2num n
    JOIN pg_temp.dimontwithfolders o ON o.c_fullname = n.c_fullname
    WHERE o.c_fullname IS NOT NULL AND o.c_basecode IS NOT NULL;
    ALTER TABLE pg_temp.conceptpath ADD PRIMARY KEY (c_basecode, path_num);

    EXECUTE format($sql$
        CREATE TEMP TABLE pathcounts ON COMMIT PRESERVE ROWS AS
        SELECT p.path_num, count(DISTINCT o.patient_num) AS num_patients
        FROM pg_temp.conceptpath p
        LEFT JOIN %s o ON p.c_basecode = o.%I
        GROUP BY p.path_num
    $sql$, v_observation, v_fact_column);
    ALTER TABLE pg_temp.pathcounts ADD PRIMARY KEY (path_num);

    CREATE TEMP TABLE finaldimcounts ON COMMIT PRESERVE ROWS AS
    SELECT p.c_fullname, c.num_patients
    FROM pg_temp.pathcounts c
    JOIN pg_temp.path2num p ON p.path_num = c.path_num;
    CREATE INDEX finaldimcounts_fullname ON pg_temp.finaldimcounts(c_fullname);

    v_duration := round((extract(epoch FROM clock_timestamp() - v_startime) * 1000)::numeric, 0);
    RAISE NOTICE '(BENCH) %,counted facts,% ms', metadataTable, v_duration;
    v_startime := clock_timestamp();

    EXECUTE format($sql$
        UPDATE %s a SET c_totalnum = (
            SELECT b.num_patients FROM pg_temp.finaldimcounts b
            WHERE b.c_fullname = a.c_fullname
        )
        WHERE lower(a.c_facttablecolumn) LIKE %L
          AND lower(a.c_tablename) = lower(%L)
          AND lower(a.c_columnname) = lower(%L)
    $sql$, v_metadata, v_fact_filter, tablename, columnname);

    INSERT INTO totalnum(c_fullname, agg_date, agg_count, typeflag_cd)
    SELECT c_fullname, CURRENT_DATE, num_patients, 'PF'
    FROM pg_temp.finaldimcounts
    WHERE num_patients > 0;

    DROP TABLE pg_temp.dimcountont;
    DROP TABLE pg_temp.dimontwithfolders;
    DROP TABLE pg_temp.path2num;
    DROP TABLE pg_temp.conceptpath;
    DROP TABLE pg_temp.pathcounts;
    DROP TABLE pg_temp.finaldimcounts;

    v_duration := round((extract(epoch FROM clock_timestamp() - v_startime) * 1000)::numeric, 0);
    RAISE NOTICE '(BENCH) %,cleanup,% ms', metadataTable, v_duration;
EXCEPTION WHEN OTHERS THEN
    errorMsg := SQLERRM;
    RAISE NOTICE 'PAT_COUNT_DIMENSIONS failed for %: %', metadataTable, SQLERRM;
END;
$procedure$;
GO
