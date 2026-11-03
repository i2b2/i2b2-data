-- Supplemental non-ACT patient_dimension counts for fast all-demographics mode.
CREATE OR REPLACE PROCEDURE fasttotalnumadditionaldimensions(
    schemaname text, tablename text DEFAULT '@'
)
LANGUAGE plpgsql
AS $sql$
DECLARE
    t record;
    item record;
    predicate text;
    count_sql text;
    patient_count integer;
    metadata_relation regclass;
BEGIN
    FOR t IN
        SELECT DISTINCT ta.c_table_name
        FROM table_access ta
        WHERE ta.c_visualattributes LIKE '%A%'
          AND (tablename = '@' OR ta.c_table_name = tablename)
          AND NOT EXISTS (
              SELECT 1 FROM table_access act
              WHERE upper(act.c_table_cd) = 'ACT_DEMO'
                AND act.c_table_name = ta.c_table_name
          )
    LOOP
        metadata_relation := to_regclass(t.c_table_name);
        IF metadata_relation IS NULL THEN
            RAISE EXCEPTION 'Ontology table % from TABLE_ACCESS does not exist', t.c_table_name;
        END IF;
        FOR item IN EXECUTE format(
            'SELECT DISTINCT c_fullname, c_facttablecolumn, c_columnname, c_operator, c_dimcode '
            || 'FROM %s WHERE m_applied_path = ''@'' AND lower(c_tablename) = ''patient_dimension''',
            metadata_relation)
        LOOP
            BEGIN
                IF lower(item.c_columnname) = 'birth_date'
                   AND lower(item.c_dimcode) LIKE '%not recorded%' THEN
                    predicate := 'IS NULL';
                ELSIF lower(item.c_operator) = 'like' THEN
                    predicate := format('LIKE %L', item.c_dimcode || '%');
                ELSIF lower(item.c_operator) = 'in' THEN
                    predicate := 'IN ' || CASE WHEN left(ltrim(item.c_dimcode), 1) = '('
                                               THEN item.c_dimcode ELSE '(' || item.c_dimcode || ')' END;
                ELSIF item.c_operator = '=' THEN
                    predicate := format('= %L', item.c_dimcode);
                ELSE
                    predicate := item.c_operator || ' ' || coalesce(item.c_dimcode, 'NULL');
                END IF;

                count_sql := format(
                    'SELECT count(DISTINCT patient_num) FROM %I.patient_dimension WHERE %I IN ('
                    || 'SELECT %I FROM %I.patient_dimension WHERE %I %s)',
                    schemaname, item.c_facttablecolumn, item.c_facttablecolumn,
                    schemaname, item.c_columnname, predicate);
                EXECUTE count_sql INTO patient_count;
                INSERT INTO totalnum(c_fullname, agg_date, agg_count, typeflag_cd)
                VALUES (item.c_fullname, current_date, patient_count, 'PA');
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE 'Skipping dimension item %: %', item.c_fullname, SQLERRM;
            END;
        END LOOP;
    END LOOP;
END;
$sql$;
