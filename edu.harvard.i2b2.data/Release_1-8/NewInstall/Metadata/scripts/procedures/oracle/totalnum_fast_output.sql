/*
Oracle Version: FastTotalnumOutput Procedure
By Mike Mendis and Jeff Klann, PhD with performance optimization by Darren Henderson (UKY)
This Oracle conversion was assisted by ChatGPT.
------------------------------------------------------------
Description:
This procedure writes the most recent totalnum counts from the TOTALNUM table into the ontology tables
specified in the TABLE_ACCESS table and generates a report (TOTALNUM_REPORT) with obfuscated counts.
It assumes that:
  - The ontology tables (listed in TABLE_ACCESS with c_visualattributes like '%A%') already exist.
  - Supporting procedures (e.g., FastTotalnumCount, EndTime, BuildTotalnumReport) have been converted to Oracle.
  - Any dynamic SQL used in this procedure is executed via EXECUTE IMMEDIATE.
  - Date functions (SYSDATE, TRUNC) and string operations are used in Oracle-compatible form.
  - The procedure runs with AUTHID CURRENT_USER so unqualified ontology table names
    from TABLE_ACCESS resolve in the caller's schema, matching the classic runtotalnum behavior.

Usage Example in Oracle:
------------------------------------------------------------
To run this procedure in Oracle SQL*Plus or SQL Developer, execute one of the following blocks:

-- To run on all ontology tables (default behavior):
BEGIN
  FastTotalnumOutput; 
END;
/

-- To run on a specific ontology table (e.g., 'MY_ONTOLOGY'):
BEGIN
  FastTotalnumOutput('MY_SCHEMA', 'MY_ONTOLOGY');
END;
/

Acknowledgement:
------------------------------------------------------------
This Oracle conversion was assisted by ChatGPT.
*/


