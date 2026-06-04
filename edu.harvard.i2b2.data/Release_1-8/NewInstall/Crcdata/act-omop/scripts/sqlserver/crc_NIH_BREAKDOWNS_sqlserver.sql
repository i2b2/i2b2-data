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
    ISNULL(MAX(RESULT_TYPE_ID), 0) + 1,
    'PATIENT_NIH_ENROLLMENT_XML',
    'NIH Enrollment Table',
    'CATNUM',
    'LA',
    NULL,
    'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator'
FROM QT_QUERY_RESULT_TYPE;
INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID) VALUES (N'PATIENT_NIH_ENROLLMENT_XML', N'select r.name+''-''+s.name+''-''+e.name patient_range, sum(case when p.race_cd is not null then 1 else 0 end) patient_count
from
(
select ''NI'' race_cd, ''No Race Info'' name
union all select ''AS'', ''Asian''
union all select ''B'', ''Black or African American''
union all select ''H'', ''Native Hawaiian or Other Pacific Islander''
union all select ''M'', ''Multiple race''
union all select ''NA'', ''American Indian or Alaska Native''
union all select ''W'', ''White''
) r cross join (
select ''NI'' sex_cd, ''No Sex Info'' name
union all select ''F'', ''Female''
union all select ''M'', ''Male''
) s cross join (
select ''NI'' ethnic_cd, ''No Ethnicity Info'' name
union all select ''Y'', ''Hispanic''
union all select ''N'', ''Not Hispanic''
) e
left outer join (
select
(case when race_cd in (''AS'',''B'',''H'',''M'',''NA'',''W'') then race_cd else ''NI'' end) race_cd,
(case when sex_cd in (''F'',''M'') then sex_cd else ''NI'' end) sex_cd,
(case when ethnic_cd in (''Y'',''N'') then ethnic_cd else ''NI'' end) ethnic_cd
from (
select race_cd, sex_cd, (case when race_cd=''Hispanic'' then ''Y'' else ''N'' end) ethnic_cd
from {{{DATABASE_NAME}}}patient_dimension
where patient_num in (select patient_num from {{{DX}}})
) t
) p
on p.race_cd=r.race_cd and p.sex_cd=s.sex_cd and p.ethnic_cd=e.ethnic_cd
group by r.name, s.name, e.name
order by patient_count', N'2023-10-01 15:38:25.260', null, null);

