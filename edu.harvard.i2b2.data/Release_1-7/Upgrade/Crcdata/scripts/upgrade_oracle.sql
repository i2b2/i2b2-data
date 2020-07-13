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

-- New column added to support new SQL breakdowns - roles based access
alter table QT_QUERY_RESULT_TYPE add (USER_ROLE_CD VARCHAR2(255))
;

-- Insert new SQL breakdowns into QT_BREAKDOWN_PATH table

insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_LOS_XML','select length_of_stay as patient_range, count(distinct a.PATIENT_num) as patient_count from visit_dimension a, DX b where a.patient_num = b.patient_num group by a.length_of_stay order by 1', SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_TOP20MEDS_XML','select * from (select b.name_char as patient_range, count(distinct a.patient_num) as patient_count from observation_fact a, concept_dimension b, DX c where a.concept_cd = b.concept_cd and concept_path like ''\i2b2\Medications\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc ) where rownum <= 20',SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_TOP20DIAG_XML','select * from (select b.name_char as patient_range, count(distinct a.patient_num) as patient_count from observation_fact a, concept_dimension b, DX c where a.concept_cd = b.concept_cd and concept_path like ''\i2b2\Diagnoses\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc ) where rownum <= 20',SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_INOUT_XML','select INOUT_CD as patient_range, count(distinct a.patient_num) as patient_count from visit_dimension a, DX b where a.patient_num = b.patient_num group by a.INOUT_CD order by 1',SYSDATE);


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
alter table QT_QUERY_RESULT_TYPE add (CLASSNAME VARCHAR2(200))
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