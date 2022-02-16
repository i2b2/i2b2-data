/*==============================================================*/
/* SNOWFLAKE Database Script to create CRC query tables         */
/*         MD SABER HOSSAIN	7/14/2023							*/
/*         University of Missouri-Columbia						*
/*==============================================================*/


/*============================================================================*/
/* Table: QT_QUERY_MASTER 											          */
/*============================================================================*/
CREATE OR REPLACE SEQUENCE SEQ_QT_QUERY_MASTER START = 1 INCREMENT = 1; 
CREATE OR REPLACE TABLE QT_QUERY_MASTER (
	QUERY_MASTER_ID		NUMBER(38, 0) NOT NULL DEFAULT SEQ_QT_QUERY_MASTER.NEXTVAL PRIMARY KEY,
	NAME				VARCHAR(250) NOT NULL,
	USER_ID				VARCHAR(50) NOT NULL,
	GROUP_ID			VARCHAR(50) NOT NULL,
	MASTER_TYPE_CD		VARCHAR(2000),
	PLUGIN_ID			INT,
	CREATE_DATE			TIMESTAMP NOT NULL,
	DELETE_DATE			TIMESTAMP,
	DELETE_FLAG			VARCHAR(3),
	REQUEST_XML			TEXT,
	GENERATED_SQL		TEXT,
	I2B2_REQUEST_XML	TEXT,
	PM_XML				TEXT
)
;


/*============================================================================*/
/* Table: QT_QUERY_RESULT_TYPE										          */
/*============================================================================*/
CREATE OR REPLACE TABLE QT_QUERY_RESULT_TYPE (
	RESULT_TYPE_ID				INT   PRIMARY KEY,
	NAME						VARCHAR(100),
	DESCRIPTION					VARCHAR(200),
	DISPLAY_TYPE_ID				VARCHAR(500),
	VISUAL_ATTRIBUTE_TYPE_ID	VARCHAR(3),
	USER_ROLE_CD 				VARCHAR(255),
	CLASSNAME					VARCHAR(200)
)
;


/*============================================================================*/
/* Table: QT_QUERY_STATUS_TYPE										          */
/*============================================================================*/
CREATE OR REPLACE TABLE QT_QUERY_STATUS_TYPE (
	STATUS_TYPE_ID	INT   PRIMARY KEY,
	NAME			VARCHAR(100),
	DESCRIPTION		VARCHAR(200)
)
;


/*============================================================================*/
/* Table: QT_QUERY_INSTANCE 										          */
/*============================================================================*/
CREATE OR REPLACE SEQUENCE SEQ_QT_QUERY_INSTANCE START = 1 INCREMENT = 1; 
CREATE OR REPLACE TABLE QT_QUERY_INSTANCE (
	QUERY_INSTANCE_ID	NUMBER(38, 0) NOT NULL DEFAULT SEQ_QT_QUERY_INSTANCE.NEXTVAL PRIMARY KEY,
	QUERY_MASTER_ID		INT,
	USER_ID				VARCHAR(50) NOT NULL,
	GROUP_ID			VARCHAR(50) NOT NULL,
	BATCH_MODE			VARCHAR(50),
	START_DATE			TIMESTAMP NOT NULL,
	END_DATE			TIMESTAMP,
	DELETE_FLAG			VARCHAR(3),
	STATUS_TYPE_ID		INT,
	MESSAGE				TEXT
)
;


/*=============================================================================*/
/* Table: QT_QUERY_RESULT_INSTANCE   								          */
/*============================================================================*/
CREATE OR REPLACE SEQUENCE SEQ_QT_QUERY_RESULT_INSTANCE START = 1 INCREMENT = 1; 
CREATE OR REPLACE TABLE QT_QUERY_RESULT_INSTANCE (
	RESULT_INSTANCE_ID	NUMBER(38, 0) NOT NULL DEFAULT SEQ_QT_QUERY_RESULT_INSTANCE.NEXTVAL PRIMARY KEY,
	QUERY_INSTANCE_ID	INT,
	RESULT_TYPE_ID		INT NOT NULL,
	SET_SIZE			INT,
	START_DATE			TIMESTAMP NOT NULL,
	END_DATE			TIMESTAMP,
	STATUS_TYPE_ID		INT NOT NULL,
	DELETE_FLAG			VARCHAR(3),
	MESSAGE				TEXT,
	DESCRIPTION			VARCHAR(200),
	REAL_SET_SIZE		INT,
	OBFUSC_METHOD		VARCHAR(500)
)
;


/*============================================================================*/
/* Table: QT_PATIENT_SET_COLLECTION									          */
/*============================================================================*/
CREATE OR REPLACE SEQUENCE SEQ_QT_PATIENT_SET_COLLECTION START = 1 INCREMENT = 1; 
CREATE OR REPLACE TABLE QT_PATIENT_SET_COLLECTION ( 
	PATIENT_SET_COLL_ID	NUMBER(38, 0) NOT NULL DEFAULT SEQ_QT_PATIENT_SET_COLLECTION.NEXTVAL PRIMARY KEY,
	RESULT_INSTANCE_ID	INT,
	SET_INDEX			INT,
	PATIENT_NUM			INT
)
;



