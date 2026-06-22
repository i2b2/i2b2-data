--==============================================================
-- Database Script to upgrade CRC from 1.8.2 to 1.8.3
--==============================================================
DELETE FROM QT_BREAKDOWN_PATH
WHERE NAME = 'PATIENT_AGE_COUNT_XML';
INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID) VALUES (N'PATIENT_AGE_COUNT_XML', N'select top 100
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
where patient_num in (select patient_num from {{{DX}}})
) t
) t
where a between 0 and 9
group by a
) t on x.a=t.a
order by x.a', N'2020-05-15 15:38:25.263', N'2020-05-19 13:15:03.103', null);
INSERT INTO QT_BREAKDOWN_PATH (NAME, VALUE, CREATE_DATE, UPDATE_DATE, USER_ID, GROUP_ID) VALUES (N'ADMIN_QUERY_DASHBOARD_CLASS_XML', N'select query_name, patient_range, patient_count from ( select top 10 ''ADMIN_TOPUSERS'' as query_name, user_id as patient_range, count( user_id)  as patient_count from {{{DATABASE_NAME}}}QT_QUERY_MASTER  where  delete_flag <>''Y''
 and  group_id = ''{{{PROJECT_ID}}}'' group by user_id  order by patient_count desc ) a
union
select query_name, patient_range, patient_count from ( select top 10 ''ADMIN_TOPUSERS_30_DAYS'' as query_name, user_id as patient_range, count( user_id)  as patient_count from {{{DATABASE_NAME}}}QT_QUERY_MASTER where create_date >= CURRENT_TIMESTAMP -30 and delete_flag <>''Y'' and  group_id = ''{{{PROJECT_ID}}}'' group by user_id order by patient_count desc ) a
union
select query_name, patient_range, patient_count from ( select top 10 ''ADMIN_TOPUSERS_7_DAYS'' as query_name, user_id as patient_range, count( user_id)  as patient_count from {{{DATABASE_NAME}}}QT_QUERY_MASTER where create_date >= CURRENT_TIMESTAMP -7 and delete_flag <>''Y'' and group_id = ''{{{PROJECT_ID}}}'' group by user_id order by patient_count desc ) a
union
select query_name, patient_range, patient_count from ( select top 10 ''ADMIN_TOPUSERS_1_DAY'' as query_name, user_id as patient_range, count( user_id)  as patient_count from {{{DATABASE_NAME}}}QT_QUERY_MASTER where create_date >= CURRENT_TIMESTAMP -1 and delete_flag <>''Y'' and  group_id = ''{{{PROJECT_ID}}}'' group by user_id order by patient_count desc ) a
union
select ''ADMIN_COUNT'' as query_name, FORMAT(create_date, ''yyyy-MM'')  AS patient_range,	COUNT(create_date) AS patient_count	from {{{DATABASE_NAME}}}qt_query_master where delete_flag <>''Y'' and group_id = ''{{{PROJECT_ID}}}''	group by FORMAT(create_date, ''yyyy-MM'')
union
select ''ADMIN_TOTAL_QUERY'' as query_name, ''total_queries'' as patient_range, count(query_master_id)  as patient_count from {{{DATABASE_NAME}}}QT_QUERY_MASTER where delete_flag <>''Y'' and group_id = ''{{{PROJECT_ID}}}''
union
select ''ADMIN_TOTAL_QUERY_30DAYS'' as query_name, ''total_queries'' as patient_range, count(query_master_id)  as patient_count from {{{DATABASE_NAME}}}QT_QUERY_MASTER where create_date >= CURRENT_TIMESTAMP -30 and delete_flag <>''Y''
 and group_id = ''{{{PROJECT_ID}}}''
union
select ''ADMIN_TOTAL_QUERY_7DAYS'' as query_name, ''total_queries'' as patient_range, count(query_master_id)  as patient_count from {{{DATABASE_NAME}}}QT_QUERY_MASTER where create_date >= CURRENT_TIMESTAMP -7 and delete_flag <>''Y'' and group_id = ''{{{PROJECT_ID}}}''
union
select ''ADMIN_TOTAL_QUERY_1DAYS'' as query_name, ''total_queries'' as patient_range, count(query_master_id)  as patient_count from {{{DATABASE_NAME}}}QT_QUERY_MASTER where create_date >= CURRENT_TIMESTAMP -1 and delete_flag <>''Y'' and group_id = ''{{{PROJECT_ID}}}''
union
select ''ADMIN_TOTAL_USER_QUERY_30DAYS'' as query_name, ''total_user_queries'' as patient_range, count(distinct user_id)  as patient_count from {{{DATABASE_NAME}}}QT_QUERY_MASTER where create_date >= CURRENT_TIMESTAMP -30 and delete_flag <>''Y'' and group_id = ''{{{PROJECT_ID}}}''
union
select ''ADMIN_TOTAL_USER_QUERY_7DAYS'' as query_name, ''total_user_queries'' as patient_range, count(distinct user_id)  as patient_count from {{{DATABASE_NAME}}}QT_QUERY_MASTER where create_date >= CURRENT_TIMESTAMP -7 and delete_flag <>''Y'' and group_id = ''{{{PROJECT_ID}}}''
union
select ''ADMIN_TOTAL_USER_QUERY_1DAYS'' as query_name, ''total_user_queries'' as patient_range, count(distinct user_id)  as patient_count from {{{DATABASE_NAME}}}QT_QUERY_MASTER where create_date >= CURRENT_TIMESTAMP -1 and delete_flag <>''Y'' and group_id = ''{{{PROJECT_ID}}}''
', null, null, null, null);
INSERT INTO QT_QUERY_RESULT_TYPE
(
    RESULT_TYPE_ID,
    NAME,
    USER_ROLE_CD,
    DESCRIPTION,
    DISPLAY_TYPE_ID,
    VISUAL_ATTRIBUTE_TYPE_ID,
    CLASSNAME
)
SELECT
    CASE
        WHEN ISNULL(MAX(RESULT_TYPE_ID), 0) + 1 < 9999 THEN 9999
        ELSE ISNULL(MAX(RESULT_TYPE_ID), 0) + 1
    END,
    'ADMIN_QUERY_DASHBOARD_CLASS_XML',
    'ADMIN',
    'Query Dashboard',
    'CATNUM',
    'LH',
    'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator'
FROM QT_QUERY_RESULT_TYPE;
