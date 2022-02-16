/*********************************************************
*         Snowflake SCRIPT TO CREATE CRC DATA TABLES
*         (converted from PostgreSQL)
**********************************************************/

-------------------------------------------------------------------------------------------
-- ENCOUNTER_MAPPING
-------------------------------------------------------------------------------------------
CREATE TABLE ENCOUNTER_MAPPING (
    ENCOUNTER_IDE           VARCHAR(200)  NOT NULL,
    ENCOUNTER_IDE_SOURCE    VARCHAR(50)   NOT NULL,
    PROJECT_ID              VARCHAR(50)   NOT NULL,
    ENCOUNTER_NUM           INTEGER       NOT NULL,
    PATIENT_IDE             VARCHAR(200)  NOT NULL,
    PATIENT_IDE_SOURCE      VARCHAR(50)   NOT NULL,
    ENCOUNTER_IDE_STATUS    VARCHAR(50)   NULL,
    UPLOAD_DATE             DATE NULL,
    UPDATE_DATE             TIMESTAMP_NTZ NULL,
    DOWNLOAD_DATE           TIMESTAMP_NTZ NULL,
    IMPORT_DATE             TIMESTAMP_NTZ NULL,
    SOURCESYSTEM_CD         VARCHAR(50)   NULL,
    UPLOAD_ID               INTEGER       NULL,
    CONSTRAINT ENCOUNTER_MAPPING_PK PRIMARY KEY (ENCOUNTER_IDE, ENCOUNTER_IDE_SOURCE, PROJECT_ID, PATIENT_IDE, PATIENT_IDE_SOURCE)
);

-------------------------------------------------------------------------------------------
-- PATIENT_MAPPING
-------------------------------------------------------------------------------------------
CREATE TABLE PATIENT_MAPPING (
    PATIENT_IDE             VARCHAR(200)  NOT NULL,
    PATIENT_IDE_SOURCE      VARCHAR(50)   NOT NULL,
    PATIENT_NUM             INTEGER       NOT NULL,
    PATIENT_IDE_STATUS      VARCHAR(50)   NULL,
    PROJECT_ID              VARCHAR(50)   NOT NULL,
    UPLOAD_DATE             TIMESTAMP_NTZ NULL,
    UPDATE_DATE             TIMESTAMP_NTZ NULL,
    DOWNLOAD_DATE           TIMESTAMP_NTZ NULL,
    IMPORT_DATE             TIMESTAMP_NTZ NULL,
    SOURCESYSTEM_CD         VARCHAR(50)   NULL,
    UPLOAD_ID               INTEGER       NULL,
    CONSTRAINT PATIENT_MAPPING_PK PRIMARY KEY (PATIENT_IDE, PATIENT_IDE_SOURCE, PROJECT_ID)
);

-------------------------------------------------------------------------------------------
-- CODE_LOOKUP
-------------------------------------------------------------------------------------------
CREATE TABLE CODE_LOOKUP (
    TABLE_CD                VARCHAR(100)  NOT NULL,
    COLUMN_CD               VARCHAR(100)  NOT NULL,
    CODE_CD                 VARCHAR(50)   NOT NULL,
    NAME_CHAR               VARCHAR(650)  NULL,
    LOOKUP_BLOB             TEXT          NULL,
    UPLOAD_DATE             TIMESTAMP_NTZ NULL,
    UPDATE_DATE             TIMESTAMP_NTZ NULL,
    DOWNLOAD_DATE           TIMESTAMP_NTZ NULL,
    IMPORT_DATE             TIMESTAMP_NTZ NULL,
    SOURCESYSTEM_CD         VARCHAR(50)   NULL,
    UPLOAD_ID               INTEGER       NULL,
    CONSTRAINT CODE_LOOKUP_PK PRIMARY KEY (TABLE_CD, COLUMN_CD, CODE_CD)
);

