insert into QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE) values ('PATIENT_GENDER_COUNT_XML','\\i2b2_DEMO\i2b2\Demographics\Gender\',getdate());
insert into QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE) values ('PATIENT_RACE_COUNT_XML','\\i2b2_DEMO\i2b2\Demographics\Race\',getdate());
insert into QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE) values ('PATIENT_VITALSTATUS_COUNT_XML','\\i2b2_DEMO\i2b2\Demographics\Vital Status\',getdate());
-- insert into QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE) values ('PATIENT_AGE_COUNT_XML','\\i2b2_DEMO\i2b2\Demographics\Age\',getdate());
insert into QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE) values ('PATIENT_AGE_COUNT_XML','select top 100
(case
when x.a=9 then ''90+ years old''
else cast(x.a*10 as varchar(10))+''-''+cast(x.a*10+9 as varchar(10))+'' years old''
end) patient_range, t.patient_count
from (
select 0 a
union all select 1
union all select 2
union all select 3
union all select 4
union all select 5
union all select 6
union all select 7
union all select 8
union all select 9
) x left outer join (
select a, count(*) patient_count
from (
select (case when a>9 then 9 else a end) a
from (
select floor(AGE_IN_YEARS_NUM/10) a
from {{{DATABASE_NAME}}}patient_dimension
where patient_num in (select patient_num from {{{DATABASE_NAME}}}#DX)
) t
) t
where a between 0 and 9
group by a
) t on x.a=t.a
order by x.a',getdate());
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_LOS_XML','select length_of_stay as patient_range, count(distinct a.PATIENT_num) as patient_count from {{{DATABASE_NAME}}}visit_dimension a, {{{DATABASE_NAME}}}#DX b where a.patient_num = b.patient_num group by a.length_of_stay order by 1', GETDATE());
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_TOP20MEDS_XML','select top 20 b.name_char as patient_range, count(distinct a.patient_num) as patient_count from {{{DATABASE_NAME}}}observation_fact a, {{{DATABASE_NAME}}}concept_dimension b, {{{DATABASE_NAME}}}#DX c where a.concept_cd = b.concept_cd and concept_path like ''\i2b2\Medications\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc', GETDATE());
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_TOP20DIAG_XML','select top 20 b.name_char as patient_range, count(distinct a.patient_num) as patient_count from {{{DATABASE_NAME}}}observation_fact a, {{{DATABASE_NAME}}}concept_dimension b, {{{DATABASE_NAME}}}#DX c where a.concept_cd = b.concept_cd and concept_path like ''\i2b2\Diagnoses\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc', GETDATE());
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_INOUT_XML','select INOUT_CD as patient_range, count(distinct a.patient_num) as patient_count from {{{DATABASE_NAME}}}visit_dimension a, {{{DATABASE_NAME}}}#DX b where a.patient_num = b.patient_num group by a.INOUT_CD order by 1', GETDATE());
