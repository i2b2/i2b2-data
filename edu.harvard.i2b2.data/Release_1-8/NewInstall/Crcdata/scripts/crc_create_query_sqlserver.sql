/*==============================================================*/
/* Sqlserver Database Script to create CRC query tables         */
/*==============================================================*/


/*============================================================================*/
/* Table: QT_QUERY_MASTER 											          */
/*============================================================================*/
CREATE TABLE QT_QUERY_MASTER (
	QUERY_MASTER_ID		INT  IDENTITY(1,1) PRIMARY KEY,
	NAME				VARCHAR(250) NOT NULL,
	USER_ID				VARCHAR(50) NOT NULL,
	GROUP_ID			VARCHAR(50) NOT NULL,
	MASTER_TYPE_CD		VARCHAR(2000),
	PLUGIN_ID			INT,
	CREATE_DATE			DATETIME NOT NULL,
	DELETE_DATE			DATETIME,
	DELETE_FLAG			VARCHAR(3),
	REQUEST_XML			VARCHAR(MAX),
	GENERATED_SQL		VARCHAR(MAX),
	I2B2_REQUEST_XML	VARCHAR(MAX),
	PM_XML				VARCHAR(MAX)
)
;
CREATE INDEX QT_IDX_QM_UGID ON QT_QUERY_MASTER(USER_ID,GROUP_ID,MASTER_TYPE_CD);


/*============================================================================*/
/* Table: QT_QUERY_RESULT_TYPE										          */
/*============================================================================*/
CREATE TABLE QT_QUERY_RESULT_TYPE (
	RESULT_TYPE_ID				INT   PRIMARY KEY,
	NAME						VARCHAR(100),
	DESCRIPTION					VARCHAR(200),
	DISPLAY_TYPE_ID				NVARCHAR(500),
	VISUAL_ATTRIBUTE_TYPE_ID	NVARCHAR(3),
	USER_ROLE_CD 				VARCHAR(255),
	CLASSNAME					VARCHAR(200)
)
;


/*============================================================================*/
/* Table: QT_QUERY_STATUS_TYPE										          */
/*============================================================================*/
CREATE TABLE QT_QUERY_STATUS_TYPE (
	STATUS_TYPE_ID	INT   PRIMARY KEY,
	NAME			VARCHAR(100),
	DESCRIPTION		VARCHAR(200)
)
;


/*============================================================================*/
/* Table: QT_QUERY_INSTANCE 										          */
/*============================================================================*/
CREATE TABLE QT_QUERY_INSTANCE (
	QUERY_INSTANCE_ID	INT  IDENTITY(1,1) PRIMARY KEY,
	QUERY_MASTER_ID		INT,
	USER_ID				VARCHAR(50) NOT NULL,
	GROUP_ID			VARCHAR(50) NOT NULL,
	BATCH_MODE			VARCHAR(50),
	START_DATE			DATETIME NOT NULL,
	END_DATE			DATETIME,
	DELETE_FLAG			VARCHAR(3),
	STATUS_TYPE_ID		INT,
	MESSAGE				VARCHAR(MAX),
	CONSTRAINT QT_FK_QI_MID FOREIGN KEY (QUERY_MASTER_ID)
		REFERENCES QT_QUERY_MASTER (QUERY_MASTER_ID),
	CONSTRAINT QT_FK_QI_STID FOREIGN KEY (STATUS_TYPE_ID)
		REFERENCES QT_QUERY_STATUS_TYPE (STATUS_TYPE_ID)
)
;
CREATE INDEX QT_IDX_QI_UGID ON QT_QUERY_INSTANCE(USER_ID,GROUP_ID)
;
CREATE INDEX QT_IDX_QI_MSTARTID ON QT_QUERY_INSTANCE(QUERY_MASTER_ID,START_DATE)
;


