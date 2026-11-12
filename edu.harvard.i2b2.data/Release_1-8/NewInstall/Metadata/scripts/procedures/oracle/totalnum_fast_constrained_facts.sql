-- Oracle: FastTotalnumConstrainedFacts complete deployment script
-- Run as the owner of TABLE_ACCESS, TNUM_ONTOLOGY, CONCEPT_CLOSURE, TOTALNUM.
-- Requires direct SELECT privileges on referenced objects (roles do not count in stored PL/SQL).
-- Setup GTTs are created only when absent; no existing data/table is dropped.

DECLARE
  v_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_exists
  FROM USER_TABLES
  WHERE TABLE_NAME = 'TNUM_CONSTRAINT_CANDIDATES';
  IF v_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE GLOBAL TEMPORARY TABLE TNUM_CONSTRAINT_CANDIDATES (
  metadata_table VARCHAR2(255) NOT NULL,
  c_fullname VARCHAR2(1200) NOT NULL,
  c_basecode VARCHAR2(50) NOT NULL,
  constraint_expression VARCHAR2(128) NOT NULL,
  normalized_expression VARCHAR2(128),
  value_text VARCHAR2(80)
) ON COMMIT PRESERVE ROWS';
    DBMS_OUTPUT.PUT_LINE('Created TNUM_CONSTRAINT_CANDIDATES');
  END IF;
END;
/

DECLARE
  v_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_exists
  FROM USER_TABLES
  WHERE TABLE_NAME = 'TNUM_PARSED_CONSTRAINTS';
  IF v_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE GLOBAL TEMPORARY TABLE TNUM_PARSED_CONSTRAINTS (
  metadata_table VARCHAR2(255) NOT NULL,
  c_fullname VARCHAR2(1200) NOT NULL,
  concept_cd VARCHAR2(50) NOT NULL,
  required_nval NUMBER(38,10) NOT NULL
) ON COMMIT PRESERVE ROWS';
    DBMS_OUTPUT.PUT_LINE('Created TNUM_PARSED_CONSTRAINTS');
  END IF;
END;
/

DECLARE
  v_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_exists
  FROM USER_TABLES
  WHERE TABLE_NAME = 'TNUM_PREPARED_CONSTRAINTS';
  IF v_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE GLOBAL TEMPORARY TABLE TNUM_PREPARED_CONSTRAINTS (
  path_num NUMBER NOT NULL,
  concept_cd VARCHAR2(50) NOT NULL,
  required_nval NUMBER(38,10) NOT NULL,
  CONSTRAINT PK_TNUM_PREP_CONS PRIMARY KEY(path_num,concept_cd,required_nval)
) ON COMMIT PRESERVE ROWS';
    DBMS_OUTPUT.PUT_LINE('Created TNUM_PREPARED_CONSTRAINTS');
  END IF;
END;
/

DECLARE
  v_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_exists
  FROM USER_TABLES
  WHERE TABLE_NAME = 'TNUM_AFFECTED_ANCESTORS';
  IF v_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE GLOBAL TEMPORARY TABLE TNUM_AFFECTED_ANCESTORS (
  path_num NUMBER NOT NULL PRIMARY KEY
) ON COMMIT PRESERVE ROWS';
    DBMS_OUTPUT.PUT_LINE('Created TNUM_AFFECTED_ANCESTORS');
  END IF;
END;
/

DECLARE
  v_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_exists
  FROM USER_TABLES
  WHERE TABLE_NAME = 'TNUM_AFFECTED_DESCENDANTS';
  IF v_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE GLOBAL TEMPORARY TABLE TNUM_AFFECTED_DESCENDANTS (
  path_num NUMBER NOT NULL PRIMARY KEY
) ON COMMIT PRESERVE ROWS';
    DBMS_OUTPUT.PUT_LINE('Created TNUM_AFFECTED_DESCENDANTS');
  END IF;
END;
/

DECLARE
  v_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_exists
  FROM USER_TABLES
  WHERE TABLE_NAME = 'TNUM_MATCHED_DESCENDANTS';
  IF v_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE GLOBAL TEMPORARY TABLE TNUM_MATCHED_DESCENDANTS (
  patient_num NUMBER NOT NULL,
  path_num NUMBER NOT NULL,
  CONSTRAINT PK_TNUM_MATCH_DESC PRIMARY KEY(patient_num,path_num)
) ON COMMIT PRESERVE ROWS';
    DBMS_OUTPUT.PUT_LINE('Created TNUM_MATCHED_DESCENDANTS');
  END IF;
