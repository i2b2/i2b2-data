
--==============================================================
-- Oracle Database Script to upgrade CRC from 1.6 to 1.7           
--==============================================================

CREATE TABLE PM_USER_LOGIN ( 
	USER_ID 	VARCHAR2(50) NOT NULL,
	ATTEMPT_CD		VARCHAR2(50) NOT NULL,
    ENTRY_DATE      TIMESTAMP NOT NULL,
	CHANGEBY_CHAR   VARCHAR2(50),
    STATUS_CD       VARCHAR2(50)   
    );    

ALTER TABLE PM_USER_LOGIN
	ADD ( PRIMARY KEY (ENTRY_DATE, USER_ID)
	NOT DEFERRABLE INITIALLY IMMEDIATE );
    
