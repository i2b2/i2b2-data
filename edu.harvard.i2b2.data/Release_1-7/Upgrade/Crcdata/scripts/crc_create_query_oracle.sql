--==============================================================
-- Database Script to upgrade CRC from 1.6 to 1.7                  
--==============================================================

alter table QT_QUERY_MASTER  add (PM_XML  clob)
;

alter table MASTER_QUERY_GLOBAL_TEMP add (TEMPORAL_START_DATE DATE)
;

alter table MASTER_QUERY_GLOBAL_TEMP add (TEMPORAL_END_DATE DATE)
;


ALTER TABLE PATIENT_MAPPING
DROP CONSTRAINT PATIENT_MAPPING_PK
;

alter table PATIENT_MAPPING add (PROJECT_ID VARCHAR2(50))
;

update PATIENT_MAPPING set PROJECT_ID = 'Demo'
;

alter table PATIENT_MAPPING modify (PROJECT_ID VARCHAR2(50) NOT NULL)
;

ALTER TABLE PATIENT_MAPPING
ADD CONSTRAINT PATIENT_MAPPING_PK PRIMARY KEY(PATIENT_IDE, PATIENT_IDE_SOURCE, PROJECT_ID)
;

ALTER TABLE ENCOUNTER_MAPPING
DROP CONSTRAINT ENCOUNTER_MAPPING_PK
;

alter table ENCOUNTER_MAPPING add (PROJECT_ID VARCHAR2(50))
;

update ENCOUNTER_MAPPING set PROJECT_ID = 'Demo'
;

alter table ENCOUNTER_MAPPING modify (PROJECT_ID VARCHAR2(50) NOT NULL)
;

ALTER TABLE ENCOUNTER_MAPPING
ADD CONSTRAINT ENCOUNTER_MAPPING_PK PRIMARY KEY(ENCOUNTER_IDE, ENCOUNTER_IDE_SOURCE, PATIENT_IDE, PATIENT_IDE_SOURCE, PROJECT_ID)
;

drop table DX
;

CREATE GLOBAL TEMPORARY TABLE DX  (
	ENCOUNTER_NUM	NUMBER(38,0),
	INSTANCE_NUM	NUMBER(38,0),
	PATIENT_NUM		NUMBER(38,0),
	CONCEPT_CD 		varchar2(50), 
	START_DATE 		DATE,
	PROVIDER_ID 	varchar2(50), 
	temporal_start_date date, 
	temporal_end_date DATE	
 ) on COMMIT PRESERVE ROWS
;
 
drop table MASTER_QUERY_GLOBAL_TEMP
;

CREATE GLOBAL TEMPORARY TABLE MASTER_QUERY_GLOBAL_TEMP    ( 
	ENCOUNTER_NUM	NUMBER(38,0),
	PATIENT_NUM		NUMBER(38,0),
	INSTANCE_NUM	NUMBER(18,0) ,
	CONCEPT_CD      VARCHAR2(50),
	START_DATE	    DATE,
	PROVIDER_ID     VARCHAR2(50),
	MASTER_ID		VARCHAR2(50),
	LEVEL_NO		NUMBER(5,0),
	TEMPORAL_START_DATE DATE,
	TEMPORAL_END_DATE DATE
 ) ON COMMIT PRESERVE ROWS
;

--==============================================================
-- Database Script to upgrade CRC from 1.7.01 to 1.7.02                  
--==============================================================


create  GLOBAL TEMPORARY TABLE TEMP_PDO_INPUTLIST    ( 
char_param1 varchar2(100)
 ) ON COMMIT PRESERVE ROWS
;

ALTER TABLE ENCOUNTER_MAPPING
DROP CONSTRAINT ENCOUNTER_MAPPING_PK
;

alter table ENCOUNTER_MAPPING modify (PATIENT_IDE VARCHAR2(200) NOT NULL)
;

alter table ENCOUNTER_MAPPING modify (PATIENT_IDE_SOURCE VARCHAR2(50) NOT NULL)
;

ALTER TABLE ENCOUNTER_MAPPING
ADD CONSTRAINT ENCOUNTER_MAPPING_PK PRIMARY KEY(ENCOUNTER_IDE, ENCOUNTER_IDE_SOURCE, PROJECT_ID, PATIENT_IDE, PATIENT_IDE_SOURCE)
;


--==============================================================
-- Database Script to upgrade CRC from 1.7.09c to 1.7.10                  
--==============================================================

alter table QT_QUERY_RESULT_TYPE add (USER_ROLE_CD VARCHAR2(255))
;
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_LOS_XML','select length_of_stay as patient_range, count(distinct a.PATIENT_num) as patient_count from visit_dimension a, DX b where a.patient_num = b.patient_num group by a.length_of_stay order by 1', SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_TOP50MEDS_XML','select * from (select b.name_char as patient_range, count(distinct a.patient_num) as patient_count from observation_fact a, concept_dimension b, DX c where a.concept_cd = b.concept_cd and concept_path like ''\i2b2\Medications\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc ) where rownum <= 50',SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_TOP50DIAG_XML','select * from (select b.name_char as patient_range, count(distinct a.patient_num) as patient_count from observation_fact a, concept_dimension b, DX c where a.concept_cd = b.concept_cd and concept_path like ''\i2b2\Diagnoses\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc ) where rownum <= 50',SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_INOUT_XML','select INOUT_CD as patient_range, count(distinct a.patient_num) as patient_count from visit_dimension a, DX b where a.patient_num = b.patient_num group by a.INOUT_CD order by 1',SYSDATE);

insert into qt_breakdown_path (name, value, create_date) values ('ADMIN_RUNNING_QUERY_XML','select a.name ||'' ''|| b.start_date as patient_range, b.batch_mode as patient_count from qt_query_master a, QT_QUERY_INSTANCE b where a.QUERY_MASTER_ID = b.QUERY_MASTER_ID and create_date >= add_months(trunc(sysdate, ''day''), - 7)  and create_date < trunc(sysdate, ''day'')  and b.END_DATE is null order by b.BATCH_MODE, a.name',SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('ADMIN_QUERY_TIME_XML','select to_char(create_date, ''HH24'') as patient_range, count(create_date) as patient_count from qt_query_master where delete_date is null group by  to_char(create_date, ''HH24'')  order by  to_char(create_date, ''HH24'')',SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('ADMIN_QUERY_BY_USER_XML','select user_id as patient_range, count(user_id)  as patient_count from qt_query_master where create_date >= add_months(trunc(sysdate, ''month''), - 12)  and create_date < trunc(sysdate, ''month'') and delete_date is null group by user_id order by user_id',SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('ADMIN_RUN_QUERY_XML','select to_char(create_date, ''MM'') as patient_range, count(create_date) as patient_count from qt_query_master where create_date >= add_months(trunc(sysdate, ''month''), - 12) and delete_date is null group by to_char(create_date, ''MM'')  order by to_char(create_date, ''MM'')',SYSDATE);

