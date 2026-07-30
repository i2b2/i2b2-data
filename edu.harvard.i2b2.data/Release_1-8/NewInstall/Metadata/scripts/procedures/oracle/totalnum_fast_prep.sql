/*
--------------------------------------------------------------------------------
Oracle Version: FastTotalnumPrep Procedure
by Darren Henderson (UKY) and Jeff Klann, PhD (MGB) 
This Oracle conversion was assisted by ChatGPT.
Last updated: 02/2025
--------------------------------------------------------------------------------
Description:
  This procedure performs all preparatory work that must happen once when the
  ontology changes, prior to running FastTotalnumRun. It performs the following tasks:
    1) Creates a view (OBSFACT_PAIRS) of distinct concept codes and patient numbers
       from either OBSERVATION_FACT or ACT-OMOP views, based on source_mode.
    2) Creates a unified ontology table (TNUM_ONTOLOGY) based on metadata from TABLE_ACCESS.
    3) Builds a transitive closure table (CONCEPT_CLOSURE) that captures ancestor/descendant
       relationships. For example, if C_FULLNAME is '\apple\fruit\', then an entry is made
       where the descendant represents 'fruit' and the ancestor represents 'apple'.
       
Usage Example in Oracle:
--------------------------------------------------------------------------------
To run on the default schema ('I2B2'):
  
  BEGIN
    FastTotalnumPrep;
  END;
  /

Or, to specify a different schema:
  
  BEGIN
    FastTotalnumPrep('MY_SCHEMA');
  END;
  /

Or, to use ACT-OMOP views:

  BEGIN
    FastTotalnumPrep('I2B2', 'omop');
  END;
  /

Required Oracle privileges:
--------------------------------------------------------------------------------
Because this procedure uses EXECUTE IMMEDIATE for DDL, required privileges must be
granted directly to the procedure owner, not only through a role. At minimum:

  GRANT CREATE PROCEDURE TO <metadata_schema>;
  GRANT CREATE VIEW TO <metadata_schema>;
  GRANT CREATE TABLE TO <metadata_schema>;
  GRANT CREATE SEQUENCE TO <metadata_schema>;

CREATE SEQUENCE is required because TNUM_ONTOLOGY uses an identity column.
The metadata schema also needs quota on its default tablespace, for example:

  ALTER USER <metadata_schema> QUOTA UNLIMITED ON <tablespace_name>;

If OBSERVATION_FACT, ACT-OMOP views, TABLE_ACCESS ontology tables, or other
metadata source tables are owned by another schema, grant SELECT on those objects
directly to <metadata_schema>.

*/



-- In Oracle you must drop the procedure manually (there’s no “IF EXISTS” clause)
-- DROP PROCEDURE FastTotalnumPrep;
 
CREATE OR REPLACE PROCEDURE FastTotalnumPrep (
  schemaname IN VARCHAR2 DEFAULT 'I2B2',
  source_mode IN VARCHAR2 DEFAULT 'i2b2'
)
IS
  -- Variables used for dynamic SQL
  sqlstr   VARCHAR2(4000);
  v_sql    CLOB;  -- For longer SQL statements
  startime DATE;
  visit_table VARCHAR2(400);
  demo_table  VARCHAR2(400);
  source_mode_norm VARCHAR2(20);
