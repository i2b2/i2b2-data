--==============================================================
-- Database Script to upgrade CRC from 1.8.2 to 1.8.3
--==============================================================

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

insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(9999,'ADMIN_QUERY_DASHBOARD_CLASS_XML','ADMIN','Query Dashboard','CATNUM','LH','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator')
;
