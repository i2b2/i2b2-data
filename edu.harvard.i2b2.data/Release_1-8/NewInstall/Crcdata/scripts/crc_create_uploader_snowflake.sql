/*==============================================================*/
/* Uploader service create script                               */
/*                                                              */
/* This script will create tables for the uploader service.     */
/* Run this script after the datamart create script             */
/*         MD SABER HOSSAIN	7/14/2023							*/
/*         University of Missouri-Columbia						*/
/*==============================================================*/

/*==============================================================*/
/* Table: DATAMART_REPORT			                    		*/
/*==============================================================*/
CREATE OR REPLACE TABLE DATAMART_REPORT ( 
	TOTAL_PATIENT         int, 
	TOTAL_OBSERVATIONFACT int, 
	TOTAL_EVENT           int,
	REPORT_DATE           TIMESTAMP
)
;




/*==============================================================*/
/* Table: UPLOAD_STATUS 					                    */
/*==============================================================*/
CREATE OR REPLACE SEQUENCE SEQ_UPLOAD_STATUS START = 1 INCREMENT = 1; 
CREATE OR REPLACE TABLE UPLOAD_STATUS (
	UPLOAD_ID 		    NUMBER(38, 0) NOT NULL DEFAULT SEQ_UPLOAD_STATUS.NEXTVAL PRIMARY KEY,
    UPLOAD_LABEL 		VARCHAR(500) NOT NULL, 
    USER_ID      		VARCHAR(100) NOT NULL, 
    SOURCE_CD   		VARCHAR(50) NOT NULL,
    NO_OF_RECORD 		bigint,
    LOADED_RECORD 		bigint,
    DELETED_RECORD		bigint, 
    LOAD_DATE    		TIMESTAMP			  NOT NULL,
	END_DATE 	        TIMESTAMP , 
    LOAD_STATUS  		VARCHAR(100), 
    MESSAGE				TEXT,
    INPUT_FILE_NAME 	TEXT, 
    LOG_FILE_NAME 		TEXT, 
    TRANSFORM_NAME 		VARCHAR(500)
   
) 
;

/*==============================================================*/
/* Table: SET_TYPE						                        */
/*==============================================================*/
CREATE OR REPLACE TABLE SET_TYPE (
	ID 				INT, 
    NAME			VARCHAR(500),
    CREATE_DATE     TIMESTAMP
) 
;



/*==============================================================*/
/* Table: SOURCE_MASTER					                        */
/*==============================================================*/
CREATE OR REPLACE TABLE SOURCE_MASTER ( 
   SOURCE_CD 				VARCHAR(50) NOT NULL,
   DESCRIPTION  			VARCHAR(300),
   CREATE_DATE 				TIMESTAMP
)
;


/*==============================================================*/
/* Table: SET_UPLOAD_STATUS				                        */
/*==============================================================*/
CREATE OR REPLACE TABLE SET_UPLOAD_STATUS  (
    UPLOAD_ID			INT,
    SET_TYPE_ID         INT,
    SOURCE_CD  		    VARCHAR(50) NOT NULL,
    NO_OF_RECORD 		BIGINT,
    LOADED_RECORD 		BIGINT,
    DELETED_RECORD		BIGINT, 
    LOAD_DATE    		TIMESTAMP NOT NULL,
    END_DATE            TIMESTAMP ,
    LOAD_STATUS  		VARCHAR(100), 
    MESSAGE			    TEXT,
    INPUT_FILE_NAME 	TEXT, 
    LOG_FILE_NAME 		TEXT, 
    TRANSFORM_NAME 		VARCHAR(500)
) 
;


 
/*==============================================================*/
/*  Adding seed data for SET_TYPE table.  					    */
/*==============================================================*/
INSERT INTO SET_TYPE(id,name,create_date) values (1,'event_set',CURRENT_DATE);
INSERT INTO SET_TYPE(id,name,create_date) values (2,'patient_set',CURRENT_DATE);
INSERT INTO SET_TYPE(id,name,create_date) values (3,'concept_set',CURRENT_DATE);
INSERT INTO SET_TYPE(id,name,create_date) values (4,'observer_set',CURRENT_DATE);
INSERT INTO SET_TYPE(id,name,create_date) values (5,'observation_set',CURRENT_DATE);
INSERT INTO SET_TYPE(id,name,create_date) values (6,'pid_set',CURRENT_DATE);
INSERT INTO SET_TYPE(id,name,create_date) values (7,'eid_set',CURRENT_DATE);
INSERT INTO SET_TYPE(id,name,create_date) values (8,'modifier_set',CURRENT_DATE);
 