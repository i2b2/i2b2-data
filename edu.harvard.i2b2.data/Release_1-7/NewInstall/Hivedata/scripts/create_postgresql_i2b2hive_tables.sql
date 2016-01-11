
 --------------------------------------------------------
--  DDL for Table ONT_DB_LOOKUP
--------------------------------------------------------
 
 CREATE TABLE ONT_DB_LOOKUP ( 
	C_DOMAIN_ID   	VARCHAR(255)   NOT NULL,
	C_PROJECT_PATH 	VARCHAR(255)   NOT NULL, 
	C_OWNER_ID     	VARCHAR(255)   NOT NULL, 
	C_DB_FULLSCHEMA   VARCHAR(255)   NOT NULL, 
	C_DB_DATASOURCE	VARCHAR(255)   NOT NULL, 
	C_DB_SERVERTYPE	VARCHAR(255)   NOT NULL, 
	C_DB_NICENAME  	VARCHAR(255)   NULL,
	C_DB_TOOLTIP   	VARCHAR(255)   NULL, 
	C_COMMENT      	TEXT   NULL,
	C_ENTRY_DATE   	timestamp   NULL,
	C_CHANGE_DATE  	timestamp   NULL,
	C_STATUS_CD    	CHAR(1)    NULL ,
     CONSTRAINT ONT_DB_LOOKUP_PK PRIMARY KEY(C_DOMAIN_ID,C_PROJECT_PATH,C_OWNER_ID)
	) ;
	
 --------------------------------------------------------
--  DDL for Table IM_DB_LOOKUP
--------------------------------------------------------
 
 CREATE TABLE IM_DB_LOOKUP ( 
	C_DOMAIN_ID   	VARCHAR(255)   NOT NULL,
	C_PROJECT_PATH 	VARCHAR(255)   NOT NULL, 
	C_OWNER_ID     	VARCHAR(255)   NOT NULL, 
	C_DB_FULLSCHEMA   VARCHAR(255)   NOT NULL, 
	C_DB_DATASOURCE	VARCHAR(255)   NOT NULL, 
	C_DB_SERVERTYPE	VARCHAR(255)   NOT NULL, 
	C_DB_NICENAME  	VARCHAR(255)   NULL,
	C_DB_TOOLTIP   	VARCHAR(255)   NULL, 
	C_COMMENT      	TEXT   NULL,
	C_ENTRY_DATE   	timestamp   NULL,
	C_CHANGE_DATE  	timestamp   NULL,
	C_STATUS_CD    	CHAR(1)    NULL ,
     CONSTRAINT IM_DB_LOOKUP_PK PRIMARY KEY(C_DOMAIN_ID,C_PROJECT_PATH,C_OWNER_ID)
	) ;
		
	
--------------------------------------------------------
--  DDL for Table WORK_DB_LOOKUP
--------------------------------------------------------
	CREATE TABLE WORK_DB_LOOKUP ( 
	C_DOMAIN_ID   	VARCHAR(255)   NOT NULL,
	C_PROJECT_PATH 	VARCHAR(255)   NOT NULL, 
	C_OWNER_ID     	VARCHAR(255)   NOT NULL, 
	C_DB_FULLSCHEMA   VARCHAR(255)   NOT NULL, 
	C_DB_DATASOURCE	VARCHAR(255)   NOT NULL, 
	C_DB_SERVERTYPE	VARCHAR(255)   NOT NULL, 
	C_DB_NICENAME  	VARCHAR(255)   NULL,
	C_DB_TOOLTIP   	VARCHAR(255)   NULL, 
	C_COMMENT      	TEXT   NULL,
	C_ENTRY_DATE   	timestamp   NULL,
	C_CHANGE_DATE  	timestamp   NULL,
	C_STATUS_CD    	CHAR(1)    NULL ,
     CONSTRAINT WORK_DB_LOOKUP_PK PRIMARY KEY(C_DOMAIN_ID,C_PROJECT_PATH,C_OWNER_ID) 
	)	;

--------------------------------------------------------
--  DDL for Table CRC_DB_LOOKUP
--------------------------------------------------------
	
 CREATE TABLE CRC_DB_LOOKUP ( 
	C_DOMAIN_ID   	VARCHAR(255)   NOT NULL,
	C_PROJECT_PATH 	VARCHAR(255)   NOT NULL, 
	C_OWNER_ID     	VARCHAR(255)   NOT NULL, 
	C_DB_FULLSCHEMA   VARCHAR(255)   NOT NULL, 
	C_DB_DATASOURCE	VARCHAR(255)   NOT NULL, 
	C_DB_SERVERTYPE	VARCHAR(255)   NOT NULL, 
	C_DB_NICENAME  	VARCHAR(255)   NULL,
	C_DB_TOOLTIP   	VARCHAR(255)   NULL, 
	C_COMMENT      	TEXT   NULL,
	C_ENTRY_DATE   	timestamp   NULL,
	C_CHANGE_DATE  	timestamp   NULL,
	C_STATUS_CD    	CHAR(1)    NULL ,
     CONSTRAINT CRC_DB_LOOKUP_PK PRIMARY KEY(C_DOMAIN_ID,C_PROJECT_PATH,C_OWNER_ID)
	) ;

create table CRC_ANALYSIS_JOB (
	job_id varchar(10) ,
	queue_name varchar(50),
	status_type_id int, 
	domain_id varchar(255), 
	project_id varchar(500), 
	user_id varchar(255), 
	request_xml text,
	create_date timestamp, 
	update_date timestamp,
	CONSTRAINT ANALSIS_JOB_PK PRIMARY KEY(JOB_ID) 
   
) ;

CREATE INDEX CRC_IDX_AJ_QNSTID ON CRC_ANALYSIS_JOB(queue_name,status_type_id);
 