END;
/

CREATE OR REPLACE PROCEDURE FastTotalnumConstrainedFacts (
    p_schemaname IN VARCHAR2 DEFAULT 'DBO',
    p_tablename IN VARCHAR2 DEFAULT '@',
    p_source_mode IN VARCHAR2 DEFAULT 'i2b2'
)
AS
    v_metadata_table VARCHAR2(255);
    v_sql CLOB;
    v_fact_object VARCHAR2(300);
    v_candidate_count NUMBER;
    v_parsed_count NUMBER;
    v_prepared_count NUMBER;
    v_invalid_count NUMBER;
    v_missing_count NUMBER;
    v_source_mode_norm VARCHAR2(20) := LOWER(NVL(NULLIF(p_source_mode,''),'i2b2'));
    v_exists NUMBER;
BEGIN
    IF v_source_mode_norm NOT IN ('i2b2', 'omop') THEN
        RAISE_APPLICATION_ERROR(-20020, 'Unsupported source_mode: ' || v_source_mode_norm || '. Use i2b2 or omop.');
    END IF;
    -- OMOP is exposed through the i2b2-compatible OBSERVATION_FACT view.
    -- Both modes use PATIENT_NUM, CONCEPT_CD and NVAL_NUM.
    DBMS_OUTPUT.PUT_LINE('Constrained facts source: ' || v_source_mode_norm);

    -- Validate the identifier components before constructing dynamic SQL.
    v_fact_object := DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(p_schemaname)) || '.OBSERVATION_FACT';
    SELECT COUNT(*) INTO v_exists
    FROM ALL_OBJECTS
    WHERE OWNER = UPPER(p_schemaname)
      AND OBJECT_NAME = 'OBSERVATION_FACT'
      AND OBJECT_TYPE IN ('TABLE','VIEW');
    IF v_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20021, 'OBSERVATION_FACT table/view not visible: ' || v_fact_object);
    END IF;

    -- Clear previous session-local rows (GTT definitions remain installed).
    DELETE FROM TNUM_MATCHED_DESCENDANTS;
    DELETE FROM TNUM_AFFECTED_DESCENDANTS;
    DELETE FROM TNUM_AFFECTED_ANCESTORS;
    DELETE FROM TNUM_PREPARED_CONSTRAINTS;
    DELETE FROM TNUM_PARSED_CONSTRAINTS;
    DELETE FROM TNUM_CONSTRAINT_CANDIDATES;

    FOR rec IN (
        SELECT DISTINCT ta.c_table_name
        FROM table_access ta
        WHERE ta.c_visualattributes LIKE '%A%'
          AND (p_tablename = '@' OR ta.c_table_name = p_tablename)
          AND NOT EXISTS (
              SELECT 1 FROM table_access act
              WHERE UPPER(act.c_table_cd) = 'ACT_DEMO'
                AND act.c_table_name = ta.c_table_name
          )
    ) LOOP
        v_metadata_table := rec.c_table_name;
        BEGIN
            -- Metadata table names may already be schema-qualified.
            -- QUALIFIED_SQL_NAME validates without executing metadata expressions.
            v_sql := 'INSERT INTO TNUM_CONSTRAINT_CANDIDATES ' ||
                     '(metadata_table,c_fullname,c_basecode,constraint_expression) ' ||
                     'SELECT DISTINCT :table_name,c_fullname,c_basecode,c_columnname ' ||
                     'FROM ' || DBMS_ASSERT.QUALIFIED_SQL_NAME(v_metadata_table) || ' ' ||
                     'WHERE m_applied_path = ''@'' ' ||
                     'AND c_visualattributes LIKE ''L%'' ' ||
                     'AND c_visualattributes LIKE ''%A%'' ' ||
                     'AND LOWER(c_facttablecolumn) = ''concept_cd'' ' ||
                     'AND LOWER(c_tablename) = ''concept_dimension'' ' ||
                     'AND LOWER(c_operator) = ''like'' ' ||
                     'AND c_basecode IS NOT NULL ' ||
                     'AND LOWER(c_columnname) LIKE ''%nval_num%'' ' ||
                     'AND LOWER(c_columnname) LIKE ''%concept_cd%''';
            EXECUTE IMMEDIATE v_sql USING v_metadata_table;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Skipping constrained metadata table ' || v_metadata_table || ': ' || SQLERRM);
        END;
    END LOOP;

    SELECT COUNT(*) INTO v_candidate_count FROM TNUM_CONSTRAINT_CANDIDATES;
    IF v_candidate_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No constrained fact ontology entries found.');
        RETURN;
    END IF;

    UPDATE TNUM_CONSTRAINT_CANDIDATES
    SET normalized_expression = LOWER(TRIM(
        REPLACE(REPLACE(REPLACE(constraint_expression,CHR(9),' '),CHR(10),' '),CHR(13),' ')
    ));

    -- Collapse runs of whitespace without executing any metadata expression.
    UPDATE TNUM_CONSTRAINT_CANDIDATES
    SET normalized_expression = REGEXP_REPLACE(normalized_expression, ' {2,}', ' ');

    UPDATE TNUM_CONSTRAINT_CANDIDATES
    SET value_text = TRIM(SUBSTR(
        normalized_expression,
        LENGTH('nval_num = ') + 1,
        LENGTH(normalized_expression) - LENGTH('nval_num = ') - LENGTH(' and concept_cd')
    ))
    WHERE SUBSTR(normalized_expression,1,LENGTH('nval_num = ')) = 'nval_num = '
      AND SUBSTR(normalized_expression,-LENGTH(' and concept_cd')) = ' and concept_cd'
      AND LENGTH(normalized_expression) > LENGTH('nval_num = ') + LENGTH(' and concept_cd');

    -- A numeric regular expression plus conversion validation replaces TRY_CONVERT.
    -- TO_NUMBER DEFAULT NULL ON CONVERSION ERROR requires Oracle 12.2+.
    INSERT INTO TNUM_PARSED_CONSTRAINTS(metadata_table,c_fullname,concept_cd,required_nval)
    SELECT DISTINCT metadata_table,c_fullname,c_basecode,
           TO_NUMBER(value_text DEFAULT NULL ON CONVERSION ERROR,
                     'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')
    FROM TNUM_CONSTRAINT_CANDIDATES
    WHERE REGEXP_LIKE(value_text, '^[+-]?([0-9]+(\.[0-9]*)?|\.[0-9]+)$')
      AND TO_NUMBER(value_text DEFAULT NULL ON CONVERSION ERROR,
                    'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''') IS NOT NULL;

    SELECT COUNT(*) INTO v_parsed_count FROM TNUM_PARSED_CONSTRAINTS;
    v_invalid_count := v_candidate_count - v_parsed_count;
    IF v_invalid_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Skipped ' || v_invalid_count || ' constrained fact entries whose C_COLUMNNAME was not supported.');
    END IF;

    INSERT INTO TNUM_PREPARED_CONSTRAINTS(path_num,concept_cd,required_nval)
    SELECT DISTINCT o.path_num,p.concept_cd,p.required_nval
    FROM TNUM_PARSED_CONSTRAINTS p
    JOIN tnum_ontology o
      ON o.c_fullname = p.c_fullname
     AND o.c_basecode = p.concept_cd
     AND o.c_visualattributes LIKE 'L%';

    SELECT COUNT(*) INTO v_prepared_count FROM TNUM_PREPARED_CONSTRAINTS;
    IF v_prepared_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Constrained fact entries are not present in TNUM_ONTOLOGY. Rerun FastTotalnumPrep.');
        RETURN;
    END IF;
    IF v_prepared_count < v_parsed_count THEN
        v_missing_count := v_parsed_count - v_prepared_count;
        DBMS_OUTPUT.PUT_LINE(v_missing_count || ' constrained fact entries not found in TNUM_ONTOLOGY; rerun FastTotalnumPrep.');
    END IF;

    INSERT INTO TNUM_AFFECTED_ANCESTORS(path_num)
    SELECT DISTINCT cc.ancestor
    FROM concept_closure cc
    JOIN TNUM_PREPARED_CONSTRAINTS r ON r.path_num = cc.descendant
    WHERE NOT EXISTS (
        SELECT 1
        FROM concept_closure branch
        JOIN tnum_ontology leaf ON leaf.path_num = branch.descendant
        WHERE branch.ancestor = cc.ancestor
          AND leaf.c_visualattributes LIKE 'L%'
          AND (LOWER(NVL(leaf.c_facttablecolumn,' ')) <> 'concept_cd'
            OR LOWER(NVL(leaf.c_tablename,' ')) <> 'concept_dimension')
    )
    AND NOT EXISTS (
        SELECT 1
        FROM concept_closure branch
        JOIN tnum_ontology leaf ON leaf.path_num = branch.descendant
        JOIN TNUM_CONSTRAINT_CANDIDATES candidate
          ON candidate.c_fullname = leaf.c_fullname
         AND candidate.c_basecode = leaf.c_basecode
        WHERE branch.ancestor = cc.ancestor
          AND NOT EXISTS (
              SELECT 1 FROM TNUM_PREPARED_CONSTRAINTS supported
              WHERE supported.path_num = leaf.path_num
          )
    );

    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No prepared constrained paths found in CONCEPT_CLOSURE. Rerun FastTotalnumPrep.');
        RETURN;
    END IF;

    INSERT INTO TNUM_AFFECTED_DESCENDANTS(path_num)
    SELECT DISTINCT cc.descendant
    FROM concept_closure cc
    JOIN TNUM_AFFECTED_ANCESTORS a ON a.path_num = cc.ancestor
    JOIN tnum_ontology o ON o.path_num = cc.descendant
    WHERE o.c_visualattributes LIKE 'L%'
      AND o.c_basecode IS NOT NULL;

    -- Ordinary leaves use the fast OBSFACT_PAIRS matches.
    INSERT INTO TNUM_MATCHED_DESCENDANTS(patient_num,path_num)
    SELECT DISTINCT f.patient_num,o.path_num
    FROM obsfact_pairs f
    JOIN tnum_ontology o ON o.c_basecode = f.concept_cd
    JOIN TNUM_AFFECTED_DESCENDANTS d ON d.path_num = o.path_num
    WHERE f.patient_num IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM TNUM_PREPARED_CONSTRAINTS r WHERE r.path_num = o.path_num
      );

    -- Supported constrained leaves match both concept_cd and nval_num.
    v_sql := 'INSERT INTO TNUM_MATCHED_DESCENDANTS(patient_num,path_num) ' ||
             'SELECT DISTINCT f.patient_num,r.path_num ' ||
             'FROM ' || v_fact_object || ' f ' ||
             'JOIN TNUM_PREPARED_CONSTRAINTS r ' ||
             '  ON r.concept_cd = f.concept_cd AND r.required_nval = f.nval_num ' ||
             'WHERE f.patient_num IS NOT NULL ' ||
             'AND NOT EXISTS (SELECT 1 FROM TNUM_MATCHED_DESCENDANTS m ' ||
             ' WHERE m.patient_num = f.patient_num AND m.path_num = r.path_num)';
    EXECUTE IMMEDIATE v_sql;

    -- Insert PA after PF; the all-demographics output can use corrected branch counts.
    INSERT INTO totalnum(c_fullname,agg_count,agg_date,typeflag_cd)
    SELECT o.c_fullname,COUNT(DISTINCT m.patient_num),SYSDATE,'PA'
    FROM TNUM_AFFECTED_ANCESTORS a
    JOIN tnum_ontology o ON o.path_num = a.path_num
    LEFT JOIN concept_closure cc ON cc.ancestor = a.path_num
    LEFT JOIN TNUM_MATCHED_DESCENDANTS m ON m.path_num = cc.descendant
    GROUP BY o.c_fullname;

    DBMS_OUTPUT.PUT_LINE('Counted ' || v_prepared_count ||
        ' prepared constrained fact entries and rebuilt eligible fact-only hierarchy branches.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FastTotalnumConstrainedFacts failed: ' || SQLERRM);
        RAISE;
END FastTotalnumConstrainedFacts;
/

-- Inspect compile errors after deployment:
-- SELECT line, position, text
-- FROM user_errors
-- WHERE name = 'FASTTOTALNUMCONSTRAINEDFACTS'
-- ORDER BY sequence;
--
-- Example:
-- BEGIN
--   FastTotalnumConstrainedFacts('I2B2SYNTHEA3', '@', 'i2b2');
-- END;
-- /
