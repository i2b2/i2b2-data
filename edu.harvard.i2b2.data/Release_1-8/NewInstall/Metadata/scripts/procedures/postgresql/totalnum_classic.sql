-- Classic/legacy function to run totalnum counts on all tables in table_access
-- 6/8/2016 - modified for PostgreSQL by Dan Vianello, Center for Biomedical Informatics, Washington University in St. Louis
-- 2019 - Modified for i2b2 1.7.12 release by Mike Mendis, Partners Healthcare
-- 2020 - Updated to support reporting and single-table runs by Jeff Klann, Massachusetts General Hospital
-- The runtotalnum compatibility wrapper is defined in totalnum_run.sql and defaults to the fast totalnum workflow.

-- Usage example:
--     select runtotalnumclassic('observation_fact','public')
--   (replace 'public' by the schema name for the fact table)
-- If using a schema other than public for metadata, you might need to run "set search_path to 'i2b2metadata','public' " first as well
-- You can optionally specify a single table name, to count using only one ontology table. This is case sensitive.
--
--   To use with multi-fact setups: Create a fact table view as the union of all your fact tables. (This is essentially going back to a single fact table,  but it is only used
--     for totalnum counting. This is needed to correctly count patients that mention multiple fact tables within a hierarchy.)
--    e.g., 
--       create view observation_fact_view as
--       select * from CONDITION_VIEW 
--       union all
--       select * from drug_view
--    And then run the totalnum counter on that fact table:
--      e.g., runtotalnumclassic('observation_fact_view','public');
--    Note this approach does not work if you have conflicting concept_cds across fact tables.
-- Corrected RunTotalnumClassic: normalize blank arguments and lowercase ontology names.
-- PostgreSQL conversion of Oracle RunTotalnumClassic.
-- Requires PostgreSQL procedures pat_count_visits, pat_count_dimensions,
-- and buildtotalnumreport with compatible signatures.
CREATE OR REPLACE PROCEDURE RunTotalnumClassic(
    IN observationTable varchar DEFAULT 'observation_fact',
    IN schemaName varchar DEFAULT 'public',
    IN tableName varchar DEFAULT '@',
    IN wildcard_factcolumn varchar DEFAULT 'N'
)
LANGUAGE plpgsql
AS $procedure$
DECLARE
    sqlstr text;
    startime timestamptz;
    derived_facttablecolumn text;
    facttablecolumn_prefix text;
    v_count bigint;
    v_observation_table text;
    v_metadata_table text;
    v_errormsg text;
    rec record;
    v_schema text;
    v_observation_name text;
    v_selected_table text;
