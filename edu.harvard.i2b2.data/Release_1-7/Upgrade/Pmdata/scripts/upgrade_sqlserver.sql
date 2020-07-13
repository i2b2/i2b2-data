CREATE TABLE PM_USER_LOGIN ( 
	USER_ID 	VARCHAR(50) NOT NULL,
	ATTEMPT_CD		VARCHAR(50) NOT NULL,
    ENTRY_DATE      DATETIME NOT NULL,
	CHANGEBY_CHAR   VARCHAR(50),
    STATUS_CD       VARCHAR(50)   
    );  

ALTER TABLE PM_USER_LOGIN
    ADD  PRIMARY KEY (ENTRY_DATE, USER_ID);	


--==============================================================
-- SQL Server Database Script to upgrade CRC from 1.7.09c to 1.7.10                  
--==============================================================

-- Drop primary key and add new index
-- If the DROP primary key fails, than use Sql Server Management Studio and manually drop the index.

ALTER TABLE PM_USER_LOGIN 
DROP PRIMARY KEY;

CREATE INDEX PM_USER_LOGIN_IDX ON PM_USER_LOGIN(USER_ID, ENTRY_DATE);
    
	
