--==============================================================
-- Database Script to upgrade CRC from 1.8.0 to 1.8.1                  
--==============================================================



alter table QT_BREAKDOWN_PATH alter column  VALUE VARCHAR(MAX)
;

insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(14,'PATIENT_DEMOGRAPHIC_REQUEST','DATA_LDS','Request Demographics Data','CATNUM','LR','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(15,'PATIENT_MEDICATION_REQUEST','DATA_LDS','Request Medication Data','CATNUM','LR','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(16,'PATIENT_PROCEDURE_REQUEST','DATA_LDS','Request Procedure Data','CATNUM','LR','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(17,'PATIENT_DIAGNOSIS_REQUEST','DATA_LDS','Request Diagnosis Data','CATNUM','LR','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(18,'PATIENT_LAB_REQUEST','DATA_LDS','Request Lab Data','CATNUM','LR','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(19,'PATIENT_DEMOGRAPHIC_CSV','MANAGER','Export Demographics Data','CATNUM','LX','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(20,'PATIENT_MEDICATION_CSV','MANAGER','Export Medication Data','CATNUM','LX','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(21,'PATIENT_PROCEDURE_CSV','MANAGER','Export Procedure Data','CATNUM','LX','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(22,'PATIENT_DIAGNOSIS_CSV','MANAGER','Export Diagnosis Data','CATNUM','LX','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(23,'PATIENT_LAB_CSV','MANAGER','Export Lab Data','CATNUM','LX','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(24,'PATIENT_MAPPING_CSV','MANAGER','Export Patient Mapping','CATNUM','LX','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientDownload')
;
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID,CLASSNAME) values(26,'PATIENT_MAPPING_REQUEST','DATA_LDS','Request Patient Mapping','CATNUM','LR','edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientRequest')
;