/*==============================================================*/
/* Snowflake Script to create CRC query tables                  */
/* (converted from PostgreSQL)                                  */
/*==============================================================*/

/*============================================================================*/
/* Table: QT_QUERY_MASTER                                                     */
/*============================================================================*/
CREATE TABLE QT_QUERY_MASTER (
    QUERY_MASTER_ID     INTEGER AUTOINCREMENT PRIMARY KEY,
    NAME                VARCHAR(250)  NOT NULL,
    USER_ID             VARCHAR(50)   NOT NULL,
    GROUP_ID            VARCHAR(50)   NOT NULL,
    MASTER_TYPE_CD      VARCHAR(2000),
    PLUGIN_ID           INTEGER,
    CREATE_DATE         TIMESTAMP_NTZ NOT NULL,
    DELETE_DATE         TIMESTAMP_NTZ,
    DELETE_FLAG         VARCHAR(3),
    REQUEST_XML         TEXT,
    GENERATED_SQL       TEXT,
    I2B2_REQUEST_XML    TEXT,
    PM_XML              TEXT
);

/*============================================================================*/
/* Table: QT_QUERY_RESULT_TYPE                                                */
/*============================================================================*/
CREATE TABLE QT_QUERY_RESULT_TYPE (
    RESULT_TYPE_ID              INTEGER PRIMARY KEY,
    NAME                        VARCHAR(100),
    DESCRIPTION                 VARCHAR(200),
    DISPLAY_TYPE_ID             VARCHAR(500),
    VISUAL_ATTRIBUTE_TYPE_ID    VARCHAR(3),
    USER_ROLE_CD                VARCHAR(255),
    CLASSNAME                   VARCHAR(200)
);

/*============================================================================*/
/* Table: QT_QUERY_STATUS_TYPE                                                */
/*============================================================================*/
CREATE TABLE QT_QUERY_STATUS_TYPE (
    STATUS_TYPE_ID  INTEGER PRIMARY KEY,
    NAME            VARCHAR(100),
    DESCRIPTION     VARCHAR(200)
);

/*============================================================================*/
/* Table: QT_QUERY_INSTANCE                                                   */
/*============================================================================*/
CREATE TABLE QT_QUERY_INSTANCE (
    QUERY_INSTANCE_ID   INTEGER AUTOINCREMENT PRIMARY KEY,
    QUERY_MASTER_ID     INTEGER,
    USER_ID             VARCHAR(50)   NOT NULL,
    GROUP_ID            VARCHAR(50)   NOT NULL,
    BATCH_MODE          VARCHAR(50),
    START_DATE          TIMESTAMP_NTZ NOT NULL,
    END_DATE            TIMESTAMP_NTZ,
    DELETE_FLAG         VARCHAR(3),
    STATUS_TYPE_ID      INTEGER,
    MESSAGE             TEXT,
    CONSTRAINT QT_FK_QI_MID  FOREIGN KEY (QUERY_MASTER_ID)  REFERENCES QT_QUERY_MASTER (QUERY_MASTER_ID),
    CONSTRAINT QT_FK_QI_STID FOREIGN KEY (STATUS_TYPE_ID)   REFERENCES QT_QUERY_STATUS_TYPE (STATUS_TYPE_ID)
);

/*============================================================================*/
/* Table: QT_QUERY_RESULT_INSTANCE                                            */
/*============================================================================*/
CREATE TABLE QT_QUERY_RESULT_INSTANCE (
    RESULT_INSTANCE_ID  INTEGER AUTOINCREMENT PRIMARY KEY,
    QUERY_INSTANCE_ID   INTEGER,
    RESULT_TYPE_ID      INTEGER       NOT NULL,
    SET_SIZE            INTEGER,
    START_DATE          TIMESTAMP_NTZ NOT NULL,
    END_DATE            TIMESTAMP_NTZ,
    STATUS_TYPE_ID      INTEGER       NOT NULL,
    DELETE_FLAG         VARCHAR(3),
    MESSAGE             TEXT,
    DESCRIPTION         VARCHAR(200),
    REAL_SET_SIZE       INTEGER,
    OBFUSC_METHOD       VARCHAR(500),
    CONSTRAINT QT_FK_QRI_RID  FOREIGN KEY (QUERY_INSTANCE_ID) REFERENCES QT_QUERY_INSTANCE (QUERY_INSTANCE_ID),
    CONSTRAINT QT_FK_QRI_RTID FOREIGN KEY (RESULT_TYPE_ID)    REFERENCES QT_QUERY_RESULT_TYPE (RESULT_TYPE_ID),
    CONSTRAINT QT_FK_QRI_STID FOREIGN KEY (STATUS_TYPE_ID)    REFERENCES QT_QUERY_STATUS_TYPE (STATUS_TYPE_ID)
);