CREATE OR REPLACE PROCEDURE FastTotalnumOutput(
  schemaname IN VARCHAR2 DEFAULT 'DBO',
  tablename  IN VARCHAR2 DEFAULT '@'
)
AUTHID CURRENT_USER
IS
  sqlstr  VARCHAR2(4000);
  sqltext VARCHAR2(4000);
  start_time DATE;

  PROCEDURE run_sql(p_sql IN VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(p_sql);
    EXECUTE IMMEDIATE p_sql;
    DBMS_OUTPUT.PUT_LINE('Rows affected: ' || SQL%ROWCOUNT);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Failed SQL: ' || p_sql);
      DBMS_OUTPUT.PUT_LINE('Oracle error: ' || SQLERRM);
      RAISE;
  END;
BEGIN
  start_time := SYSDATE;
  
  ---------------------------------------------------------------------------
  -- Iterate through each ontology table specified in TABLE_ACCESS (those
  -- with c_visualattributes like '%A%')
  ---------------------------------------------------------------------------
  FOR rec IN (SELECT DISTINCT c_table_name
                FROM table_access
               WHERE c_visualattributes LIKE '%A%') LOOP
    sqltext := rec.c_table_name;  -- current table name from TABLE_ACCESS
    -- Process if running on all tables (tablename='@') or only on a specified table.
    IF tablename = '@' OR tablename = sqltext THEN
      -- Output a timing message using the EndTime helper (assumed converted separately)
      EndTime(start_time, sqltext, 'ready to go');
      start_time := SYSDATE;
      
      -----------------------------------------------------------------------
      -- Null the counts in the ontology table
      -----------------------------------------------------------------------
      sqlstr := 'UPDATE ' || sqltext || ' SET c_totalnum = NULL';
      run_sql(sqlstr);
      
      -----------------------------------------------------------------------
      -- Zero the counts in the ontology where c_operator = 'LIKE' and 
      -- c_visualattributes like '%A%'
      -----------------------------------------------------------------------
      sqlstr := 'UPDATE ' || sqltext ||
                ' SET c_totalnum = 0 WHERE c_operator = ''LIKE'' ' ||
                '  AND c_visualattributes LIKE ''%A%''';
      run_sql(sqlstr);
      
      -----------------------------------------------------------------------
      -- Update counts in the ontology (only works on the same day the counts
      -- are performed). In SQL Server a join was used; here we use a correlated
      -- subquery with a row_number analytic to pick the most recent count.
      -----------------------------------------------------------------------
      sqlstr :=
       'UPDATE ' || sqltext || ' o SET c_totalnum = (' ||
         'SELECT agg_count FROM (' ||
            'SELECT row_number() OVER (PARTITION BY c_fullname ORDER BY agg_date DESC) rn, ' ||
                   'c_fullname, agg_count, agg_date ' ||
            'FROM totalnum WHERE typeflag_cd LIKE ''P%''' ||
         ') t WHERE t.c_fullname = o.c_fullname AND rn = 1' ||
       ') WHERE EXISTS (' ||
         'SELECT 1 FROM (' ||
            'SELECT row_number() OVER (PARTITION BY c_fullname ORDER BY agg_date DESC) rn, ' ||
                   'c_fullname, agg_count, agg_date ' ||
            'FROM totalnum WHERE typeflag_cd LIKE ''P%''' ||
         ') t WHERE t.c_fullname = o.c_fullname AND rn = 1' ||
       ')';
      run_sql(sqlstr);
      
      -----------------------------------------------------------------------
      -- Update counts in the top-level TABLE_ACCESS.
      -- In SQL Server an UPDATE with a join is used; in Oracle we use a correlated
      -- subquery.
      -----------------------------------------------------------------------
      sqlstr :=
       'UPDATE table_access t SET c_totalnum = (' ||
         'SELECT x.c_totalnum FROM ' || sqltext || ' x WHERE x.c_fullname = t.c_fullname' ||
       ') WHERE EXISTS (' ||
         'SELECT 1 FROM ' || sqltext || ' x WHERE x.c_fullname = t.c_fullname' ||
       ')';
      run_sql(sqlstr);
      
      -----------------------------------------------------------------------
      -- Null out cases that are actually 0 in the ontology table where
      -- c_visualattributes like ''C%''
      -----------------------------------------------------------------------
      sqlstr := 'UPDATE ' || sqltext ||
                ' SET c_totalnum = NULL WHERE c_totalnum = 0 ' ||
                '   AND c_visualattributes LIKE ''C%''';
      run_sql(sqlstr);
    END IF;
  END LOOP;
  
  ---------------------------------------------------------------------------
  -- Refresh top-level TABLE_ACCESS counts directly from the latest TOTALNUM
  -- rows. This avoids depending on the per-ontology copy-back above for roots
  -- whose C_FULLNAME exists in TOTALNUM but was not populated in the ontology
  -- table during the same run.
  ---------------------------------------------------------------------------
  sqlstr :=
   'UPDATE table_access t SET c_totalnum = (' ||
     'SELECT agg_count FROM (' ||
        'SELECT row_number() OVER (PARTITION BY c_fullname ORDER BY agg_date DESC) rn, ' ||
               'c_fullname, agg_count, agg_date ' ||
        'FROM totalnum WHERE typeflag_cd LIKE ''P%''' ||
     ') x WHERE x.c_fullname = t.c_fullname AND rn = 1' ||
   ') WHERE EXISTS (' ||
     'SELECT 1 FROM (' ||
        'SELECT row_number() OVER (PARTITION BY c_fullname ORDER BY agg_date DESC) rn, ' ||
               'c_fullname, agg_count, agg_date ' ||
        'FROM totalnum WHERE typeflag_cd LIKE ''P%''' ||
     ') x WHERE x.c_fullname = t.c_fullname AND rn = 1' ||
   ')';
  run_sql(sqlstr);

  ---------------------------------------------------------------------------
  -- Cleanup: update table_access so that c_totalnum is set to null where 0.
  ---------------------------------------------------------------------------
  sqlstr := 'UPDATE table_access SET c_totalnum = NULL WHERE c_totalnum = 0';
  run_sql(sqlstr);
  
  ---------------------------------------------------------------------------
  -- Denominator: if no row exists in totalnum for c_fullname='\denominator\facts\'
  -- for today, then insert one.
  ---------------------------------------------------------------------------
  DECLARE
    cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO cnt
      FROM totalnum
     WHERE c_fullname = '\denominator\facts\' 
       AND TRUNC(agg_date) = TRUNC(SYSDATE);
    IF cnt = 0 THEN
      sqlstr :=
       'INSERT INTO totalnum(c_fullname, agg_date, agg_count, typeflag_cd) ' ||
       'SELECT ''\denominator\facts\'', SYSDATE, COUNT(DISTINCT patient_num), ''PX'' ' ||
       'FROM ' || schemaname || '.observation_fact';
      BEGIN
        run_sql(sqlstr);
      EXCEPTION
        WHEN OTHERS THEN
          IF SQLCODE = -942 THEN
            DBMS_OUTPUT.PUT_LINE('Skipping denominator insert: ' || schemaname || '.observation_fact is not visible.');
          ELSE
            RAISE;
          END IF;
      END;
    END IF;
  END;
  
  ---------------------------------------------------------------------------
  -- Build the report table.
  -- (This call assumes that the BuildTotalnumReport procedure exists and accepts
  -- two parameters, e.g. BuildTotalnumReport(10, 6.5);)
  ---------------------------------------------------------------------------
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Calling BuildTotalnumReport(10, 6.5)');
    BuildTotalnumReport(10, 6.5);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('BuildTotalnumReport failed. Verify TOTALNUM_REPORT exists and is visible to the caller.');
      DBMS_OUTPUT.PUT_LINE('Oracle error: ' || SQLERRM);
      RAISE;
  END;
  
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END FastTotalnumOutput;
