
-------------------------------------------------------------------------------------------
-- create IM_MPI_DEMOGRAPHICS table  
-------------------------------------------------------------------------------------------

CREATE TABLE IM_MPI_DEMOGRAPHICS (
	GLOBAL_ID        VARCHAR2(200) NOT NULL,
	GLOBAL_STATUS    VARCHAR2(50) NULL,
    DEMOGRAPHICS     VARCHAR2 (400) NULL,
	UPDATE_DATE	     DATE, 
    DOWNLOAD_DATE    DATE,
    IMPORT_DATE      DATE,
    SOURCESYSTEM_CD  VARCHAR2(50) NULL,
    UPLOAD_ID        NUMBER(38,0),
	CONSTRAINT IM_MPI_DEMOGRAPHICS_PK PRIMARY KEY(GLOBAL_ID)
 )
;


-------------------------------------------------------------------------------------------
-- create IM_MPI_MAPPING table  
-------------------------------------------------------------------------------------------

CREATE TABLE IM_MPI_MAPPING  ( 
	GLOBAL_ID        VARCHAR2(200) NOT NULL,
	LCL_SITE         VARCHAR2(50) NOT NULL,
	LCL_ID           VARCHAR2(200) NOT NULL,
	LCL_STATUS       VARCHAR2(50) NULL,
	UPDATE_DATE	     DATE NOT NULL, 
    DOWNLOAD_DATE    DATE,
    IMPORT_DATE      DATE,
    SOURCESYSTEM_CD  VARCHAR2(50) NULL,
    UPLOAD_ID        NUMBER(38,0),
    CONSTRAINT IM_MPI_MAPPING_PK PRIMARY KEY(LCL_SITE, LCL_ID, UPDATE_DATE)
 )
;


-------------------------------------------------------------------------------------------
-- create IM_PROJECT_SITES table  
-------------------------------------------------------------------------------------------

CREATE TABLE IM_PROJECT_SITES  ( 
	PROJECT_ID       VARCHAR2(50) NOT NULL,
	LCL_SITE         VARCHAR2(50) NOT NULL,
	PROJECT_STATUS   VARCHAR2(50) NULL,
	UPDATE_DATE	     DATE,
    DOWNLOAD_DATE    DATE,
    IMPORT_DATE      DATE,
    SOURCESYSTEM_CD  VARCHAR2(50) NULL,
    UPLOAD_ID        NUMBER(38,0),
    CONSTRAINT IM_PROJECT_SITES_PK PRIMARY KEY(PROJECT_ID, LCL_SITE)
 )
;


-------------------------------------------------------------------------------------------
-- create IM_PROJECT_PATIENTS table  
-------------------------------------------------------------------------------------------

CREATE TABLE IM_PROJECT_PATIENTS  ( 
	PROJECT_ID               VARCHAR2(50) NOT NULL,
	GLOBAL_ID                VARCHAR2(200) NOT NULL,
	PATIENT_PROJECT_STATUS   VARCHAR2(50) NULL,
	UPDATE_DATE	             DATE,
    DOWNLOAD_DATE            DATE,
    IMPORT_DATE              DATE,
    SOURCESYSTEM_CD          VARCHAR2(50) NULL,
    UPLOAD_ID                NUMBER(38,0),
    CONSTRAINT IM_PROJECT_PATIENTS_PK PRIMARY KEY(PROJECT_ID, GLOBAL_ID)
 )
;

-------------------------------------------------------------------------------------------
-- create IM_AUDIT table  
-------------------------------------------------------------------------------------------

CREATE TABLE IM_AUDIT  ( 
	QUERY_DATE        DATE  DEFAULT SYSDATE,
	LCL_SITE         VARCHAR2(50) NOT NULL,
	LCL_ID           VARCHAR2(200) NOT NULL,
	USER_ID			 VARCHAR2(50) NOT NULL,
	PROJECT_ID       VARCHAR2(50) NOT NULL,
	COMMENTS		 CLOB NULL
	);

-------------------------------------------------------------------------------------------
-- create IM_TEMP_SITE table  
-------------------------------------------------------------------------------------------

CREATE GLOBAL TEMPORARY TABLE IM_TEMP_SITE  ( 
	LCL_SITE         VARCHAR2(50) NULL,
	LCL_ID           VARCHAR2(200) NULL,
	PROJECT_ID       VARCHAR2(50) NULL
	) ON COMMIT PRESERVE ROWS;