/*============================================================================*/
/* Table: QT_PATIENT_SET_COLLECTION                                           */
/*============================================================================*/
CREATE TABLE QT_PATIENT_SET_COLLECTION (
    PATIENT_SET_COLL_ID INTEGER AUTOINCREMENT PRIMARY KEY,
    RESULT_INSTANCE_ID  INTEGER,
    SET_INDEX           INTEGER,
    PATIENT_NUM         INTEGER,
    CONSTRAINT QT_FK_PSC_RI FOREIGN KEY (RESULT_INSTANCE_ID) REFERENCES QT_QUERY_RESULT_INSTANCE (RESULT_INSTANCE_ID)
);

/*============================================================================*/
/* Table: QT_PATIENT_ENC_COLLECTION                                           */
/*============================================================================*/
CREATE TABLE QT_PATIENT_ENC_COLLECTION (
    PATIENT_ENC_COLL_ID INTEGER AUTOINCREMENT PRIMARY KEY,
    RESULT_INSTANCE_ID  INTEGER,
    SET_INDEX           INTEGER,
    PATIENT_NUM         INTEGER,
    ENCOUNTER_NUM       INTEGER,
    CONSTRAINT QT_FK_PESC_RI FOREIGN KEY (RESULT_INSTANCE_ID) REFERENCES QT_QUERY_RESULT_INSTANCE (RESULT_INSTANCE_ID)
);

/*============================================================================*/
/* Table: QT_XML_RESULT                                                       */
/*============================================================================*/
CREATE TABLE QT_XML_RESULT (
    XML_RESULT_ID       INTEGER AUTOINCREMENT PRIMARY KEY,
    RESULT_INSTANCE_ID  INTEGER,
    XML_VALUE           TEXT,
    CONSTRAINT QT_FK_XMLR_RIID FOREIGN KEY (RESULT_INSTANCE_ID) REFERENCES QT_QUERY_RESULT_INSTANCE (RESULT_INSTANCE_ID)
);

/*============================================================================*/
/* Table: QT_ANALYSIS_PLUGIN                                                  */
/*============================================================================*/
CREATE TABLE QT_ANALYSIS_PLUGIN (
    PLUGIN_ID           INTEGER       NOT NULL,
    PLUGIN_NAME         VARCHAR(2000),
    DESCRIPTION         VARCHAR(2000),
    VERSION_CD          VARCHAR(50),
    PARAMETER_INFO      TEXT,
    PARAMETER_INFO_XSD  TEXT,
    COMMAND_LINE        TEXT,
    WORKING_FOLDER      TEXT,
    COMMANDOPTION_CD    TEXT,
    PLUGIN_ICON         TEXT,
    STATUS_CD           VARCHAR(50),
    USER_ID             VARCHAR(50),
    GROUP_ID            VARCHAR(50),
    CREATE_DATE         TIMESTAMP_NTZ,
    UPDATE_DATE         TIMESTAMP_NTZ,
    CONSTRAINT ANALYSIS_PLUGIN_PK PRIMARY KEY (PLUGIN_ID)
);

/*============================================================================*/
/* Table: QT_ANALYSIS_PLUGIN_RESULT_TYPE                                      */
/*============================================================================*/
CREATE TABLE QT_ANALYSIS_PLUGIN_RESULT_TYPE (
    PLUGIN_ID       INTEGER,
    RESULT_TYPE_ID  INTEGER,
    CONSTRAINT ANALYSIS_PLUGIN_RESULT_PK PRIMARY KEY (PLUGIN_ID, RESULT_TYPE_ID)
);

/*============================================================================*/
/* Table: QT_PRIVILEGE                                                        */
/*============================================================================*/
CREATE TABLE QT_PRIVILEGE (
    PROTECTION_LABEL_CD     VARCHAR(1500) PRIMARY KEY,
    DATAPROT_CD             VARCHAR(1000),
    HIVEMGMT_CD             VARCHAR(1000),
    PLUGIN_ID               INTEGER
);

/*============================================================================*/
/* Table: QT_BREAKDOWN_PATH                                                   */
/*============================================================================*/
CREATE TABLE QT_BREAKDOWN_PATH (
    NAME            VARCHAR(100),
    VALUE           TEXT,
    CREATE_DATE     TIMESTAMP_NTZ,
    UPDATE_DATE     TIMESTAMP_NTZ,
    USER_ID         VARCHAR(50),
    GROUP_ID        VARCHAR(50)
);

