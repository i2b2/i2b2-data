INSERT INTO QT_QUERY_RESULT_TYPE
(
    result_type_id,
    name,
    description,
    display_type_id,
    visual_attribute_type_id,
    user_role_cd,
    classname
)
SELECT
    COALESCE(MAX(result_type_id), 0) + 1,
    'PATIENT_NIH_ENROLLMENT_XML',
    'NIH Enrollment Table',
    'CATNUM',
    'LA',
    NULL,
    'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator'
FROM QT_QUERY_RESULT_TYPE;
INSERT INTO qt_breakdown_path (name, value, create_date, update_date, user_id) VALUES ('PATIENT_NIH_ENROLLMENT_XML', $SQL$
select r.name || '-' || s.name || '-' || e.name as patient_range,
       sum(case when p.race_cd is not null then 1 else 0 end) as patient_count
from
(
select 'NI' as race_cd, 'No Race Info' as name
union all select 'AS', 'Asian'
union all select 'B', 'Black or African American'
union all select 'H', 'Native Hawaiian or Other Pacific Islander'
union all select 'M', 'Multiple race'
union all select 'NA', 'American Indian or Alaska Native'
union all select 'W', 'White'
) r
cross join (
select 'NI' as sex_cd, 'No Sex Info' as name
union all select 'F', 'Female'
union all select 'M', 'Male'
) s
cross join (
select 'NI' as ethnic_cd, 'No Ethnicity Info' as name
union all select 'Y', 'Hispanic'
union all select 'N', 'Not Hispanic'
) e
left outer join (
select
case when race_cd in ('AS','B','H','M','NA','W') then race_cd else 'NI' end as race_cd,
case when sex_cd in ('F','M') then sex_cd else 'NI' end as sex_cd,
case when ethnic_cd in ('Y','N') then ethnic_cd else 'NI' end as ethnic_cd
from (
select race_cd, sex_cd, case when race_cd='Hispanic' then 'Y' else 'N' end as ethnic_cd
from {{{DATABASE_NAME}}}patient_dimension
where patient_num in (select patient_num from {{{DX}}})
) t
) p
on p.race_cd = r.race_cd and p.sex_cd = s.sex_cd and p.ethnic_cd = e.ethnic_cd
group by r.name, s.name, e.name
order by patient_count
$SQL$, '2024-06-06 17:34:32.000000', null, null);
