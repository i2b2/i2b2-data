--==============================================================
-- Database Script to upgrade CRC from 1.8.2 to 1.8.3
--==============================================================

insert into QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE,UPDATE_DATE,USER_ID,GROUP_ID) values('ADMIN_QUERY_DASHBOARD_CLASS_XML',$SQL$
SELECT query_name, patient_range, patient_count
FROM (
    SELECT
        'ADMIN_TOPUSERS' AS query_name,
        user_id AS patient_range,
        COUNT(user_id) AS patient_count
    FROM {{{DATABASE_NAME}}}qt_query_master
    GROUP BY user_id
    ORDER BY COUNT(user_id) DESC
    LIMIT 10
) a

UNION ALL

SELECT query_name, patient_range, patient_count
FROM (
    SELECT
        'ADMIN_TOPUSERS_30_DAYS' AS query_name,
        user_id AS patient_range,
        COUNT(user_id) AS patient_count
    FROM {{{DATABASE_NAME}}}qt_query_master
    WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY user_id
    ORDER BY COUNT(user_id) DESC
    LIMIT 10
) a

UNION ALL

SELECT query_name, patient_range, patient_count
FROM (
    SELECT
        'ADMIN_TOPUSERS_7_DAYS' AS query_name,
        user_id AS patient_range,
        COUNT(user_id) AS patient_count
    FROM {{{DATABASE_NAME}}}qt_query_master
    WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL '7 days'
    GROUP BY user_id
    ORDER BY COUNT(user_id) DESC
    LIMIT 10
) a

UNION ALL

SELECT query_name, patient_range, patient_count
FROM (
    SELECT
        'ADMIN_TOPUSERS_1_DAY' AS query_name,
        user_id AS patient_range,
        COUNT(user_id) AS patient_count
    FROM {{{DATABASE_NAME}}}qt_query_master
    WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL '1 day'
    GROUP BY user_id
    ORDER BY COUNT(user_id) DESC
    LIMIT 10
) a

UNION ALL

SELECT
    'ADMIN_COUNT' AS query_name,
    TO_CHAR(create_date, 'YYYY-MM') AS patient_range,
    COUNT(create_date) AS patient_count
FROM {{{DATABASE_NAME}}}qt_query_master
GROUP BY TO_CHAR(create_date, 'YYYY-MM')

UNION ALL

SELECT
    'ADMIN_TOTAL_QUERY' AS query_name,
    'total_queries' AS patient_range,
    COUNT(query_master_id) AS patient_count
FROM {{{DATABASE_NAME}}}qt_query_master

UNION ALL

SELECT
    'ADMIN_TOTAL_QUERY_30DAYS' AS query_name,
    'total_queries' AS patient_range,
    COUNT(query_master_id) AS patient_count
FROM {{{DATABASE_NAME}}}qt_query_master
WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL '30 days'

UNION ALL

SELECT
    'ADMIN_TOTAL_QUERY_7DAYS' AS query_name,
    'total_queries' AS patient_range,
    COUNT(query_master_id) AS patient_count
FROM {{{DATABASE_NAME}}}qt_query_master
WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL '7 days'

UNION ALL

SELECT
    'ADMIN_TOTAL_QUERY_1DAYS' AS query_name,
    'total_queries' AS patient_range,
    COUNT(query_master_id) AS patient_count
FROM {{{DATABASE_NAME}}}qt_query_master
WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL '1 day'

UNION ALL

SELECT
    'ADMIN_TOTAL_USER_QUERY_30DAYS' AS query_name,
    'total_user_queries' AS patient_range,
    COUNT(DISTINCT user_id) AS patient_count
FROM {{{DATABASE_NAME}}}qt_query_master
WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL '30 days'

UNION ALL

SELECT
    'ADMIN_TOTAL_USER_QUERY_7DAYS' AS query_name,
    'total_user_queries' AS patient_range,
    COUNT(DISTINCT user_id) AS patient_count
FROM {{{DATABASE_NAME}}}qt_query_master
WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL '7 days'

UNION ALL

SELECT
    'ADMIN_TOTAL_USER_QUERY_1DAYS' AS query_name,
    'total_user_queries' AS patient_range,
    COUNT(DISTINCT user_id) AS patient_count
FROM {{{DATABASE_NAME}}}qt_query_master
WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL '1 day'
$SQL$,NULL,NULL,NULL,NULL)
;

insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(9999,'ADMIN_QUERY_DASHBOARD_CLASS_XML','ADMIN','Query Dashboard','CATNUM','LH','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator')
;
