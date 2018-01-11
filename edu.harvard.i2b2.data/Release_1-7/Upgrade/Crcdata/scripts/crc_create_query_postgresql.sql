
--==============================================================
-- Database Script to upgrade CRC from 1.7.09c to 1.7.10                  
--==============================================================

alter table QT_QUERY_RESULT_TYPE add column USER_ROLE_CD VARCHAR(255)
;
