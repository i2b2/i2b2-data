--==============================================================
-- Database Script to upgrade CRC from 1.8.2 to 1.8.3
--==============================================================

ALTER TABLE QT_QUERY_RESULT_TYPE
MODIFY RESULT_TYPE_ID NUMBER(4,0)
;
ALTER TABLE QT_QUERY_RESULT_INSTANCE
MODIFY RESULT_TYPE_ID NUMBER(4,0)
;
DELETE FROM QT_BREAKDOWN_PATH
WHERE NAME = 'PATIENT_AGE_COUNT_XML'
;
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
) where rownum <= 100')
;
insert into QT_BREAKDOWN_PATH
(NAME,CREATE_DATE,UPDATE_DATE,USER_ID,VALUE,GROUP_ID)
values
(
'ADMIN_QUERY_DASHBOARD_CLASS_XML',
NULL,
NULL,
NULL,

TO_CLOB(q'[
SELECT query_name, patient_range, patient_count
FROM  (
    SELECT
        'ADMIN_TOPUSERS' AS query_name,
        user_id AS patient_range,
        COUNT(user_id) AS patient_count
    FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
   where  delete_flag <>'Y'
 and group_id = '{{{PROJECT_ID}}}'
    GROUP BY user_id
    ORDER BY patient_count DESC
)
WHERE ROWNUM <= 10



UNION

SELECT query_name, patient_range, patient_count
FROM (
    SELECT
        'ADMIN_TOPUSERS_30_DAYS' AS query_name,
        user_id AS patient_range,
        COUNT(user_id) AS patient_count
    FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
    WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL '30' DAY
    and delete_flag <>'Y'
 and group_id = '{{{PROJECT_ID}}}'
    GROUP BY user_id
    ORDER BY patient_count DESC
)
WHERE ROWNUM <= 10

UNION

SELECT query_name, patient_range, patient_count
FROM (
    SELECT
        'ADMIN_TOPUSERS_7_DAYS' AS query_name,
        user_id AS patient_range,
        COUNT(user_id) AS patient_count
    FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
    WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL '7' DAY
    and delete_flag <>'Y'
 and group_id = '{{{PROJECT_ID}}}'
    GROUP BY user_id
    ORDER BY patient_count DESC
)
WHERE ROWNUM <= 10
]')
||

TO_CLOB(q'[

UNION

SELECT query_name, patient_range, patient_count
FROM (
    SELECT
        'ADMIN_TOPUSERS_1_DAY' AS query_name,
        user_id AS patient_range,
        COUNT(user_id) AS patient_count
    FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
    WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL '1' DAY
    and delete_flag <>'Y'
 and group_id = '{{{PROJECT_ID}}}'
    GROUP BY user_id
    ORDER BY patient_count DESC
)
WHERE ROWNUM <= 10

UNION

SELECT
    'ADMIN_COUNT' AS query_name,
    TO_CHAR(create_date, 'YYYY-MM') AS patient_range,
    COUNT(create_date) AS patient_count
FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER where delete_flag <>'Y'
 and group_id = '{{{PROJECT_ID}}}'
GROUP BY TO_CHAR(create_date, 'YYYY-MM')

UNION

SELECT
    'ADMIN_TOTAL_QUERY' AS query_name,
    'total_queries' AS patient_range,
    COUNT(query_master_id) AS patient_count
FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER where delete_flag <>'Y'
 and group_id = '{{{PROJECT_ID}}}'

UNION

SELECT
    'ADMIN_TOTAL_QUERY_30DAYS' AS query_name,
    'total_queries' AS patient_range,
    COUNT(query_master_id) AS patient_count
FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL '30' DAY
and delete_flag <>'Y'
 and group_id = '{{{PROJECT_ID}}}'
]')
||

TO_CLOB(q'[

UNION

SELECT
    'ADMIN_TOTAL_QUERY_7DAYS' AS query_name,
    'total_queries' AS patient_range,
    COUNT(query_master_id) AS patient_count
FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL '7' DAY
and delete_flag <>'Y'
 and group_id = '{{{PROJECT_ID}}}'

UNION

SELECT
    'ADMIN_TOTAL_QUERY_1DAYS' AS query_name,
    'total_queries' AS patient_range,
    COUNT(query_master_id) AS patient_count
FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL '1' DAY
and delete_flag <>'Y'
 and group_id = '{{{PROJECT_ID}}}'

UNION

SELECT
    'ADMIN_TOTAL_USER_QUERY_30DAYS' AS query_name,
    'total_user_queries' AS patient_range,
    COUNT(DISTINCT user_id) AS patient_count
FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL '30' DAY
and delete_flag <>'Y'
 and group_id = '{{{PROJECT_ID}}}'

UNION

SELECT
    'ADMIN_TOTAL_USER_QUERY_7DAYS' AS query_name,
    'total_user_queries' AS patient_range,
    COUNT(DISTINCT user_id) AS patient_count
FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL '7' DAY
and delete_flag <>'Y'
 and group_id = '{{{PROJECT_ID}}}'
]')
||

TO_CLOB(q'[


UNION

SELECT
    'ADMIN_TOTAL_USER_QUERY_1DAYS' AS query_name,
    'total_user_queries' AS patient_range,
    COUNT(DISTINCT user_id) AS patient_count
FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL '1' DAY
and delete_flag <>'Y'
and group_id = '{{{PROJECT_ID}}}'
]')
,
NULL
)
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(9999,'ADMIN_QUERY_DASHBOARD_CLASS_XML','ADMIN','Query Dashboard','CATNUM','LH','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator')
;
