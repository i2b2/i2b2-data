--==============================================================
-- Database Script to upgrade CRC from 1.8.2 to 1.8.3
--==============================================================

insert into QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE,UPDATE_DATE,USER_ID,GROUP_ID) values('ADMIN_QUERY_DASHBOARD_CLASS_XML',N'select query_name, patient_range, patient_count
from (
    select top 10
        ''ADMIN_TOPUSERS'' as query_name,
        user_id as patient_range,
        count(user_id) as patient_count
    from {{{DATABASE_NAME}}}QT_QUERY_MASTER
    group by user_id
    order by count(user_id) desc
) a

union all

select query_name, patient_range, patient_count
from (
    select top 10
        ''ADMIN_TOPUSERS_30_DAYS'' as query_name,
        user_id as patient_range,
        count(user_id) as patient_count
    from {{{DATABASE_NAME}}}QT_QUERY_MASTER
    where create_date >= DATEADD(day, -30, CURRENT_TIMESTAMP)
    group by user_id
    order by count(user_id) desc
) a

union all

select query_name, patient_range, patient_count
from (
    select top 10
        ''ADMIN_TOPUSERS_7_DAYS'' as query_name,
        user_id as patient_range,
        count(user_id) as patient_count
    from {{{DATABASE_NAME}}}QT_QUERY_MASTER
    where create_date >= DATEADD(day, -7, CURRENT_TIMESTAMP)
    group by user_id
    order by count(user_id) desc
) a

union all

select query_name, patient_range, patient_count
from (
    select top 10
        ''ADMIN_TOPUSERS_1_DAY'' as query_name,
        user_id as patient_range,
        count(user_id) as patient_count
    from {{{DATABASE_NAME}}}QT_QUERY_MASTER
    where create_date >= DATEADD(day, -1, CURRENT_TIMESTAMP)
    group by user_id
    order by count(user_id) desc
) a

union all

select
    ''ADMIN_COUNT'' as query_name,
    CONVERT(char(7), create_date, 120) as patient_range,
    count(create_date) as patient_count
from {{{DATABASE_NAME}}}QT_QUERY_MASTER
group by CONVERT(char(7), create_date, 120)

union all

select
    ''ADMIN_TOTAL_QUERY'' as query_name,
    ''total_queries'' as patient_range,
    count(query_master_id) as patient_count
from {{{DATABASE_NAME}}}QT_QUERY_MASTER

union all

select
    ''ADMIN_TOTAL_QUERY_30DAYS'' as query_name,
    ''total_queries'' as patient_range,
    count(query_master_id) as patient_count
from {{{DATABASE_NAME}}}QT_QUERY_MASTER
where create_date >= DATEADD(day, -30, CURRENT_TIMESTAMP)

union all

select
    ''ADMIN_TOTAL_QUERY_7DAYS'' as query_name,
    ''total_queries'' as patient_range,
    count(query_master_id) as patient_count
from {{{DATABASE_NAME}}}QT_QUERY_MASTER
where create_date >= DATEADD(day, -7, CURRENT_TIMESTAMP)

union all

select
    ''ADMIN_TOTAL_QUERY_1DAYS'' as query_name,
    ''total_queries'' as patient_range,
    count(query_master_id) as patient_count
from {{{DATABASE_NAME}}}QT_QUERY_MASTER
where create_date >= DATEADD(day, -1, CURRENT_TIMESTAMP)

union all

select
    ''ADMIN_TOTAL_USER_QUERY_30DAYS'' as query_name,
    ''total_user_queries'' as patient_range,
    count(distinct user_id) as patient_count
from {{{DATABASE_NAME}}}QT_QUERY_MASTER
where create_date >= DATEADD(day, -30, CURRENT_TIMESTAMP)

union all

select
    ''ADMIN_TOTAL_USER_QUERY_7DAYS'' as query_name,
    ''total_user_queries'' as patient_range,
    count(distinct user_id) as patient_count
from {{{DATABASE_NAME}}}QT_QUERY_MASTER
where create_date >= DATEADD(day, -7, CURRENT_TIMESTAMP)

union all

select
    ''ADMIN_TOTAL_USER_QUERY_1DAYS'' as query_name,
    ''total_user_queries'' as patient_range,
    count(distinct user_id) as patient_count
from {{{DATABASE_NAME}}}QT_QUERY_MASTER
where create_date >= DATEADD(day, -1, CURRENT_TIMESTAMP)',NULL,NULL,NULL,NULL)
;

insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(9999,'ADMIN_QUERY_DASHBOARD_CLASS_XML','ADMIN','Query Dashboard','CATNUM','LH','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator')
;