/*=============================================================================*/
/* Table: QT_QUERY_RESULT_INSTANCE   								          */
/*============================================================================*/
	CREATE TABLE QT_QUERY_RESULT_INSTANCE (
	RESULT_INSTANCE_ID	INT  IDENTITY(1,1) PRIMARY KEY,
	QUERY_INSTANCE_ID	INT,
	RESULT_TYPE_ID		INT NOT NULL,
	SET_SIZE			INT,
	START_DATE			DATETIME NOT NULL,
	END_DATE			DATETIME,
	STATUS_TYPE_ID		INT NOT NULL,
	DELETE_FLAG			VARCHAR(3),
	MESSAGE				VARCHAR(MAX),
	DESCRIPTION			VARCHAR(200),
	REAL_SET_SIZE		INT,
	OBFUSC_METHOD		VARCHAR(500),
	CONSTRAINT QT_FK_QRI_RID FOREIGN KEY (QUERY_INSTANCE_ID)
		REFERENCES QT_QUERY_INSTANCE (QUERY_INSTANCE_ID),
	CONSTRAINT QT_FK_QRI_RTID FOREIGN KEY (RESULT_TYPE_ID)
		REFERENCES QT_QUERY_RESULT_TYPE (RESULT_TYPE_ID),
	CONSTRAINT QT_FK_QRI_STID FOREIGN KEY (STATUS_TYPE_ID)
		REFERENCES QT_QUERY_STATUS_TYPE (STATUS_TYPE_ID)
)
;


/*============================================================================*/
/* Table: QT_PATIENT_SET_COLLECTION									          */
/*============================================================================*/
CREATE TABLE QT_PATIENT_SET_COLLECTION ( 
	PATIENT_SET_COLL_ID	BIGINT  IDENTITY(1,1) PRIMARY KEY,
	RESULT_INSTANCE_ID	INT,
	SET_INDEX			INT,
	PATIENT_NUM			INT,
	CONSTRAINT QT_FK_PSC_RI FOREIGN KEY (RESULT_INSTANCE_ID )
		REFERENCES QT_QUERY_RESULT_INSTANCE (RESULT_INSTANCE_ID)
)
;
CREATE INDEX QT_IDX_QPSC_RIID ON QT_PATIENT_SET_COLLECTION(RESULT_INSTANCE_ID)
;


/*============================================================================*/
/* Table: QT_PATIENT_ENC_COLLECTION									          */
/*============================================================================*/
CREATE TABLE QT_PATIENT_ENC_COLLECTION (
	PATIENT_ENC_COLL_ID	BIGINT  IDENTITY(1,1) PRIMARY KEY,
	RESULT_INSTANCE_ID	INT,
	SET_INDEX			INT,
	PATIENT_NUM			INT,
	ENCOUNTER_NUM		INT,
	CONSTRAINT QT_FK_PESC_RI FOREIGN KEY (RESULT_INSTANCE_ID)
		REFERENCES QT_QUERY_RESULT_INSTANCE(RESULT_INSTANCE_ID)
)
;


/*============================================================================*/
/* Table: QT_XML_RESULT												          */
/*============================================================================*/
CREATE TABLE QT_XML_RESULT (
	XML_RESULT_ID		INT  IDENTITY(1,1) PRIMARY KEY,
	RESULT_INSTANCE_ID	INT,
	XML_VALUE			VARCHAR(MAX),
	CONSTRAINT QT_FK_XMLR_RIID FOREIGN KEY (RESULT_INSTANCE_ID)
		REFERENCES QT_QUERY_RESULT_INSTANCE (RESULT_INSTANCE_ID)
)
;


/*============================================================================*/
/* Table: QT_ANALYSIS_PLUGIN										          */
/*============================================================================*/
CREATE TABLE QT_ANALYSIS_PLUGIN (
	PLUGIN_ID			INT NOT NULL,
	PLUGIN_NAME			VARCHAR(2000),
	DESCRIPTION			VARCHAR(2000),
	VERSION_CD			VARCHAR(50),	--support for version
	PARAMETER_INFO		VARCHAR(MAX),			-- plugin parameter stored as xml
	PARAMETER_INFO_XSD	VARCHAR(MAX),
	COMMAND_LINE		VARCHAR(MAX),
	WORKING_FOLDER		VARCHAR(MAX),
	COMMANDOPTION_CD	VARCHAR(MAX),
	PLUGIN_ICON         VARCHAR(MAX),
	STATUS_CD			VARCHAR(50),	-- active,deleted,..
	USER_ID				VARCHAR(50),
	GROUP_ID			VARCHAR(50),
	CREATE_DATE			DATETIME,
	UPDATE_DATE			DATETIME,
	CONSTRAINT ANALYSIS_PLUGIN_PK PRIMARY KEY(PLUGIN_ID)
)
;
CREATE INDEX QT_APNAMEVERGRP_IDX ON QT_ANALYSIS_PLUGIN(PLUGIN_NAME,VERSION_CD,GROUP_ID);


