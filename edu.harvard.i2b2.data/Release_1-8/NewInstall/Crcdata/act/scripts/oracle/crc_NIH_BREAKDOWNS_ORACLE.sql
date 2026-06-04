INSERT INTO QT_QUERY_RESULT_TYPE
(
    RESULT_TYPE_ID,
    NAME,
    DESCRIPTION,
    DISPLAY_TYPE_ID,
    VISUAL_ATTRIBUTE_TYPE_ID,
    USER_ROLE_CD,
    CLASSNAME
)
SELECT
    NVL(MAX(RESULT_TYPE_ID), 0) + 1,
    'PATIENT_NIH_ENROLLMENT_XML',
    'NIH Enrollment Table',
    'CATNUM',
    'LA',
    NULL,
    'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator'
FROM QT_QUERY_RESULT_TYPE;
INSERT INTO QT_BREAKDOWN_PATH (NAME, CREATE_DATE, UPDATE_DATE, USER_ID, VALUE) VALUES ('PATIENT_NIH_ENROLLMENT_XML', DATE '2023-10-02', null, null, 'select r.name || ''-'' || s.name || ''-'' || e.name as patient_range, sum(case when p.race_cd is not null then 1 else 0 end) as patient_count
from
(
select ''NI'' as race_cd, ''No Race Info'' as name from dual
union all select ''AS'', ''Asian'' from dual
union all select ''B'', ''Black or African American'' from dual
union all select ''H'', ''Native Hawaiian or Other Pacific Islander'' from dual
union all select ''M'', ''Multiple race'' from dual
union all select ''NA'', ''American Indian or Alaska Native'' from dual
union all select ''W'', ''White'' from dual
) r
cross join (
select ''NI'' as sex_cd, ''No Sex Info'' as name from dual
union all select ''F'', ''Female'' from dual
union all select ''M'', ''Male'' from dual
) s
cross join (
select ''NI'' as ethnic_cd, ''No Ethnicity Info'' as name from dual
union all select ''Y'', ''Hispanic'' from dual
union all select ''N'', ''Not Hispanic'' from dual
) e
left outer join (
select
case when race_cd in (''AS'',''B'',''H'',''M'',''NA'',''W'') then race_cd else ''NI'' end as race_cd,
case when sex_cd in (''F'',''M'') then sex_cd else ''NI'' end as sex_cd,
case when ethnic_cd in (''Y'',''N'') then ethnic_cd else ''NI'' end as ethnic_cd
from (
select race_cd, sex_cd, case when race_cd=''Hispanic'' then ''Y'' else ''N'' end as ethnic_cd
from {{{DATABASE_NAME}}}patient_dimension
where patient_num in (select patient_num from {{{DX}}})
) t
) p
on p.race_cd = r.race_cd and p.sex_cd = s.sex_cd and p.ethnic_cd = e.ethnic_cd
group by r.name, s.name, e.name
order by patient_count');
