/*
--------------------------------------------------------------------------------
Postgres Version: fasttotalnumprep
--------------------------------------------------------------------------------
Written by Darren Henderson (DARREN.HENDERSON@UKY.EDU) and Jeff Klann, PhD.

Description:
  This function prepares the environment for the FastTotalnum process by performing
  the following steps:
    1) Re-creates the "obsfact_pairs" view, which selects distinct patient numbers and
       concept codes from either "observation_fact" or ACT-OMOP views, based on source_mode.
    2) Creates the unified ontology table "tnum_ontology" that consolidates metadata.
    3) Loads additional ontology override entries into "tnum_ontology" from hardcoded 
       values to accommodate specific business rules.
    4) Constructs the transitive closure table "concept_closure" using a recursive CTE.
       This table captures ancestor/descendant relationships between ontology elements.
       For example, if a concept's full name is "\apple\fruit\", then "apple" becomes the
       ancestor and "fruit" the descendant.
       
Usage Examples:
  -- Run the function on the default schema:
  SELECT fasttotalnumprep();
  
  -- Run the function on a specified schema (e.g., "my_schema"):
  SELECT fasttotalnumprep('my_schema','i2b2');

  -- Run the function using ACT-OMOP views:
  SELECT fasttotalnumprep('public', 'omop');
  
Acknowledgements:
  This PostgreSQL conversion by Jeff Klann, with assistance from ChatGPT.
--------------------------------------------------------------------------------
*/
-- Builds OBSFACT_PAIRS, TNUM_ONTOLOGY, and CONCEPT_CLOSURE.
-- Requires source metadata tables and, for OMOP mode, the ACT-OMOP views.
-- Assumes physical PostgreSQL ontology tables use lowercase identifiers.
-- TABLE_ACCESS names such as ACT_DEM_V42 are normalized to act_dem_v42.

CREATE OR REPLACE PROCEDURE fasttotalnumprep(
    IN schemaname varchar DEFAULT 'public',
    IN source_mode varchar DEFAULT 'i2b2'
)
LANGUAGE plpgsql
AS $procedure$
DECLARE
    v_schema text := COALESCE(NULLIF(btrim(schemaname), ''), 'public');
    source_mode_norm text := lower(COALESCE(NULLIF(btrim(source_mode), ''), 'i2b2'));
    visit_table text;
    demo_table text;
    rec record;
    v_sql text;
    startime timestamp := clock_timestamp();
    v_view_definition text;
    v_omop_views text[] := ARRAY[
        'condition_ns_view', 'condition_view', 'drug_ns_view',
        'device_view', 'device_ns_view', 'drug_view',
        'measurement_ns_view', 'measurement_view',
        'observation_ns_view', 'observation_view',
        'procedure_ns_view', 'procedure_view', 'visit_ns_view'
    ];
    v_name text;
    v_parts text[];
    v_relation text;
    v_visit_relation text;
    v_demo_relation text;
