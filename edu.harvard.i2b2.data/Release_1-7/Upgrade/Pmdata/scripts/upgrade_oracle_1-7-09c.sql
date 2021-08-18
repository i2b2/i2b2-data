
--==============================================================
-- Oracle Database Script to upgrade CRC from 1.7.09c to 1.7.10                  
--==============================================================

-- Drop primary key and add new index

ALTER TABLE PM_USER_LOGIN 
DROP PRIMARY KEY;

CREATE INDEX PM_USER_LOGIN_IDX ON PM_USER_LOGIN(USER_ID, ENTRY_DATE)

