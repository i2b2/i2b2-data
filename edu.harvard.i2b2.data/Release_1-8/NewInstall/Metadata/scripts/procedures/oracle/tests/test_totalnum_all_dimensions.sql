-- Manual Oracle validation. Run only on a disposable metadata/data installation.
-- Install the procedures first. Confirm TABLE_ACCESS maps ACT_DEMO to its
-- physical ontology table and that another active ontology contains
-- patient_dimension rows with M_APPLIED_PATH = '@'.
-- Replace I2B2DEMODATA and OTHER_ONTOLOGY with your actual names.

-- 1. Baseline: optimized ACT path only.
BEGIN
  RunTotalnum('observation_fact', 'I2B2DEMODATA');
END;
/

-- 2. All demographics, reusing the prepared structures from step 1.
BEGIN
  RunTotalnum('observation_fact', 'I2B2DEMODATA', run_prep => 0,
              demographics_mode => 'all');
END;
/

-- 3. Verify PA rows exist only for non-ACT patient_dimension paths, including
-- zero counts. Compare sample C_TOTALNUM values with direct counts against
-- I2B2DEMODATA.PATIENT_DIMENSION and verify ACT_DEMO values did not change.
SELECT c_fullname, agg_count, agg_date
FROM totalnum
WHERE typeflag_cd = 'PA'
ORDER BY agg_date DESC, c_fullname;

-- 4. Check the affected ontology and TABLE_ACCESS, replacing the table name.
-- SELECT c_fullname, c_totalnum FROM OTHER_ONTOLOGY
--  WHERE LOWER(c_tablename) = 'patient_dimension';
-- SELECT c_table_cd, c_totalnum FROM table_access
--  WHERE c_table_name = 'OTHER_ONTOLOGY';

-- 5. Run the default mode again and confirm it selects only PF rows.
-- The older PA history remains in TOTALNUM but should not drive fast output.
BEGIN
  RunTotalnum('observation_fact', 'I2B2DEMODATA', run_prep => 0);
END;
/