BEGIN
  source_mode_norm := LOWER(NVL(NULLIF(source_mode, ''), 'i2b2'));

  IF source_mode_norm NOT IN ('i2b2','omop') THEN
    RAISE_APPLICATION_ERROR(-20003, 'Invalid source_mode. Use i2b2 or omop.');
  END IF;

  SELECT MAX(C_TABLE_NAME)
    INTO visit_table
    FROM TABLE_ACCESS
   WHERE UPPER(C_TABLE_CD) = 'ACT_VISIT';

  SELECT MAX(C_TABLE_NAME)
    INTO demo_table
    FROM TABLE_ACCESS
   WHERE UPPER(C_TABLE_CD) = 'ACT_DEMO';

  IF visit_table IS NULL THEN
    DBMS_OUTPUT.PUT_LINE('Skipping ACT_VISIT ontology supplement: TABLE_ACCESS has no row for C_TABLE_CD = ACT_VISIT.');
  END IF;

  IF demo_table IS NULL THEN
    DBMS_OUTPUT.PUT_LINE('Skipping ACT_DEMO ontology supplement: TABLE_ACCESS has no row for C_TABLE_CD = ACT_DEMO.');
  END IF;

  ---------------------------------------------------------------------------
  -- 1. Build the OBSFACT_PAIRS view
  ---------------------------------------------------------------------------
  BEGIN
    -- Try to drop the view if it exists.
    EXECUTE IMMEDIATE 'DROP VIEW OBSFACT_PAIRS';
  EXCEPTION
    WHEN OTHERS THEN
      -- ORA-00942: table or view does not exist
      IF SQLCODE != -942 THEN
        RAISE;
      END IF;
  END;
  
  -- Create (or replace) the view.
  IF source_mode_norm = 'omop' THEN
    EXECUTE IMMEDIATE
      'CREATE OR REPLACE VIEW OBSFACT_PAIRS AS
       SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM CONDITION_NS_VIEW UNION ALL
       SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM CONDITION_VIEW UNION ALL
       SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM DRUG_NS_VIEW UNION ALL
       SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM DEVICE_VIEW UNION ALL
       SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM DEVICE_NS_VIEW UNION ALL
       SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM DRUG_VIEW UNION ALL
       SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM MEASUREMENT_NS_VIEW UNION ALL
       SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM MEASUREMENT_VIEW UNION ALL
       SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM OBSERVATION_NS_VIEW UNION ALL
       SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM OBSERVATION_VIEW UNION ALL
       SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM PROCEDURE_NS_VIEW UNION ALL
       SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM PROCEDURE_VIEW UNION ALL
       SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM VISIT_NS_VIEW';
  ELSE
    EXECUTE IMMEDIATE
      'CREATE OR REPLACE VIEW OBSFACT_PAIRS AS
       SELECT DISTINCT PATIENT_NUM, CONCEPT_CD
         FROM observation_fact';
  END IF;
  
  -- (If you have a logging or timing procedure named EndTime, call it here.)
  BEGIN
    EndTime(startime, 'observation_fact', 'pairs');
  EXCEPTION
    WHEN OTHERS THEN
      NULL;  -- EndTime not defined? Ignore.
  END;
  startime := SYSDATE;
  
  ---------------------------------------------------------------------------
  -- 2. Create the master ontology table TNUM_ONTOLOGY.
  --    (SQL Server’s IDENTITY(1,1) is replaced here by an Oracle identity column.)
  ---------------------------------------------------------------------------
  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE TNUM_ONTOLOGY';
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
        RAISE;
      END IF;
  END;
  
  EXECUTE IMMEDIATE q'[ 
    CREATE TABLE TNUM_ONTOLOGY (
      PATH_NUM            NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
      C_HLEVEL            NUMBER NOT NULL,
      C_FULLNAME          VARCHAR2(700) NOT NULL,
      C_SYNONYM_CD        CHAR(1) NOT NULL,
      C_VISUALATTRIBUTES  CHAR(3) NOT NULL,
      C_BASECODE          VARCHAR2(50),
      C_FACTTABLECOLUMN   VARCHAR2(50) NOT NULL,
      C_TABLENAME         VARCHAR2(50) NOT NULL,
      C_COLUMNNAME        VARCHAR2(50) NOT NULL,
      C_COLUMNDATATYPE    VARCHAR2(50) NOT NULL,
      C_OPERATOR          VARCHAR2(10) NOT NULL,
      C_DIMCODE           VARCHAR2(700) NOT NULL,
      M_APPLIED_PATH      VARCHAR2(900) NOT NULL
    )
  ]';
  
  ---------------------------------------------------------------------------
  -- 3. Load TNUM_ONTOLOGY from metadata.
  --    (This cursor loops over rows from TABLE_ACCESS. In each iteration a dynamic
  --     INSERT statement is built that selects ontology rows from a fact table.)
  ---------------------------------------------------------------------------
  FOR rec IN (
    SELECT C_TABLE_NAME, C_FULLNAME || '%' AS path
      FROM TABLE_ACCESS
     WHERE C_TABLE_CD NOT IN ('ACT_DEMO','ACT_VISIT')
       AND C_VISUALATTRIBUTES LIKE '%A%'
  ) LOOP
    v_sql := 'INSERT INTO TNUM_ONTOLOGY (C_HLEVEL, C_FULLNAME, C_SYNONYM_CD, C_VISUALATTRIBUTES, ' ||
             'C_BASECODE, C_FACTTABLECOLUMN, C_TABLENAME, C_COLUMNNAME, C_COLUMNDATATYPE, ' ||
             'C_OPERATOR, C_DIMCODE, M_APPLIED_PATH) ' ||
             'SELECT DISTINCT C_HLEVEL, C_FULLNAME, C_SYNONYM_CD, C_VISUALATTRIBUTES, ' ||
             'C_BASECODE, C_FACTTABLECOLUMN, C_TABLENAME, C_COLUMNNAME, C_COLUMNDATATYPE, ' ||
             'C_OPERATOR, C_DIMCODE, M_APPLIED_PATH ' ||
             'FROM ' || rec.C_TABLE_NAME ||
             ' WHERE C_FULLNAME LIKE ''' || rec.path || '''';
    DBMS_OUTPUT.PUT_LINE(v_sql);  -- (Equivalent to SQL Server’s PRINT)
    EXECUTE IMMEDIATE v_sql;
  END LOOP;
  
  BEGIN
    EndTime(startime, 'ontology', 'ontology');
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;
  startime := SYSDATE;
  
  ---------------------------------------------------------------------------
  -- 4. Load additional ontology override data into TNUM_ONTOLOGY.
  --    (This block uses a CTE. Note that Oracle string functions differ slightly:
  --     INSTR replaces CHARINDEX, and Oracle’s empty string is NULL.)
  ---------------------------------------------------------------------------
  IF visit_table IS NOT NULL AND demo_table IS NOT NULL THEN
  v_sql := 
  'INSERT INTO TNUM_ONTOLOGY (C_HLEVEL, C_FULLNAME, C_SYNONYM_CD, C_VISUALATTRIBUTES, ' ||
  '   C_BASECODE, C_FACTTABLECOLUMN, C_TABLENAME, C_COLUMNNAME, C_COLUMNDATATYPE, ' ||
  '   C_OPERATOR, C_DIMCODE, M_APPLIED_PATH) ' ||
  'WITH CTE_BASECODE_OVERRIDE AS ( ' ||
  '  SELECT ''\ACT\Visit Details\Length of stay\ > 10 days'' AS c_fullname, ''visit_dimension|length_of_stay:>10'' AS c_basecode FROM dual UNION ALL ' ||
  '  SELECT ''\ACT\Visit Details\Length of stay'' AS c_fullname, ''visit_dimension|length_of_stay:>0'' FROM dual UNION ALL ' ||
  '  SELECT ''\ACT\Visit Details\Length of stay'' AS c_fullname, ''visit_dimension|length_of_stay:>0'' FROM dual UNION ALL ' ||
  '  SELECT ''\ACT\Visit Details\Age at visit\>= 65 years old'' AS c_fullname, ''VIS|AGE:>=65'' FROM dual UNION ALL ' ||
  '  SELECT ''\ACT\Visit Details\Age at visit\>= 85 years old'' AS c_fullname, ''VIS|AGE:>=85'' FROM dual UNION ALL ' ||
  '  SELECT ''\ACT\Visit Details\Age at visit\>= 90 years old'' AS c_fullname, ''VIS|AGE:>=90'' FROM dual UNION ALL ' ||
  '  SELECT ''\ACT\Demographics\Age\>= 90 years old'' AS c_fullname, ''DEM|AGE:>=90'' FROM dual UNION ALL ' ||
  '  SELECT ''\ACT\Demographics\Age\>= 85 years old'' AS c_fullname, ''DEM|AGE:>=85'' FROM dual UNION ALL ' ||
  '  SELECT ''\ACT\Demographics\Age\>= 65 years old'' AS c_fullname, ''DEM|AGE:>=65'' FROM dual UNION ALL ' ||
  '  SELECT ''\ACT\Demographics\Age\>= 18 years old'' AS c_fullname, ''DEM|AGE:>=18'' FROM dual UNION ALL ' ||
  '  SELECT ''\ACT\Demographics\Age\< 18 years old'' AS c_fullname, ''DEM|AGE:<18'' FROM dual ' ||
  ') ' ||
  'SELECT DISTINCT c_hlevel, M.c_fullname, c_synonym_cd, c_visualattributes, ' ||
  '       NVL(BO.c_basecode, M.c_basecode) AS c_basecode, ' ||
  '       c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, ' ||
  '       c_operator, c_dimcode, m_applied_path ' ||
  'FROM ( ' ||
  '  SELECT c_hlevel, c_fullname, c_synonym_cd, c_visualattributes, ' ||
  '         CASE WHEN INSTR(c_basecode, '':'') = 0 AND c_basecode IS NOT NULL THEN ' ||
  '              c_tablename || ''|'' || c_columnname || '':'' || c_basecode ' ||
  '              WHEN c_fullname LIKE ''\ACT\Visit Details\Age at visit\%'' THEN ' ||
  '              REPLACE(c_basecode, ''DEM|'', ''VIS|'') ' ||
  '              ELSE c_basecode ' ||
  '         END AS c_basecode, ' ||
  '         c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, ' ||
  '         c_operator, c_dimcode, m_applied_path ' ||
  '  FROM ' || schemaname || '.' || visit_table || ' ' ||
  '  UNION ' ||
  '  SELECT c_hlevel, c_fullname, c_synonym_cd, c_visualattributes, ' ||
  '         CASE WHEN INSTR(c_basecode, '':'') = 0 AND c_basecode IS NOT NULL THEN ' ||
  '              c_tablename || ''|'' || c_columnname || '':'' || c_basecode ' ||
  '              ELSE c_basecode ' ||
  '         END AS c_basecode, ' ||
  '         c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, ' ||
  '         c_operator, c_dimcode, m_applied_path ' ||
  '  FROM ' || schemaname || '.' || demo_table || ' ' ||
  ') M LEFT JOIN CTE_BASECODE_OVERRIDE BO ' ||
  '  ON M.c_fullname = BO.c_fullname ' ||
  'WHERE C_FACTTABLECOLUMN <> ''concept_cd''';

