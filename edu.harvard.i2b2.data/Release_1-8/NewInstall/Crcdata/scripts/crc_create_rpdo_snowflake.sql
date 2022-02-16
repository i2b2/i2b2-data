/*============================================================================*/
/* Table: RPDO_TABLE_REQUEST                                                  */
/*============================================================================*/
CREATE TABLE RPDO_TABLE_REQUEST (
    TABLE_REQUEST_ID                    INTEGER AUTOINCREMENT,
    TABLE_INSTANCE_ID                   INTEGER       NOT NULL,
    TABLE_INSTANCE_NAME                 VARCHAR(250)  NOT NULL,
    USER_ID                             VARCHAR(50)   NOT NULL,
    GROUP_ID                            VARCHAR(50)   NOT NULL,
    SET_INDEX                           INTEGER       NOT NULL,
    C_FACTTABLECOLUMN                   VARCHAR(50)   NOT NULL,
    C_TABLENAME                         VARCHAR(100)  NOT NULL,
    COLUMN_NAME                         VARCHAR(1000),
    C_FULLPATH                          VARCHAR(700),
    C_COLUMNNAME                        VARCHAR(30),
    C_COLUMNDATATYPE                    VARCHAR(50),
    C_OPERATOR                          VARCHAR(30),
    C_DIMCODE                           VARCHAR(1000),
    AGG_TYPE                            VARCHAR(50)   NOT NULL,
    CONSTRAIN_BY_DATE_TO                DATE,
    CONSTRAIN_BY_DATE_FROM              DATE,
    CONSTRAIN_BY_VALUE_OPERATOR         VARCHAR(20),
    CONSTRAIN_BY_VALUE_CONSTRAINT       VARCHAR(1000),
    CONSTRAIN_BY_VALUE_UNIT_OF_MEASURE  VARCHAR(50),
    CONSTRAIN_BY_VALUE_TYPE             VARCHAR(50),
    CREATE_DATE                         DATE,
    DELETE_DATE                         DATE,
    UPDATE_DATE                         DATE,
    DELETE_FLAG                         VARCHAR(3),
    GENERATED_SQL                       TEXT,
    JSON_DATA                           TEXT,
    CONSTRAIN_BY_INDEXDATE_COLUMNNAME   VARCHAR(1000),
    CONSTRAIN_BY_INDEXDATE_FROM_DAYS    INTEGER,
    CONSTRAIN_BY_INDEXDATE_TO_DAYS      INTEGER,
    USE_AS_COHORT                       CHAR(1),
    REQUIRED                            VARCHAR(3),
    SHARED                              CHAR(1),
    C_VISUALATTRIBUTES                  CHAR(3)       NOT NULL DEFAULT 'LA'
);

/*============================================================================*/
/* Table: RPDO_LOG                                                            */
/*============================================================================*/
CREATE TABLE RPDO_LOG (
    LOGGED TEXT
);

/*============================================================================*/
/* SEED DATA                                                                  */
/*============================================================================*/
INSERT INTO RPDO_TABLE_REQUEST (
    TABLE_INSTANCE_ID, TABLE_INSTANCE_NAME, USER_ID, GROUP_ID, SET_INDEX,
    C_FACTTABLECOLUMN, C_TABLENAME, COLUMN_NAME, C_FULLPATH, C_COLUMNNAME,
    C_COLUMNDATATYPE, C_OPERATOR, C_DIMCODE, AGG_TYPE,
    DELETE_FLAG, JSON_DATA, USE_AS_COHORT, REQUIRED, C_VISUALATTRIBUTES
) VALUES
    (-1, 'Default Required', '@', '@', 1, 'sex_cd',            'patient_dimension', 'Gender', ' @', ' @', '@', ' @', ' @', 'Value', '', '[{"dataOption":"Value","index":1,"sdxData":{"renderData":{"title":"Gender"}}}]', '', 'Y', 'LA'),
    (-1, 'Default Required', '@', '@', 2, 'age_in_years_num',  'patient_dimension', 'Age',    ' @', ' @', '@', ' @', ' @', 'Value', '', '[{"dataOption":"Value","index":2,"sdxData":{"renderData":{"title":"Age"}}}]',    '', 'Y', 'LA'),
    (-1, 'Default Required', '@', '@', 3, 'race_cd',           'patient_dimension', 'Race',   ' @', ' @', '@', ' @', ' @', 'Value', '', '[{"dataOption":"Value","index":3,"sdxData":{"renderData":{"title":"Race"}}}]',   '', 'Y', 'LA');