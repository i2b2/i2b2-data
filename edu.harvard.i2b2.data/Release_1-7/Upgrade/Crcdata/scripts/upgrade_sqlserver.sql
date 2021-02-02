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

-- New column added to support new SQL breakdowns - roles based access
alter table QT_QUERY_RESULT_TYPE add USER_ROLE_CD VARCHAR(255)
;
-- Insert new SQL breakdowns into QT_BREAKDOWN_PATH table

insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_LOS_XML','select length_of_stay as patient_range, count(distinct a.PATIENT_num) as patient_count from {{{DATABASE_NAME}}}.visit_dimension a, {{{DATABASE_NAME}}}.#DX b where a.patient_num = b.patient_num group by a.length_of_stay order by 1', GETDATE());
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_TOP20MEDS_XML','select top 20 b.name_char as patient_range, count(distinct a.patient_num) as patient_count from {{{DATABASE_NAME}}}.observation_fact a, {{{DATABASE_NAME}}}.concept_dimension b, {{{DATABASE_NAME}}}.#DX c where a.concept_cd = b.concept_cd and concept_path like ''\i2b2\Medications\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc', GETDATE());
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_TOP20DIAG_XML','select top 20 b.name_char as patient_range, count(distinct a.patient_num) as patient_count from {{{DATABASE_NAME}}}.observation_fact a, {{{DATABASE_NAME}}}.concept_dimension b, {{{DATABASE_NAME}}}.#DX c where a.concept_cd = b.concept_cd and concept_path like ''\i2b2\Diagnoses\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc', GETDATE());
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_INOUT_XML','select INOUT_CD as patient_range, count(distinct a.patient_num) as patient_count from {{{DATABASE_NAME}}}.visit_dimension a, {{{DATABASE_NAME}}}.#DX b where a.patient_num = b.patient_num group by a.INOUT_CD order by 1', GETDATE());


-- Insert new SQL breakdowns into QT_QUERY_RESULT_TYPE table

insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(10,'PATIENT_LOS_XML','DATA_LDS','Length of stay breakdown','CATNUM','LA');
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(11,'PATIENT_TOP20MEDS_XML','DATA_LDS','Top 20 medications breakdown','CATNUM','LA');
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(12,'PATIENT_TOP20DIAG_XML','DATA_LDS','Top 20 diagnoses breakdown','CATNUM','LA');
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(13,'PATIENT_INOUT_XML','DATA_LDS','Inpatient and outpatient breakdown','CATNUM','LA');


--==============================================================
-- Database Script to upgrade CRC from 1.7.10 to 1.7.11                  
--==============================================================

insert into QT_PRIVILEGE(PROTECTION_LABEL_CD, DATAPROT_CD, HIVEMGMT_CD) values ('SETFINDER_QRY_PROTECTED','DATA_PROT','USER')
;

--==============================================================
-- Database Script to upgrade CRC from 1.7.11 to 1.7.12                  
--==============================================================
alter table QT_QUERY_RESULT_TYPE add CLASSNAME VARCHAR(200)
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSetGenerator' where NAME='PATIENTSET'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultEncounterSetGenerator' where NAME='PATIENT_ENCOUNTER_SET'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientCountGenerator' where NAME='PATIENT_COUNT_XML'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator' where NAME='PATIENT_GENDER_COUNT_XML'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator' where NAME='PATIENT_VITALSTATUS_COUNT_XML'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator' where NAME='PATIENT_RACE_COUNT_XML'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator' where NAME='PATIENT_AGE_COUNT_XML'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator' where NAME='PATIENT_LOS_XML'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator' where NAME='PATIENT_TOP20MEDS_XML'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator' where NAME='PATIENT_TOP20DIAG_XML'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator' where NAME='PATIENT_INOUT_XML'
;

                                                                 
--==============================================================
-- Database Script to upgrade CRC from 1.7.12a to 1.7.13                
--==============================================================
-- if the following command belows fails due to lack of temp space, rename PATIENT_ENC_COLL_ID to QT_PATIENT_ENC_COLLECTION_BAK, create a new table QT_PATIENT_ENC_COLLECTION 
-- and copy data from QT_PATIENT_ENC_COLLECTION_BAK to QT_PATIENT_ENC_COLLECTION
alter table QT_PATIENT_ENC_COLLECTION alter column  PATIENT_ENC_COLL_ID BIGINT NOT NULL
;
                                                                 