DBMS_OUTPUT.PUT_LINE(v_sql);
EXECUTE IMMEDIATE v_sql;
  END IF;

  
  -- Create an index on TNUM_ONTOLOGY.
  -- (Oracle does not support the SQL Server “INCLUDE” clause; if you need extra columns, consider other approaches.)
  EXECUTE IMMEDIATE 'CREATE INDEX IDX_ONT_ITEMS ON TNUM_ONTOLOGY (C_FULLNAME)';
  
  BEGIN
    EndTime(startime, 'ontology', 'ontology');
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;
  startime := SYSDATE;
  
  ---------------------------------------------------------------------------
  -- 5. Build the closure table CONCEPT_CLOSURE.
  ---------------------------------------------------------------------------
  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CONCEPT_CLOSURE';
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
        RAISE;
      END IF;
  END;
  
  EXECUTE IMMEDIATE q'[
    CREATE TABLE CONCEPT_CLOSURE (
      ANCESTOR   NUMBER,
      DESCENDANT NUMBER,
      C_BASECODE VARCHAR2(50),
      CONSTRAINT PK_CONCEPT_CLOSURE PRIMARY KEY (ANCESTOR, DESCENDANT)
    )
  ]';
  
  -- Use a recursive WITH clause to “close” the ontology hierarchy.
