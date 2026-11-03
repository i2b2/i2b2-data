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
-- Remove the unused source_mode signature if it was installed by an upgrade.
DROP ROUTINE IF EXISTS fasttotalnumoutput(text, text, text);
DROP ROUTINE IF EXISTS fasttotalnumoutput(text, text);

CREATE OR REPLACE PROCEDURE fasttotalnumoutput(schemaname text DEFAULT 'public', tablename text DEFAULT '@', demographics_mode text DEFAULT 'act')
LANGUAGE plpgsql
AS $sql$
DECLARE
    sqlstr text;
    sqltext text;
    rec record;
    start_time timestamp;
    row_count integer;
    mode_norm text;
    act_demo_table text;
    count_predicate text;
BEGIN
    mode_norm := lower(coalesce(nullif(demographics_mode, ''), 'act'));
    IF mode_norm NOT IN ('act', 'all') THEN
      RAISE EXCEPTION 'Invalid demographics_mode. Use act or all.';
    END IF;
    SELECT max(c_table_name) INTO act_demo_table FROM table_access
      WHERE upper(c_table_cd) = 'ACT_DEMO';
    start_time := now();
    -- Iterate through each distinct ontology table from table_access (with c_visualattributes like '%A%')
    FOR rec IN
      SELECT DISTINCT c_table_name FROM table_access WHERE c_visualattributes LIKE '%A%'
    LOOP
      sqltext := rec.c_table_name;
      IF tablename = '@' OR tablename = sqltext THEN
        count_predicate := CASE WHEN mode_norm = 'all' AND sqltext IS DISTINCT FROM act_demo_table
                                THEN 'IN (''PF'', ''PA'')' ELSE '= ''PF''' END;
        PERFORM endtime(start_time, sqltext, 'ready to go');
        start_time := now();
        
        -- Null the counts in the ontology table
        sqlstr := 'UPDATE ' || sqltext || ' SET c_totalnum = NULL';
        RAISE NOTICE '%', sqlstr;
        EXECUTE sqlstr;
        GET DIAGNOSTICS row_count = ROW_COUNT;
        RAISE NOTICE 'Rows affected: %', row_count;
        
        -- Set zero counts where c_operator = ''LIKE'' and c_visualattributes LIKE '%A%'
        sqlstr := 'UPDATE ' || sqltext ||
                  ' SET c_totalnum = 0 WHERE c_operator = ''LIKE'' AND c_visualattributes LIKE ''%A%''';
        RAISE NOTICE '%', sqlstr;
        EXECUTE sqlstr;
        GET DIAGNOSTICS row_count = ROW_COUNT;
        RAISE NOTICE 'Rows affected: %', row_count;
        
        -- Update counts in the ontology table using the latest record from totalnum.
        sqlstr := 'UPDATE ' || sqltext || ' o SET c_totalnum = t.agg_count ' ||
                  'FROM ( ' ||
                  '  SELECT c_fullname, agg_count, row_number() OVER (PARTITION BY c_fullname ORDER BY agg_date DESC, CASE WHEN typeflag_cd = ''PA'' THEN 1 ELSE 0 END DESC) as rn ' ||
                  '  FROM totalnum WHERE typeflag_cd ' || count_predicate || ' ' ||
                  ') t ' ||
                  'WHERE o.c_fullname = t.c_fullname AND t.rn = 1';
        RAISE NOTICE '%', sqlstr;
        EXECUTE sqlstr;
        GET DIAGNOSTICS row_count = ROW_COUNT;
        RAISE NOTICE 'Rows affected: %', row_count;
        
        -- Update counts in table_access from the ontology table.
        sqlstr := 'UPDATE table_access t SET c_totalnum = x.c_totalnum ' ||
                  'FROM ' || sqltext || ' x ' ||
                  'WHERE x.c_fullname = t.c_fullname';
        RAISE NOTICE '%', sqlstr;
        EXECUTE sqlstr;
        GET DIAGNOSTICS row_count = ROW_COUNT;
        RAISE NOTICE 'Rows affected: %', row_count;
        
        -- Null out cases that are actually 0 where c_visualattributes LIKE ''C%''
        sqlstr := 'UPDATE ' || sqltext ||
                  ' SET c_totalnum = NULL WHERE c_totalnum = 0 AND c_visualattributes LIKE ''C%''';
        RAISE NOTICE '%', sqlstr;
        EXECUTE sqlstr;
        GET DIAGNOSTICS row_count = ROW_COUNT;
        RAISE NOTICE 'Rows affected: %', row_count;
      END IF;
    END LOOP;

    -- Refresh top-level table_access counts directly from the latest totalnum rows.
    sqlstr := 'UPDATE table_access t SET c_totalnum = x.agg_count ' ||
              'FROM ( ' ||
              '  SELECT c_fullname, agg_count, row_number() OVER (PARTITION BY c_fullname ORDER BY agg_date DESC, CASE WHEN typeflag_cd = ''PA'' THEN 1 ELSE 0 END DESC) AS rn ' ||
              '  FROM totalnum WHERE typeflag_cd ' ||
              CASE WHEN mode_norm = 'all' THEN 'IN (''PF'', ''PA'')' ELSE '= ''PF''' END || ' ' ||
              ') x ' ||
              'WHERE x.c_fullname = t.c_fullname AND x.rn = 1';
    RAISE NOTICE '%', sqlstr;
    EXECUTE sqlstr;
    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE 'Rows affected: %', row_count;
    
    -- Cleanup: set c_totalnum to NULL in table_access where the value is 0.
    sqlstr := 'UPDATE table_access SET c_totalnum = NULL WHERE c_totalnum = 0';
    RAISE NOTICE '%', sqlstr;
    EXECUTE sqlstr;
    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE 'Rows affected: %', row_count;
    
    -- Denominator: if no row exists in totalnum for c_fullname = ''\denominator\facts\'' today, then insert one.
    IF (SELECT COUNT(*) FROM totalnum 
        WHERE c_fullname = E'\denominator\\facts\\' 
          AND agg_date::date = current_date) = 0 THEN
      sqlstr := 'INSERT INTO totalnum(c_fullname, agg_date, agg_count, typeflag_cd) ' ||
                'SELECT E''\denominator\\facts\\'', now(), COUNT(DISTINCT patient_num), ''PX'' ' ||
                'FROM obsfact_pairs';
      RAISE NOTICE '%', sqlstr;
      BEGIN
        EXECUTE sqlstr;
        GET DIAGNOSTICS row_count = ROW_COUNT;
        RAISE NOTICE 'Rows affected: %', row_count;
      END;
    END IF;
    
    -- Build the report table by calling the BuildTotalnumReport procedure with parameters 10 and 6.5.
    BEGIN
      RAISE NOTICE 'Calling buildtotalnumreport(10, 6.5::float)';
      PERFORM buildtotalnumreport(10, 6.5::float, mode_norm);
    EXCEPTION
      WHEN undefined_function THEN
        RAISE NOTICE 'Skipping totalnum_report build: buildtotalnumreport(int, float, text) is not loaded.';
      WHEN undefined_table THEN
        RAISE NOTICE 'Skipping totalnum_report build: totalnum_report is not visible.';
    END;
    
END;
$sql$;
