-- By Mike Mendis, Partners Healthcare based on SQL Server code by Griffin Weber, MD, PhD at Harvard Medical School
-- Performance improvements by Jeff Green and Jeff Klann, PhD 03-20
 
-- Classic/legacy count totalnumbers of patients for all metadata tables in table access.
-- The results are in: c_totalnum column of all ontology tables, the totalnum table (keeps a historical record), and the totalnum_report table (most recent run, obfuscated) 
-- The runtotalnum compatibility wrapper is defined in totalnum_run.sql and defaults to the fast totalnum workflow.
-- Run the classic procedure like this (but with your schema name instead of i2b2demodata):
--begin
--  RunTotalnumClassic('observation_fact','i2b2demodata');
-- end;
-- You can optionally include a table named if you only want to count one ontology table (this IS case sensitive):
--begin
--  RunTotalnumClassic('observation_fact','i2b2demodata','I2B2');
-- end;
--   To use with multi-fact setups: Create a fact table view as the union of all your fact tables. (This is essentially going back to a single fact table,  but it is only used
--     for totalnum counting. This is needed to correctly count patients that mention multiple fact tables within a hierarchy.)
--    e.g., 
--       create view observation_fact_view as
--       select * from CONDITION_VIEW 
--       union all
--       select * from drug_view
--    And then run the totalnum counter on that fact table:
--      e.g., RunTotalnumClassic('observation_fact_view','i2b2demodata');
--    Note this approach does not work if you have conflicting concept_cds across fact tables.

create or replace PROCEDURE RunTotalnumClassic (
    observationTable IN VARCHAR2 DEFAULT 'observation_fact',
    schemaName IN VARCHAR2 DEFAULT 'dbo',
    tableName IN VARCHAR2 DEFAULT '@',
    wildcard_factcolumn IN VARCHAR2 DEFAULT 'N'
)
AUTHID CURRENT_USER
AS
    sqlstr VARCHAR2(4000);
    sqltext VARCHAR2(4000);
    startime DATE;
    derived_facttablecolumn VARCHAR2(4000);
    facttablecolumn_prefix VARCHAR2(4000);
    v_count NUMBER;
    v_observation_table VARCHAR2(300);
    v_metadata_table VARCHAR2(300);
    v_errormsg VARCHAR2(4000);
