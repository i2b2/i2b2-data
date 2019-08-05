CREATE TABLE PM_USER_LOGIN ( 
	USER_ID 		VARCHAR(50) NOT NULL,
	ATTEMPT_CD		VARCHAR(50) NOT NULL,
    ENTRY_DATE      timestamp NOT NULL,
	CHANGEBY_CHAR   VARCHAR(50),
    STATUS_CD       VARCHAR(50)   
    );    
    	
CREATE INDEX PM_USER_LOGIN_IDX ON PM_USER_LOGIN(USER_ID, ENTRY_DATE);	

--==================================================================
-- PostgreSQL Database Script to upgrade CRC from 1.7.09c to 1.7.10                  
--==================================================================

-- Drop primary key and add new index

alter table pm_user_login
	drop constraint if exists pm_user_login_pk cascade 
;

create index pm_user_login_idx on pm_user_login(user_id, entry_date)
;
