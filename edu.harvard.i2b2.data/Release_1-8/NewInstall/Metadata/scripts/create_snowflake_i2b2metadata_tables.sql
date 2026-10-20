/*********************************************************
*       SNOWFLAKE SCRIPT TO CREATE ONT CELL TABLES
*       MD SABER HOSSAIN	7/14/2023
*		University of Missouri-Columbia
**********************************************************/
--------------------------------------------------------
--  DDL for Table I2B2
--------------------------------------------------------
CREATE TABLE I2B2 (
    C_HLEVEL            INTEGER         NOT NULL,
    C_FULLNAME          VARCHAR(700)    NOT NULL,
    C_NAME              VARCHAR(2000)   NOT NULL,
    C_SYNONYM_CD        CHAR(1)         NOT NULL,
    C_VISUALATTRIBUTES  CHAR(3)         NOT NULL,
    C_TOTALNUM          INTEGER         NULL,
    C_BASECODE          VARCHAR(50)     NULL,
    C_METADATAXML       TEXT            NULL,
    C_FACTTABLECOLUMN   VARCHAR(50)     NOT NULL,
    C_TABLENAME         VARCHAR(50)     NOT NULL,
    C_COLUMNNAME        VARCHAR(50)     NOT NULL,
    C_COLUMNDATATYPE    VARCHAR(50)     NOT NULL,
    C_OPERATOR          VARCHAR(10)     NOT NULL,
    C_DIMCODE           VARCHAR(700)    NOT NULL,
    C_COMMENT           TEXT            NULL,
    C_TOOLTIP           VARCHAR(900)    NULL,
    M_APPLIED_PATH      VARCHAR(700)    NOT NULL,
    UPDATE_DATE         TIMESTAMP_NTZ   NOT NULL,
    DOWNLOAD_DATE       TIMESTAMP_NTZ   NULL,
    IMPORT_DATE         TIMESTAMP_NTZ   NULL,
    SOURCESYSTEM_CD     VARCHAR(50)     NULL,
    VALUETYPE_CD        VARCHAR(50)     NULL,
    M_EXCLUSION_CD      VARCHAR(25)     NULL,
    C_PATH              VARCHAR(700)    NULL,
    C_SYMBOL            VARCHAR(50)     NULL
);

--------------------------------------------------------
--  DDL for Table BIRN
--------------------------------------------------------
CREATE TABLE BIRN (
    C_HLEVEL            INTEGER         NOT NULL,
    C_FULLNAME          VARCHAR(700)    NOT NULL,
    C_NAME              VARCHAR(2000)   NOT NULL,
    C_SYNONYM_CD        CHAR(1)         NOT NULL,
    C_VISUALATTRIBUTES  CHAR(3)         NOT NULL,
    C_TOTALNUM          INTEGER         NULL,
    C_BASECODE          VARCHAR(50)     NULL,
    C_METADATAXML       TEXT            NULL,
    C_FACTTABLECOLUMN   VARCHAR(50)     NOT NULL,
    C_TABLENAME         VARCHAR(50)     NOT NULL,
    C_COLUMNNAME        VARCHAR(50)     NOT NULL,
    C_COLUMNDATATYPE    VARCHAR(50)     NOT NULL,
    C_OPERATOR          VARCHAR(10)     NOT NULL,
    C_DIMCODE           VARCHAR(700)    NOT NULL,
    C_COMMENT           TEXT            NULL,
    C_TOOLTIP           VARCHAR(900)    NULL,
    M_APPLIED_PATH      VARCHAR(700)    NOT NULL,
    UPDATE_DATE         TIMESTAMP_NTZ   NOT NULL,
    DOWNLOAD_DATE       TIMESTAMP_NTZ   NULL,
    IMPORT_DATE         TIMESTAMP_NTZ   NULL,
    SOURCESYSTEM_CD     VARCHAR(50)     NULL,
    VALUETYPE_CD        VARCHAR(50)     NULL,
    M_EXCLUSION_CD      VARCHAR(25)     NULL,
    C_PATH              VARCHAR(700)    NULL,
    C_SYMBOL            VARCHAR(50)     NULL
);

