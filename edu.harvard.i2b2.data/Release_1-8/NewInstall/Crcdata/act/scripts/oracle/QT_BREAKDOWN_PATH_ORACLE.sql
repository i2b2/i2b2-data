INSERT INTO QT_BREAKDOWN_PATH (NAME, CREATE_DATE, UPDATE_DATE, USER_ID, VALUE) VALUES ('PATIENT_HISTORICAL_DATA_XML', DATE '2023-10-01', null, null, '\\ACT_RESEARCH\ACT\Research\Historical Data\');
INSERT INTO QT_BREAKDOWN_PATH (NAME, CREATE_DATE, UPDATE_DATE, USER_ID, VALUE) VALUES ('PATIENT_CHARLSON_XML', DATE '2023-10-02', null, null, '\\ACT_RESEARCH\ACT\Research\Comorbidities\Charlson\CharlsonComorbidity\');
INSERT INTO QT_BREAKDOWN_PATH (NAME, CREATE_DATE, UPDATE_DATE, USER_ID, VALUE) VALUES ('PATIENT_COMMON_LAB_XML', DATE '2023-10-02', null, null, '\\ACT_COVID_V1\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0242656\LABS_OF_INTEREST\');
INSERT INTO QT_BREAKDOWN_PATH (NAME, CREATE_DATE, UPDATE_DATE, USER_ID, VALUE) VALUES ('PATIENT_TOP20DIAG_CLASS_XML', DATE '2023-10-02', null, null, 'select * from ( with three_dig_path as (select substr(concept_path, 1, instr(concept_path,''\'',1,9)) dx3_path, concept_path, concept_cd from {{{DATABASE_NAME}}}concept_dimension where concept_path like ''\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\%''),dx3 as (select p.concept_path dx_path, p.concept_cd dx_code, o.concept_cd dx3_code, o.name_char as dx3_name from three_dig_path p join {{{DATABASE_NAME}}}concept_dimension o on o.concept_path = p.dx3_path where o.concept_path like ''\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\%'') select i.dx3_name as patient_range, count(distinct f.patient_num) as patient_count from dx3 i join {{{DATABASE_NAME}}}observation_fact f on f.concept_cd = i.dx_code join {{{DX}}} c on c.patient_num = f.patient_num group by i.dx3_name order by 2 desc) where rownum <= 20');
INSERT INTO QT_BREAKDOWN_PATH (NAME, CREATE_DATE, UPDATE_DATE, USER_ID, VALUE) VALUES ('PATIENT_NIH_ENROLLMENT_XML', DATE '2023-10-02', null, null, '\\ACT_RESEARCH\ACT\Research\NIH Enrollment\');
INSERT INTO QT_BREAKDOWN_PATH (NAME, CREATE_DATE, UPDATE_DATE, USER_ID, VALUE) VALUES ('PATIENT_TOP20MEDS_CLASS_XML', DATE '2023-10-02', null, null, ' select * from ( with ingredient_path as (select substr(concept_path, 1, instr(concept_path,''\'',1,8))
     ingred_path, concept_path, concept_cd from {{{DATABASE_NAME}}}concept_dimension where concept_path like
      ''\ACT\Medications\MedicationsByAlpha\V2_12112018\RxNormUMLSRxNav\%''),
        ingredient as (select p.concept_path drug_path, p.concept_cd drug, o.concept_cd ingred_code,
        o.name_char as ingred_name from
        ingredient_path p join {{{DATABASE_NAME}}}concept_dimension o on o.concept_path = p.ingred_path
            where o.concept_path like
            ''\ACT\Medications\MedicationsByAlpha\V2_12112018\RxNormUMLSRxNav\%'')
      select  i.ingred_name as patient_range, count(distinct f.patient_num) as patient_count
          from ingredient i join {{{DATABASE_NAME}}}observation_fact f on f.concept_cd = i.drug join {{{DX}}}
     c on   c.patient_num = f.patient_num group by i.ingred_name order by 2 desc) where rownum <= 20');
