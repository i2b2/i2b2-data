-- Supplemental non-ACT patient_dimension counts for fast all-demographics mode.
CREATE OR REPLACE PROCEDURE public.fasttotalnumadditionaldimensions(
    IN schemaname VARCHAR,
    IN tablename VARCHAR DEFAULT '@'
)
LANGUAGE plpgsql
AS $procedure$
DECLARE
    t RECORD;
    item RECORD;
    v_metadata_table TEXT;
    v_patient_table TEXT;
    v_sql TEXT;
    v_predicate TEXT;
    v_count BIGINT;
BEGIN
    v_patient_table := format('%I.patient_dimension', schemaname);

    FOR t IN
        SELECT DISTINCT ta.c_table_name
        FROM public.table_access AS ta
        WHERE ta.c_visualattributes LIKE '%A%'
          AND (tablename = '@' OR ta.c_table_name = tablename)
          AND NOT EXISTS (
              SELECT 1
              FROM public.table_access AS act
              WHERE UPPER(act.c_table_cd) = 'ACT_DEMO'
                AND act.c_table_name = ta.c_table_name
          )
    LOOP
        BEGIN
            -- Resolve ontology table in the specified schema, unless already qualified.
            IF strpos(t.c_table_name, '.') > 0 THEN
                v_metadata_table := format('%I.%I',
                    split_part(t.c_table_name, '.', 1),
                    split_part(t.c_table_name, '.', 2));
            ELSE
                v_metadata_table := format('%I.%I', schemaname, t.c_table_name);
            END IF;

            v_sql := format(
                'SELECT DISTINCT c_fullname, c_facttablecolumn, c_columnname, c_operator, c_dimcode
                 FROM %s
                 WHERE m_applied_path = ''@''
                   AND LOWER(c_tablename) = ''patient_dimension''',
                v_metadata_table
            );

            FOR item IN EXECUTE v_sql
            LOOP
                BEGIN
                    IF LOWER(item.c_columnname) = 'birth_date'
                       AND LOWER(item.c_dimcode) LIKE '%not recorded%' THEN
                        v_predicate := 'IS NULL';
                    ELSIF LOWER(item.c_operator) = 'like' THEN
                        v_predicate := format('LIKE %L', COALESCE(item.c_dimcode, '') || '%');
                    ELSIF LOWER(item.c_operator) = 'in' THEN
                        v_predicate := 'IN ' ||
                            CASE WHEN LEFT(TRIM(item.c_dimcode), 1) = '('
                                 THEN item.c_dimcode
                                 ELSE '(' || item.c_dimcode || ')'
                            END;
                    ELSIF item.c_operator = '=' THEN
                        v_predicate := format('= %L', item.c_dimcode);
                    ELSE
                        v_predicate := item.c_operator || ' ' || COALESCE(item.c_dimcode, 'NULL');
                    END IF;

                    v_sql := format(
                        'SELECT COUNT(DISTINCT patient_num)
                         FROM %s
                         WHERE %I IN (
                             SELECT %I
                             FROM %s
                             WHERE %I %s
                         )',
                        v_patient_table,
                        item.c_facttablecolumn,
                        item.c_facttablecolumn,
                        v_patient_table,
                        item.c_columnname,
                        v_predicate
                    );

                    EXECUTE v_sql INTO v_count;

                    INSERT INTO public.totalnum(c_fullname, agg_date, agg_count, typeflag_cd)
                    VALUES (item.c_fullname, CURRENT_TIMESTAMP, v_count, 'PA');
                EXCEPTION WHEN OTHERS THEN
                    RAISE NOTICE 'Skipping dimension item %: %', item.c_fullname, SQLERRM;
                END;
            END LOOP;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Skipping ontology table %: %', t.c_table_name, SQLERRM;
        END;
    END LOOP;
END;
$procedure$;
GO

-- All eligible ontology tables:
-- CALL public.fasttotalnumadditionaldimensions('public', '@');
-- One ontology table:
-- CALL public.fasttotalnumadditionaldimensions('public', 'metadata_recover_adult');
