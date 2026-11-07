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
  - Supporting counting procedures have been converted to Oracle. Report generation
    is skipped when BuildTotalnumReport or TOTALNUM_REPORT is unavailable.
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

create or replace PROCEDURE FastTotalnumOutput(
    schemaname       IN VARCHAR2 DEFAULT 'i2b2',
    tablename        IN VARCHAR2 DEFAULT '@',
    demographics_mode IN VARCHAR2 DEFAULT 'act'
)
AUTHID CURRENT_USER
IS
    sqlstr          VARCHAR2(32767);
    sqltext         VARCHAR2(4000);
    start_time      DATE;
    mode_norm       VARCHAR2(20);
    count_source    VARCHAR2(4000);
    act_demo_table  VARCHAR2(255);
    conflict_count  NUMBER;
    metadata_object VARCHAR2(500);

    PROCEDURE run_sql(p_sql IN VARCHAR2)
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(SUBSTR(p_sql, 1, 4000));

        EXECUTE IMMEDIATE p_sql;

        DBMS_OUTPUT.PUT_LINE(
            'Rows affected: ' || SQL%ROWCOUNT
        );

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE(
                'Failed SQL: ' || SUBSTR(p_sql, 1, 4000)
            );
            DBMS_OUTPUT.PUT_LINE(
                'Oracle error: ' || SQLERRM
            );
            RAISE;
    END run_sql;

