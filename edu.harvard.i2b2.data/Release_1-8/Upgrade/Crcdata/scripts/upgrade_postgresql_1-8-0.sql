--==============================================================
-- Database Script to upgrade CRC from 1.8.0 to 1.8.1                  
--==============================================================



alter table QT_BREAKDOWN_PATH alter column VALUE type TEXT
;

insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(100,'PATIENT_DEMOGRAPHIC_REQUEST','DATA_LDS','Request Demographics Data','CATNUM','LR','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(101,'PATIENT_MEDICATION_REQUEST','DATA_LDS','Request Medication Data','CATNUM','LR','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(102,'PATIENT_PROCEDURE_REQUEST','DATA_LDS','Request Procedure Data','CATNUM','LR','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(103,'PATIENT_DIAGNOSIS_REQUEST','DATA_LDS','Request Diagnosis Data','CATNUM','LR','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(104,'PATIENT_LAB_REQUEST','DATA_LDS','Request Lab Data','CATNUM','LR','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(105,'PATIENT_DEMOGRAPHIC_CSV','MANAGER','Export Demographics Data','CATNUM','LX','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(106,'PATIENT_MEDICATION_CSV','MANAGER','Export Medication Data','CATNUM','LX','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(107,'PATIENT_PROCEDURE_CSV','MANAGER','Export Procedure Data','CATNUM','LX','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(108,'PATIENT_DIAGNOSIS_CSV','MANAGER','Export Diagnosis Data','CATNUM','LX','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(109,'PATIENT_LAB_CSV','MANAGER','Export Lab Data','CATNUM','LX','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(110,'PATIENT_MAPPING_CSV','MANAGER','Export Patient Mapping','CATNUM','LX','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(111,'PATIENT_MAPPING_REQUEST','DATA_LDS','Request Patient Mapping','CATNUM','LR','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest')
;
