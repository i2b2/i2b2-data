
/*
--------------------------------------------------------------------------------
Oracle Version: FastTotalnumCount Procedure
--------------------------------------------------------------------------------
This version by Darren Henderson (DARREN.HENDERSON@UKY.EDU)
and Jeff Klann, PhD.

Based on code by Griffin Weber, Jeff Klann, Mike Mendis,
Lori Phillips, Jeff Green, and Darren Henderson.

Description:
  Builds patient and visit dimension fact tuples in PV_FACT_PAIRS,
  then calculates distinct patient counts using OBSFACT_PAIRS,
  TNUM_ONTOLOGY, and CONCEPT_CLOSURE.

--------------------------------------------------------------------------------
*/

-- Create global temporary table if it does not exist.

DECLARE
  table_exists NUMBER;
BEGIN
  SELECT COUNT(*)
    INTO table_exists
    FROM USER_TABLES
   WHERE TABLE_NAME = 'PV_FACT_PAIRS';

  IF table_exists = 0 THEN

    EXECUTE IMMEDIATE '
      CREATE GLOBAL TEMPORARY TABLE PV_FACT_PAIRS (
        PATIENT_NUM NUMBER,
        CONCEPT_CD VARCHAR2(50),
        CONSTRAINT PK_PV_FACT_PAIRS
          PRIMARY KEY (PATIENT_NUM, CONCEPT_CD)
      )
      ON COMMIT PRESERVE ROWS
    ';

    DBMS_OUTPUT.PUT_LINE(
      'Global Temporary Table PV_FACT_PAIRS created successfully.'
    );

  ELSE

    DBMS_OUTPUT.PUT_LINE(
      'Global Temporary Table PV_FACT_PAIRS already exists.'
    );

  END IF;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'Error creating PV_FACT_PAIRS: ' || SQLERRM
    );
    RAISE;
END;
GO

-- Create or replace FastTotalnumCount procedure.

CREATE OR REPLACE PROCEDURE FastTotalnumCount
(
    schemaName  IN VARCHAR2 DEFAULT 'DBO',
    source_mode IN VARCHAR2 DEFAULT 'i2b2'
)
AUTHID CURRENT_USER
IS
    source_mode_norm VARCHAR2(20);
    start_time       DATE;