BEGIN

    -----------------------------------------------------------------------
    -- Validate demographics mode
    -----------------------------------------------------------------------
    mode_norm :=
        LOWER(NVL(TRIM(demographics_mode), 'act'));

    IF mode_norm NOT IN ('act', 'all') THEN
        RAISE_APPLICATION_ERROR(
            -20006,
            'Invalid demographics_mode. Use act or all.'
        );
    END IF;

    -----------------------------------------------------------------------
    -- Identify ACT_DEMO physical ontology table
    -----------------------------------------------------------------------
    SELECT MAX(c_table_name)
    INTO act_demo_table
    FROM table_access
    WHERE UPPER(c_table_cd) = 'ACT_DEMO';

    start_time := SYSDATE;

    -----------------------------------------------------------------------
    -- Process ontology tables
    -----------------------------------------------------------------------
    FOR rec IN (
        SELECT DISTINCT c_table_name
        FROM table_access
        WHERE c_visualattributes LIKE '%A%'
          AND c_table_name IS NOT NULL
          AND c_table_name <> '@'
          AND (
              tablename = '@'
              OR c_table_name = tablename
          )
    )
    LOOP

        sqltext := rec.c_table_name;

        -- Validate dynamic table identifier
        metadata_object :=
            DBMS_ASSERT.SQL_OBJECT_NAME(sqltext);

        DBMS_OUTPUT.PUT_LINE(
            'Processing ontology table: ' || sqltext
        );

        -------------------------------------------------------------------
        -- Determine count source
        -------------------------------------------------------------------
        count_source :=
            'SELECT ROW_NUMBER() OVER (' ||
            'PARTITION BY c_fullname ' ||
            'ORDER BY agg_date DESC, ' ||
            'CASE WHEN typeflag_cd = ''PA'' THEN 1 ELSE 0 END DESC, ' ||
            'agg_count DESC) rn, ' ||
            'c_fullname, agg_count ' ||
            'FROM totalnum WHERE typeflag_cd ' ||

            CASE
                WHEN mode_norm = 'all'
                     AND (
                         act_demo_table IS NULL
                         OR sqltext <> act_demo_table
                     )
                THEN 'IN (''PF'', ''PA'')'
                ELSE '= ''PF'''
            END;

        -------------------------------------------------------------------
        -- Timing
        -------------------------------------------------------------------
        EndTime(
            start_time,
            sqltext,
            'ready to go'
        );

        start_time := SYSDATE;

        -------------------------------------------------------------------
        -- Step 1: Clear existing ontology counts
        -------------------------------------------------------------------
        sqlstr :=
            'UPDATE ' || metadata_object ||
            ' SET c_totalnum = NULL';

        run_sql(sqlstr);

        -------------------------------------------------------------------
        -- Step 2: Initialize eligible ontology counts to zero
        -------------------------------------------------------------------
        sqlstr :=
            'UPDATE ' || metadata_object ||
            ' SET c_totalnum = 0 ' ||
            'WHERE c_operator = ''LIKE'' ' ||
            'AND c_visualattributes LIKE ''%A%''';

        run_sql(sqlstr);

        -------------------------------------------------------------------
        -- Step 3: Update ontology counts from TOTALNUM
        -------------------------------------------------------------------
        sqlstr :=
            'UPDATE ' || metadata_object ||
            ' o SET c_totalnum = (' ||
                'SELECT t.agg_count FROM (' ||
                    count_source ||
                ') t ' ||
                'WHERE t.c_fullname = o.c_fullname ' ||
                'AND t.rn = 1' ||
            ') WHERE EXISTS (' ||
                'SELECT 1 FROM (' ||
                    count_source ||
                ') t ' ||
                'WHERE t.c_fullname = o.c_fullname ' ||
                'AND t.rn = 1' ||
            ')';

        run_sql(sqlstr);

        -------------------------------------------------------------------
        -- Step 4: Detect conflicting duplicate ontology counts
        -------------------------------------------------------------------
        sqlstr :=
            'SELECT COUNT(*) FROM (' ||
                'SELECT c_fullname ' ||
                'FROM ' || metadata_object || ' ' ||
                'GROUP BY c_fullname ' ||
                'HAVING COUNT(DISTINCT c_totalnum) > 1' ||
            ')';

        EXECUTE IMMEDIATE sqlstr INTO conflict_count;

        IF conflict_count > 0 THEN
            RAISE_APPLICATION_ERROR(
                -20007,
                'Conflicting C_TOTALNUM values found in '
                || sqltext
                || ' for '
                || conflict_count
                || ' C_FULLNAME values.'
            );
        END IF;

        -------------------------------------------------------------------
        -- Step 5: Update TABLE_ACCESS
        --
        -- FIX FOR ORA-01427:
        -- MAX() ensures that the scalar subquery returns one row.
        -- Conflicting non-null counts were checked above.
        -------------------------------------------------------------------
        sqlstr :=
            'UPDATE table_access t SET c_totalnum = (' ||
                'SELECT MAX(x.c_totalnum) ' ||
                'FROM ' || metadata_object || ' x ' ||
                'WHERE x.c_fullname = t.c_fullname' ||
            ') WHERE EXISTS (' ||
                'SELECT 1 ' ||
                'FROM ' || metadata_object || ' x ' ||
                'WHERE x.c_fullname = t.c_fullname' ||
            ')';

        run_sql(sqlstr);

        -------------------------------------------------------------------
        -- Step 6: Null zero counts for C% ontology attributes
        -------------------------------------------------------------------
        sqlstr :=
            'UPDATE ' || metadata_object ||
            ' SET c_totalnum = NULL ' ||
            'WHERE c_totalnum = 0 ' ||
            'AND c_visualattributes LIKE ''C%''';

        run_sql(sqlstr);

    END LOOP;

    -----------------------------------------------------------------------
    -- Step 7: Refresh TABLE_ACCESS directly from TOTALNUM
    -----------------------------------------------------------------------
    count_source :=
        'SELECT ROW_NUMBER() OVER (' ||
        'PARTITION BY c_fullname ' ||
        'ORDER BY agg_date DESC, ' ||
        'CASE WHEN typeflag_cd = ''PA'' THEN 1 ELSE 0 END DESC, ' ||
        'agg_count DESC) rn, ' ||
        'c_fullname, agg_count ' ||
        'FROM totalnum WHERE typeflag_cd ' ||

        CASE
            WHEN mode_norm = 'all'
            THEN 'IN (''PF'', ''PA'')'
            ELSE '= ''PF'''
        END;

    sqlstr :=
        'UPDATE table_access t SET c_totalnum = (' ||
            'SELECT x.agg_count FROM (' ||
                count_source ||
            ') x ' ||
            'WHERE x.c_fullname = t.c_fullname ' ||
            'AND x.rn = 1' ||
        ') WHERE EXISTS (' ||
            'SELECT 1 FROM (' ||
                count_source ||
            ') x ' ||
            'WHERE x.c_fullname = t.c_fullname ' ||
            'AND x.rn = 1' ||
        ')';

    run_sql(sqlstr);

    -----------------------------------------------------------------------
    -- Step 8: Null zero counts in TABLE_ACCESS
    -----------------------------------------------------------------------
    sqlstr :=
        'UPDATE table_access ' ||
        'SET c_totalnum = NULL ' ||
        'WHERE c_totalnum = 0';

    run_sql(sqlstr);

    -----------------------------------------------------------------------
    -- Step 9: Insert denominator count if missing for today
    -----------------------------------------------------------------------
    DECLARE
        cnt NUMBER;
    BEGIN

        SELECT COUNT(*)
        INTO cnt
        FROM totalnum
        WHERE c_fullname = '\denominator\facts\'
          AND TRUNC(agg_date) = TRUNC(SYSDATE);

        IF cnt = 0 THEN

            sqlstr :=
                'INSERT INTO totalnum (' ||
                'c_fullname, agg_date, agg_count, typeflag_cd' ||
                ') ' ||
                'SELECT ''\denominator\facts\'', ' ||
                'SYSDATE, COUNT(DISTINCT patient_num), ''PX'' ' ||
                'FROM OBSFACT_PAIRS';

            run_sql(sqlstr);

        END IF;

    END;

    -----------------------------------------------------------------------
    -- Step 10: Generate optional obfuscated report
    -----------------------------------------------------------------------
    BEGIN

        DBMS_OUTPUT.PUT_LINE(
            'Calling BuildTotalnumReport(10, 6.5)'
        );

        EXECUTE IMMEDIATE
            'BEGIN BuildTotalnumReport(10, 6.5, :mode); END;'
            USING mode_norm;

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE(
                'Skipping totalnum report build. ' ||
                'Verify BuildTotalnumReport and TOTALNUM_REPORT.'
            );

            DBMS_OUTPUT.PUT_LINE(
                'Oracle error: ' || SQLERRM
            );
    END;

    -----------------------------------------------------------------------
    -- Complete
    -----------------------------------------------------------------------
    COMMIT;

    DBMS_OUTPUT.PUT_LINE(
        'FastTotalnumOutput completed successfully.'
    );

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        DBMS_OUTPUT.PUT_LINE(
            'ERROR in FastTotalnumOutput: '
            || SQLCODE || ' - ' || SQLERRM
        );

        RAISE;

END FastTotalnumOutput;
/

