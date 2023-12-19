--==============================================================
-- SQL Server Database Script to upgrade PM from 1.6 to 1.7             
--==============================================================

CREATE TABLE PM_USER_LOGIN ( 
	USER_ID 	VARCHAR(50) NOT NULL,
	ATTEMPT_CD		VARCHAR(50) NOT NULL,
    ENTRY_DATE      DATETIME NOT NULL,
	CHANGEBY_CHAR   VARCHAR(50),
    STATUS_CD       VARCHAR(50)   
    );  

ALTER TABLE PM_USER_LOGIN
    ADD  PRIMARY KEY (ENTRY_DATE, USER_ID);	