EXECUTE IMMEDIATE q'[
  INSERT INTO CONCEPT_CLOSURE (ANCESTOR, DESCENDANT, C_BASECODE)
  WITH CONCEPTS (C_FULLNAME, C_HLEVEL, C_BASECODE, DESCENDANT) AS (
    -- Anchor: start with each ontology row.
    SELECT C_FULLNAME,
           C_HLEVEL,
           C_BASECODE,
           PATH_NUM AS DESCENDANT
      FROM TNUM_ONTOLOGY
     WHERE C_FULLNAME IS NOT NULL
       AND C_BASECODE IS NOT NULL
    UNION ALL
    -- Recursive step: remove the last component from the path.
    SELECT SUBSTR(
             SUBSTR(C_FULLNAME, 1, LENGTH(C_FULLNAME) - 1), -- remove trailing slash
             1,
             LENGTH(SUBSTR(C_FULLNAME, 1, LENGTH(C_FULLNAME) - 1)) - 
             INSTR(REVERSE(SUBSTR(C_FULLNAME, 1, LENGTH(C_FULLNAME) - 1)), '\') + 1
           ) AS C_FULLNAME,
           C_HLEVEL - 1,
           C_BASECODE,
           DESCENDANT
      FROM CONCEPTS
     WHERE C_HLEVEL > 0
  )
  SELECT DISTINCT O.PATH_NUM AS ANCESTOR,
                  C.DESCENDANT,
                  NVL(C.C_BASECODE, '') AS C_BASECODE
    FROM CONCEPTS C
         INNER JOIN TNUM_ONTOLOGY O ON C.C_FULLNAME = O.C_FULLNAME
]';

  
  EXECUTE IMMEDIATE 'CREATE INDEX IDX_DESCN ON CONCEPT_CLOSURE (DESCENDANT)';
  
  BEGIN
    EndTime(startime, 'ontology', 'closure');
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;
  startime := SYSDATE;
  
EXCEPTION
  WHEN OTHERS THEN
    -- In production, add error logging here.
    RAISE;
END FastTotalnumPrep;

CREATE OR REPLACE PROCEDURE EndTime (
  startime IN DATE,
  label    IN VARCHAR2,
  label2   IN VARCHAR2
)
IS
  duration NUMBER;
BEGIN
  -- Calculate the elapsed time in seconds.
  duration := TRUNC((SYSDATE - startime) * 86400);

  -- Output the debug message.
  -- (Note: DBMS_OUTPUT.PUT_LINE buffers output until the block completes;
  --  there is no direct NOWAIT equivalent.)
  DBMS_OUTPUT.PUT_LINE('(BENCH) ' || label || ',' || label2 || ',' || duration);
END EndTime;