/*============================================================================*/
/* Table: QT_PATIENT_ENC_COLLECTION									          */
/*============================================================================*/
CREATE OR REPLACE SEQUENCE SEQ_QT_PATIENT_ENC_COLLECTION START = 1 INCREMENT = 1; 
CREATE OR REPLACE TABLE QT_PATIENT_ENC_COLLECTION (
	PATIENT_ENC_COLL_ID	NUMBER(38, 0) NOT NULL DEFAULT SEQ_QT_PATIENT_ENC_COLLECTION.NEXTVAL PRIMARY KEY,
	RESULT_INSTANCE_ID	INT,
	SET_INDEX			INT,
	PATIENT_NUM			INT,
	ENCOUNTER_NUM		INT
)
;


/*============================================================================*/
/* Table: QT_XML_RESULT												          */
/*============================================================================*/
CREATE OR REPLACE SEQUENCE SEQ_QT_XML_RESULT START = 1 INCREMENT = 1; 
CREATE OR REPLACE TABLE QT_XML_RESULT (
	XML_RESULT_ID		NUMBER(38, 0) NOT NULL DEFAULT SEQ_QT_PATIENT_ENC_COLLECTION.NEXTVAL PRIMARY KEY,
	RESULT_INSTANCE_ID	INT,
	XML_VALUE			TEXT
)
;


/*============================================================================*/
/* Table: QT_ANALYSIS_PLUGIN										          */
/*============================================================================*/
CREATE OR REPLACE TABLE QT_ANALYSIS_PLUGIN (
	PLUGIN_ID			INT NOT NULL,
	PLUGIN_NAME			VARCHAR(2000),
	DESCRIPTION			VARCHAR(2000),
	VERSION_CD			VARCHAR(50),	--support for version
	PARAMETER_INFO		TEXT,			-- plugin parameter stored as xml
	PARAMETER_INFO_XSD	TEXT,
	COMMAND_LINE		TEXT,
	WORKING_FOLDER		TEXT,
	COMMANDOPTION_CD	TEXT,
	PLUGIN_ICON         TEXT,
	STATUS_CD			VARCHAR(50),	-- active,deleted,..
	USER_ID				VARCHAR(50),
	GROUP_ID			VARCHAR(50),
	CREATE_DATE			TIMESTAMP,
	UPDATE_DATE			TIMESTAMP
)
;


/*============================================================================*/
/* Table: QT_ANALYSIS_PLUGIN_RESULT_TYPE							          */
/*============================================================================*/
CREATE OR REPLACE TABLE QT_ANALYSIS_PLUGIN_RESULT_TYPE (
	PLUGIN_ID		INT,
	RESULT_TYPE_ID	INT,
	CONSTRAINT ANALYSIS_PLUGIN_RESULT_PK PRIMARY KEY(PLUGIN_ID,RESULT_TYPE_ID)
)
;


/*============================================================================*/
/* Table: QT_PRIVILEGE												          */
/*============================================================================*/
CREATE OR REPLACE TABLE QT_PRIVILEGE(
	PROTECTION_LABEL_CD		VARCHAR(1500) PRIMARY KEY,
	DATAPROT_CD				VARCHAR(1000),
	HIVEMGMT_CD				VARCHAR(1000),
	PLUGIN_ID				INT
)
;


/*============================================================================*/
/* Table: QT_BREAKDOWN_PATH											          */
/*============================================================================*/
CREATE OR REPLACE TABLE QT_BREAKDOWN_PATH (
	NAME			VARCHAR(100), 
	VALUE			VARCHAR(2000), 
	CREATE_DATE		TIMESTAMP,
	UPDATE_DATE		TIMESTAMP,
	USER_ID			VARCHAR(50)
)
;


