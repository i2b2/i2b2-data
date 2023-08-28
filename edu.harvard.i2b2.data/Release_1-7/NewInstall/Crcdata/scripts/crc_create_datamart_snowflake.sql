/*********************************************************
*         SNOWFLAKE SCRIPT TO CREATE DATA TABLES
*         MD SABER HOSSAIN	7/14/2023
/*        University of Missouri-Columbia			
**********************************************************/


-------------------------------------------------------------------------------------------
-- create ENCOUNTER_MAPPING table with clustered PK on ENCOUNTER_IDE, ENCOUNTER_IDE_SOURCE 
-------------------------------------------------------------------------------------------

CREATE TABLE ENCOUNTER_MAPPING ( 
    ENCOUNTER_IDE       	VARCHAR(200)  NOT NULL,
    ENCOUNTER_IDE_SOURCE	VARCHAR(50)  NOT NULL,
    PROJECT_ID              VARCHAR(50) NOT NULL,
    ENCOUNTER_NUM			INT NOT NULL,
    PATIENT_IDE         	VARCHAR(200) NOT NULL,
    PATIENT_IDE_SOURCE  	VARCHAR(50) NOT NULL,
    ENCOUNTER_IDE_STATUS	VARCHAR(50) NULL,
    UPLOAD_DATE         	TIMESTAMP NULL,
    UPDATE_DATE             TIMESTAMP NULL,
    DOWNLOAD_DATE       	TIMESTAMP NULL,
    IMPORT_DATE             TIMESTAMP NULL,
    SOURCESYSTEM_CD         VARCHAR(50) NULL,
    UPLOAD_ID               INT NULL
 )
;

-------------------------------------------------------------------------------------
-- create PATIENT_MAPPING table with clustered PK on PATIENT_IDE, PATIENT_IDE_SOURCE
-------------------------------------------------------------------------------------

CREATE TABLE PATIENT_MAPPING ( 
    PATIENT_IDE         VARCHAR(200)  NOT NULL,
    PATIENT_IDE_SOURCE	VARCHAR(50)  NOT NULL,
    PATIENT_NUM       	INT NOT NULL,
    PATIENT_IDE_STATUS	VARCHAR(50) NULL,
    PROJECT_ID          VARCHAR(50) NOT NULL,
    UPLOAD_DATE       	TIMESTAMP NULL,
    UPDATE_DATE       	TIMESTAMP NULL,
    DOWNLOAD_DATE     	TIMESTAMP NULL,
    IMPORT_DATE         TIMESTAMP NULL,
    SOURCESYSTEM_CD   	VARCHAR(50) NULL,
    UPLOAD_ID         	INT NULL
 )
;

------------------------------------------------------------------------------
-- create CODE_LOOKUP table with clustered PK on TABLE_CD, COLUMN_CD, CODE_CD 
------------------------------------------------------------------------------

CREATE TABLE CODE_LOOKUP ( 
    TABLE_CD            VARCHAR(100) NOT NULL,
    COLUMN_CD           VARCHAR(100) NOT NULL,
    CODE_CD             VARCHAR(50) NOT NULL,
    NAME_CHAR           VARCHAR(650) NULL,
    LOOKUP_BLOB         TEXT NULL, 
    UPLOAD_DATE       	TIMESTAMP NULL,
    UPDATE_DATE         TIMESTAMP NULL,
    DOWNLOAD_DATE     	TIMESTAMP NULL,
    IMPORT_DATE         TIMESTAMP NULL,
    SOURCESYSTEM_CD   	VARCHAR(50) NULL,
    UPLOAD_ID         	INT NULL
	)
;

--------------------------------------------------------------------
-- create CONCEPT_DIMENSION table with clustered PK on CONCEPT_PATH 
--------------------------------------------------------------------

CREATE TABLE CONCEPT_DIMENSION ( 
	CONCEPT_PATH   		VARCHAR(700) NOT NULL,
	CONCEPT_CD     		VARCHAR(50) NULL,
	NAME_CHAR      		VARCHAR(2000) NULL,
	CONCEPT_BLOB   		TEXT NULL,
	UPDATE_DATE    		TIMESTAMP NULL,
	DOWNLOAD_DATE  		TIMESTAMP NULL,
	IMPORT_DATE    		TIMESTAMP NULL,
	SOURCESYSTEM_CD		VARCHAR(50) NULL,
    UPLOAD_ID			INT NULL
	)
;


---------------------------------------------------------------------------------------------------------------------------------------
-- create OBSERVATION_FACT table with NONclustered PK on ENCOUNTER_NUM, CONCEPT_CD, PROVIDER_ID, START_DATE, MODIFIER_CD, INSTANCE_NUM 
---------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE OBSERVATION_FACT ( 
	ENCOUNTER_NUM  		INT NOT NULL,
	PATIENT_NUM    		INT NOT NULL,
	CONCEPT_CD     		VARCHAR(50) NOT NULL,
	PROVIDER_ID    		VARCHAR(50) NOT NULL,
	START_DATE     		TIMESTAMP NOT NULL,
	MODIFIER_CD    		VARCHAR(100) default '@' NOT NULL,
	INSTANCE_NUM		INT default (1) NOT NULL,
	VALTYPE_CD     		VARCHAR(50) NULL,
	TVAL_CHAR      		VARCHAR(255) NULL,
	NVAL_NUM       		DECIMAL(18,5) NULL,
	VALUEFLAG_CD   		VARCHAR(50) NULL,
	QUANTITY_NUM   		DECIMAL(18,5) NULL,
	UNITS_CD       		VARCHAR(50) NULL,
	END_DATE       		TIMESTAMP NULL,
	LOCATION_CD    		VARCHAR(50) NULL,
	OBSERVATION_BLOB	TEXT NULL,
	CONFIDENCE_NUM 		DECIMAL(18,5) NULL,
	UPDATE_DATE    		TIMESTAMP NULL,
	DOWNLOAD_DATE  		TIMESTAMP NULL,
	IMPORT_DATE    		TIMESTAMP NULL,
	SOURCESYSTEM_CD		VARCHAR(50) NULL, 
    UPLOAD_ID         	INT NULL,
    TEXT_SEARCH_INDEX   NUMBER(38, 0) NOT NULL
	)