BEGIN
    v_observation_table :=
        DBMS_ASSERT.QUALIFIED_SQL_NAME(schemaName || '.' || observationTable);

    /* 03-22: DWH - build concept patient table once here, rather than in each call to count */
    SELECT COUNT(*)
      INTO v_count
      FROM USER_TABLES
     WHERE TABLE_NAME = 'TNUM_CONCEPTPATIENT';

    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE TNUM_CONCEPTPATIENT';
    END IF;

    DBMS_OUTPUT.PUT_LINE('Building tnum_ConceptPatient');

    /* CREATE TABLE WITH CONSTRAINTS AND INSERT */
    EXECUTE IMMEDIATE '
        CREATE TABLE TNUM_CONCEPTPATIENT (
            PATIENT_NUM NUMBER(10) NOT NULL,
            CONCEPT_CD VARCHAR2(50) NOT NULL,
            CONSTRAINT PKCONPAT PRIMARY KEY (CONCEPT_CD, PATIENT_NUM)
        )';

    sqlstr :=
        'INSERT INTO TNUM_CONCEPTPATIENT (concept_cd, patient_num) ' ||
        'SELECT DISTINCT concept_cd, patient_num ' ||
        'FROM ' || v_observation_table || ' f';

    EXECUTE IMMEDIATE sqlstr;

    FOR rec IN (
        SELECT DISTINCT c_table_name
          FROM TABLE_ACCESS
         WHERE c_visualattributes LIKE '%A%'
    )
    LOOP
        sqltext := rec.c_table_name;
        v_metadata_table := DBMS_ASSERT.QUALIFIED_SQL_NAME(sqltext);

        IF LOWER(observationTable) = 'observation_fact' THEN
            derived_facttablecolumn := '';
        ELSE
            derived_facttablecolumn := observationTable || '.';
        END IF;

        IF UPPER(NVL(wildcard_factcolumn, 'N')) = 'Y' THEN
            facttablecolumn_prefix := '%';
        ELSIF LOWER(observationTable) = 'observation_fact' THEN
            facttablecolumn_prefix := '';
        ELSE
            facttablecolumn_prefix := observationTable || '.';
        END IF;

        IF tableName = '@' OR tableName = sqltext THEN

            DBMS_OUTPUT.PUT_LINE(sqltext);

            sqlstr := 'UPDATE ' || v_metadata_table ||
                      ' SET c_totalnum = NULL';

            EXECUTE IMMEDIATE sqlstr;

            IF derived_facttablecolumn IS NULL THEN
                startime := SYSDATE;

                v_errormsg := NULL;
                PAT_COUNT_VISITS(sqltext, schemaName, v_errormsg);

                IF v_errormsg IS NOT NULL THEN
                    DBMS_OUTPUT.PUT_LINE('PAT_COUNT_VISITS: ' || v_errormsg);
                END IF;

                EndTime(startime, sqltext, 'PAT_COUNT_VISITS');
            END IF;

            startime := SYSDATE;

            derived_facttablecolumn :=
                facttablecolumn_prefix || 'concept_cd';

            v_errormsg := NULL;
            PAT_COUNT_DIMENSIONS(
                sqltext,
                schemaName,
                observationTable,
                derived_facttablecolumn,
                'concept_dimension',
                'concept_path',
                v_errormsg
            );

            IF v_errormsg IS NOT NULL THEN
                DBMS_OUTPUT.PUT_LINE('PAT_COUNT_concept_dimension: ' || v_errormsg);
            END IF;

            EndTime(startime, sqltext, 'PAT_COUNT_concept_dimension');

            startime := SYSDATE;

            derived_facttablecolumn :=
                facttablecolumn_prefix || 'provider_id';

            v_errormsg := NULL;
            PAT_COUNT_DIMENSIONS(
                sqltext,
                schemaName,
                observationTable,
                derived_facttablecolumn,
                'provider_dimension',
                'provider_path',
                v_errormsg
            );

            IF v_errormsg IS NOT NULL THEN
                DBMS_OUTPUT.PUT_LINE('PAT_COUNT_provider_dimension: ' || v_errormsg);
            END IF;

            EndTime(startime, sqltext, 'PAT_COUNT_provider_dimension');

            startime := SYSDATE;

            derived_facttablecolumn :=
                facttablecolumn_prefix || 'modifier_cd';

            v_errormsg := NULL;
            PAT_COUNT_DIMENSIONS(
                sqltext,
                schemaName,
                observationTable,
                derived_facttablecolumn,
                'modifier_dimension',
                'modifier_path',
                v_errormsg
            );

            IF v_errormsg IS NOT NULL THEN
                DBMS_OUTPUT.PUT_LINE('PAT_COUNT_modifier_dimension: ' || v_errormsg);
            END IF;

            EndTime(startime, sqltext, 'PAT_COUNT_modifier_dimension');

            startime := SYSDATE;

            -- New 11/20 - update counts in top levels (table_access) at the end
            sqlstr :=
                'UPDATE TABLE_ACCESS t ' ||
                'SET c_totalnum = ( ' ||
                '    SELECT MAX(x.c_totalnum) ' ||
                '    FROM ' || v_metadata_table || ' x ' ||
                '    WHERE x.c_fullname = t.c_fullname ' ||
                ') ' ||
                'WHERE EXISTS ( ' ||
                '    SELECT 1 FROM ' || v_metadata_table || ' x ' ||
                '    WHERE x.c_fullname = t.c_fullname ' ||
                ')';

            EXECUTE IMMEDIATE sqlstr;

            -- Null out cases that are actually 0 [1/21]
            sqlstr :=
                'UPDATE ' || v_metadata_table ||
                ' SET c_totalnum = NULL ' ||
                'WHERE c_totalnum = 0 ' ||
                'AND c_visualattributes LIKE ''C%''';

            EXECUTE IMMEDIATE sqlstr;

        END IF;
    END LOOP;

    -- Cleanup (1/21)
    UPDATE TABLE_ACCESS
       SET c_totalnum = NULL
     WHERE c_totalnum = 0;

    -- Denominator (1/21)
    SELECT COUNT(*)
      INTO v_count
      FROM TOTALNUM
     WHERE c_fullname = '\denominator\facts\'
       AND TRUNC(agg_date) = TRUNC(SYSDATE);

    IF v_count = 0 THEN
        sqlstr :=
            'INSERT INTO TOTALNUM ' ||
            '(c_fullname, agg_date, agg_count, typeflag_cd) ' ||
            'SELECT ''\denominator\facts\'', ' ||
            'SYSDATE, COUNT(DISTINCT patient_num), ''PX'' ' ||
            'FROM ' || v_observation_table;

        EXECUTE IMMEDIATE sqlstr;
    END IF;

    -- Drop temporary working table
    SELECT COUNT(*)
      INTO v_count
      FROM USER_TABLES
     WHERE TABLE_NAME = 'TNUM_CONCEPTPATIENT';

    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE TNUM_CONCEPTPATIENT';
    END IF;

    BuildTotalnumReport(10, 6.5);

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            'RunTotalnumClassic failed: ' || SQLERRM
        );
        RAISE;
END RunTotalnumClassic;


