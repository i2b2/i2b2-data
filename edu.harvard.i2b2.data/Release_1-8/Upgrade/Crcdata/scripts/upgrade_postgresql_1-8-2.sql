--==============================================================
-- Database Script to upgrade CRC from 1.8.2 to 1.8.3
--==============================================================

INSERT INTO qt_breakdown_path (name, value, create_date, update_date, user_id, group_id) VALUES ('ADMIN_QUERY_DASHBOARD_CLASS_XML', e'SELECT query_name, patient_range, patient_count
FROM (
    SELECT
        \'ADMIN_TOPUSERS\' AS query_name,
        user_id::text AS patient_range,
        COUNT(user_id) AS patient_count
    FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
	 where  delete_flag <>\'Y\'
 and group_id = \'{{{PROJECT_ID}}}\'
    GROUP BY user_id
    ORDER BY patient_count DESC
    LIMIT 10
) a

UNION

SELECT query_name, patient_range, patient_count
FROM (
    SELECT
        \'ADMIN_TOPUSERS_30_DAYS\' AS query_name,
        user_id::text AS patient_range,
        COUNT(user_id) AS patient_count
    FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
    WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL \'30 days\'
	and delete_flag <>\'Y\'
 and group_id = \'{{{PROJECT_ID}}}\'
    GROUP BY user_id
    ORDER BY patient_count DESC
    LIMIT 10
) a

UNION

SELECT query_name, patient_range, patient_count
FROM (
    SELECT
        \'ADMIN_TOPUSERS_7_DAYS\' AS query_name,
        user_id::text AS patient_range,
        COUNT(user_id) AS patient_count
    FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
    WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL \'7 days\'
	and delete_flag <>\'Y\'
 and group_id = \'{{{PROJECT_ID}}}\'
    GROUP BY user_id
    ORDER BY patient_count DESC
    LIMIT 10
) a

UNION

SELECT query_name, patient_range, patient_count
FROM (
    SELECT
        \'ADMIN_TOPUSERS_1_DAY\' AS query_name,
        user_id::text AS patient_range,
        COUNT(user_id) AS patient_count
    FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
    WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL \'1 day\'
	and delete_flag <>\'Y\'
 and group_id = \'{{{PROJECT_ID}}}\'
    GROUP BY user_id
    ORDER BY patient_count DESC
    LIMIT 10
) a

UNION

SELECT
    \'ADMIN_TOTAL_QUERY\' AS query_name,
    \'total_queries\' AS patient_range,
    COUNT(query_master_id) AS patient_count
FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
where delete_flag <>\'Y\'
 and group_id = \'{{{PROJECT_ID}}}\'
UNION

SELECT
    \'ADMIN_TOTAL_QUERY_30DAYS\' AS query_name,
    \'total_queries\' AS patient_range,
    COUNT(query_master_id) AS patient_count
FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL \'30 days\'
and delete_flag <>\'Y\'
 and group_id = \'{{{PROJECT_ID}}}\'

UNION

SELECT
    \'ADMIN_TOTAL_QUERY_7DAYS\' AS query_name,
    \'total_queries\' AS patient_range,
    COUNT(query_master_id) AS patient_count
FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL \'7 days\'
and delete_flag <>\'Y\'
 and group_id = \'{{{PROJECT_ID}}}\'

UNION

SELECT
    \'ADMIN_TOTAL_QUERY_1DAYS\' AS query_name,
    \'total_queries\' AS patient_range,
    COUNT(query_master_id) AS patient_count
FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL \'1 day\'
and delete_flag <>\'Y\'
 and group_id = \'{{{PROJECT_ID}}}\'
UNION

SELECT
    \'ADMIN_TOTAL_USER_QUERY_30DAYS\' AS query_name,
    \'total_user_queries\' AS patient_range,
    COUNT(DISTINCT user_id) AS patient_count
FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL \'30 days\'
and delete_flag <>\'Y\'
 and group_id = \'{{{PROJECT_ID}}}\'
UNION

SELECT
    \'ADMIN_TOTAL_USER_QUERY_7DAYS\' AS query_name,
    \'total_user_queries\' AS patient_range,
    COUNT(DISTINCT user_id) AS patient_count
FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL \'7 days\'
and delete_flag <>\'Y\'
and group_id = \'{{{PROJECT_ID}}}\'
UNION

SELECT
    \'ADMIN_TOTAL_USER_QUERY_1DAYS\' AS query_name,
    \'total_user_queries\' AS patient_range,
    COUNT(DISTINCT user_id) AS patient_count
FROM {{{DATABASE_NAME}}}QT_QUERY_MASTER
WHERE create_date >= CURRENT_TIMESTAMP - INTERVAL \'1 day\'
and delete_flag <>\'Y\'
and group_id = \'{{{PROJECT_ID}}}\'
 UNION ALL
SELECT query_name, patient_range, patient_count
FROM (

SELECT
    \'ADMIN_COUNT\' AS query_name,
    TO_CHAR(create_date, \'YYYY-MM\') AS patient_range,
    COUNT(create_date) AS patient_count
FROM qt_query_master 
where delete_flag <>\'Y\'
 and group_id = \'{{{PROJECT_ID}}}\'
GROUP BY TO_CHAR(create_date, \'YYYY-MM\')
ORDER BY TO_CHAR(create_date, \'YYYY-MM\')
) a', null, null, null, null)
;

insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(9999,'ADMIN_QUERY_DASHBOARD_CLASS_XML','ADMIN','Query Dashboard','CATNUM','LH','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator')
;