--------------------------------------------------------
--  DDL for Table SCHEMES
--------------------------------------------------------
CREATE TABLE SCHEMES (
    C_KEY               VARCHAR(50)     NOT NULL,
    C_NAME              VARCHAR(50)     NOT NULL,
    C_DESCRIPTION       VARCHAR(100)    NULL,
    CONSTRAINT SCHEMES_PK PRIMARY KEY (C_KEY)
);

--------------------------------------------------------
--  DDL for Table TABLE_ACCESS
--------------------------------------------------------
CREATE TABLE TABLE_ACCESS (
    C_TABLE_CD          VARCHAR(50)     NOT NULL,
    C_TABLE_NAME        VARCHAR(50)     NOT NULL,
    C_PROTECTED_ACCESS  CHAR(1)         NULL,
    C_ONTOLOGY_PROTECTION TEXT          NULL,
    C_HLEVEL            INTEGER         NOT NULL,
    C_FULLNAME          VARCHAR(700)    NOT NULL,
    C_NAME              VARCHAR(2000)   NOT NULL,
    C_SYNONYM_CD        CHAR(1)         NOT NULL,
    C_VISUALATTRIBUTES  CHAR(3)         NOT NULL,
    C_TOTALNUM          INTEGER         NULL,
    C_BASECODE          VARCHAR(50)     NULL,
    C_METADATAXML       TEXT            NULL,
    C_FACTTABLECOLUMN   VARCHAR(50)     NOT NULL,
    C_DIMTABLENAME      VARCHAR(50)     NOT NULL,
    C_COLUMNNAME        VARCHAR(50)     NOT NULL,
    C_COLUMNDATATYPE    VARCHAR(50)     NOT NULL,
    C_OPERATOR          VARCHAR(10)     NOT NULL,
    C_DIMCODE           VARCHAR(700)    NOT NULL,
    C_COMMENT           TEXT            NULL,
    C_TOOLTIP           VARCHAR(900)    NULL,
    C_ENTRY_DATE        TIMESTAMP_NTZ   NULL,
    C_CHANGE_DATE       TIMESTAMP_NTZ   NULL,
    C_STATUS_CD         CHAR(1)         NULL,
    VALUETYPE_CD        VARCHAR(50)     NULL
);

--------------------------------------------------------
--  DDL for Table CUSTOM_META
--------------------------------------------------------
CREATE TABLE CUSTOM_META (
    C_HLEVEL            INTEGER         NOT NULL,
    C_FULLNAME          VARCHAR(700)    NOT NULL,
    C_NAME              VARCHAR(2000)   NOT NULL,
    C_SYNONYM_CD        CHAR(1)         NOT NULL,
    C_VISUALATTRIBUTES  CHAR(3)         NOT NULL,
    C_TOTALNUM          INTEGER         NULL,
    C_BASECODE          VARCHAR(50)     NULL,
    C_METADATAXML       TEXT            NULL,
    C_FACTTABLECOLUMN   VARCHAR(50)     NOT NULL,
    C_TABLENAME         VARCHAR(50)     NOT NULL,
    C_COLUMNNAME        VARCHAR(50)     NOT NULL,
    C_COLUMNDATATYPE    VARCHAR(50)     NOT NULL,
    C_OPERATOR          VARCHAR(10)     NOT NULL,
    C_DIMCODE           VARCHAR(700)    NOT NULL,
    C_COMMENT           TEXT            NULL,
    C_TOOLTIP           VARCHAR(900)    NULL,
    M_APPLIED_PATH      VARCHAR(700)    NOT NULL,
    UPDATE_DATE         TIMESTAMP_NTZ   NOT NULL,
    DOWNLOAD_DATE       TIMESTAMP_NTZ   NULL,
    IMPORT_DATE         TIMESTAMP_NTZ   NULL,
    SOURCESYSTEM_CD     VARCHAR(50)     NULL,
    VALUETYPE_CD        VARCHAR(50)     NULL,
    M_EXCLUSION_CD      VARCHAR(25)     NULL,
    C_PATH              VARCHAR(700)    NULL,
    C_SYMBOL            VARCHAR(50)     NULL
);

