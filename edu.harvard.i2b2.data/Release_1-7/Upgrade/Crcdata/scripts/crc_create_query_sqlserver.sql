alter table qt_query_master add PM_XML TEXT
;

ALTER TABLE PATIENT_MAPPING
DROP CONSTRAINT PATIENT_MAPPING_PK
;

alter table PATIENT_MAPPING add  PROJECT_ID VARCHAR(50)
;

update PATIENT_MAPPING set PROJECT_ID = 'Demo'
;

alter table PATIENT_MAPPING alter column  PROJECT_ID VARCHAR(50) NOT NULL
;

ALTER TABLE PATIENT_MAPPING
ADD CONSTRAINT PATIENT_MAPPING_PK PRIMARY KEY nonclustered (PATIENT_IDE, PATIENT_IDE_SOURCE, PROJECT_ID)
;

ALTER TABLE ENCOUNTER_MAPPING
DROP CONSTRAINT ENCOUNTER_MAPPING_PK
;

alter table ENCOUNTER_MAPPING add  PROJECT_ID VARCHAR(50)
;

update ENCOUNTER_MAPPING set PROJECT_ID = 'Demo'
;

alter table ENCOUNTER_MAPPING alter column  PROJECT_ID VARCHAR(50) NOT NULL
;

ALTER TABLE ENCOUNTER_MAPPING
ADD CONSTRAINT ENCOUNTER_MAPPING_PK PRIMARY KEY nonclustered (ENCOUNTER_IDE, ENCOUNTER_IDE_SOURCE, PATIENT_IDE, PATIENT_IDE_SOURCE, PROJECT_ID)
;


--==============================================================
-- Database Script to upgrade CRC from 1.7.01 to 1.7.02                  
--==============================================================


ALTER TABLE ENCOUNTER_MAPPING
DROP CONSTRAINT ENCOUNTER_MAPPING_PK
;

DROP INDEX ENCOUNTER_MAPPING.EM_IDX_ENCPATH
;

DROP INDEX ENCOUNTER_MAPPING.EM_IDX_UPLOADID
;

DROP INDEX ENCOUNTER_MAPPING.EM_ENCNUM_IDX
;

alter table ENCOUNTER_MAPPING alter column  PATIENT_IDE VARCHAR(200) NOT NULL
;

alter table ENCOUNTER_MAPPING alter column  PATIENT_IDE_SOURCE VARCHAR(50) NOT NULL
;

ALTER TABLE ENCOUNTER_MAPPING
ADD CONSTRAINT ENCOUNTER_MAPPING_PK PRIMARY KEY nonclustered (ENCOUNTER_IDE, ENCOUNTER_IDE_SOURCE, PROJECT_ID, PATIENT_IDE, PATIENT_IDE_SOURCE)
;

CREATE  INDEX EM_IDX_ENCPATH ON ENCOUNTER_MAPPING(ENCOUNTER_IDE, ENCOUNTER_IDE_SOURCE, PATIENT_IDE, PATIENT_IDE_SOURCE, ENCOUNTER_NUM)
;
CREATE  INDEX EM_IDX_UPLOADID ON ENCOUNTER_MAPPING(UPLOAD_ID)
;
CREATE INDEX EM_ENCNUM_IDX ON ENCOUNTER_MAPPING(ENCOUNTER_NUM)


--==============================================================
-- Database Script to upgrade CRC from 1.7.09c to 1.7.10                  
--==============================================================

alter table QT_QUERY_RESULT_TYPE add USER_ROLE_CD VARCHAR(255)
;
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_LOS_XML','select length_of_stay as patient_range, count(distinct a.PATIENT_num) as patient_count from {{{DATABASE_NAME}}}.visit_dimension a, {{{DATABASE_NAME}}}.#DX b where a.patient_num = b.patient_num group by a.length_of_stay order by 1', GETDATE());
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_TOP50MEDS_XML','select top 50 b.name_char as patient_range, count(distinct a.patient_num) as patient_count from {{{DATABASE_NAME}}}.observation_fact a, {{{DATABASE_NAME}}}.concept_dimension b, {{{DATABASE_NAME}}}.#DX c where a.concept_cd = b.concept_cd and concept_path like ''\i2b2\Medications\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc', GETDATE());
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_TOP50DIAG_XML','select top 50 b.name_char as patient_range, count(distinct a.patient_num) as patient_count from {{{DATABASE_NAME}}}.observation_fact a, {{{DATABASE_NAME}}}.concept_dimension b, {{{DATABASE_NAME}}}.#DX c where a.concept_cd = b.concept_cd and concept_path like ''\i2b2\Diagnoses\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc', GETDATE());
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_INOUT_XML','select INOUT_CD as patient_range, count(distinct a.patient_num) as patient_count from {{{DATABASE_NAME}}}.visit_dimension a, {{{DATABASE_NAME}}}.#DX b where a.patient_num = b.patient_num group by a.INOUT_CD order by 1', GETDATE());
insert into qt_breakdown_path (name, value, create_date) values ('ADMIN_RUNNING_QUERY_XML','select a.name + '' '' + format(b.start_date, ''yyyy-MM-dd'')  as patient_range, b.batch_mode as patient_count from qt_query_master a, QT_QUERY_INSTANCE b where a.QUERY_MASTER_ID = b.QUERY_MASTER_ID and create_date >=  DATEADD(day,-7, GETDATE())   and b.END_DATE is null order by b.BATCH_MODE, a.name',GETDATE());
insert into qt_breakdown_path (name, value, create_date) values ('ADMIN_QUERY_TIME_XML','select format(create_date, ''HH'') as patient_range, count(create_date) as patient_count from qt_query_master where delete_date is null GROUP BY   format(create_date, ''HH'')',GETDATE());
insert into qt_breakdown_path (name, value, create_date) values ('ADMIN_QUERY_BY_USER_XML','select user_id as patient_range, count(user_id)  as patient_count from qt_query_master where create_date >=   DATEADD(month,-1, GETDATE())   and delete_date is null group by user_id order by user_id',GETDATE());
insert into qt_breakdown_path (name, value, create_date) values ('ADMIN_RUN_QUERY_XML','select format(create_date, ''MM'') as patient_range, count(create_date) as patient_count from qt_query_master where create_date >= DATEADD(month,-12, GETDATE())  and delete_date is null GROUP BY format(create_date, ''MM'')',GETDATE());


