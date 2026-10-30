-- Run after loading fasttotalnumadditionaldimensions on a disposable database.
-- This fixture is transaction-scoped and rolls back its temporary tables and rows.
BEGIN;

CREATE TEMP TABLE table_access (
    c_table_cd text, c_table_name text, c_visualattributes text
);
CREATE TEMP TABLE totalnum (
    c_fullname text, agg_date date, agg_count integer, typeflag_cd text
);
CREATE TEMP TABLE patient_dimension (
    patient_num integer, sex_cd text
);
CREATE TEMP TABLE act_demo (
    c_fullname text, c_facttablecolumn text, c_columnname text,
    c_operator text, c_dimcode text, c_tablename text, m_applied_path text
);
CREATE TEMP TABLE other_demo (LIKE act_demo);

INSERT INTO table_access VALUES
    ('ACT_DEMO', 'act_demo', 'A'),
    ('OTHER_DEMO', 'other_demo', 'A');
INSERT INTO patient_dimension VALUES (1, 'M'), (2, 'M'), (3, 'F');
INSERT INTO act_demo VALUES
    ('\act\sex\', 'patient_num', 'sex_cd', '=', 'M', 'patient_dimension', '@');
INSERT INTO other_demo VALUES
    ('\other\male\', 'patient_num', 'sex_cd', '=', 'M', 'patient_dimension', '@'),
    ('\other\missing\', 'patient_num', 'sex_cd', '=', 'X', 'patient_dimension', '@'),
    ('\other\visit\', 'patient_num', 'sex_cd', '=', 'M', 'visit_dimension', '@');

CALL fasttotalnumadditionaldimensions('pg_temp', '@');

DO $test$
BEGIN
    IF (SELECT count(*) FROM totalnum WHERE typeflag_cd = 'PA') <> 2 THEN
        RAISE EXCEPTION 'Expected two non-ACT patient-dimension PA rows';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM totalnum
                   WHERE c_fullname = '\other\male\' AND agg_count = 2) THEN
        RAISE EXCEPTION 'Expected two male patients';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM totalnum
                   WHERE c_fullname = '\other\missing\' AND agg_count = 0) THEN
        RAISE EXCEPTION 'Expected an explicit zero count';
    END IF;
    IF EXISTS (SELECT 1 FROM totalnum WHERE c_fullname = '\act\sex\'
                                    OR c_fullname = '\other\visit\') THEN
        RAISE EXCEPTION 'ACT or visit metadata leaked into the PA supplement';
    END IF;
END;
$test$;

ROLLBACK;

-- On a full test installation, also compare wrapper runs with the default
-- act mode and demographics_mode => 'all', including run_prep => false.
-- Confirm ACT_DEMO counts match, only the all run adds PA rows, and output
-- updates non-ACT ontology C_TOTALNUM and TABLE_ACCESS as expected.