INSERT INTO QT_BREAKDOWN_PATH (NAME, CREATE_DATE, UPDATE_DATE, USER_ID, VALUE) VALUES ('PATIENT_ELIXHAUSER_XML', DATE '2023-10-02', null, null, '\\ACT_RESEARCH\ACT\Research\Comorbidities\Elixhauser\');
INSERT INTO QT_BREAKDOWN_PATH (NAME, CREATE_DATE, UPDATE_DATE, USER_ID, VALUE) VALUES ('PATIENT_TOP20MEDS_XML', TIMESTAMP '2024-05-15 01:18:24', null, null, 'select * from (select b.name_char as patient_range, count(distinct a.patient_num) as patient_count from {{{DATABASE_NAME}}}observation_fact a, {{{DATABASE_NAME}}}concept_dimension b, {{{DX}}} c where a.concept_cd = b.concept_cd and b.concept_path like ''\ACT\Medications\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc ) where rownum <= 20');
INSERT INTO QT_BREAKDOWN_PATH (NAME, CREATE_DATE, UPDATE_DATE, USER_ID, VALUE) VALUES ('PATIENT_GENDER_COUNT_XML', TIMESTAMP '2024-05-15 01:18:24', null, null, '\\ACT_DEMO\ACT\Demographics\Sex\');
INSERT INTO QT_BREAKDOWN_PATH (NAME, CREATE_DATE, UPDATE_DATE, USER_ID, VALUE) VALUES ('PATIENT_RACE_COUNT_XML', TIMESTAMP '2024-05-15 01:18:24', null, null, '\\ACT_DEMO\ACT\Demographics\Race\');
INSERT INTO QT_BREAKDOWN_PATH (NAME, CREATE_DATE, UPDATE_DATE, USER_ID, VALUE) VALUES ('PATIENT_VITALSTATUS_COUNT_XML', TIMESTAMP '2024-05-15 01:18:24', null, null, '\\ACT_DEMO\ACT\Demographics\Vital Status\');
-- INSERT INTO QT_BREAKDOWN_PATH (NAME, CREATE_DATE, UPDATE_DATE, USER_ID, VALUE) VALUES ('PATIENT_AGE_COUNT_XML', TIMESTAMP '2024-05-15 01:18:24', null, null, '\\ACT_DEMO\ACT\Demographics\Age\');
-- PATIENT_AGE_COUNT_XML
-- This overrides the default age breakdown.
INSERT INTO QT_BREAKDOWN_PATH (NAME, CREATE_DATE, UPDATE_DATE, USER_ID, VALUE) VALUES ('PATIENT_AGE_COUNT_XML', TIMESTAMP '2024-05-15 01:18:24', null, null, 'select * from (
select
case
when x.a = 9 then ''90+ years old''
else to_char(x.a*10) || ''-'' || to_char(x.a*10+9) || '' years old''
end as patient_range,
t.patient_count
from (
select 0 as a from dual
union all select 1 from dual
union all select 2 from dual
union all select 3 from dual
union all select 4 from dual
union all select 5 from dual
union all select 6 from dual
union all select 7 from dual
union all select 8 from dual
union all select 9 from dual
) x
left outer join (
select a, count(*) as patient_count
from (
select case when a > 9 then 9 else a end as a
from (
select floor(age_in_years_num/10) as a
from {{{DATABASE_NAME}}}patient_dimension
where patient_num in (select patient_num from {{{DX}}})
) t
) t
where a between 0 and 9
group by a
) t on x.a = t.a
order by x.a
) where rownum <= 100');
INSERT INTO QT_BREAKDOWN_PATH (NAME, CREATE_DATE, UPDATE_DATE, USER_ID, VALUE) VALUES ('PATIENT_LOS_XML', TIMESTAMP '2024-05-15 01:18:24', null, null, 'select length_of_stay as patient_range, count(distinct a.PATIENT_num)
    as patient_count from visit_dimension a,{{{DX}}} b where a.patient_num = b.patient_num group by a.length_of_stay order by 1');
INSERT INTO QT_BREAKDOWN_PATH (NAME, CREATE_DATE, UPDATE_DATE, USER_ID, VALUE) VALUES ('PATIENT_TOP20DIAG_XML', TIMESTAMP '2024-05-15 01:18:24', null, null, 'select * from (select b.name_char as patient_range, count(distinct a.patient_num) as patient_count from {{{DATABASE_NAME}}}observation_fact a, {{{DATABASE_NAME}}}concept_dimension b, {{{DX}}} c where a.concept_cd = b.concept_cd and b.concept_path like ''\ACT\Diagnosis\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc ) where rownum <= 20');
INSERT INTO QT_BREAKDOWN_PATH (NAME, CREATE_DATE, UPDATE_DATE, USER_ID, VALUE) VALUES ('PATIENT_INOUT_XML', TIMESTAMP '2024-05-15 01:18:24', null, null, 'select INOUT_CD as patient_range, count(distinct a.patient_num) as patient_count from visit_dimension a, DX b where a.patient_num = b.patient_num group by a.INOUT_CD order by 1');
