/*
--------------------------------------------------------------------------------
Postgres Version: FastTotalnumOutput Procedure
--------------------------------------------------------------------------------
Fast version by Darren Henderson (DARREN.HENDERSON@UKY.EDU) and Jeff Klann, PhD.
Based on code by Mike Mendis, Jeff Klann, and others.

Description:
  This procedure writes the most recent totalnum counts from the totalnum table into
  the ontology tables specified in table_access and then generates an obfuscated report
  in the totalnum_report table. It updates the c_totalnum column in both the ontology
  tables and in table_access. The report build is optional: if make_report.sql has not
  been loaded, the ontology and table_access updates still remain in place.
  
Usage Examples:
  -- To run on all ontology tables:
  CALL fasttotalnumoutput('public','@');
  
  -- To run on a specific ontology table (e.g., 'my_ontology'):
  CALL fasttotalnumoutput('public', 'my_ontology');

Acknowledgement:
  This Postgres conversion was assisted by ChatGPT.
--------------------------------------------------------------------------------
*/
-- Preserves the ontology updates, PF/PA selection, conflict checks,
-- denominator calculation, and optional obfuscated report.
-- Assumes ordinary unquoted/lowercase PostgreSQL table and column names.

CREATE OR REPLACE PROCEDURE public.fasttotalnumoutput(
    IN schemaname VARCHAR DEFAULT 'public',
    IN tablename VARCHAR DEFAULT '@',
    IN demographics_mode VARCHAR DEFAULT 'act'
)
LANGUAGE plpgsql
AS $procedure$
DECLARE
    sqlstr TEXT;
    count_source TEXT;
    start_time TIMESTAMP;
    mode_norm TEXT;
    act_demo_table TEXT;
    conflict_count BIGINT;
    metadata_object TEXT;
    rec RECORD;
    cnt BIGINT;
    affected BIGINT;
    schema_ident TEXT;
    access_table TEXT;
    totalnum_table TEXT;
    pairs_view TEXT;