/*============================================================================*/
/* Table: QT_ANALYSIS_PLUGIN_RESULT_TYPE							          */
/*============================================================================*/
CREATE TABLE QT_ANALYSIS_PLUGIN_RESULT_TYPE (
	PLUGIN_ID		INT,
	RESULT_TYPE_ID	INT,
	CONSTRAINT ANALYSIS_PLUGIN_RESULT_PK PRIMARY KEY(PLUGIN_ID,RESULT_TYPE_ID)
)
;


/*============================================================================*/
/* Table: QT_PRIVILEGE												          */
/*============================================================================*/
CREATE TABLE QT_PRIVILEGE(
	PROTECTION_LABEL_CD		VARCHAR(1500) PRIMARY KEY,
	DATAPROT_CD				VARCHAR(1000),
	HIVEMGMT_CD				VARCHAR(1000),
	PLUGIN_ID				INT
)
;


/*============================================================================*/
/* Table: QT_BREAKDOWN_PATH											          */
/*============================================================================*/
CREATE TABLE QT_BREAKDOWN_PATH (
	NAME			VARCHAR(100), 
	VALUE			VARCHAR(MAX), 
	CREATE_DATE		DATETIME,
	UPDATE_DATE		DATETIME,
	USER_ID			VARCHAR(50),
	GROUP_ID                VARCHAR(50)
)
;


/*============================================================================*/
/* Table:QT_PDO_QUERY_MASTER 										          */
/*============================================================================*/
CREATE TABLE QT_PDO_QUERY_MASTER (
	QUERY_MASTER_ID		INT  IDENTITY(1,1) PRIMARY KEY,
	USER_ID				VARCHAR(50) NOT NULL,
	GROUP_ID			VARCHAR(50) NOT NULL,
	CREATE_DATE			DATETIME NOT NULL,
	REQUEST_XML			VARCHAR(MAX),
	I2B2_REQUEST_XML	VARCHAR(MAX)
)
;
CREATE INDEX QT_IDX_PQM_UGID ON QT_PDO_QUERY_MASTER(USER_ID,GROUP_ID);



--------------------------------------------------------
--INIT WITH SEED DATA
--------------------------------------------------------
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(1,'QUEUED',' WAITING IN QUEUE TO START PROCESS');
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(2,'PROCESSING','PROCESSING');
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(3,'FINISHED','FINISHED');
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(4,'ERROR','ERROR');
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(5,'INCOMPLETE','INCOMPLETE');
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(6,'COMPLETED','COMPLETED');
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(7,'MEDIUM_QUEUE','MEDIUM QUEUE');
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(8,'LARGE_QUEUE','LARGE QUEUE');
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(9,'CANCELLED','CANCELLED');
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(10,'TIMEDOUT','TIMEDOUT');


insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(1,'PATIENTSET','Patient set','LIST','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSetGenerator')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(2,'PATIENT_ENCOUNTER_SET','Encounter set','LIST','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultEncounterSetGenerator')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(3,'XML','Generic query result','CATNUM','LH',null)
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME, VISUAL_TYPE) values(4,'PATIENT_COUNT_XML','Number of patients','CATNUM','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientCountGenerator', '{
    "COUNT": true
  }')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME, VISUAL_TYPE) values(5,'PATIENT_GENDER_COUNT_XML','Gender patient breakdown','CATNUM','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator', '{
    "BARS": true,
    "TABLE": true,
    "DOWNLOAD": true
  }')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME, VISUAL_TYPE) values(6,'PATIENT_VITALSTATUS_COUNT_XML','Vital Status patient breakdown','CATNUM','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator', '{
    "BARS": true,
    "TABLE": true,
    "DOWNLOAD": true
  }')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME, VISUAL_TYPE) values(7,'PATIENT_RACE_COUNT_XML','Race patient breakdown','CATNUM','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator', '{
    "BARS": true,
    "TABLE": true,
    "DOWNLOAD": true
  }')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME, VISUAL_TYPE) values(8,'PATIENT_AGE_COUNT_XML','Age patient breakdown','CATNUM','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator', '{
    "PIECHART": true,
    "BARS": {
      "maxLabelLength": 15
    },
    "TABLE": true,
    "DOWNLOAD": true
  }')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME, VISUAL_TYPE) values(10,'PATIENT_LOS_XML','DATA_LDS','Length of stay breakdown','CATNUM','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator', '{
    "BARS": true,
    "TABLE": true,
    "DOWNLOAD": true
  }')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME, VISUAL_TYPE) values(11,'PATIENT_TOP20MEDS_XML','DATA_LDS','Top 20 medications breakdown','CATNUM','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator', '{
    "BARS": true,
    "TABLE": {
      "forceInitialDisplay": true
    },
    "DOWNLOAD": true
  }')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME, VISUAL_TYPE) values(12,'PATIENT_TOP20DIAG_XML','DATA_LDS','Top 20 diagnoses breakdown','CATNUM','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator', '{
    "BARS": true,
    "TABLE": {
      "forceInitialDisplay": true
    },
    "DOWNLOAD": true
  }')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME, VISUAL_TYPE) values(13,'PATIENT_INOUT_XML','DATA_LDS','Inpatient and outpatient breakdown','CATNUM','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator', '{
    "BARS": true,
    "TABLE": true,
    "DOWNLOAD": true
  }')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(114,'PATIENT_DEMOGRAPHIC_REQUEST','DATA_LDS','Request Demographics Data','CATNUM','LR','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(115,'PATIENT_MEDICATION_REQUEST','DATA_LDS','Request Medication Data','CATNUM','LR','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(116,'PATIENT_PROCEDURE_REQUEST','DATA_LDS','Request Procedure Data','CATNUM','LR','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(117,'PATIENT_DIAGNOSIS_REQUEST','DATA_LDS','Request Diagnosis Data','CATNUM','LR','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(118,'PATIENT_LAB_REQUEST','DATA_LDS','Request Lab Data','CATNUM','LR','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(119,'PATIENT_DEMOGRAPHIC_CSV','MANAGER','Export Demographics Data','CATNUM','LH','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(120,'PATIENT_MEDICATION_CSV','MANAGER','Export Medication Data','CATNUM','LH','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(121,'PATIENT_PROCEDURE_CSV','MANAGER','Export Procedure Data','CATNUM','LH','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(122,'PATIENT_DIAGNOSIS_CSV','MANAGER','Export Diagnosis Data','CATNUM','LH','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(123,'PATIENT_LAB_CSV','MANAGER','Export Lab Data','CATNUM','LH','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(124,'PATIENT_MAPPING_CSV','MANAGER','Export Patient Mapping','CATNUM','LH','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(126,'PATIENT_MAPPING_REQUEST','DATA_LDS','Request Patient Mapping','CATNUM','LR','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest')
;
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


insert into QT_PRIVILEGE(PROTECTION_LABEL_CD,DATAPROT_CD,HIVEMGMT_CD) values ('PDO_WITHOUT_BLOB','DATA_LDS','USER');
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD,DATAPROT_CD,HIVEMGMT_CD) values ('PDO_WITH_BLOB','DATA_DEID','USER');
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD,DATAPROT_CD,HIVEMGMT_CD) values ('SETFINDER_QRY_WITH_DATAOBFSC','DATA_OBFSC','USER');
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD,DATAPROT_CD,HIVEMGMT_CD) values ('SETFINDER_QRY_WITHOUT_DATAOBFSC','DATA_AGG','USER');
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD,DATAPROT_CD,HIVEMGMT_CD) values ('UPLOAD','DATA_OBFSC','MANAGER');
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD,DATAPROT_CD,HIVEMGMT_CD) values ('SETFINDER_QRY_WITH_LGTEXT','DATA_DEID','USER'); 
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD, DATAPROT_CD, HIVEMGMT_CD) values ('SETFINDER_QRY_PROTECTED','DATA_PROT','USER');
;