BEGIN

    start_time := SYSDATE;

    source_mode_norm := LOWER(
        NVL(NULLIF(source_mode, ''), 'i2b2')
    );

    IF source_mode_norm NOT IN ('i2b2', 'omop') THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'Invalid source_mode. Use i2b2 or omop.'
        );
    END IF;

    --------------------------------------------------------------------------
    -- CLEAR OUT TEMP DATA FROM PREVIOUS RUN
    --------------------------------------------------------------------------

    EXECUTE IMMEDIATE 'TRUNCATE TABLE PV_FACT_PAIRS';

    --------------------------------------------------------------------------
    -- BUILD PATIENT/VISIT FEATURES AS FACT TUPLES
    --------------------------------------------------------------------------

    INSERT INTO PV_FACT_PAIRS (PATIENT_NUM, CONCEPT_CD)

    WITH PATIENT_VISIT_PRELIM AS (
      SELECT
        P.PATIENT_NUM,

        FLOOR((SYSDATE - P.BIRTH_DATE) / 365.25)
          AS AGE_TODAY_NUM,

        'DEM|AGE:' ||
        CASE
          WHEN FLOOR((SYSDATE - P.BIRTH_DATE) / 365.25) >= 3
          THEN TO_CHAR(
                 FLOOR((SYSDATE - P.BIRTH_DATE) / 365.25)
               )
          ELSE
            TO_CHAR(
              TRUNC(MONTHS_BETWEEN(SYSDATE, P.BIRTH_DATE) / 12)
            )
            || '.' ||
            TO_CHAR(
              MOD(
                TRUNC(MONTHS_BETWEEN(SYSDATE, P.BIRTH_DATE)),
                12
              )
            )
        END AS AGE_TODAY_CHAR,

        FLOOR((V.START_DATE - P.BIRTH_DATE) / 365.25)
          AS AGE_VISIT_NUM,

        'VIS|AGE:' ||
        CASE
          WHEN FLOOR((V.START_DATE - P.BIRTH_DATE) / 365.25) >= 3
          THEN TO_CHAR(
                 FLOOR((V.START_DATE - P.BIRTH_DATE) / 365.25)
               )
          ELSE
            TO_CHAR(
              TRUNC(
                MONTHS_BETWEEN(V.START_DATE, P.BIRTH_DATE) / 12
              )
            )
            || '.' ||
            TO_CHAR(
              MOD(
                TRUNC(
                  MONTHS_BETWEEN(V.START_DATE, P.BIRTH_DATE)
                ),
                12
              )
            )
        END AS AGE_VISIT_CHAR,

        'visit_dimension|length_of_stay:' ||
          TO_CHAR(V.END_DATE - V.START_DATE)
          AS LENGTH_OF_STAY,

        CASE
          WHEN (V.END_DATE - V.START_DATE) >= 10
          THEN 'visit_dimension|length_of_stay:>10'
          ELSE NULL
        END AS LENGTH_OF_STAY_GTE10,

        'visit_dimension|inout_cd:' || V.INOUT_CD
          AS INOUT_CD,

        'DEM|RACE:' || P.RACE_CD
          AS RACE_CD,

        'DEM|SEX:' || P.SEX_CD
          AS SEX_CD

      FROM PATIENT_DIMENSION P
      JOIN VISIT_DIMENSION V
        ON P.PATIENT_NUM = V.PATIENT_NUM
    ),

    Derived AS (
      SELECT
        PATIENT_NUM,

        CAST(AGE_TODAY_CHAR AS VARCHAR2(50))
          AS AGE_TODAY,

        CAST(AGE_VISIT_CHAR AS VARCHAR2(50))
          AS AGE_VISIT,

        CAST(
          CASE WHEN AGE_TODAY_NUM < 18
            THEN 'DEM|AGE:<18'
            ELSE NULL
          END AS VARCHAR2(50)
        ) AS AGE_TODAY_LT18,

        CAST(
          CASE WHEN AGE_TODAY_NUM >= 18
            THEN 'DEM|AGE:>=18'
            ELSE NULL
          END AS VARCHAR2(50)
        ) AS AGE_TODAY_GTE18,

        CAST(
          CASE WHEN AGE_TODAY_NUM >= 65
            THEN 'DEM|AGE:>=65'
            ELSE NULL
          END AS VARCHAR2(50)
        ) AS AGE_TODAY_GTE65,

        CAST(
          CASE WHEN AGE_TODAY_NUM >= 85
            THEN 'DEM|AGE:>=85'
            ELSE NULL
          END AS VARCHAR2(50)
        ) AS AGE_TODAY_GTE85,

        CAST(
          CASE WHEN AGE_TODAY_NUM >= 90
            THEN 'DEM|AGE:>=90'
            ELSE NULL
          END AS VARCHAR2(50)
        ) AS AGE_TODAY_GTE90,

        CAST(
          CASE WHEN AGE_VISIT_NUM >= 65
            THEN 'VIS|AGE:>=65'
            ELSE NULL
          END AS VARCHAR2(50)
        ) AS AGE_VISIT_GTE65,

        CAST(
          CASE WHEN AGE_VISIT_NUM >= 85
            THEN 'VIS|AGE:>=85'
            ELSE NULL
          END AS VARCHAR2(50)
        ) AS AGE_VISIT_GTE85,

        CAST(
          CASE WHEN AGE_VISIT_NUM >= 90
            THEN 'VIS|AGE:>=90'
            ELSE NULL
          END AS VARCHAR2(50)
        ) AS AGE_VISIT_GTE90,

        CAST(LENGTH_OF_STAY AS VARCHAR2(50))
          AS LENGTH_OF_STAY,

        CAST(LENGTH_OF_STAY_GTE10 AS VARCHAR2(50))
          AS LENGTH_OF_STAY_GTE10,

        CAST(INOUT_CD AS VARCHAR2(50))
          AS INOUT_CD,

        CAST(RACE_CD AS VARCHAR2(50))
          AS RACE_CD,

        CAST(SEX_CD AS VARCHAR2(50))
          AS SEX_CD

      FROM PATIENT_VISIT_PRELIM
    )

    SELECT DISTINCT
      PATIENT_NUM,
      VAL AS CONCEPT_CD

    FROM Derived

    UNPIVOT (
      VAL FOR FACT IN (
        AGE_TODAY,
        AGE_VISIT,
        AGE_TODAY_LT18,
        AGE_TODAY_GTE18,
        AGE_TODAY_GTE65,
        AGE_TODAY_GTE85,
        AGE_TODAY_GTE90,
        AGE_VISIT_GTE65,
        AGE_VISIT_GTE85,
        AGE_VISIT_GTE90,
        LENGTH_OF_STAY,
        LENGTH_OF_STAY_GTE10,
        INOUT_CD,
        RACE_CD,
        SEX_CD
      )
    );

    --------------------------------------------------------------------------
    -- CALCULATE TOTAL NUMBERS
    --------------------------------------------------------------------------

    INSERT INTO TOTALNUM (
      C_FULLNAME,
      AGG_COUNT,
      AGG_DATE,
      TYPEFLAG_CD
    )

    WITH CTE_FACT_PAIRS AS (
      SELECT PATIENT_NUM, CONCEPT_CD
      FROM PV_FACT_PAIRS

      UNION ALL

      SELECT PATIENT_NUM, CONCEPT_CD
      FROM OBSFACT_PAIRS
    )

    SELECT DISTINCT
      OANC.C_FULLNAME,
      C.AGG_COUNT,
      SYSDATE,
      'PF'

    FROM (
      SELECT
        CC_ANCESTOR.ANCESTOR,
        COUNT(DISTINCT F.PATIENT_NUM) AS AGG_COUNT

      FROM CONCEPT_CLOSURE CC_ANCESTOR

      JOIN TNUM_ONTOLOGY O
        ON CC_ANCESTOR.DESCENDANT = O.PATH_NUM

      JOIN CTE_FACT_PAIRS F
        ON O.C_BASECODE = F.CONCEPT_CD

      GROUP BY CC_ANCESTOR.ANCESTOR
    ) C

    JOIN TNUM_ONTOLOGY OANC
      ON C.ANCESTOR = OANC.PATH_NUM;

    --------------------------------------------------------------------------
    -- RECORD TIMING INFORMATION
    --------------------------------------------------------------------------

    EndTime(
      start_time,
      'all ontologies',
      'counting'
    );

    start_time := SYSDATE;

    COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;

END FastTotalnumCount;