-------------------------------------------------------------------------------------------
-- CONCEPT_DIMENSION
-------------------------------------------------------------------------------------------
CREATE TABLE CONCEPT_DIMENSION (
    CONCEPT_PATH            VARCHAR(700)  NOT NULL,
    CONCEPT_CD              VARCHAR(50)   NULL,
    NAME_CHAR               VARCHAR(2000) NULL,
    CONCEPT_BLOB            TEXT          NULL,
    UPDATE_DATE             TIMESTAMP_NTZ NULL,
    DOWNLOAD_DATE           TIMESTAMP_NTZ NULL,
    IMPORT_DATE             TIMESTAMP_NTZ NULL,
    SOURCESYSTEM_CD         VARCHAR(50)   NULL,
    UPLOAD_ID               INTEGER       NULL,
    CONSTRAINT CONCEPT_DIMENSION_PK PRIMARY KEY (CONCEPT_PATH)
);

-------------------------------------------------------------------------------------------
-- OBSERVATION_FACT
-------------------------------------------------------------------------------------------
CREATE TABLE OBSERVATION_FACT (
    ENCOUNTER_NUM           INTEGER           NOT NULL,
    PATIENT_NUM             INTEGER           NOT NULL,
    CONCEPT_CD              VARCHAR(50)       NOT NULL,
    PROVIDER_ID             VARCHAR(50)       NOT NULL,
    START_DATE              TIMESTAMP_NTZ     NOT NULL,
    MODIFIER_CD             VARCHAR(100)      DEFAULT '@' NOT NULL,
    INSTANCE_NUM            INTEGER           DEFAULT 1  NOT NULL,
    VALTYPE_CD              VARCHAR(50)       NULL,
    TVAL_CHAR               VARCHAR(255)      NULL,
    NVAL_NUM                DECIMAL(18,5)     NULL,
    VALUEFLAG_CD            VARCHAR(50)       NULL,
    QUANTITY_NUM            DECIMAL(18,5)     NULL,
    UNITS_CD                VARCHAR(50)       NULL,
    END_DATE                TIMESTAMP_NTZ     NULL,
    LOCATION_CD             VARCHAR(50)       NULL,
    OBSERVATION_BLOB        TEXT              NULL,
    CONFIDENCE_NUM          DECIMAL(18,5)     NULL,
    UPDATE_DATE             TIMESTAMP_NTZ     NULL,
    DOWNLOAD_DATE           TIMESTAMP_NTZ     NULL,
    IMPORT_DATE             TIMESTAMP_NTZ     NULL,
    SOURCESYSTEM_CD         VARCHAR(50)       NULL,
    UPLOAD_ID               INTEGER           NULL,
    TEXT_SEARCH_INDEX        INTEGER AUTOINCREMENT,
    CONSTRAINT OBSERVATION_FACT_PK PRIMARY KEY (PATIENT_NUM, CONCEPT_CD, MODIFIER_CD, START_DATE, ENCOUNTER_NUM, INSTANCE_NUM, PROVIDER_ID)
);

-------------------------------------------------------------------------------------------
-- PATIENT_DIMENSION
-------------------------------------------------------------------------------------------
CREATE TABLE PATIENT_DIMENSION (
    PATIENT_NUM             INTEGER       NOT NULL,
    VITAL_STATUS_CD         VARCHAR(50)   NULL,
    BIRTH_DATE              TIMESTAMP_NTZ NULL,
    DEATH_DATE              TIMESTAMP_NTZ NULL,
    SEX_CD                  VARCHAR(50)   NULL,
    AGE_IN_YEARS_NUM        INTEGER       NULL,
    LANGUAGE_CD             VARCHAR(50)   NULL,
    RACE_CD                 VARCHAR(50)   NULL,
    MARITAL_STATUS_CD       VARCHAR(50)   NULL,
    RELIGION_CD             VARCHAR(50)   NULL,
    ZIP_CD                  VARCHAR(10)   NULL,
    STATECITYZIP_PATH       VARCHAR(700)  NULL,
    INCOME_CD               VARCHAR(50)   NULL,
    PATIENT_BLOB            TEXT          NULL,
    UPDATE_DATE             TIMESTAMP_NTZ NULL,
    DOWNLOAD_DATE           TIMESTAMP_NTZ NULL,
    IMPORT_DATE             TIMESTAMP_NTZ NULL,
    SOURCESYSTEM_CD         VARCHAR(50)   NULL,
    UPLOAD_ID               INTEGER       NULL,
    CONSTRAINT PATIENT_DIMENSION_PK PRIMARY KEY (PATIENT_NUM)
);

