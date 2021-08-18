--==============================================================
-- Database Script to upgrade CRC from 1.7.12a to 1.7.13                 
--==============================================================
alter table QT_PATIENT_SET_COLLECTION alter column PATIENT_SET_COLL_ID BIGSERIAL
;
