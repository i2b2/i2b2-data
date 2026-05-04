INSERT INTO qt_breakdown_path (name, value, create_date, update_date, user_id) VALUES ('PATIENT_AGE_COUNT_XML', '\\ACT_DEMO\ACT\Demographics\Age\', '2024-02-06 22:01:34.091135', null, null);
INSERT INTO qt_breakdown_path (name, value, create_date, update_date, user_id) VALUES ('PATIENT_VITALSTATUS_COUNT_XML', '\\ACT_DEMO\ACT\Demographics\Vital Status\', '2024-02-06 22:01:34.074910', null, null);
INSERT INTO qt_breakdown_path (name, value, create_date, update_date, user_id) VALUES ('PATIENT_RACE_COUNT_XML', '\\ACT_DEMO\ACT\Demographics\Race\', '2024-02-06 22:01:34.055906', null, null);
INSERT INTO qt_breakdown_path (name, value, create_date, update_date, user_id) VALUES ('PATIENT_GENDER_COUNT_XML', '\\ACT_DEMO\ACT\Demographics\Sex\', '2024-02-06 22:01:34.041046', null, null);
INSERT INTO qt_breakdown_path (name, value, create_date, update_date, user_id) VALUES ('PATIENT_COMMON_LAB_XML', '\\ACT_DX_ICD10_2018\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\', '2023-10-01 15:38:25.260000', null, null);
INSERT INTO qt_breakdown_path (name, value, create_date, update_date, user_id) VALUES ('PATIENT_LOS_XML', 'select length_of_stay as patient_range, count(distinct a.PATIENT_num) as patient_count from {{{DATABASE_NAME}}}visit_dimension a, {{{DX}}} b where a.patient_num = b.patient_num group by a.length_of_stay order by 1', '2024-02-06 22:01:34.101048', null, null);
INSERT INTO qt_breakdown_path (name, value, create_date, update_date, user_id) VALUES ('PATIENT_INOUT_XML', 'select INOUT_CD as patient_range, count(distinct a.patient_num) as patient_count from {{{DATABASE_NAME}}}visit_dimension a, {{{DX}}} b where a.patient_num = b.patient_num group by a.INOUT_CD order by 1', '2024-02-06 22:01:34.144812', null, null);
INSERT INTO qt_breakdown_path (name, value, create_date, update_date, user_id) VALUES ('PATIENT_TOP20MEDS_XML', e'select b.name_char as patient_range, count(distinct a.patient_num) as patient_count
from {{{DATABASE_NAME}}}observation_fact a, {{{DATABASE_NAME}}}concept_dimension b, {{{DX}}}
    c where a.concept_cd = b.concept_cd
     and concept_path like \'\\\\ACT\\\\Medications\\\\%\' and a.patient_num = c.patient_num
  group by name_char order by patient_count desc limit 20', '2024-02-06 22:01:34.110501', null, null);
INSERT INTO qt_breakdown_path (name, value, create_date, update_date, user_id) VALUES ('PATIENT_TOP20DIAG_XML', e'select b.name_char as patient_range, count(distinct a.patient_num) as patient_count
from {{{DATABASE_NAME}}}observation_fact a, {{{DATABASE_NAME}}}concept_dimension b, {{{DX}}}
    c where a.concept_cd = b.concept_cd
     and concept_path like \'\\\\ACT\\\\Diagnosis\\\\%\' and a.patient_num = c.patient_num
  group by name_char order by patient_count desc limit 20', '2024-02-06 22:01:34.110501', null, null);
INSERT INTO qt_breakdown_path (name, value, create_date, update_date, user_id) VALUES ('PATIENT_NIH_ENROLLMENT_XML', '\\ACT_RESEARCH\ACT\Research\NIH Enrollment\', '2024-06-06 17:34:32.000000', null, null);
INSERT INTO qt_breakdown_path (name, value, create_date, update_date, user_id) VALUES ('PATIENT_HISTORICAL_DATA_XML', '\\ACT_RESEARCH\ACT\Research\Historical Data\', null, null, null);
INSERT INTO qt_breakdown_path (name, value, create_date, update_date, user_id) VALUES ('PATIENT_ELIXHAUSER_XML', '\\ACT_RESEARCH\ACT\Research\Comorbidities\Elixhauser\', '2024-06-06 17:34:32.000000', null, null);
INSERT INTO qt_breakdown_path (name, value, create_date, update_date, user_id) VALUES ('PATIENT_CHARLSON_XML', '\\ACT_RESEARCH\ACT\Research\Comorbidities\Charlson\CharlsonComorbidity\', null, null, null);
INSERT INTO qt_breakdown_path (name, value, create_date, update_date, user_id) VALUES ('PATIENT_TOP20MEDS_CLASS_XML', e'with ingredient_path as (  SELECT  split_part(concept_path, split_part(
         concept_path,\'\\\',9),1)  ingred_path, concept_path,
concept_cd from {{{DATABASE_NAME}}}concept_dimension where concept_path like
            \'\\\\ACT\\\\Medications\\\\MedicationsByAlpha\\\\V2_12112018\\\\RxNormUMLSRxNav\\\\%\'),
ingredient as (select p.concept_path drug_path, p.concept_cd drug, o.concept_cd ingred_code,
 o.name_char as ingred_name from ingredient_path p join {{{DATABASE_NAME}}}concept_dimension o
 on o.concept_path = p.ingred_path where o.concept_path like
     \'\\\\ACT\\\\Medications\\\\MedicationsByAlpha\\\\V2_12112018\\\\RxNormUMLSRxNav\\\\%\')
 select i.ingred_name as patient_range, count(distinct f.patient_num) as patient_count from
    ingredient i join {{{DATABASE_NAME}}}observation_fact f on f.concept_cd = i.drug
 join {{{DX}}} c on c.patient_num = f.patient_num
 group by i.ingred_name   order by 2 desc LIMIT 20', null, null, null);
INSERT INTO qt_breakdown_path (name, value, create_date, update_date, user_id) VALUES ('PATIENT_TOP20DIAG_CLASS_XML', e'with three_dig_path as (
  SELECT  split_part(concept_path, split_part(
         concept_path,\'\\\',9),1) dx3_path, concept_path, concept_cd from
{{{DATABASE_NAME}}}concept_dimension where concept_path like \'\\\\ACT\\\\Diagnosis\\\\ICD10\\\\V2_2018AA\\\\A20098492\\\\%\'),
 dx3 as (select p.concept_path dx_path, p.concept_cd dx_code, o.concept_cd dx3_code,
 o.name_char as dx3_name from three_dig_path p join {{{DATABASE_NAME}}}concept_dimension o on
 o.concept_path = p.dx3_path where o.concept_path like \'\\\\ACT\\\\Diagnosis\\\\ICD10\\\\V2_2018AA\\\\A20098492\\\\%\')
  select  i.dx3_name as patient_range, count(distinct f.patient_num) as patient_count from dx3 i
 join {{{DATABASE_NAME}}}observation_fact f on f.concept_cd = i.dx_code join {{{DX}}} c on c.patient_num = f.patient_num
     group by i.dx3_name order by 2 desc LIMIT 20', null, null, null);
