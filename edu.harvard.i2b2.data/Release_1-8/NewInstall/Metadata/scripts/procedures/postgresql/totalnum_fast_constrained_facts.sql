-- CALL public.fasttotalnumconstrainedfacts('public', '@', 'omop');
-- CALL public.fasttotalnumconstrainedfacts('public', '@', 'i2b2');
-- Prerequisites in p_schemaname: table_access, tnum_ontology,
-- concept_closure, obsfact_pairs, totalnum, observation_fact (table/view).
-- Requires PostgreSQL 11+ for CREATE PROCEDURE and CALL.
-- The procedure creates session-local temporary tables automatically.

CREATE OR REPLACE PROCEDURE public.fasttotalnumconstrainedfacts(
    IN p_schemaname text DEFAULT 'public',
    IN p_tablename text DEFAULT '@',
    IN p_source_mode text DEFAULT 'i2b2'
)
LANGUAGE plpgsql
AS $procedure$
DECLARE
    v_schema text := COALESCE(NULLIF(btrim(p_schemaname), ''), 'public');
    v_mode text := lower(COALESCE(NULLIF(btrim(p_source_mode), ''), 'i2b2'));
    v_metadata_table text;
    v_metadata_oid regclass;
    v_candidates bigint;
    v_parsed bigint;
    v_prepared bigint;
    v_affected bigint;
