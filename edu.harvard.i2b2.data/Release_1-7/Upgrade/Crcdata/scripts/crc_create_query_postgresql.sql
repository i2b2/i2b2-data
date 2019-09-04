
--==============================================================
-- Database Script to upgrade CRC from 1.7.09c to 1.7.10                  
--==============================================================

-- New column added to support new SQL breakdowns - roles based access
alter table QT_QUERY_RESULT_TYPE add column USER_ROLE_CD VARCHAR(255)
;


--==============================================================
-- Database Script to upgrade CRC from 1.7.10 to 1.7.11                  
--==============================================================

insert into QT_PRIVILEGE(PROTECTION_LABEL_CD, DATAPROT_CD, HIVEMGMT_CD) values ('SETFINDER_QRY_PROTECTED','DATA_PROT','USER')
;

--==============================================================
-- Database Script to upgrade CRC from 1.7.11 to 1.7.12                  
--==============================================================
alter table QT_QUERY_RESULT_TYPE add column CLASSNAME VARCHAR(200)
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSetGenerator' where NAME='PATIENTSET'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultEncounterSetGenerator' where NAME='PATIENT_ENCOUNTER_SET'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientCountGenerator' where NAME='PATIENT_COUNT_XML'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator' where NAME='PATIENT_GENDER_COUNT_XML'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator' where NAME='PATIENT_VITALSTATUS_COUNT_XML'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator' where NAME='PATIENT_RACE_COUNT_XML'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator' where NAME='PATIENT_AGE_COUNT_XML'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator' where NAME='PATIENT_LOS_XML'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator' where NAME='PATIENT_TOP20MEDS_XML'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator' where NAME='PATIENT_TOP20DIAG_XML'
;
update QT_QUERY_RESULT_TYPE set CLASSNAME='edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator' where NAME='PATIENT_INOUT_XML'
;