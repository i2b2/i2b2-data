-- pat_visit_counts(tabname)
-- DISCLAIMER: assumes that the default value for missing sex_cd is lower('not recorded')
-- adjust the function if a different value is used
-- By Mike Mendis, Partners Healthcare
-- Based on code from Dan Vianello, Center for Biomedical Informatics, Washington University in St. Louis
-- Assumes ontology metadata and dimension tables are in schemaName.


CREATE OR REPLACE PROCEDURE public.pat_count_visits(
    IN metadataTable VARCHAR,
    IN schemaName VARCHAR,
    INOUT errorMsg VARCHAR
)
LANGUAGE plpgsql
AS $procedure$
DECLARE
    rec RECORD;
    v_metadata_table TEXT;
    v_dimension_table TEXT;
    v_predicate TEXT;
    v_sql TEXT;
    v_count BIGINT;
BEGIN
    errorMsg := NULL;

    IF metadataTable IS NULL OR btrim(metadataTable) = '' OR
       schemaName IS NULL OR btrim(schemaName) = '' THEN
        RAISE EXCEPTION 'metadataTable and schemaName are required';
    END IF;

    -- Unqualified ontology tables are resolved in the supplied schema.
    -- Qualified names may be supplied as schema.table.
    IF strpos(metadataTable, '.') > 0 THEN
        IF array_length(string_to_array(metadataTable, '.'), 1) <> 2 THEN
            RAISE EXCEPTION 'Invalid metadata table name: %', metadataTable;
        END IF;
        v_metadata_table := format('%I.%I', split_part(metadataTable, '.', 1),
                                             split_part(metadataTable, '.', 2));
    ELSE
        v_metadata_table := format('%I.%I', schemaName, metadataTable);
    END IF;

    -- A session-local table avoids collisions between concurrent executions.
    DROP TABLE IF EXISTS pg_temp.ontpatvisitdims;

    EXECUTE format($sql$
        CREATE TEMP TABLE ontpatvisitdims ON COMMIT PRESERVE ROWS AS
        SELECT c_fullname, c_basecode, c_facttablecolumn,
               c_tablename, c_columnname, c_operator, c_dimcode,
               c_totalnum AS numpats
        FROM %s
        WHERE m_applied_path = '@'
          AND lower(c_tablename) IN ('patient_dimension', 'visit_dimension')
    $sql$, v_metadata_table);

    CREATE INDEX ontpatvisitdims_idx ON pg_temp.ontpatvisitdims (c_fullname);

    FOR rec IN
        SELECT c_fullname, c_facttablecolumn, c_tablename,
               c_columnname, c_operator, c_dimcode
        FROM pg_temp.ontpatvisitdims
    LOOP
        v_dimension_table := format('%I.%I', schemaName, lower(btrim(rec.c_tablename)));

        IF lower(btrim(rec.c_columnname)) = 'birth_date'
           AND lower(btrim(rec.c_tablename)) = 'patient_dimension'
           AND lower(rec.c_dimcode) LIKE '%not recorded%' THEN
            v_predicate := 'IS NULL';
        ELSIF lower(btrim(rec.c_operator)) = 'like' THEN
            v_predicate := format('LIKE %L', coalesce(rec.c_dimcode, '') || '%');
        ELSIF lower(btrim(rec.c_operator)) = 'in' THEN
            v_predicate := 'IN ' ||
                CASE WHEN left(btrim(rec.c_dimcode), 1) = '('
                     THEN rec.c_dimcode
                     ELSE '(' || rec.c_dimcode || ')' END;
        ELSIF btrim(rec.c_operator) = '=' THEN
            v_predicate := format('= %L', rec.c_dimcode);
        ELSE
            v_predicate := btrim(rec.c_operator) || ' ' || coalesce(rec.c_dimcode, 'NULL');
        END IF;

        v_sql := format(
            'SELECT COUNT(DISTINCT patient_num) FROM %s WHERE %I %s',
            v_dimension_table, btrim(rec.c_columnname), v_predicate
        );
        EXECUTE v_sql INTO v_count;

        -- As in the Oracle source, fill only NULL working counts.
        UPDATE pg_temp.ontpatvisitdims
           SET numpats = v_count
         WHERE c_fullname = rec.c_fullname
           AND numpats IS NULL;
    END LOOP;

    -- MAX avoids scalar-subquery errors for duplicate ontology paths.
    EXECUTE format($sql$
        UPDATE %s AS a
           SET c_totalnum = (
               SELECT max(b.numpats)
               FROM pg_temp.ontpatvisitdims AS b
               WHERE b.c_fullname = a.c_fullname AND b.numpats > 0
           )
    $sql$, v_metadata_table);

    EXECUTE format($sql$
        INSERT INTO %I.totalnum (c_fullname, agg_date, agg_count, typeflag_cd)
        SELECT c_fullname, CURRENT_DATE, numpats, 'PD'
        FROM pg_temp.ontpatvisitdims
    $sql$, schemaName);

    DROP TABLE IF EXISTS pg_temp.ontpatvisitdims;
    RAISE NOTICE 'PAT_COUNT_VISITS completed for %', v_metadata_table;

EXCEPTION WHEN OTHERS THEN
    errorMsg := SQLERRM;
    RAISE NOTICE 'PAT_COUNT_VISITS failed for %: %', metadataTable, errorMsg;
END;
$procedure$;
GO

-- Standalone example:
-- CALL public.pat_count_visits('metadata_recover_adult', 'public', NULL);
-- From PL/pgSQL RunTotalnumClassic:
-- CALL public.pat_count_visits(sqltext, schemaName, v_errormsg);
