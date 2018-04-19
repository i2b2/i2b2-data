
--==============================================================
-- Database Script to upgrade CRC from 1.7.09c to 1.7.10                  
--==============================================================

-- New column added to support new SQL breakdowns - roles based access
alter table QT_QUERY_RESULT_TYPE add column USER_ROLE_CD VARCHAR(255)
;
