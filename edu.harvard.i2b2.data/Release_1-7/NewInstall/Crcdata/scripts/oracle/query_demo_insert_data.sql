delete QT_BREAKDOWN_PATH
;
insert into QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE) values ('PATIENT_GENDER_COUNT_XML','\\i2b2_DEMO\i2b2\Demographics\Gender\',sysdate)
;
insert into QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE) values ('PATIENT_RACE_COUNT_XML','\\i2b2_DEMO\i2b2\Demographics\Race\',sysdate)
;
insert into QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE) values ('PATIENT_VITALSTATUS_COUNT_XML','\\i2b2_DEMO\i2b2\Demographics\Vital Status\',sysdate)
;
insert into QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE) values ('PATIENT_AGE_COUNT_XML','\\i2b2_DEMO\i2b2\Demographics\Age\',sysdate)
;
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_LOS_XML','select length_of_stay as patient_range, count(distinct a.PATIENT_num) as patient_count from visit_dimension a, DX b where a.patient_num = b.patient_num group by a.length_of_stay order by 1', SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_TOP50MEDS_XML','select * from (select b.name_char as patient_range, count(distinct a.patient_num) as patient_count from observation_fact a, concept_dimension b, DX c where a.concept_cd = b.concept_cd and concept_path like ''\i2b2\Medications\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc ) where rownum <= 50',SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_TOP50DIAG_XML','select * from (select b.name_char as patient_range, count(distinct a.patient_num) as patient_count from observation_fact a, concept_dimension b, DX c where a.concept_cd = b.concept_cd and concept_path like ''\i2b2\Diagnoses\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc ) where rownum <= 50',SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_INOUT_XML','select INOUT_CD as patient_range, count(distinct a.patient_num) as patient_count from visit_dimension a, DX b where a.patient_num = b.patient_num group by a.INOUT_CD order by 1',SYSDATE);

insert into qt_breakdown_path (name, value, create_date) values ('ADMIN_RUNNING_QUERY_XML','select a.name ||' '|| b.start_date as patient_range, b.batch_mode as patient_count from qt_query_master a, QT_QUERY_INSTANCE b where a.QUERY_MASTER_ID = b.QUERY_MASTER_ID and create_date >= add_months(trunc(sysdate, ''day''), - 7)  and create_date < trunc(sysdate, ''day'')  and b.END_DATE is null order by b.BATCH_MODE, a.name',SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('ADMIN_QUERY_TIME_XML','select to_char(create_date, ''HH24'') as patient_range, count(create_date) as patient_count from qt_query_master where delete_date is null group by  to_char(create_date, ''HH24'')  order by  to_char(create_date, ''HH24'')',SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('ADMIN_QUERY_BY_USER_XML','select user_id as patient_range, count(user_id)  as patient_count from qt_query_master where create_date >= add_months(trunc(sysdate, ''month''), - 12)  and create_date < trunc(sysdate, ''month'') and delete_date is null group by user_id order by user_id',SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('ADMIN_RUN_QUERY_XML','select to_char(create_date, ''MM'') as patient_range, count(create_date) as patient_count from qt_query_master where create_date >= add_months(trunc(sysdate, ''month''), - 12) and delete_date is null group by to_char(create_date, ''MM'')  order by to_char(create_date, ''MM'')',SYSDATE);