BEGIN
    IF v_mode NOT IN ('i2b2', 'omop') THEN
        RAISE EXCEPTION 'Unsupported source_mode: %. Use i2b2 or omop.', v_mode;
    END IF;

    IF to_regclass(format('%I.%I', v_schema, 'observation_fact')) IS NULL THEN
        RAISE EXCEPTION 'Missing %.observation_fact table/view', v_schema;
    END IF;

    -- Create in pg_temp, regardless of the caller's search_path.
    CREATE TEMP TABLE IF NOT EXISTS tnum_constraint_candidates (
        metadata_table varchar(255) NOT NULL,
        c_fullname varchar(1200) NOT NULL,
        c_basecode varchar(50) NOT NULL,
        constraint_expression varchar(128) NOT NULL,
        normalized_expression varchar(128),
        value_text varchar(80)
    ) ON COMMIT PRESERVE ROWS;

    CREATE TEMP TABLE IF NOT EXISTS tnum_parsed_constraints (
        metadata_table varchar(255) NOT NULL,
        c_fullname varchar(1200) NOT NULL,
        concept_cd varchar(50) NOT NULL,
        required_nval numeric(38,10) NOT NULL
    ) ON COMMIT PRESERVE ROWS;

    CREATE TEMP TABLE IF NOT EXISTS tnum_prepared_constraints (
        path_num numeric NOT NULL,
        concept_cd varchar(50) NOT NULL,
        required_nval numeric(38,10) NOT NULL,
        PRIMARY KEY (path_num, concept_cd, required_nval)
    ) ON COMMIT PRESERVE ROWS;

    CREATE TEMP TABLE IF NOT EXISTS tnum_affected_ancestors (
        path_num numeric PRIMARY KEY
    ) ON COMMIT PRESERVE ROWS;

    CREATE TEMP TABLE IF NOT EXISTS tnum_affected_descendants (
        path_num numeric PRIMARY KEY
    ) ON COMMIT PRESERVE ROWS;

    CREATE TEMP TABLE IF NOT EXISTS tnum_matched_descendants (
        patient_num numeric NOT NULL,
        path_num numeric NOT NULL,
        PRIMARY KEY (patient_num, path_num)
    ) ON COMMIT PRESERVE ROWS;

    TRUNCATE TABLE
        pg_temp.tnum_matched_descendants,
        pg_temp.tnum_affected_descendants,
        pg_temp.tnum_affected_ancestors,
        pg_temp.tnum_prepared_constraints,
        pg_temp.tnum_parsed_constraints,
        pg_temp.tnum_constraint_candidates;

    -- Locate all active non-ACT ontology tables.
    FOR v_metadata_table IN EXECUTE format($q$
        SELECT DISTINCT ta.c_table_name
        FROM %I.table_access ta
        WHERE ta.c_visualattributes LIKE '%%A%%'
          AND ta.c_table_name IS NOT NULL
          AND ($1 = '@' OR ta.c_table_name = $1)
          AND NOT EXISTS (
              SELECT 1 FROM %I.table_access act
              WHERE upper(act.c_table_cd) = 'ACT_DEMO'
                AND act.c_table_name = ta.c_table_name
          )
    $q$, v_schema, v_schema) USING p_tablename
    LOOP
        -- Names in table_access may be schema-qualified. Unqualified names
        -- are resolved within p_schemaname rather than the session search_path.
        IF strpos(v_metadata_table, '.') > 0 THEN
            v_metadata_oid := to_regclass(v_metadata_table);
        ELSE
            v_metadata_oid := to_regclass(format('%I.%I', v_schema, v_metadata_table));
        END IF;
        IF v_metadata_oid IS NULL THEN
            RAISE NOTICE 'Skipping metadata table %: not found', v_metadata_table;
            CONTINUE;
        END IF;

        BEGIN
            EXECUTE format($q$
                INSERT INTO pg_temp.tnum_constraint_candidates
                    (metadata_table, c_fullname, c_basecode, constraint_expression)
                SELECT DISTINCT $1, c_fullname, c_basecode, c_columnname
                FROM %s
                WHERE m_applied_path = '@'
                  AND c_visualattributes LIKE 'L%%'
                  AND c_visualattributes LIKE '%%A%%'
                  AND lower(c_facttablecolumn) = 'concept_cd'
                  AND lower(c_tablename) = 'concept_dimension'
                  AND lower(c_operator) = 'like'
                  AND c_basecode IS NOT NULL
                  AND lower(c_columnname) LIKE '%%nval_num%%'
                  AND lower(c_columnname) LIKE '%%concept_cd%%'
            $q$, v_metadata_oid) USING v_metadata_table;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Skipping constrained metadata table %: %', v_metadata_table, SQLERRM;
        END;
    END LOOP;

    SELECT count(*) INTO v_candidates FROM pg_temp.tnum_constraint_candidates;
    IF v_candidates = 0 THEN
        RAISE NOTICE 'No constrained fact ontology entries found.';
        RETURN;
    END IF;

    UPDATE pg_temp.tnum_constraint_candidates
    SET normalized_expression = lower(btrim(
        replace(replace(replace(constraint_expression, chr(9), ' '), chr(10), ' '), chr(13), ' ')
    ));
    UPDATE pg_temp.tnum_constraint_candidates
    SET normalized_expression = regexp_replace(normalized_expression, ' {2,}', ' ', 'g');

    -- Supported form: nval_num = <numeric literal> and concept_cd
    UPDATE pg_temp.tnum_constraint_candidates
    SET value_text = btrim(substring(normalized_expression
                        FROM '^nval_num = (.+) and concept_cd$'));

    INSERT INTO pg_temp.tnum_parsed_constraints
        (metadata_table, c_fullname, concept_cd, required_nval)
    SELECT DISTINCT metadata_table, c_fullname, c_basecode,
           value_text::numeric(38,10)
    FROM pg_temp.tnum_constraint_candidates
    WHERE value_text ~ '^[+-]?([0-9]{1,28}(\.[0-9]{0,10})?|\.[0-9]{1,10})$';

    SELECT count(*) INTO v_parsed FROM pg_temp.tnum_parsed_constraints;
    IF v_parsed < v_candidates THEN
        RAISE NOTICE 'Skipped % unsupported/duplicate constrained expressions.', v_candidates - v_parsed;
    END IF;

    EXECUTE format($q$
        INSERT INTO pg_temp.tnum_prepared_constraints(path_num, concept_cd, required_nval)
        SELECT DISTINCT o.path_num, p.concept_cd, p.required_nval
        FROM pg_temp.tnum_parsed_constraints p
        JOIN %I.tnum_ontology o ON o.c_fullname = p.c_fullname
                               AND o.c_basecode = p.concept_cd
                               AND o.c_visualattributes LIKE 'L%%'
        ON CONFLICT DO NOTHING
    $q$, v_schema);

    SELECT count(*) INTO v_prepared FROM pg_temp.tnum_prepared_constraints;
    IF v_prepared = 0 THEN
        RAISE NOTICE 'No constrained entries found in TNUM_ONTOLOGY; rerun FastTotalnumPrep.';
        RETURN;
    END IF;

    EXECUTE format($q$
        INSERT INTO pg_temp.tnum_affected_ancestors(path_num)
        SELECT DISTINCT cc.ancestor
        FROM %1$I.concept_closure cc
        JOIN pg_temp.tnum_prepared_constraints r ON r.path_num = cc.descendant
        WHERE NOT EXISTS (
            SELECT 1
            FROM %1$I.concept_closure branch
            JOIN %1$I.tnum_ontology leaf ON leaf.path_num = branch.descendant
            WHERE branch.ancestor = cc.ancestor
              AND leaf.c_visualattributes LIKE 'L%%'
              AND (lower(coalesce(leaf.c_facttablecolumn, ' ')) <> 'concept_cd'
                OR lower(coalesce(leaf.c_tablename, ' ')) <> 'concept_dimension')
        )
        AND NOT EXISTS (
            SELECT 1
            FROM %1$I.concept_closure branch
            JOIN %1$I.tnum_ontology leaf ON leaf.path_num = branch.descendant
            JOIN pg_temp.tnum_constraint_candidates candidate
              ON candidate.c_fullname = leaf.c_fullname
             AND candidate.c_basecode = leaf.c_basecode
            WHERE branch.ancestor = cc.ancestor
              AND NOT EXISTS (
                  SELECT 1 FROM pg_temp.tnum_prepared_constraints supported
                  WHERE supported.path_num = leaf.path_num
              )
        )
        ON CONFLICT DO NOTHING
    $q$, v_schema);
    GET DIAGNOSTICS v_affected = ROW_COUNT;
    IF v_affected = 0 THEN
        RAISE NOTICE 'No constrained paths found in CONCEPT_CLOSURE; rerun FastTotalnumPrep.';
        RETURN;
    END IF;

    EXECUTE format($q$
        INSERT INTO pg_temp.tnum_affected_descendants(path_num)
        SELECT DISTINCT cc.descendant
        FROM %1$I.concept_closure cc
        JOIN pg_temp.tnum_affected_ancestors a ON a.path_num = cc.ancestor
        JOIN %1$I.tnum_ontology o ON o.path_num = cc.descendant
        WHERE o.c_visualattributes LIKE 'L%%' AND o.c_basecode IS NOT NULL
        ON CONFLICT DO NOTHING
    $q$, v_schema);

    EXECUTE format($q$
        INSERT INTO pg_temp.tnum_matched_descendants(patient_num, path_num)
        SELECT DISTINCT f.patient_num, o.path_num
        FROM %1$I.obsfact_pairs f
        JOIN %1$I.tnum_ontology o ON o.c_basecode = f.concept_cd
        JOIN pg_temp.tnum_affected_descendants d ON d.path_num = o.path_num
        WHERE f.patient_num IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM pg_temp.tnum_prepared_constraints r
              WHERE r.path_num = o.path_num
          )
        ON CONFLICT DO NOTHING
    $q$, v_schema);

    EXECUTE format($q$
        INSERT INTO pg_temp.tnum_matched_descendants(patient_num, path_num)
        SELECT DISTINCT f.patient_num, r.path_num
        FROM %I.observation_fact f
        JOIN pg_temp.tnum_prepared_constraints r
          ON r.concept_cd = f.concept_cd AND r.required_nval = f.nval_num
        WHERE f.patient_num IS NOT NULL
        ON CONFLICT DO NOTHING
    $q$, v_schema);

    EXECUTE format($q$
        INSERT INTO %1$I.totalnum(c_fullname, agg_count, agg_date, typeflag_cd)
        SELECT o.c_fullname, count(DISTINCT m.patient_num), CURRENT_TIMESTAMP, 'PA'
        FROM pg_temp.tnum_affected_ancestors a
        JOIN %1$I.tnum_ontology o ON o.path_num = a.path_num
        LEFT JOIN %1$I.concept_closure cc ON cc.ancestor = a.path_num
        LEFT JOIN pg_temp.tnum_matched_descendants m ON m.path_num = cc.descendant
        GROUP BY o.c_fullname
    $q$, v_schema);

    RAISE NOTICE 'Constrained facts source %, prepared %, affected ancestors %',
        v_mode, v_prepared, v_affected;
END;
$procedure$;
GO

-- After deploying, run in a session with access to the source schema:
-- CALL public.fasttotalnumconstrainedfacts('public', '@', 'omop');
-- SELECT c_fullname, agg_count, agg_date FROM public.totalnum
-- WHERE typeflag_cd = 'PA' ORDER BY agg_date DESC LIMIT 20;
-- If calling from RunTotalnum, ensure it invokes this procedure for OMOP mode.