/*============================================================================*/
/* Table:QT_PDO_QUERY_MASTER 										          */
/*============================================================================*/
CREATE OR REPLACE SEQUENCE SEQ_QT_PDO_QUERY_MASTER START = 1 INCREMENT = 1; 
CREATE OR REPLACE TABLE QT_PDO_QUERY_MASTER (
	QUERY_MASTER_ID		NUMBER(38, 0) NOT NULL DEFAULT SEQ_QT_PDO_QUERY_MASTER.NEXTVAL PRIMARY KEY,
	USER_ID				VARCHAR(50) NOT NULL,
	GROUP_ID			VARCHAR(50) NOT NULL,
	CREATE_DATE			TIMESTAMP NOT NULL,
	REQUEST_XML			TEXT,
	I2B2_REQUEST_XML	TEXT
)
;



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
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(4,'PATIENT_COUNT_XML','Number of patients','CATNUM','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientCountGenerator')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(5,'PATIENT_GPCSITE_COUNT_XML','GPC Site breakdown','CATNUM','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(6,'PATIENT_GENDER_COUNT_XML','Gender patient breakdown','CATNUM','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(7,'PATIENT_VITALSTATUS_COUNT_XML','Vital Status patient breakdown','CATNUM','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(8,'PATIENT_RACE_COUNT_XML','Race patient breakdown','CATNUM','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(9,'PATIENT_AGE_COUNT_XML','Age patient breakdown','CATNUM','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(10,'PATIENTSET','Timeline','LIST','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSetGenerator')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(10,'PATIENT_LOS_XML','DATA_LDS','Length of stay breakdown','CATNUM','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(11,'PATIENT_TOP20MEDS_XML','DATA_LDS','Top 20 medications breakdown','CATNUM','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(12,'PATIENT_TOP20DIAG_XML','DATA_LDS','Top 20 diagnoses breakdown','CATNUM','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(13,'PATIENT_INOUT_XML','DATA_LDS','Inpatient and outpatient breakdown','CATNUM','LA','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator')
;



insert into QT_PRIVILEGE(PROTECTION_LABEL_CD,DATAPROT_CD,HIVEMGMT_CD) values ('PDO_WITHOUT_BLOB','DATA_LDS','USER');
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD,DATAPROT_CD,HIVEMGMT_CD) values ('PDO_WITH_BLOB','DATA_DEID','USER');
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD,DATAPROT_CD,HIVEMGMT_CD) values ('SETFINDER_QRY_WITH_DATAOBFSC','DATA_OBFSC','USER');
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD,DATAPROT_CD,HIVEMGMT_CD) values ('SETFINDER_QRY_WITHOUT_DATAOBFSC','DATA_AGG','USER');
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD,DATAPROT_CD,HIVEMGMT_CD) values ('UPLOAD','DATA_OBFSC','MANAGER');
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD,DATAPROT_CD,HIVEMGMT_CD) values ('SETFINDER_QRY_WITH_LGTEXT','DATA_DEID','USER'); 
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD, DATAPROT_CD, HIVEMGMT_CD) values ('SETFINDER_QRY_PROTECTED','DATA_PROT','USER');





--INSERT INTO QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE) VALUES ('PATIENT_GPCSITE_COUNT_XML','\\\\ACT_DEMO\\ACT\\Demographics\\GPC Sites\\', CURRENT_TIMESTAMP);
INSERT INTO QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE) VALUES ('PATIENT_GENDER_COUNT_XML','\\\\ACT_DEMO\\ACT\\Demographics\\Sex\\', CURRENT_TIMESTAMP);
INSERT INTO QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE) VALUES ('PATIENT_RACE_COUNT_XML','\\\\ACT_DEMO\\ACT\\Demographics\\Race\\', CURRENT_TIMESTAMP);
INSERT INTO QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE) VALUES ('PATIENT_VITALSTATUS_COUNT_XML','\\\\ACT_DEMO\\ACT\\Demographics\\Vital Status\\',CURRENT_TIMESTAMP);
INSERT INTO QT_BREAKDOWN_PATH(NAME,VALUE,CREATE_DATE) VALUES ('PATIENT_AGE_COUNT_XML','\\\\ACT_DEMO\\ACT\\Demographics\\Age\\', CURRENT_TIMESTAMP);
INSERT INTO qt_breakdown_path (name, value, create_date) VALUES ('PATIENT_LOS_XML','select length_of_stay as patient_range, count(distinct a.PATIENT_num) as patient_count from visit_dimension a, DX b where a.patient_num = b.patient_num group by a.length_of_stay order by 1', CURRENT_TIMESTAMP);
INSERT INTO qt_breakdown_path (name, value, create_date) VALUES ('PATIENT_TOP20MEDS_XML','select b.name_char as patient_range, count(distinct a.patient_num) as patient_count from prescribing_fact a, concept_dimension b, DX c where a.concept_cd = b.concept_cd and concept_path like ''\\\\ACT\\\\Medications\\\\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc limit 20', CURRENT_TIMESTAMP);
INSERT INTO qt_breakdown_path (name, value, create_date) VALUES ('PATIENT_TOP20DIAG_XML','select b.name_char as patient_range, count(distinct a.patient_num) as patient_count from diagnosis_fact a, concept_dimension b, DX c where a.concept_cd = b.concept_cd and concept_path like ''\\\\ACT\\\\Diagnosis\\\\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc limit 20', CURRENT_TIMESTAMP);
INSERT INTO qt_breakdown_path  (name, value, create_date) VALUES ('PATIENT_INOUT_XML','select INOUT_CD as patient_range, count(distinct a.patient_num) as patient_count from visit_dimension a, DX b where a.patient_num = b.patient_num group by a.INOUT_CD order by 1', CURRENT_TIMESTAMP);














