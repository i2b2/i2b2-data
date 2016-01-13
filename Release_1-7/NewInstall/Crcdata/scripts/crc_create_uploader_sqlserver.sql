/*==============================================================*/
/* Uploader service create script                               */
/*                                                              */
/* This script will create tables for the uploader service.     */
/* Run this script after the datamart create script             */
/*==============================================================*/


/*============================================================================*/
/* Table: ARCHIVE_OBSERVATION_FACT (HOLDS DELETED ENTRIES OF OBSERVATION_FACT) */
/*============================================================================*/
select * into ARCHIVE_OBSERVATION_FACT from OBSERVATION_FACT where 1=2 
;

ALTER TABLE ARCHIVE_OBSERVATION_FACT  ADD  ARCHIVE_UPLOAD_ID int
;

CREATE INDEX PK_ARCHIVE_OBSFACT ON ARCHIVE_OBSERVATION_FACT
 		(ENCOUNTER_NUM , PATIENT_NUM , CONCEPT_CD , PROVIDER_ID , START_DATE , MODIFIER_CD , ARCHIVE_UPLOAD_ID) 
;


/*==============================================================*/
/* Table: DATAMART_REPORT			                    		*/
/*==============================================================*/
create table DATAMART_REPORT ( 
	TOTAL_PATIENT         int, 
	TOTAL_OBSERVATIONFACT int, 
	TOTAL_EVENT           int,
	REPORT_DATE           DATETIME)
;




/*==============================================================*/
/* Table: UPLOAD_STATUS 					                    */
/*==============================================================*/
CREATE TABLE UPLOAD_STATUS (
	UPLOAD_ID 		    int identity(1,1) PRIMARY KEY, 	
    UPLOAD_LABEL 		VARCHAR(500) NOT NULL, 
    USER_ID      		VARCHAR(100) NOT NULL, 
    SOURCE_CD   		VARCHAR(50) NOT NULL,
    NO_OF_RECORD 		bigint,
    LOADED_RECORD 		bigint,
    DELETED_RECORD		bigint, 
    LOAD_DATE    		DATETIME			  NOT NULL,
	END_DATE 	        DATETIME , 
    LOAD_STATUS  		VARCHAR(100), 
    MESSAGE				VARCHAR(MAX),
    INPUT_FILE_NAME 	VARCHAR(MAX), 
    LOG_FILE_NAME 		VARCHAR(MAX), 
    TRANSFORM_NAME 		VARCHAR(500)
   
) 
;

/*==============================================================*/
/* Table: SET_TYPE						                        */
/*==============================================================*/
CREATE TABLE SET_TYPE (
	ID 				INT, 
    NAME			VARCHAR(500),
    CREATE_DATE     DATETIME,
    CONSTRAINT PK_ST_ID PRIMARY KEY (ID)
) 
;



/*==============================================================*/
/* Table: SOURCE_MASTER					                        */
/*==============================================================*/
CREATE TABLE SOURCE_MASTER ( 
   SOURCE_CD 				VARCHAR(50) NOT NULL,
   DESCRIPTION  			VARCHAR(300),
   CREATE_DATE 				DATETIME,
   CONSTRAINT PK_SOURCEMASTER_SOURCECD  PRIMARY KEY (SOURCE_CD)
)
;


/*==============================================================*/
/* Table: SET_UPLOAD_STATUS				                        */
/*==============================================================*/
CREATE TABLE SET_UPLOAD_STATUS  (
    UPLOAD_ID			INT,
    SET_TYPE_ID         INT,
    SOURCE_CD  		    VARCHAR(50) NOT NULL,
    NO_OF_RECORD 		BIGINT,
    LOADED_RECORD 		BIGINT,
    DELETED_RECORD		BIGINT, 
    LOAD_DATE    		DATETIME NOT NULL,
    END_DATE            DATETIME ,
    LOAD_STATUS  		VARCHAR(100), 
    MESSAGE			    VARCHAR(MAX),
    INPUT_FILE_NAME 	VARCHAR(MAX), 
    LOG_FILE_NAME 		VARCHAR(MAX), 
    TRANSFORM_NAME 		VARCHAR(500),
    CONSTRAINT PK_UP_UPSTATUS_IDSETTYPEID  PRIMARY KEY (UPLOAD_ID,SET_TYPE_ID),
    CONSTRAINT FK_UP_SET_TYPE_ID FOREIGN KEY (SET_TYPE_ID) REFERENCES SET_TYPE(ID)
) 
;


 
/*==============================================================*/
/*  Adding seed data for SET_TYPE table.  					    */
/*==============================================================*/
INSERT INTO SET_TYPE(id,name,create_date) values (1,'event_set',getdate());
INSERT INTO SET_TYPE(id,name,create_date) values (2,'patient_set',getdate());
INSERT INTO SET_TYPE(id,name,create_date) values (3,'concept_set',getdate());
INSERT INTO SET_TYPE(id,name,create_date) values (4,'observer_set',getdate());
INSERT INTO SET_TYPE(id,name,create_date) values (5,'observation_set',getdate());
INSERT INTO SET_TYPE(id,name,create_date) values (6,'pid_set',getdate());
INSERT INTO SET_TYPE(id,name,create_date) values (7,'eid_set',getdate());
INSERT INTO SET_TYPE(id,name,create_date) values (8,'modifier_set',getdate());
 