BEGIN
    IF source_mode_norm NOT IN ('i2b2', 'omop') THEN
        RAISE EXCEPTION 'Invalid source_mode. Use i2b2 or omop.' USING ERRCODE = '22023';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = v_schema) THEN
        RAISE EXCEPTION 'Schema % does not exist', v_schema USING ERRCODE = '3F000';
    END IF;

    -- Use the target schema for unqualified table references inside the procedure.
    PERFORM set_config('search_path', format('%I, pg_catalog', v_schema), true);

    SELECT max(c_table_name)
      INTO visit_table
      FROM table_access WHERE upper(c_table_cd) = 'ACT_VISIT';
    SELECT max(c_table_name) INTO demo_table
      FROM table_access WHERE upper(c_table_cd) = 'ACT_DEMO';

    IF visit_table IS NULL THEN
        RAISE NOTICE 'Skipping ACT_VISIT ontology supplement: TABLE_ACCESS has no row for C_TABLE_CD = ACT_VISIT.';
    END IF;
    IF demo_table IS NULL THEN
        RAISE NOTICE 'Skipping ACT_DEMO ontology supplement: TABLE_ACCESS has no row for C_TABLE_CD = ACT_DEMO.';
    END IF;

    -- 1. Build or update OBSFACT_PAIRS view. CREATE OR REPLACE VIEW
    -- preserves dependent objects and also handles switching source modes.
    IF source_mode_norm = 'omop' THEN
        v_view_definition := '';
        FOREACH v_name IN ARRAY v_omop_views LOOP
            IF v_view_definition <> '' THEN
                v_view_definition := v_view_definition || E'\nUNION ALL\n';
            END IF;
            v_view_definition := v_view_definition || format(
                'SELECT DISTINCT patient_num, concept_cd FROM %I.%I', v_schema, v_name
            );
        END LOOP;
    ELSE
        v_view_definition := format(
            'SELECT DISTINCT patient_num, concept_cd FROM %I.observation_fact', v_schema
        );
    END IF;

    EXECUTE format('CREATE OR REPLACE VIEW %I.obsfact_pairs AS %s', v_schema, v_view_definition);
    RAISE NOTICE 'OBSFACT_PAIRS view prepared for source_mode=%', source_mode_norm;
    RAISE NOTICE 'Observation pairs prepared in % ms',
        round(extract(epoch FROM clock_timestamp() - startime) * 1000);
    startime := clock_timestamp();

    -- 2. Create master ontology table and index if absent.
    EXECUTE format($ddl$
        CREATE TABLE IF NOT EXISTS %I.tnum_ontology (
            path_num bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
            c_hlevel numeric NOT NULL,
            c_fullname varchar(700) NOT NULL,
            c_synonym_cd char(1) NOT NULL,
            c_visualattributes char(3) NOT NULL,
            c_basecode varchar(50),
            c_facttablecolumn varchar(50) NOT NULL,
            c_tablename varchar(50) NOT NULL,
            c_columnname varchar(50) NOT NULL,
            c_columndatatype varchar(50) NOT NULL,
            c_operator varchar(10) NOT NULL,
            c_dimcode varchar(700) NOT NULL,
            m_applied_path varchar(900) NOT NULL
        )
    $ddl$, v_schema);
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_ont_items ON %I.tnum_ontology (c_fullname)', v_schema);

    -- 3. Clear closure before ontology (TRUNCATE in PostgreSQL takes
    -- ACCESS EXCLUSIVE locks; do not run concurrently with other readers).
    IF to_regclass(format('%I.concept_closure', v_schema)) IS NOT NULL THEN
        EXECUTE format('TRUNCATE TABLE %I.concept_closure', v_schema);
    END IF;
    EXECUTE format('TRUNCATE TABLE %I.tnum_ontology RESTART IDENTITY', v_schema);

    -- 4. Load metadata tables listed by TABLE_ACCESS.
    FOR rec IN
        SELECT c_table_name, c_fullname AS path
          FROM table_access
         WHERE c_table_cd NOT IN ('ACT_DEMO', 'ACT_VISIT')
           AND c_visualattributes LIKE '%A%'
    LOOP
        -- c_table_name is a metadata-provided identifier, not raw SQL.
        -- Accept either table or schema.table; reject other forms.
        v_parts := string_to_array(btrim(rec.c_table_name), '.');
        IF array_length(v_parts, 1) = 1 THEN
            v_relation := format('%I.%I', v_schema, lower(v_parts[1]));
        ELSIF array_length(v_parts, 1) = 2 THEN
            v_relation := format('%I.%I', lower(v_parts[1]), lower(v_parts[2]));
        ELSE
            RAISE EXCEPTION 'Unsupported TABLE_ACCESS.C_TABLE_NAME: %', rec.c_table_name;
        END IF;

        v_sql := format($query$
            INSERT INTO %I.tnum_ontology (
                c_hlevel, c_fullname, c_synonym_cd, c_visualattributes,
                c_basecode, c_facttablecolumn, c_tablename, c_columnname,
                c_columndatatype, c_operator, c_dimcode, m_applied_path
            )
            SELECT DISTINCT
                c_hlevel, c_fullname, c_synonym_cd, c_visualattributes,
                c_basecode, c_facttablecolumn, c_tablename, c_columnname,
                c_columndatatype, c_operator, c_dimcode, m_applied_path
            FROM %s
            WHERE left(c_fullname, length($1)) = $1
        $query$, v_schema, v_relation);
        EXECUTE v_sql USING rec.path;
    END LOOP;
    RAISE NOTICE 'Ontology prepared in % ms',
        round(extract(epoch FROM clock_timestamp() - startime) * 1000);
    startime := clock_timestamp();

    -- 5. Add ACT_VISIT and ACT_DEMO supplements with basecode overrides.
    IF visit_table IS NOT NULL AND demo_table IS NOT NULL THEN
        v_parts := string_to_array(btrim(visit_table), '.');
        IF array_length(v_parts, 1) = 1 THEN
            v_visit_relation := format('%I.%I', v_schema, lower(v_parts[1]));
        ELSIF array_length(v_parts, 1) = 2 THEN
            v_visit_relation := format('%I.%I', lower(v_parts[1]), lower(v_parts[2]));
        ELSE
            RAISE EXCEPTION 'Unsupported ACT_VISIT table name: %', visit_table;
        END IF;
        v_parts := string_to_array(btrim(demo_table), '.');
        IF array_length(v_parts, 1) = 1 THEN
            v_demo_relation := format('%I.%I', v_schema, lower(v_parts[1]));
        ELSIF array_length(v_parts, 1) = 2 THEN
            v_demo_relation := format('%I.%I', lower(v_parts[1]), lower(v_parts[2]));
        ELSE
            RAISE EXCEPTION 'Unsupported ACT_DEMO table name: %', demo_table;
        END IF;

        v_sql := format($query$
            INSERT INTO %I.tnum_ontology (
                c_hlevel, c_fullname, c_synonym_cd, c_visualattributes,
                c_basecode, c_facttablecolumn, c_tablename, c_columnname,
                c_columndatatype, c_operator, c_dimcode, m_applied_path
            )
            WITH cte_basecode_override(c_fullname, c_basecode) AS (
                VALUES
                  ('\ACT\Visit Details\Length of stay\ > 10 days', 'visit_dimension|length_of_stay:>10'),
                  ('\ACT\Visit Details\Length of stay', 'visit_dimension|length_of_stay:>0'),
                  ('\ACT\Visit Details\Length of stay', 'visit_dimension|length_of_stay:>0'),
                  ('\ACT\Visit Details\Age at visit\>= 65 years old', 'VIS|AGE:>=65'),
                  ('\ACT\Visit Details\Age at visit\>= 85 years old', 'VIS|AGE:>=85'),
                  ('\ACT\Visit Details\Age at visit\>= 90 years old', 'VIS|AGE:>=90'),
                  ('\ACT\Demographics\Age\>= 90 years old', 'DEM|AGE:>=90'),
                  ('\ACT\Demographics\Age\>= 85 years old', 'DEM|AGE:>=85'),
                  ('\ACT\Demographics\Age\>= 65 years old', 'DEM|AGE:>=65'),
                  ('\ACT\Demographics\Age\>= 18 years old', 'DEM|AGE:>=18'),
                  ('\ACT\Demographics\Age\< 18 years old', 'DEM|AGE:<18')
            ), m AS (
                SELECT c_hlevel, c_fullname, c_synonym_cd, c_visualattributes,
                       CASE
                           WHEN strpos(c_basecode, ':') = 0 AND c_basecode IS NOT NULL
                           THEN c_tablename || '|' || c_columnname || ':' || c_basecode
                           WHEN left(c_fullname, length(chr(92) || 'ACT' || chr(92) || 'Visit Details' || chr(92) || 'Age at visit' || chr(92))) = chr(92) || 'ACT' || chr(92) || 'Visit Details' || chr(92) || 'Age at visit' || chr(92)
                           THEN replace(c_basecode, 'DEM|', 'VIS|')
                           ELSE c_basecode
                       END AS c_basecode,
                       c_facttablecolumn, c_tablename, c_columnname,
                       c_columndatatype, c_operator, c_dimcode, m_applied_path
                FROM %s
                UNION
                SELECT c_hlevel, c_fullname, c_synonym_cd, c_visualattributes,
                       CASE WHEN strpos(c_basecode, ':') = 0 AND c_basecode IS NOT NULL
                            THEN c_tablename || '|' || c_columnname || ':' || c_basecode
                            ELSE c_basecode END AS c_basecode,
                       c_facttablecolumn, c_tablename, c_columnname,
                       c_columndatatype, c_operator, c_dimcode, m_applied_path
                FROM %s
            )
            SELECT DISTINCT m.c_hlevel, m.c_fullname, m.c_synonym_cd,
                   m.c_visualattributes, coalesce(bo.c_basecode, m.c_basecode),
                   m.c_facttablecolumn, m.c_tablename, m.c_columnname,
                   m.c_columndatatype, m.c_operator, m.c_dimcode, m.m_applied_path
            FROM m LEFT JOIN cte_basecode_override bo ON m.c_fullname = bo.c_fullname
            WHERE m.c_facttablecolumn <> 'concept_cd'
        $query$, v_schema, v_visit_relation, v_demo_relation);
        EXECUTE v_sql;
    END IF;

    -- 6. Create closure table and compute ancestor/descendant links.
    EXECUTE format($ddl$
        CREATE TABLE IF NOT EXISTS %I.concept_closure (
            ancestor bigint,
            descendant bigint,
            c_basecode varchar(50),
            CONSTRAINT pk_concept_closure PRIMARY KEY (ancestor, descendant)
        )
    $ddl$, v_schema);
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_descn ON %I.concept_closure (descendant)', v_schema);

    -- Recursive step strips the final path component using the same
    -- length/reverse/position arithmetic as the Oracle source.
    EXECUTE format($query$
        WITH RECURSIVE concepts(c_fullname, c_hlevel, c_basecode, descendant) AS (
            SELECT c_fullname::text, c_hlevel, c_basecode, path_num
              FROM %I.tnum_ontology
             WHERE c_fullname IS NOT NULL AND c_basecode IS NOT NULL
            UNION ALL
            SELECT left(
                       left(c_fullname, length(c_fullname) - 1),
                       length(left(c_fullname, length(c_fullname) - 1))
                       - strpos(reverse(left(c_fullname, length(c_fullname) - 1)), chr(92)) + 1
                   ),
                   c_hlevel - 1, c_basecode, descendant
              FROM concepts
             WHERE c_hlevel > 0
        )
        INSERT INTO %I.concept_closure (ancestor, descendant, c_basecode)
        SELECT DISTINCT o.path_num, c.descendant, c.c_basecode
          FROM concepts c
          JOIN %I.tnum_ontology o ON c.c_fullname = o.c_fullname
    $query$, v_schema, v_schema, v_schema);

    RAISE NOTICE 'Concept closure prepared in % ms',
        round(extract(epoch FROM clock_timestamp() - startime) * 1000);
END;
$procedure$;
GO

-- Example:
-- CALL public.fasttotalnumprep('public', 'i2b2');
-- CALL public.fasttotalnumprep('public', 'omop');