-------------------------------------------------------------------------------------------
-- PROVIDER_DIMENSION
-------------------------------------------------------------------------------------------
CREATE TABLE PROVIDER_DIMENSION (
    PROVIDER_ID             VARCHAR(50)   NOT NULL,
    PROVIDER_PATH           VARCHAR(700)  NOT NULL,
    NAME_CHAR               VARCHAR(850)  NULL,
    PROVIDER_BLOB           TEXT          NULL,
    UPDATE_DATE             TIMESTAMP_NTZ NULL,
    DOWNLOAD_DATE           TIMESTAMP_NTZ NULL,
    IMPORT_DATE             TIMESTAMP_NTZ NULL,
    SOURCESYSTEM_CD         VARCHAR(50)   NULL,
    UPLOAD_ID               INTEGER       NULL,
    CONSTRAINT PROVIDER_DIMENSION_PK PRIMARY KEY (PROVIDER_PATH, PROVIDER_ID)
);

-------------------------------------------------------------------------------------------
-- VISIT_DIMENSION
-------------------------------------------------------------------------------------------
CREATE TABLE VISIT_DIMENSION (
    ENCOUNTER_NUM           INTEGER       NOT NULL,
    PATIENT_NUM             INTEGER       NOT NULL,
    ACTIVE_STATUS_CD        VARCHAR(50)   NULL,
    START_DATE              TIMESTAMP_NTZ NULL,
    END_DATE                TIMESTAMP_NTZ NULL,
    INOUT_CD                VARCHAR(50)   NULL,
    LOCATION_CD             VARCHAR(50)   NULL,
    LOCATION_PATH           VARCHAR(900)  NULL,
    LENGTH_OF_STAY          INTEGER       NULL,
    VISIT_BLOB              TEXT          NULL,
    UPDATE_DATE             TIMESTAMP_NTZ NULL,
    DOWNLOAD_DATE           TIMESTAMP_NTZ NULL,
    IMPORT_DATE             TIMESTAMP_NTZ NULL,
    SOURCESYSTEM_CD         VARCHAR(50)   NULL,
    UPLOAD_ID               INTEGER       NULL,
    CONSTRAINT VISIT_DIMENSION_PK PRIMARY KEY (ENCOUNTER_NUM, PATIENT_NUM)
);

-------------------------------------------------------------------------------------------
-- MODIFIER_DIMENSION
-------------------------------------------------------------------------------------------
CREATE TABLE MODIFIER_DIMENSION (
    MODIFIER_PATH           VARCHAR(700)  NOT NULL,
    MODIFIER_CD             VARCHAR(50)   NULL,
    NAME_CHAR               VARCHAR(2000) NULL,
    MODIFIER_BLOB           TEXT          NULL,
    UPDATE_DATE             TIMESTAMP_NTZ NULL,
    DOWNLOAD_DATE           TIMESTAMP_NTZ NULL,
    IMPORT_DATE             TIMESTAMP_NTZ NULL,
    SOURCESYSTEM_CD         VARCHAR(50)   NULL,
    UPLOAD_ID               INTEGER       NULL,
    CONSTRAINT MODIFIER_DIMENSION_PK PRIMARY KEY (MODIFIER_PATH)
);