--------------------------------------------------------
--  DDL for Table ONT_PROCESS_STATUS
--------------------------------------------------------
CREATE TABLE ONT_PROCESS_STATUS (
    PROCESS_ID          INTEGER AUTOINCREMENT PRIMARY KEY,
    PROCESS_TYPE_CD     VARCHAR(50)     NULL,
    START_DATE          DATE   NULL,
    END_DATE            DATE   NULL,
    PROCESS_STEP_CD     VARCHAR(50)     NULL,
    PROCESS_STATUS_CD   VARCHAR(50)     NULL,
    CRC_UPLOAD_ID       INTEGER         NULL,
    STATUS_CD           VARCHAR(50)     NULL,
    MESSAGE             TEXT            NULL,
    ENTRY_DATE          TIMESTAMP_NTZ   NULL,
    CHANGE_DATE         TIMESTAMP_NTZ   NULL,
    CHANGEDBY_CHAR      CHAR(50)        NULL
);

--------------------------------------------------------
--  DDL for Table ICD10_ICD9
--------------------------------------------------------
CREATE TABLE ICD10_ICD9 (
    C_HLEVEL            INTEGER         NOT NULL,
    C_FULLNAME          VARCHAR(700)    NOT NULL,
    C_NAME              VARCHAR(2000)   NOT NULL,
    C_SYNONYM_CD        CHAR(1)         NOT NULL,
    C_VISUALATTRIBUTES  CHAR(3)         NOT NULL,
    C_TOTALNUM          INTEGER         NULL,
    C_BASECODE          VARCHAR(50)     NULL,
    C_METADATAXML       TEXT            NULL,
    C_FACTTABLECOLUMN   VARCHAR(50)     NOT NULL,
    C_TABLENAME         VARCHAR(50)     NOT NULL,
    C_COLUMNNAME        VARCHAR(50)     NOT NULL,
    C_COLUMNDATATYPE    VARCHAR(50)     NOT NULL,
    C_OPERATOR          VARCHAR(10)     NOT NULL,
    C_DIMCODE           VARCHAR(700)    NOT NULL,
    C_COMMENT           TEXT            NULL,
    C_TOOLTIP           VARCHAR(900)    NULL,
    M_APPLIED_PATH      VARCHAR(700)    NOT NULL,
    UPDATE_DATE         TIMESTAMP_NTZ   NOT NULL,
    DOWNLOAD_DATE       TIMESTAMP_NTZ   NULL,
    IMPORT_DATE         TIMESTAMP_NTZ   NULL,
    SOURCESYSTEM_CD     VARCHAR(50)     NULL,
    VALUETYPE_CD        VARCHAR(50)     NULL,
    M_EXCLUSION_CD      VARCHAR(25)     NULL,
    C_PATH              VARCHAR(700)    NULL,
    C_SYMBOL            VARCHAR(50)     NULL,
    PLAIN_CODE          VARCHAR(25)     NULL
);

--------------------------------------------------------
--  DDL for totalnum tables
--------------------------------------------------------
CREATE TABLE TOTALNUM (
    C_FULLNAME          VARCHAR(850)    NULL,
    AGG_DATE            DATE            NULL,
    AGG_COUNT           INTEGER         NULL,
    TYPEFLAG_CD         VARCHAR(3)      NULL
);

CREATE TABLE TOTALNUM_REPORT (
    C_FULLNAME          VARCHAR(850)    NULL,
    AGG_DATE            VARCHAR(50)     NULL,
    AGG_COUNT           INTEGER         NULL
); 