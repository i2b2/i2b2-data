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
  SELECT fasttotalnumprep('my_schema');

  -- Run the function using ACT-OMOP views:
  SELECT fasttotalnumprep('public', 'omop');
  
Acknowledgements:
  This PostgreSQL conversion by Jeff Klann, with assistance from ChatGPT.
--------------------------------------------------------------------------------
*/

DROP FUNCTION IF EXISTS fasttotalnumprep(text);

CREATE OR REPLACE FUNCTION fasttotalnumprep(schemaname text DEFAULT 'public', source_mode text DEFAULT 'i2b2')
RETURNS void
LANGUAGE plpgsql
AS $sql$
DECLARE
    sqlstr text;
    v_sql text;
    startime timestamp;
    rec record;
    visit_table text;
    demo_table text;
    source_mode_norm text;
BEGIN
    source_mode_norm := lower(coalesce(nullif(source_mode, ''), 'i2b2'));

    IF source_mode_norm NOT IN ('i2b2','omop') THEN
      RAISE EXCEPTION 'Invalid source_mode. Use i2b2 or omop.';
    END IF;

    SELECT max(c_table_name)
    INTO visit_table
    FROM table_access
    WHERE lower(c_table_cd) = 'act_visit';

    SELECT max(c_table_name)
    INTO demo_table
    FROM table_access
    WHERE lower(c_table_cd) = 'act_demo';

    IF visit_table IS NULL THEN
      RAISE NOTICE 'Skipping ACT_VISIT ontology supplement: TABLE_ACCESS has no row for C_TABLE_CD = ACT_VISIT.';
    END IF;

    IF demo_table IS NULL THEN
      RAISE NOTICE 'Skipping ACT_DEMO ontology supplement: TABLE_ACCESS has no row for C_TABLE_CD = ACT_DEMO.';
    END IF;

    --------------------------------------------------------------------------
    -- 1. Create the OBSFACT_PAIRS view
    --------------------------------------------------------------------------
    EXECUTE 'DROP VIEW IF EXISTS obsfact_pairs';
    IF source_mode_norm = 'omop' THEN
      EXECUTE '
        CREATE OR REPLACE VIEW obsfact_pairs AS
        SELECT DISTINCT patient_num, concept_cd FROM condition_ns_view UNION ALL
        SELECT DISTINCT patient_num, concept_cd FROM condition_view UNION ALL
        SELECT DISTINCT patient_num, concept_cd FROM drug_ns_view UNION ALL
        SELECT DISTINCT patient_num, concept_cd FROM device_view UNION ALL
        SELECT DISTINCT patient_num, concept_cd FROM device_ns_view UNION ALL
        SELECT DISTINCT patient_num, concept_cd FROM drug_view UNION ALL
        SELECT DISTINCT patient_num, concept_cd FROM measurement_ns_view UNION ALL
        SELECT DISTINCT patient_num, concept_cd FROM measurement_view UNION ALL
        SELECT DISTINCT patient_num, concept_cd FROM observation_ns_view UNION ALL
        SELECT DISTINCT patient_num, concept_cd FROM observation_view UNION ALL
        SELECT DISTINCT patient_num, concept_cd FROM procedure_ns_view UNION ALL
        SELECT DISTINCT patient_num, concept_cd FROM procedure_view UNION ALL
        SELECT DISTINCT patient_num, concept_cd FROM visit_ns_view
      ';
    ELSE
      EXECUTE '
        CREATE OR REPLACE VIEW obsfact_pairs AS
        SELECT DISTINCT patient_num, concept_cd FROM observation_fact
      ';
    END IF;

    startime := now();
    -- If you have an endtime function, you can call it here:
    PERFORM endtime(startime, 'observation_fact', 'pairs');
    startime := now();

    --------------------------------------------------------------------------
    -- 2. Create the unified ontology table TNUM_ONTOLOGY
    --------------------------------------------------------------------------
    EXECUTE 'DROP TABLE IF EXISTS tnum_ontology';
    EXECUTE '
      CREATE TABLE tnum_ontology (
         path_num              SERIAL PRIMARY KEY,
         c_hlevel              integer NOT NULL,
         c_fullname            varchar(700) NOT NULL,
         c_synonym_cd          char(1) NOT NULL,
         c_visualattributes    char(3) NOT NULL,
         c_basecode            varchar(50),
         c_facttablecolumn     varchar(50) NOT NULL,
         c_tablename           varchar(50) NOT NULL,
         c_columnname          varchar(50) NOT NULL,
         c_columndatatype      varchar(50) NOT NULL,
         c_operator            varchar(10) NOT NULL,
         c_dimcode             varchar(700) NOT NULL,
         m_applied_path        varchar(900) NOT NULL
      )
    ';

    --------------------------------------------------------------------------
    -- 3. Load TNUM_ONTOLOGY from metadata (from TABLE_ACCESS)
    --------------------------------------------------------------------------
    FOR rec IN
      SELECT c_table_name, c_fullname || '%' AS path
      FROM table_access
      WHERE lower(c_table_cd) NOT IN ('act_demo','act_visit')
        AND c_visualattributes LIKE '%A%'
    LOOP
      v_sql := 'INSERT INTO tnum_ontology (c_hlevel, c_fullname, c_synonym_cd, c_visualattributes, ' ||
               'c_basecode, c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, ' ||
               'c_operator, c_dimcode, m_applied_path) ' ||
               'SELECT DISTINCT c_hlevel, c_fullname, c_synonym_cd, c_visualattributes, ' ||
               'c_basecode, c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, ' ||
               'c_operator, c_dimcode, m_applied_path ' ||
               'FROM ' || rec.c_table_name ||
               ' WHERE c_fullname LIKE ''' || replace(rec.path, '\', '\\') || '''';
      RAISE NOTICE '%', v_sql;
      EXECUTE v_sql;
    END LOOP;

    PERFORM endtime(startime, 'ontology', 'ontology');
    startime := now();

    --------------------------------------------------------------------------
    -- 4. Load additional ontology overrides into TNUM_ONTOLOGY
    --------------------------------------------------------------------------
 IF visit_table IS NOT NULL AND demo_table IS NOT NULL THEN
 v_sql := 'WITH cte_basecode_override AS ( ' ||
           '  SELECT ''\ACT\Visit Details\Length of stay\ > 10 days'' AS c_fullname, ''visit_dimension|length_of_stay:>10'' AS c_basecode UNION ALL ' ||
           '  SELECT ''\ACT\Visit Details\Length of stay'' AS c_fullname, ''visit_dimension|length_of_stay:>0'' UNION ALL ' ||
           '  SELECT ''\ACT\Visit Details\Length of stay'' AS c_fullname, ''visit_dimension|length_of_stay:>0'' UNION ALL ' ||
           '  SELECT ''\ACT\Visit Details\Age at visit\>= 65 years old'' AS c_fullname, ''VIS|AGE:>=65'' UNION ALL ' ||
           '  SELECT ''\ACT\Visit Details\Age at visit\>= 85 years old'' AS c_fullname, ''VIS|AGE:>=85'' UNION ALL ' ||
           '  SELECT ''\ACT\Visit Details\Age at visit\>= 90 years old'' AS c_fullname, ''VIS|AGE:>=90'' UNION ALL ' ||
           '  SELECT ''\ACT\Demographics\Age\>= 90 years old'' AS c_fullname, ''DEM|AGE:>=90'' UNION ALL ' ||
           '  SELECT ''\ACT\Demographics\Age\>= 85 years old'' AS c_fullname, ''DEM|AGE:>=85'' UNION ALL ' ||
           '  SELECT ''\ACT\Demographics\Age\>= 65 years old'' AS c_fullname, ''DEM|AGE:>=65'' UNION ALL ' ||
           '  SELECT ''\ACT\Demographics\Age\>= 18 years old'' AS c_fullname, ''DEM|AGE:>=18'' UNION ALL ' ||
           '  SELECT ''\ACT\Demographics\Age\< 18 years old'' AS c_fullname, ''DEM|AGE:<18'' ' ||
           ') ' ||
           'INSERT INTO tnum_ontology (c_hlevel, c_fullname, c_synonym_cd, c_visualattributes, ' ||
           '   c_basecode, c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, ' ||
           '   c_operator, c_dimcode, m_applied_path) ' ||
           'SELECT DISTINCT c_hlevel, m.c_fullname, c_synonym_cd, c_visualattributes, ' ||
           '       COALESCE(bo.c_basecode, m.c_basecode) AS c_basecode, ' ||
           '       c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, ' ||
           '       c_operator, c_dimcode, m_applied_path ' ||
           'FROM ( ' ||
           '  SELECT c_hlevel, c_fullname, c_synonym_cd, c_visualattributes, ' ||
           '         CASE WHEN position('':'' in c_basecode) = 0 AND c_basecode IS NOT NULL THEN ' ||
           '              c_tablename || ''|'' || c_columnname || '':'' || c_basecode ' ||
           '              WHEN c_fullname LIKE ''\ACT\Visit Details\Age at visit%'' THEN ' ||
           '              replace(c_basecode, ''DEM|'', ''VIS|'') ' ||
           '              ELSE c_basecode ' ||
           '         END AS c_basecode, ' ||
           '         c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, ' ||
           '         c_operator, c_dimcode, m_applied_path ' ||
           '  FROM ' || schemaname || '.' || visit_table || ' ' ||
           '  UNION ' ||
           '  SELECT c_hlevel, c_fullname, c_synonym_cd, c_visualattributes, ' ||
           '         CASE WHEN position('':'' in c_basecode) = 0 AND c_basecode IS NOT NULL THEN ' ||
           '              c_tablename || ''|'' || c_columnname || '':'' || c_basecode ' ||
           '              ELSE c_basecode ' ||
           '         END AS c_basecode, ' ||
           '         c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, ' ||
           '         c_operator, c_dimcode, m_applied_path ' ||
           '  FROM ' || schemaname || '.' || demo_table || ' ' ||
           ') m LEFT JOIN cte_basecode_override bo ' ||
           '  ON m.c_fullname = bo.c_fullname ' ||
           'WHERE c_facttablecolumn <> ''concept_cd''';
    RAISE NOTICE '%', v_sql;
    EXECUTE v_sql;
 END IF;

        --------------------------------------------------------------------------
    -- 5. Build the closure table: CONCEPT_CLOSURE
    --------------------------------------------------------------------------
    EXECUTE 'DROP TABLE IF EXISTS concept_closure';
    EXECUTE '
      CREATE TABLE concept_closure (
         ancestor   integer,
         descendant integer,
         c_basecode varchar(350),
         CONSTRAINT pk_concept_closure PRIMARY KEY (ancestor, descendant)
      )
    ';

    -- Build the closure table using a recursive CTE.
   v_sql := $closure$
WITH RECURSIVE concepts (c_fullname, c_hlevel, c_basecode, descendant) AS (
  SELECT c_fullname, c_hlevel, c_basecode, path_num AS descendant
  FROM tnum_ontology
  WHERE c_fullname IS NOT NULL AND c_basecode IS NOT NULL
  UNION ALL
  SELECT
    (substring(
      rtrim(c_fullname, E'\\')
      from 1 for (
        char_length(rtrim(c_fullname, E'\\'))
        - position(E'\\' in reverse(rtrim(c_fullname, E'\\')))
      )
    ) || E'\\')::varchar(700) AS c_fullname,
    c_hlevel - 1,
    c_basecode,
    descendant
  FROM concepts
  WHERE c_hlevel > 0
)
INSERT INTO concept_closure (ancestor, descendant, c_basecode)
SELECT DISTINCT o.path_num AS ancestor,
                c.descendant,
                COALESCE(c.c_basecode, '') AS c_basecode
FROM concepts c
INNER JOIN tnum_ontology o ON c.c_fullname = o.c_fullname
$closure$;
    RAISE NOTICE '%', v_sql;
    EXECUTE v_sql;


    PERFORM endtime(startime, 'ontology', 'closure');
    startime := now();

EXCEPTION
    WHEN OTHERS THEN
      RAISE;
END;
$sql$;