;

-------------------------------------------------------------------
-- create PATIENT_DIMENSION table with clustered PK on PATIENT_NUM 
-------------------------------------------------------------------

CREATE TABLE PATIENT_DIMENSION ( 
	PATIENT_NUM      	INT NOT NULL,
	VITAL_STATUS_CD  	VARCHAR(50) NULL,
	BIRTH_DATE       	DATE NULL,
	DEATH_DATE       	DATE NULL,
	SEX_CD           	VARCHAR(2) NULL,
	LANGUAGE_CD      	VARCHAR(3) NULL,
	HISPANIC			VARCHAR(2) NULL,
	RACE_CD          	VARCHAR(50) NULL,
	MARITAL_STATUS_CD	VARCHAR(50) NULL,
	AGE_IN_YEARS_NUM	INT NULL default null,
	RELIGION_CD      	VARCHAR(50) NULL default null,
	ZIP_CD           	VARCHAR(10) NULL default null,
	STATECITYZIP_PATH	VARCHAR(700) NULL default null,
	INCOME_CD			VARCHAR(50) NULL default null,
	PATIENT_BLOB     	TEXT NULL default null,
	UPDATE_DATE      	DATE NULL,
	DOWNLOAD_DATE    	DATE NULL,
	IMPORT_DATE      	DATE NULL,
	SOURCESYSTEM_CD  	VARCHAR(50) NULL,
	UPLOAD_ID        	INT NULL
	)
;



-----------------------------------------------------------------------------------
-- create PROVIDER_DIMENSION table with clustered PK on PROVIDER_PATH, PROVIDER_ID 
-----------------------------------------------------------------------------------

CREATE TABLE PROVIDER_DIMENSION ( 
	PROVIDER_ID        		 			VARCHAR(50) NOT NULL,
	PROVIDER_SEX						VARCHAR(2)  NULL,
	PROVIDER_PATH  		VARCHAR(700) NOT NULL default '@',
	NAME_CHAR      		VARCHAR(850) NULL default null,
	PROVIDER_BLOB  		TEXT NULL,
	PROVIDER_SPECIALTY_PRIMARY       	VARCHAR(50) NULL,
	PROVIDER_NPI 				 		VARCHAR(8) NULL,
	PROVIDER_NPI_FLAG					VARCHAR(1) NULL,			
	RAW_PROVIDER_SPECIALTY_PRIMARY		VARCHAR(50) NULL,
	UPDATE_DATE     	DATE NULL,
	DOWNLOAD_DATE       DATE NULL,
	IMPORT_DATE         DATE NULL,
	SOURCESYSTEM_CD     VARCHAR(50) NULL,
	UPLOAD_ID        	INT NULL
	)
;

-------------------------------------------------------------------
-- create VISIT_DIMENSION table with clustered PK on ENCOUNTER_NUM 
-------------------------------------------------------------------

CREATE TABLE VISIT_DIMENSION ( 
	ENCOUNTER_NUM       INT NOT NULL,
	PATIENT_NUM        	INT NOT NULL,
	PROVIDER_ID         VARCHAR(50) NOT NULL,
	START_DATE          DATE NULL,
	END_DATE            DATE NULL,
	ENC_TYPE            VARCHAR(2) NULL,
	LENGTH_OF_STAY      INT NULL,
	ACTIVE_STATUS_CD	VARCHAR(50) default null,
	INOUT_CD       		VARCHAR(50) NULL default null,
	LOCATION_CD    		VARCHAR(50) NULL default null,
	LOCATION_PATH  		VARCHAR(900) NULL default null,
	VISIT_BLOB     		TEXT NULL default null,
	UPDATE_DATE         DATE NULL,
	DOWNLOAD_DATE       DATE NULL,
	IMPORT_DATE         DATE NULL,
	SOURCESYSTEM_CD     VARCHAR(50) NULL,
	UPLOAD_ID       	INT NULL
	)
;


------------------------------------------------------------
-- create MODIFIER_DIMENSION table with PK on MODIFIER_PATH 
------------------------------------------------------------

CREATE TABLE MODIFIER_DIMENSION ( 
	MODIFIER_PATH   	VARCHAR(700) NOT NULL,
	MODIFIER_CD     	VARCHAR(50) NULL,
	NAME_CHAR      		VARCHAR(2000) NULL,
	MODIFIER_BLOB   	TEXT NULL,
	UPDATE_DATE    		TIMESTAMP NULL,
	DOWNLOAD_DATE  		TIMESTAMP NULL,
	IMPORT_DATE    		TIMESTAMP NULL,
	SOURCESYSTEM_CD		VARCHAR(50) NULL,
    UPLOAD_ID			INT NULL
	)
;