BEGIN
    -- Normalize Oracle-style empty strings and unquoted PostgreSQL names.
    v_schema := lower(coalesce(nullif(btrim(schemaName), ''), 'public'));
    v_observation_name := lower(coalesce(nullif(btrim(observationTable), ''), 'observation_fact'));
    v_selected_table := coalesce(nullif(btrim(tableName), ''), '@');

    IF position('.' IN v_observation_name) > 0 THEN
        IF split_part(v_observation_name, '.', 1) = ''
           OR split_part(v_observation_name, '.', 2) = ''
           OR split_part(v_observation_name, '.', 3) <> '' THEN
            RAISE EXCEPTION 'Invalid observationTable: %', observationTable;
        END IF;
        v_observation_table := format('%I.%I',
            split_part(v_observation_name, '.', 1),
            split_part(v_observation_name, '.', 2));
    ELSE
        v_observation_table := format('%I.%I', v_schema, v_observation_name);
    END IF;

    IF to_regclass(v_observation_table) IS NULL THEN
        RAISE EXCEPTION 'Observation table % does not exist', v_observation_table;
    END IF;

    -- Resolve unqualified dependency calls and tables in the requested schema.
    PERFORM set_config('search_path', format('%I, pg_catalog', v_schema), true);

    -- A temporary table avoids dropping a permanent shared table.
    CREATE TEMP TABLE IF NOT EXISTS tnum_conceptpatient (
        patient_num bigint NOT NULL,
        concept_cd varchar(50) NOT NULL,
        CONSTRAINT pkconpat PRIMARY KEY (concept_cd, patient_num)
    ) ON COMMIT PRESERVE ROWS;
    TRUNCATE TABLE pg_temp.tnum_conceptpatient;

    RAISE NOTICE 'Building tnum_conceptpatient';
    sqlstr := format('INSERT INTO pg_temp.tnum_conceptpatient (concept_cd, patient_num) SELECT DISTINCT concept_cd, patient_num FROM %s f', v_observation_table);
    RAISE NOTICE 'Running: %', sqlstr;
    EXECUTE sqlstr;

    FOR rec IN
        SELECT DISTINCT c_table_name
        FROM table_access
        WHERE c_visualattributes LIKE '%A%'
    LOOP
        IF nullif(btrim(rec.c_table_name), '') IS NULL THEN CONTINUE; END IF;
        IF position('.' IN rec.c_table_name) > 0 THEN
            v_metadata_table := format('%I.%I', lower(split_part(rec.c_table_name, '.', 1)), lower(split_part(rec.c_table_name, '.', 2)));
        ELSE
            v_metadata_table := format('%I.%I', v_schema, lower(rec.c_table_name));
        END IF;

        IF v_observation_name = 'observation_fact' THEN
            derived_facttablecolumn := '';
        ELSE
            derived_facttablecolumn := v_observation_name || '.';
        END IF;

        IF upper(coalesce(wildcard_factcolumn, 'N')) = 'Y' THEN
            facttablecolumn_prefix := '%';
        ELSIF v_observation_name = 'observation_fact' THEN
            facttablecolumn_prefix := '';
        ELSE
            facttablecolumn_prefix := v_observation_name || '.';
        END IF;

        IF v_selected_table = '@' OR lower(v_selected_table) = lower(rec.c_table_name) THEN
            IF to_regclass(v_metadata_table) IS NULL THEN
                RAISE EXCEPTION 'Ontology table % does not exist (TABLE_ACCESS name: %)',
                    v_metadata_table, rec.c_table_name;
            END IF;
            RAISE NOTICE 'Processing %', v_metadata_table;
            EXECUTE format('UPDATE %s SET c_totalnum = NULL', v_metadata_table);

            -- Oracle treats '' as NULL. Preserve the original visit-counting
            -- branch when using the default observation_fact table.
            IF derived_facttablecolumn = '' THEN
                startime := clock_timestamp();
                v_errormsg := NULL;
                CALL pat_count_visits(lower(rec.c_table_name), v_schema, v_errormsg);
                IF v_errormsg IS NOT NULL THEN
                    RAISE NOTICE 'PAT_COUNT_VISITS: %', v_errormsg;
                END IF;
                RAISE NOTICE '% PAT_COUNT_VISITS: % seconds', rec.c_table_name, extract(epoch FROM clock_timestamp() - startime);
            END IF;

            startime := clock_timestamp();
            derived_facttablecolumn := facttablecolumn_prefix || 'concept_cd';
            v_errormsg := NULL;
            CALL pat_count_dimensions(lower(rec.c_table_name), v_schema, v_observation_name,
                                      derived_facttablecolumn, 'concept_dimension', 'concept_path', v_errormsg);
            IF v_errormsg IS NOT NULL THEN RAISE NOTICE 'PAT_COUNT_concept_dimension: %', v_errormsg; END IF;
            RAISE NOTICE '% PAT_COUNT_concept_dimension: % seconds', rec.c_table_name, extract(epoch FROM clock_timestamp() - startime);

            startime := clock_timestamp();
            derived_facttablecolumn := facttablecolumn_prefix || 'provider_id';
            v_errormsg := NULL;
            CALL pat_count_dimensions(lower(rec.c_table_name), v_schema, v_observation_name,
                                      derived_facttablecolumn, 'provider_dimension', 'provider_path', v_errormsg);
            IF v_errormsg IS NOT NULL THEN RAISE NOTICE 'PAT_COUNT_provider_dimension: %', v_errormsg; END IF;
            RAISE NOTICE '% PAT_COUNT_provider_dimension: % seconds', rec.c_table_name, extract(epoch FROM clock_timestamp() - startime);

            startime := clock_timestamp();
            derived_facttablecolumn := facttablecolumn_prefix || 'modifier_cd';
            v_errormsg := NULL;
            CALL pat_count_dimensions(lower(rec.c_table_name), v_schema, v_observation_name,
                                      derived_facttablecolumn, 'modifier_dimension', 'modifier_path', v_errormsg);
            IF v_errormsg IS NOT NULL THEN RAISE NOTICE 'PAT_COUNT_modifier_dimension: %', v_errormsg; END IF;
            RAISE NOTICE '% PAT_COUNT_modifier_dimension: % seconds', rec.c_table_name, extract(epoch FROM clock_timestamp() - startime);

            EXECUTE format(
                'UPDATE %I.table_access t SET c_totalnum = (SELECT MAX(x.c_totalnum) FROM %s x WHERE x.c_fullname = t.c_fullname) WHERE EXISTS (SELECT 1 FROM %s x WHERE x.c_fullname = t.c_fullname)',
                v_schema, v_metadata_table, v_metadata_table
            );
            EXECUTE format('UPDATE %s SET c_totalnum = NULL WHERE c_totalnum = 0 AND c_visualattributes LIKE ''C%%''', v_metadata_table);
        END IF;
    END LOOP;

    EXECUTE format('UPDATE %I.table_access SET c_totalnum = NULL WHERE c_totalnum = 0', v_schema);

    EXECUTE format('SELECT COUNT(*) FROM %I.totalnum WHERE c_fullname = %L AND agg_date::date = CURRENT_DATE', v_schema, E'\\denominator\\facts\\') INTO v_count;
    IF v_count = 0 THEN
        EXECUTE format('INSERT INTO %I.totalnum (c_fullname, agg_date, agg_count, typeflag_cd) SELECT %L, CURRENT_TIMESTAMP, COUNT(DISTINCT patient_num), ''PX'' FROM %s',
                       v_schema, E'\\denominator\\facts\\', v_observation_table);
    END IF;

    DROP TABLE IF EXISTS pg_temp.tnum_conceptpatient;
    -- Report procedure must exist with compatible numeric argument types.
    CALL buildtotalnumreport(10, 6.5);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'RunTotalnumClassic failed: % (SQLSTATE %)', SQLERRM, SQLSTATE;
    RAISE;
END;
$procedure$;
GO
