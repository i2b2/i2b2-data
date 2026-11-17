-- Supplemental non-ACT patient_dimension counts for fast supplemental demographics mode.
DROP PROCEDURE IF EXISTS fasttotalnumadditionaldimensions(varchar, varchar);

CREATE OR REPLACE PROCEDURE fasttotalnumadditionaldimensions(
    IN schemaname text,
    IN tablename text DEFAULT '@'
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
    metadata_schema text := current_schema();
BEGIN
    v_patient_table := format('%I.patient_dimension', coalesce(nullif(btrim(schemaname), ''), 'public'));

    FOR t IN
        SELECT DISTINCT ta.c_table_name
        FROM table_access AS ta
        WHERE ta.c_visualattributes LIKE '%A%'
          AND (tablename = '@' OR lower(ta.c_table_name) = lower(tablename))
          AND NOT EXISTS (
              SELECT 1
              FROM table_access AS act
              WHERE UPPER(act.c_table_cd) = 'ACT_DEMO'
                AND act.c_table_name = ta.c_table_name
          )
    LOOP
        BEGIN
            -- Match the identifier folding used by prep and output.
            IF strpos(t.c_table_name, '.') > 0 THEN
                v_metadata_table := format('%I.%I',
                    lower(split_part(t.c_table_name, '.', 1)),
                    lower(split_part(t.c_table_name, '.', 2)));
            ELSE
                v_metadata_table := format('%I.%I', metadata_schema, lower(t.c_table_name));
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

                    EXECUTE format(
                        'INSERT INTO %I.totalnum(c_fullname, agg_date, agg_count, typeflag_cd)
                         VALUES ($1, CURRENT_TIMESTAMP, $2, ''PA'')', metadata_schema
                    ) USING item.c_fullname, v_count;
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