/*============================================================================*/
/* Table: QT_PDO_QUERY_MASTER                                                 */
/*============================================================================*/
CREATE TABLE QT_PDO_QUERY_MASTER (
    QUERY_MASTER_ID     INTEGER AUTOINCREMENT PRIMARY KEY,
    USER_ID             VARCHAR(50)   NOT NULL,
    GROUP_ID            VARCHAR(50)   NOT NULL,
    CREATE_DATE         TIMESTAMP_NTZ NOT NULL,
    REQUEST_XML         TEXT,
    I2B2_REQUEST_XML    TEXT
);

/*============================================================================*/
/* Temporary Tables                                                           */
/* Snowflake TEMPORARY tables are session-scoped (auto-drop at session end).  */
/* These are created at runtime by the CRC cell in PostgreSQL — included here */
/* for reference but you may not need them if Snowflake is reporting-only.    */
/*============================================================================*/
CREATE TEMPORARY TABLE DX (
    ENCOUNTER_NUM       INTEGER,
    PATIENT_NUM         INTEGER,
    INSTANCE_NUM        INTEGER,
    CONCEPT_CD          VARCHAR(50),
    START_DATE          TIMESTAMP_NTZ,
    PROVIDER_ID         VARCHAR(50),
    TEMPORAL_START_DATE TIMESTAMP_NTZ,
    TEMPORAL_END_DATE   TIMESTAMP_NTZ
);

CREATE TEMPORARY TABLE TEMP_PDO_INPUTLIST (
    CHAR_PARAM1         VARCHAR(100)
);

CREATE TEMPORARY TABLE QUERY_GLOBAL_TEMP (
    ENCOUNTER_NUM       INTEGER,
    PATIENT_NUM         INTEGER,
    INSTANCE_NUM        INTEGER,
    CONCEPT_CD          VARCHAR(50),
    START_DATE          DATE,
    PROVIDER_ID         VARCHAR(50),
    PANEL_COUNT         INTEGER,
    FACT_COUNT          INTEGER,
    FACT_PANELS         INTEGER
);

CREATE TEMPORARY TABLE GLOBAL_TEMP_PARAM_TABLE (
    SET_INDEX           INTEGER,
    CHAR_PARAM1         VARCHAR(500),
    CHAR_PARAM2         VARCHAR(500),
    NUM_PARAM1          INTEGER,
    NUM_PARAM2          INTEGER
);

CREATE TEMPORARY TABLE GLOBAL_TEMP_FACT_PARAM_TABLE (
    SET_INDEX           INTEGER,
    CHAR_PARAM1         VARCHAR(500),
    CHAR_PARAM2         VARCHAR(500),
    NUM_PARAM1          INTEGER,
    NUM_PARAM2          INTEGER
);

CREATE TEMPORARY TABLE MASTER_QUERY_GLOBAL_TEMP (
    ENCOUNTER_NUM       INTEGER,
    PATIENT_NUM         INTEGER,
    INSTANCE_NUM        INTEGER,
    CONCEPT_CD          VARCHAR(50),
    START_DATE          DATE,
    PROVIDER_ID         VARCHAR(50),
    MASTER_ID           VARCHAR(50),
    LEVEL_NO            INTEGER,
    TEMPORAL_START_DATE DATE,
    TEMPORAL_END_DATE   DATE
);

/*============================================================================*/
/* SEED DATA                                                                  */
/*============================================================================*/
INSERT INTO QT_QUERY_STATUS_TYPE (STATUS_TYPE_ID, NAME, DESCRIPTION) VALUES
    (1,  'QUEUED',       'WAITING IN QUEUE TO START PROCESS'),
    (2,  'PROCESSING',   'PROCESSING'),
    (3,  'FINISHED',     'FINISHED'),
    (4,  'ERROR',        'ERROR'),
    (5,  'INCOMPLETE',   'INCOMPLETE'),
    (6,  'COMPLETED',    'COMPLETED'),
    (7,  'MEDIUM_QUEUE', 'MEDIUM QUEUE'),
    (8,  'LARGE_QUEUE',  'LARGE QUEUE'),
    (9,  'CANCELLED',    'CANCELLED'),
    (10, 'TIMEDOUT',     'TIMEDOUT');

