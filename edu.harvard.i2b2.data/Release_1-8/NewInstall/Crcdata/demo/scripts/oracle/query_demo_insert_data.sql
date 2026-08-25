delete QT_BREAKDOWN_PATH
;

insert into QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE) values ('PATIENT_GENDER_COUNT_XML','\\i2b2_DEMO\i2b2\Demographics\Gender\',sysdate);
insert into QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE) values ('PATIENT_RACE_COUNT_XML','\\i2b2_DEMO\i2b2\Demographics\Race\',sysdate);
insert into QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE) values ('PATIENT_VITALSTATUS_COUNT_XML','\\i2b2_DEMO\i2b2\Demographics\Vital Status\',sysdate);
insert into QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE) values ('PATIENT_AGE_COUNT_XML','select * from (
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
from patient_dimension
where patient_num in (select patient_num from DX)
) t
) t
where a between 0 and 9
group by a
) t on x.a = t.a
order by x.a
) where rownum <= 100',sysdate);
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_LOS_XML','select length_of_stay as patient_range, count(distinct a.PATIENT_num) as patient_count from visit_dimension a, DX b where a.patient_num = b.patient_num group by a.length_of_stay order by 1', SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_TOP20MEDS_XML','select * from (select b.name_char as patient_range, count(distinct a.patient_num) as patient_count from observation_fact a, concept_dimension b, DX c where a.concept_cd = b.concept_cd and concept_path like ''\i2b2\Medications\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc ) where rownum <= 20',SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_TOP20DIAG_XML','select * from (select b.name_char as patient_range, count(distinct a.patient_num) as patient_count from observation_fact a, concept_dimension b, DX c where a.concept_cd = b.concept_cd and concept_path like ''\i2b2\Diagnoses\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc ) where rownum <= 20',SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_INOUT_XML','select INOUT_CD as patient_range, count(distinct a.patient_num) as patient_count from visit_dimension a, DX b where a.patient_num = b.patient_num group by a.INOUT_CD order by 1',SYSDATE);
