-- Supplemental non-ACT patient_dimension counts for fast all-demographics mode.
CREATE OR REPLACE PROCEDURE FastTotalnumAdditionalDimensions(
  schemaName IN VARCHAR2,
  tableName IN VARCHAR2 DEFAULT '@'
) AUTHID CURRENT_USER IS
  v_sql VARCHAR2(32767);
  v_predicate VARCHAR2(4000);
  v_count NUMBER;
  v_table VARCHAR2(261);
BEGIN
  FOR t IN (
    SELECT DISTINCT ta.c_table_name
    FROM table_access ta
    WHERE ta.c_visualattributes LIKE '%A%'
      AND (tableName = '@' OR ta.c_table_name = tableName)
      AND NOT EXISTS (
        SELECT 1 FROM table_access act
        WHERE UPPER(act.c_table_cd) = 'ACT_DEMO'
          AND act.c_table_name = ta.c_table_name
      )
  ) LOOP
    v_table := DBMS_ASSERT.SQL_OBJECT_NAME(t.c_table_name);
    v_sql := 'SELECT DISTINCT c_fullname, c_facttablecolumn, c_columnname, c_operator, c_dimcode ' ||
             'FROM ' || v_table || ' WHERE m_applied_path = ''@'' ' ||
             'AND LOWER(c_tablename) = ''patient_dimension''';
    DECLARE
      TYPE item_cursor IS REF CURSOR;
      c item_cursor;
      v_path VARCHAR2(1200);
      v_factcol VARCHAR2(128);
      v_column VARCHAR2(128);
      v_operator VARCHAR2(20);
      v_dimcode VARCHAR2(4000);
    BEGIN
      OPEN c FOR v_sql;
      LOOP
        FETCH c INTO v_path, v_factcol, v_column, v_operator, v_dimcode;
        EXIT WHEN c%NOTFOUND;
        BEGIN
          IF LOWER(v_column) = 'birth_date' AND LOWER(v_dimcode) LIKE '%not recorded%' THEN
            v_predicate := 'IS NULL';
          ELSIF LOWER(v_operator) = 'like' THEN
            v_predicate := 'LIKE ''' || REPLACE(v_dimcode, '''', '''''') || '%''';
          ELSIF LOWER(v_operator) = 'in' THEN
            v_predicate := 'IN ' || CASE WHEN SUBSTR(TRIM(v_dimcode), 1, 1) = '(' THEN v_dimcode
                                         ELSE '(' || v_dimcode || ')' END;
          ELSIF v_operator = '=' THEN
            v_predicate := '= ''' || REPLACE(v_dimcode, '''', '''''') || '''';
          ELSE
            v_predicate := v_operator || ' ' || NVL(v_dimcode, 'NULL');
          END IF;

          v_sql := 'SELECT COUNT(DISTINCT patient_num) FROM ' ||
                   DBMS_ASSERT.SIMPLE_SQL_NAME(schemaName) || '.patient_dimension WHERE ' ||
                   DBMS_ASSERT.SIMPLE_SQL_NAME(v_factcol) || ' IN (SELECT ' ||
                   DBMS_ASSERT.SIMPLE_SQL_NAME(v_factcol) || ' FROM ' ||
                   DBMS_ASSERT.SIMPLE_SQL_NAME(schemaName) || '.patient_dimension WHERE ' ||
                   DBMS_ASSERT.SIMPLE_SQL_NAME(v_column) || ' ' || v_predicate || ')';
          EXECUTE IMMEDIATE v_sql INTO v_count;
          INSERT INTO totalnum(c_fullname, agg_date, agg_count, typeflag_cd)
          VALUES (v_path, SYSDATE, v_count, 'PA');
        EXCEPTION WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('Skipping dimension item ' || v_path || ': ' || SQLERRM);
        END;
      END LOOP;
      CLOSE c;
    END;
  END LOOP;
END FastTotalnumAdditionalDimensions;
