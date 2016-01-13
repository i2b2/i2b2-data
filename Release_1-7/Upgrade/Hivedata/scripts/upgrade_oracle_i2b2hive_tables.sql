 CREATE TABLE IM_DB_LOOKUP ( 
	"C_DOMAIN_ID"   	VARCHAR2(255)	NOT NULL,
	"C_PROJECT_PATH" 	VARCHAR2(255)	NOT NULL, 
	"C_OWNER_ID"     	VARCHAR2(255)	NOT NULL, 
	"C_DB_FULLSCHEMA"   VARCHAR2(255)	NOT NULL, 
	"C_DB_DATASOURCE"	VARCHAR2(255)	NOT NULL, 
	"C_DB_SERVERTYPE"	VARCHAR2(255)	NOT NULL, 
	"C_DB_NICENAME"  	VARCHAR2(255)	NULL,
	"C_DB_TOOLTIP"   	VARCHAR2(255)	NULL, 
	"C_COMMENT"      	CLOB	NULL,
	"C_ENTRY_DATE"   	DATE	NULL,
	"C_CHANGE_DATE"  	DATE	NULL,
	"C_STATUS_CD"    	CHAR(1) NULL,
     CONSTRAINT IM_DB_LOOKUP_PK PRIMARY KEY(C_DOMAIN_ID,C_PROJECT_PATH,C_OWNER_ID)
	) ;
	
INSERT INTO IM_DB_LOOKUP(c_domain_id, c_project_path, c_owner_id, c_db_fullschema, c_db_datasource, c_db_servertype, c_db_nicename, c_db_tooltip, c_comment, c_entry_date, c_change_date, c_status_cd)
  VALUES('i2b2demo', 'Demo/', '@', 'i2b2imdata', 'java:/IMDemoDS', 'ORACLE', 'IM', NULL, NULL, NULL, NULL, NULL);

	