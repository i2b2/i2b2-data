INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID) VALUES (N'PATIENT_GENDER_COUNT_XML', N'\\ACT_DEMO\ACT\Demographics\sex\', N'2020-05-15 15:38:25.260', N'2020-05-19 13:14:51.943', null);
INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID) VALUES (N'PATIENT_RACE_COUNT_XML', N'\\ACT_DEMO\ACT\Demographics\Race\', N'2020-05-15 15:38:25.260', N'2020-05-19 13:14:55.790', null);
INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID) VALUES (N'PATIENT_VITALSTATUS_COUNT_XML', N'\\ACT_DEMO\ACT\Demographics\Vital Status\', N'2020-05-15 15:38:25.260', N'2020-05-19 13:14:58.970', null);
INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID) VALUES (N'PATIENT_AGE_COUNT_XML', N'\\ACT_DEMO\ACT\Demographics\Age\', N'2020-05-15 15:38:25.263', N'2020-05-19 13:15:03.103', null);
INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID) VALUES (N'PATIENT_TOTALNUM_XML', N'select c_fullname as patient_range, agg_count as patient_count from  {{{DATABASE_NAME}}}totalnum_report where agg_count is not null and agg_count >= 10 
			and c_fullname like ''\ACT\UMLS_C0031437\%''', N'2020-05-19 13:20:32.657', null, null);
INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID) VALUES (N'PATIENT_LOS_XML', N'select length_of_stay as patient_range, count(distinct a.PATIENT_num) as patient_count from {{{DATABASE_NAME}}}visit_dimension a, {{{DATABASE_NAME}}}#DX b where a.patient_num = b.patient_num group by a.length_of_stay order by 1', N'2023-12-13 11:29:01.827', null, null);
INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID) VALUES (N'PATIENT_HISTORICAL_DATA_XML', N'\\ACT_RESEARCH\ACT\Research\Historical Data\', N'2023-10-01 15:38:25.260', null, null);
INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID) VALUES (N'PATIENT_CHARLSON_XML', N'\\ACT_RESEARCH\ACT\Research\Comorbidities\Charlson\CharlsonComorbidity\', N'2023-10-01 15:38:25.260', null, null);
INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID) VALUES (N'PATIENT_COMMON_LAB_XML', N'\\ACT_COVID_V1\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0242656\LABS_OF_INTEREST\', N'2023-10-01 15:38:25.260', null, null);
INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID) VALUES (N'PATIENT_NIH_ENROLLMENT_XML', N'\\ACT_RESEARCH\ACT\Research\NIH Enrollment\', N'2023-10-01 15:38:25.260', null, null);
INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID) VALUES (N'PATIENT_ELIXHAUSER_XML', N'\\ACT_RESEARCH\ACT\Research\Comorbidities\Elixhauser\', N'2023-10-01 15:38:25.260', null, null);
INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID) VALUES (N'PATIENT_TOP20MEDS_XML', N'select top 20 b.name_char as patient_range, count(distinct a.patient_num) as patient_count from {{{DATABASE_NAME}}}observation_fact a, {{{DATABASE_NAME}}}concept_dimension b, {{{DATABASE_NAME}}}#DX c where a.concept_cd = b.concept_cd and concept_path like ''\ACT\Medications\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc', N'2023-12-13 12:05:11.767', null, null);
INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID) VALUES (N'PATIENT_TOP20DIAG_XML', N'select top 20 b.name_char as patient_range, count(distinct a.patient_num) as patient_count
from {{{DATABASE_NAME}}}observation_fact a, {{{DATABASE_NAME}}}concept_dimension b,
{{{DX}}}c where a.concept_cd = b.concept_cd and concept_path like ''\ACT\Diagnosis\%''
and a.patient_num = c.patient_num   group by name_char order by patient_count desc', N'2023-12-13 12:05:11.770', null, null);
INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID) VALUES (N'PATIENT_INOUT_XML', N'select INOUT_CD as patient_range, count(distinct a.patient_num) as patient_count from {{{DATABASE_NAME}}}visit_dimension a, {{{DATABASE_NAME}}}#DX b where a.patient_num = b.patient_num group by a.INOUT_CD order by 1', N'2023-12-13 12:05:11.770', null, null);
INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID) VALUES (N'', null, null, null, null);
INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID) VALUES (N'PATIENT_TOP20DIAG_CLASS_XML', N'with three_dig_path as (
   SELECT SUBSTRING(concept_path, 1, CHARINDEX(''\'', concept_path, CHARINDEX(''\'', concept_path, CHARINDEX
  (''\'', concept_path, CHARINDEX(''\'', concept_path,  CHARINDEX(''\'', concept_path, 
  CHARINDEX(''\'', concept_path, CHARINDEX(''\'', concept_path, CHARINDEX(''\'', concept_path,CHARINDEX(''\'', concept_path,
  0) +1) +1) +1 )+1) +1) +1) +1 )-1)) dx3_path, concept_path, concept_cd from
{{{DATABASE_NAME}}}concept_dimension where concept_path like ''\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\%''),
 dx3 as (select p.concept_path dx_path, p.concept_cd dx_code, o.concept_cd dx3_code,
 o.name_char as dx3_name from three_dig_path p join {{{DATABASE_NAME}}}concept_dimension o on
 o.concept_path = p.dx3_path where o.concept_path like ''\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\%'')
 select top 20 i.dx3_name as patient_range, count(distinct f.patient_num) as patient_count from dx3 i
 join {{{DATABASE_NAME}}}observation_fact f on f.concept_cd = i.dx_code join {{{DATABASE_NAME}}}#DX c on c.patient_num = f.patient_num
 group by i.dx3_name order by 2 desc', null, null, null);
 INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID) VALUES (N'PATIENT_TOP20MEDS_CLASS_XML', N'with ingredient_path as ( SELECT SUBSTRING(concept_path, 1, CHARINDEX(''\'', concept_path, CHARINDEX(''\'', concept_path, CHARINDEX
  (''\'', concept_path, CHARINDEX(''\'', concept_path,  CHARINDEX(''\'', concept_path, 
  CHARINDEX(''\'', concept_path, CHARINDEX(''\'', concept_path, CHARINDEX(''\'', concept_path,CHARINDEX(''\'', concept_path,
  0) +1) +1) +1 )+1) +1) +1) +1 )-1)) ingred_path, concept_path,
concept_cd from {{{DATABASE_NAME}}}concept_dimension where concept_path like ''\ACT\Medications\MedicationsByAlpha\V2_12112018\RxNormUMLSRxNav\%''),
ingredient as (select p.concept_path drug_path, p.concept_cd drug, o.concept_cd ingred_code,
 o.name_char as ingred_name from ingredient_path p join {{{DATABASE_NAME}}}concept_dimension o
 on o.concept_path = p.ingred_path where o.concept_path like ''\ACT\Medications\MedicationsByAlpha\V2_12112018\RxNormUMLSRxNav\%'')
 select top 20 i.ingred_name as patient_range, count(distinct f.patient_num) as patient_count from
 ingredient i join {{{DATABASE_NAME}}}observation_fact f on f.concept_cd = i.drug
 join #DX c on c.patient_num = f.patient_num
 group by i.ingred_name   order by 2 desc', null, null, null);