BEGIN
    IF schemaname IS NULL OR btrim(schemaname) = '' THEN
        RAISE EXCEPTION 'schemaname must not be empty';
    END IF;

    schemaname := lower(btrim(schemaname));
    schema_ident := format('%I', schemaname);
    access_table := format('%I.table_access', schemaname);
    totalnum_table := format('%I.totalnum', schemaname);
    pairs_view := format('%I.obsfact_pairs', schemaname);

    mode_norm := lower(coalesce(nullif(btrim(demographics_mode), ''), 'act'));
    IF mode_norm NOT IN ('act', 'all') THEN
        RAISE EXCEPTION 'Invalid demographics_mode. Use act or all.';
    END IF;

    EXECUTE format(
        'SELECT max(c_table_name) FROM %s WHERE upper(c_table_cd) = ''ACT_DEMO''',
        access_table
    ) INTO act_demo_table;

    start_time := clock_timestamp();

    -- Process ontology tables registered in TABLE_ACCESS.
    FOR rec IN EXECUTE format(
        'SELECT DISTINCT c_table_name FROM %s
          WHERE c_visualattributes LIKE ''%%A%%''
            AND c_table_name IS NOT NULL
            AND c_table_name <> ''@''
            AND ($1 = ''@'' OR lower(c_table_name) = lower($1))',
        access_table
    ) USING tablename
    LOOP
        -- Oracle metadata may use uppercase names; physical PG tables are lowercase.
        -- Accept either table_name or schema.table_name from TABLE_ACCESS.
        IF strpos(rec.c_table_name, '.') > 0 THEN
            IF split_part(rec.c_table_name, '.', 1) = ''
               OR split_part(rec.c_table_name, '.', 2) = ''
               OR split_part(rec.c_table_name, '.', 3) <> '' THEN
                RAISE EXCEPTION 'Invalid ontology table name: %', rec.c_table_name;
            END IF;
            metadata_object := format('%I.%I',
                lower(split_part(rec.c_table_name, '.', 1)),
                lower(split_part(rec.c_table_name, '.', 2)));
        ELSE
            metadata_object := format('%I.%I', schemaname, lower(rec.c_table_name));
        END IF;
        IF to_regclass(metadata_object) IS NULL THEN
            RAISE EXCEPTION 'Ontology table % does not exist (TABLE_ACCESS C_TABLE_NAME: %)',
                metadata_object, rec.c_table_name;
        END IF;
        RAISE NOTICE 'Processing ontology table: %', metadata_object;

        count_source := format(
            'SELECT row_number() OVER (
                PARTITION BY c_fullname
                ORDER BY agg_date DESC,
                         CASE WHEN typeflag_cd = ''PA'' THEN 1 ELSE 0 END DESC,
                         agg_count DESC
             ) AS rn, c_fullname, agg_count
             FROM %s WHERE typeflag_cd %s',
            totalnum_table,
            CASE WHEN mode_norm = 'all'
                      AND (act_demo_table IS NULL OR lower(rec.c_table_name) <> lower(act_demo_table))
                 THEN 'IN (''PF'', ''PA'')'
                 ELSE '= ''PF''' END
        );

        RAISE NOTICE 'Ready to process % (elapsed: %)',
            metadata_object, clock_timestamp() - start_time;
        start_time := clock_timestamp();

        -- Step 1: Clear existing ontology counts.
        sqlstr := format('UPDATE %s SET c_totalnum = NULL', metadata_object);
        EXECUTE sqlstr;
        GET DIAGNOSTICS affected = ROW_COUNT;
        RAISE NOTICE 'Rows affected (clear): %', affected;

        -- Step 2: Initialize eligible ontology counts to zero.
        sqlstr := format(
            'UPDATE %s SET c_totalnum = 0
             WHERE c_operator = ''LIKE'' AND c_visualattributes LIKE ''%%A%%''',
            metadata_object
        );
        EXECUTE sqlstr;
        GET DIAGNOSTICS affected = ROW_COUNT;
        RAISE NOTICE 'Rows affected (initialize): %', affected;

        -- Step 3: Apply the latest count per full name.
        sqlstr := format(
            'UPDATE %s AS o SET c_totalnum = t.agg_count
             FROM (%s) AS t
             WHERE t.c_fullname = o.c_fullname AND t.rn = 1',
            metadata_object, count_source
        );
        EXECUTE sqlstr;
        GET DIAGNOSTICS affected = ROW_COUNT;
        RAISE NOTICE 'Rows affected (counts): %', affected;

        -- Step 4: Reject conflicting duplicate ontology counts.
        sqlstr := format(
            'SELECT count(*) FROM (
                 SELECT c_fullname FROM %s
                 GROUP BY c_fullname
                 HAVING count(DISTINCT c_totalnum) > 1
             ) AS conflicts', metadata_object
        );
        EXECUTE sqlstr INTO conflict_count;
        IF conflict_count > 0 THEN
            RAISE EXCEPTION
                'Conflicting C_TOTALNUM values found in % for % C_FULLNAME values.',
                metadata_object, conflict_count;
        END IF;

        -- Step 5: Update TABLE_ACCESS from this ontology table.
        sqlstr := format(
            'UPDATE %s AS t SET c_totalnum = (
                 SELECT max(x.c_totalnum) FROM %s AS x
                 WHERE x.c_fullname = t.c_fullname
             ) WHERE EXISTS (
                 SELECT 1 FROM %s AS x WHERE x.c_fullname = t.c_fullname
             )',
            access_table, metadata_object, metadata_object
        );
        EXECUTE sqlstr;
        GET DIAGNOSTICS affected = ROW_COUNT;
        RAISE NOTICE 'Rows affected (table_access): %', affected;

        -- Step 6: Suppress zero counts on C% ontology attributes.
        sqlstr := format(
            'UPDATE %s SET c_totalnum = NULL
             WHERE c_totalnum = 0 AND c_visualattributes LIKE ''C%%''',
            metadata_object
        );
        EXECUTE sqlstr;
    END LOOP;

    -- Step 7: Refresh TABLE_ACCESS directly from TOTALNUM.
    count_source := format(
        'SELECT row_number() OVER (
             PARTITION BY c_fullname
             ORDER BY agg_date DESC,
                      CASE WHEN typeflag_cd = ''PA'' THEN 1 ELSE 0 END DESC,
                      agg_count DESC
         ) AS rn, c_fullname, agg_count
         FROM %s WHERE typeflag_cd %s',
        totalnum_table,
        CASE WHEN mode_norm = 'all' THEN 'IN (''PF'', ''PA'')'
             ELSE '= ''PF''' END
    );
    sqlstr := format(
        'UPDATE %s AS t SET c_totalnum = x.agg_count
         FROM (%s) AS x
         WHERE x.c_fullname = t.c_fullname AND x.rn = 1',
        access_table, count_source
    );
    EXECUTE sqlstr;
    GET DIAGNOSTICS affected = ROW_COUNT;
    RAISE NOTICE 'Rows affected (direct table_access refresh): %', affected;

    -- Step 8: Suppress zero counts in TABLE_ACCESS.
    EXECUTE format(
        'UPDATE %s SET c_totalnum = NULL WHERE c_totalnum = 0',
        access_table
    );

    -- Step 9: Add today's denominator if it does not exist.
    EXECUTE format(
        'SELECT count(*) FROM %s
         WHERE c_fullname = $1 AND agg_date >= current_date
           AND agg_date < current_date + INTERVAL ''1 day''',
        totalnum_table
    ) INTO cnt USING E'\\denominator\\facts\\';

    IF cnt = 0 THEN
        EXECUTE format(
            'INSERT INTO %s (c_fullname, agg_date, agg_count, typeflag_cd)
             SELECT $1, clock_timestamp(), count(DISTINCT patient_num), ''PX''
             FROM %s',
            totalnum_table, pairs_view
        ) USING E'\\denominator\\facts\\';
    END IF;

    -- Step 10: Optional obfuscated report.
    -- Requires a PostgreSQL procedure buildtotalnumreport(numeric, numeric, text).
    BEGIN
        RAISE NOTICE 'Calling BuildTotalnumReport(10, 6.5, %) ', mode_norm;
        EXECUTE format('CALL %I.buildtotalnumreport($1, $2, $3)', schemaname)
            USING 10::numeric, 6.5::numeric, mode_norm;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Skipping totalnum report build. Verify BuildTotalnumReport and TOTALNUM_REPORT. Error: %', SQLERRM;
    END;

    -- No COMMIT/ROLLBACK here: transaction is controlled by the caller.
    RAISE NOTICE 'FastTotalnumOutput completed successfully.';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ERROR in FastTotalnumOutput: %', SQLERRM;
    RAISE;
END;
$procedure$;
GO

-- Example:
-- CALL public.fasttotalnumoutput('public', '@', 'act');
-- CALL public.fasttotalnumoutput('public', '@', 'all');