INSERT INTO QT_QUERY_RESULT_TYPE (RESULT_TYPE_ID, NAME, USER_ROLE_CD, DESCRIPTION, DISPLAY_TYPE_ID, VISUAL_ATTRIBUTE_TYPE_ID, CLASSNAME) VALUES
    (1,   'PATIENTSET',                    NULL,       'Patient set',                    'LIST',   'LA', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSetGenerator'),
    (2,   'PATIENT_ENCOUNTER_SET',         NULL,       'Encounter set',                  'LIST',   'LA', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultEncounterSetGenerator'),
    (3,   'XML',                           NULL,       'Generic query result',           'CATNUM', 'LH', NULL),
    (4,   'PATIENT_COUNT_XML',             NULL,       'Number of patients',             'CATNUM', 'LA', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientCountGenerator'),
    (5,   'PATIENT_GENDER_COUNT_XML',      NULL,       'Gender patient breakdown',       'CATNUM', 'LA', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator'),
    (6,   'PATIENT_VITALSTATUS_COUNT_XML', NULL,       'Vital Status patient breakdown', 'CATNUM', 'LA', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator'),
    (7,   'PATIENT_RACE_COUNT_XML',        NULL,       'Race patient breakdown',         'CATNUM', 'LA', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator'),
    (8,   'PATIENT_AGE_COUNT_XML',         NULL,       'Age patient breakdown',          'CATNUM', 'LA', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator'),
    (10,  'PATIENT_LOS_XML',              'DATA_LDS',  'Length of stay breakdown',       'CATNUM', 'LA', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator'),
    (11,  'PATIENT_TOP20MEDS_XML',        'DATA_LDS',  'Top 20 medications breakdown',  'CATNUM', 'LA', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator'),
    (12,  'PATIENT_TOP20DIAG_XML',        'DATA_LDS',  'Top 20 diagnoses breakdown',    'CATNUM', 'LA', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator'),
    (13,  'PATIENT_INOUT_XML',            'DATA_LDS',  'Inpatient and outpatient breakdown', 'CATNUM', 'LA', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator'),
    (114, 'PATIENT_DEMOGRAPHIC_REQUEST',  'DATA_LDS',  'Request Demographics Data',     'CATNUM', 'LR', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest'),
    (115, 'PATIENT_MEDICATION_REQUEST',   'DATA_LDS',  'Request Medication Data',       'CATNUM', 'LR', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest'),
    (116, 'PATIENT_PROCEDURE_REQUEST',    'DATA_LDS',  'Request Procedure Data',        'CATNUM', 'LR', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest'),
    (117, 'PATIENT_DIAGNOSIS_REQUEST',    'DATA_LDS',  'Request Diagnosis Data',        'CATNUM', 'LR', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest'),
    (118, 'PATIENT_LAB_REQUEST',          'DATA_LDS',  'Request Lab Data',              'CATNUM', 'LR', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest'),
    (119, 'PATIENT_DEMOGRAPHIC_CSV',      'MANAGER',   'Export Demographics Data',      'CATNUM', 'LH', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload'),
    (120, 'PATIENT_MEDICATION_CSV',       'MANAGER',   'Export Medication Data',        'CATNUM', 'LH', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload'),
    (121, 'PATIENT_PROCEDURE_CSV',        'MANAGER',   'Export Procedure Data',         'CATNUM', 'LH', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload'),
    (122, 'PATIENT_DIAGNOSIS_CSV',        'MANAGER',   'Export Diagnosis Data',         'CATNUM', 'LH', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload'),
    (123, 'PATIENT_LAB_CSV',              'MANAGER',   'Export Lab Data',               'CATNUM', 'LH', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload'),
    (124, 'PATIENT_MAPPING_CSV',          'MANAGER',   'Export Patient Mapping',        'CATNUM', 'LH', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload'),
    (126, 'PATIENT_MAPPING_REQUEST',      'DATA_LDS',  'Request Patient Mapping',      'CATNUM', 'LR', 'edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest');

INSERT INTO QT_PRIVILEGE (PROTECTION_LABEL_CD, DATAPROT_CD, HIVEMGMT_CD) VALUES
    ('PDO_WITHOUT_BLOB',                    'DATA_LDS',  'USER'),
    ('PDO_WITH_BLOB',                       'DATA_DEID', 'USER'),
    ('SETFINDER_QRY_WITH_DATAOBFSC',        'DATA_OBFSC','USER'),
    ('SETFINDER_QRY_WITHOUT_DATAOBFSC',     'DATA_AGG',  'USER'),
    ('UPLOAD',                              'DATA_OBFSC','MANAGER'),
    ('SETFINDER_QRY_WITH_LGTEXT',           'DATA_DEID', 'USER'),
    ('SETFINDER_QRY_PROTECTED',             'DATA_PROT', 'USER');