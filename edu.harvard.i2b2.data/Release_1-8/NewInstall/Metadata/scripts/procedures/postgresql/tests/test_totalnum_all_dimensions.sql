-- In a disposable database, install the totalnum routines in an empty
-- metadata schema and put it first on search_path before running this test.
-- The fixture creates test tables and a separate data schema, then rolls back.
BEGIN;

CREATE SCHEMA tnum_test_data;

CREATE TABLE table_access (
    c_table_cd text, c_table_name text, c_visualattributes text,
    c_fullname text, c_totalnum integer
);
CREATE TABLE totalnum (
    c_fullname text, agg_date date, agg_count integer, typeflag_cd text
);
CREATE TABLE totalnum_report (c_fullname text, agg_date text, agg_count integer);
CREATE TABLE tnum_test_data.patient_dimension (
    patient_num integer, sex_cd text, race_cd text, birth_date date
);
CREATE TABLE tnum_test_data.visit_dimension (
    patient_num integer, start_date date, end_date date, inout_cd text
);
CREATE TABLE tnum_test_data.observation_fact (
    patient_num integer, concept_cd varchar(50), nval_num numeric,
    provider_id text, modifier_cd text
);
CREATE TABLE act_demo (
    c_fullname text, c_facttablecolumn text, c_columnname text,
    c_operator text, c_dimcode text, c_tablename text, m_applied_path text,
    c_hlevel integer, c_basecode text, c_synonym_cd text,
    c_visualattributes text, c_columndatatype text, c_totalnum integer
);
CREATE TABLE act_visit (LIKE act_demo);
CREATE TABLE other_demo (LIKE act_demo);

INSERT INTO table_access(c_table_cd, c_table_name, c_visualattributes, c_fullname) VALUES
    ('act_demo', 'ACT_DEMO', 'A', '\act\sex\'),
    ('ACT_VISIT', 'ACT_VISIT', 'A', '\visits\'),
    ('OTHER_DEMO', 'OTHER_DEMO', 'A', '\other\');
INSERT INTO tnum_test_data.patient_dimension(patient_num, sex_cd) VALUES (1, 'M'), (2, 'M'), (3, 'F');
INSERT INTO tnum_test_data.visit_dimension(patient_num) VALUES (1), (2), (3);
INSERT INTO tnum_test_data.observation_fact VALUES (1, 'C1', 1, NULL, NULL), (2, 'C1', 0, NULL, NULL);
INSERT INTO act_demo VALUES
    ('\act\sex\', 'patient_num', 'sex_cd', '=', 'M', 'patient_dimension', '@', 0, 'DEM|SEX:M', 'N', 'LA', 'T');
INSERT INTO other_demo VALUES
    ('\other\male\', 'patient_num', 'sex_cd', '=', 'M', 'patient_dimension', '@', 1, NULL, 'N', 'LA', 'T'),
    ('\other\missing\', 'patient_num', 'sex_cd', '=', 'X', 'patient_dimension', '@', 1, NULL, 'N', 'LA', 'T'),
    ('\other\visit\', 'patient_num', 'inout_cd', '=', 'I', 'visit_dimension', '@', 1, NULL, 'N', 'LA', 'T'),
    ('\other\value\', 'concept_cd', 'nval_num = 1 AND concept_cd', 'LIKE', 'C1', 'concept_dimension', '@', 1, 'C1', 'N', 'LA', 'T'),
    ('\other\unconstrained\', 'concept_cd', 'concept_path', 'LIKE', 'C1', 'concept_dimension', '@', 1, 'C1', 'N', 'LA', 'T');

CALL runtotalnum('observation_fact', 'tnum_test_data');
DO $test$
BEGIN
    IF (SELECT c_totalnum FROM act_demo) IS DISTINCT FROM 2
       OR (SELECT c_totalnum FROM table_access WHERE c_table_cd = 'act_demo') IS DISTINCT FROM 2
       OR EXISTS (SELECT 1 FROM totalnum WHERE typeflag_cd = 'PA')
       OR NOT EXISTS (SELECT 1 FROM totalnum_report WHERE c_fullname = '\act\sex\') THEN
        RAISE EXCEPTION 'Default fast count or report failed';
    END IF;
END;
$test$;

CALL runtotalnum('observation_fact', 'tnum_test_data', run_prep => 0,
                   demographics_mode => 'other');

DO $test$
BEGIN
    IF (SELECT count(*) FROM totalnum WHERE typeflag_cd = 'PA') <> 3 THEN
        RAISE EXCEPTION 'Expected two patient-dimension PA rows and one constrained PA row';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM totalnum
                   WHERE c_fullname = '\other\male\' AND agg_count = 2) THEN
        RAISE EXCEPTION 'Expected two male patients';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM totalnum
                   WHERE c_fullname = '\other\missing\' AND agg_count = 0) THEN
        RAISE EXCEPTION 'Expected an explicit zero count';
    END IF;
    IF EXISTS (SELECT 1 FROM totalnum WHERE typeflag_cd = 'PA'
               AND c_fullname IN ('\act\sex\', '\other\visit\')) THEN
        RAISE EXCEPTION 'ACT or visit metadata leaked into the PA supplement';
    END IF;
    IF (SELECT c_totalnum FROM other_demo WHERE c_fullname = '\other\value\') IS DISTINCT FROM 1
       OR NOT EXISTS (SELECT 1 FROM totalnum_report WHERE c_fullname = '\other\male\') THEN
        RAISE EXCEPTION 'Supplemental output or report failed';
    END IF;
END;
$test$;

TRUNCATE TABLE totalnum_report;
CALL runtotalnum('observation_fact', 'tnum_test_data', totalnum_mode => 'classic');
DO $test$
BEGIN
    IF (SELECT c_totalnum FROM other_demo WHERE c_fullname = '\other\unconstrained\') IS DISTINCT FROM 2
       OR NOT EXISTS (SELECT 1 FROM totalnum_report WHERE c_fullname = '\other\unconstrained\') THEN
        RAISE EXCEPTION 'Classic count or report failed';
    END IF;
END;
$test$;

SELECT runtotalnumclassic('observation_fact', 'tnum_test_data');
DO $test$
BEGIN
    EXECUTE format(
        'CALL %I.runtotalnum(''observation_fact'', ''tnum_test_data'', ''@'', ''N'', ''fast'', ''act'', ''1'')',
        current_schema()
    );
END;
$test$;

DO $test$
BEGIN
    CALL runtotalnum('observation_fact', 'tnum_test_data', demographics_mode => 'all');
    RAISE EXCEPTION 'Expected the old demographics mode to be rejected';
EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Invalid demographics_mode. Use act or other.' THEN
        RAISE;
    END IF;
END;
$test$;

ROLLBACK;
