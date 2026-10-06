/*==============================================================*/
/* Snowflake Uploader service create script                     */
/* (converted from PostgreSQL)                                  */
/*==============================================================*/

/*============================================================================*/
/* Table: ARCHIVE_OBSERVATION_FACT (HOLDS DELETED ENTRIES OF OBSERVATION_FACT) */
/*============================================================================*/
CREATE TABLE ARCHIVE_OBSERVATION_FACT AS
    SELECT *, NULL::INTEGER AS ARCHIVE_UPLOAD_ID
    FROM OBSERVATION_FACT
    WHERE 1=2;

/*==============================================================*/
/* Table: DATAMART_REPORT                                       */
/*==============================================================*/
CREATE TABLE DATAMART_REPORT (
    TOTAL_PATIENT         INTEGER,
    TOTAL_OBSERVATIONFACT INTEGER,
    TOTAL_EVENT           INTEGER,
    REPORT_DATE           TIMESTAMP_NTZ
);

/*==============================================================*/
/* Table: UPLOAD_STATUS                                         */
/*==============================================================*/
CREATE TABLE UPLOAD_STATUS (
    UPLOAD_ID           INTEGER AUTOINCREMENT PRIMARY KEY,
    UPLOAD_LABEL        VARCHAR(500)  NOT NULL,
    USER_ID             VARCHAR(100)  NOT NULL,
    SOURCE_CD           VARCHAR(50)   NOT NULL,
    NO_OF_RECORD        BIGINT,
    LOADED_RECORD       BIGINT,
    DELETED_RECORD      BIGINT,
    LOAD_DATE           TIMESTAMP_NTZ NOT NULL,
    END_DATE            TIMESTAMP_NTZ,
    LOAD_STATUS         VARCHAR(100),
    MESSAGE             TEXT,
    INPUT_FILE_NAME     TEXT,
    LOG_FILE_NAME       TEXT,
    TRANSFORM_NAME      VARCHAR(500)
);

/*==============================================================*/
/* Table: SET_TYPE                                              */
/*==============================================================*/
CREATE TABLE SET_TYPE (
    ID                  INTEGER,
    NAME                VARCHAR(500),
    CREATE_DATE         TIMESTAMP_NTZ,
    CONSTRAINT PK_ST_ID PRIMARY KEY (ID)
);

/*==============================================================*/
/* Table: SOURCE_MASTER                                         */
/*==============================================================*/
CREATE TABLE SOURCE_MASTER (
    SOURCE_CD           VARCHAR(50)   NOT NULL,
    DESCRIPTION         VARCHAR(300),
    CREATE_DATE         TIMESTAMP_NTZ,
    CONSTRAINT PK_SOURCEMASTER_SOURCECD PRIMARY KEY (SOURCE_CD)
);

/*==============================================================*/
/* Table: SET_UPLOAD_STATUS                                     */
/*==============================================================*/
CREATE TABLE SET_UPLOAD_STATUS (
    UPLOAD_ID           INTEGER,
    SET_TYPE_ID         INTEGER,
    SOURCE_CD           VARCHAR(50)   NOT NULL,
    NO_OF_RECORD        BIGINT,
    LOADED_RECORD       BIGINT,
    DELETED_RECORD      BIGINT,
    LOAD_DATE           TIMESTAMP_NTZ NOT NULL,
    END_DATE            TIMESTAMP_NTZ,
    LOAD_STATUS         VARCHAR(100),
    MESSAGE             TEXT,
    INPUT_FILE_NAME     TEXT,
    LOG_FILE_NAME       TEXT,
    TRANSFORM_NAME      VARCHAR(500),
    CONSTRAINT PK_UP_UPSTATUS_IDSETTYPEID PRIMARY KEY (UPLOAD_ID, SET_TYPE_ID),
    CONSTRAINT FK_UP_SET_TYPE_ID FOREIGN KEY (SET_TYPE_ID) REFERENCES SET_TYPE(ID)
);

/*==============================================================*/
/* SEED DATA                                                    */
/*==============================================================*/
INSERT INTO SET_TYPE (ID, NAME, CREATE_DATE) VALUES
    (1, 'event_set',       CURRENT_TIMESTAMP()),
    (2, 'patient_set',     CURRENT_TIMESTAMP()),
    (3, 'concept_set',     CURRENT_TIMESTAMP()),
    (4, 'observer_set',    CURRENT_TIMESTAMP()),
    (5, 'observation_set', CURRENT_TIMESTAMP()),
    (6, 'pid_set',         CURRENT_TIMESTAMP()),
    (7, 'eid_set',         CURRENT_TIMESTAMP()),
    (8, 'modifier_set',    CURRENT_TIMESTAMP());