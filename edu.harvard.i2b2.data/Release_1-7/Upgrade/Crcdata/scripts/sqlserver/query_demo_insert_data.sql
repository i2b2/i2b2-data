--====================================================================
-- SQL Server Database Script to upgrade CRC from 1.7.09c to 1.7.10
-- Script inserts updated demo data into an upgraded 1.7.10 database
--====================================================================

-- Insert new SQL breakdowns into QT_BREAKDOWN_PATH table

insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_LOS_XML','select length_of_stay as patient_range, count(distinct a.PATIENT_num) as patient_count from {{{DATABASE_NAME}}}.visit_dimension a, {{{DATABASE_NAME}}}.#DX b where a.patient_num = b.patient_num group by a.length_of_stay order by 1', GETDATE());
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_TOP20MEDS_XML','select top 20 b.name_char as patient_range, count(distinct a.patient_num) as patient_count from {{{DATABASE_NAME}}}.observation_fact a, {{{DATABASE_NAME}}}.concept_dimension b, {{{DATABASE_NAME}}}.#DX c where a.concept_cd = b.concept_cd and concept_path like ''\i2b2\Medications\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc', GETDATE());
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_TOP20DIAG_XML','select top 20 b.name_char as patient_range, count(distinct a.patient_num) as patient_count from {{{DATABASE_NAME}}}.observation_fact a, {{{DATABASE_NAME}}}.concept_dimension b, {{{DATABASE_NAME}}}.#DX c where a.concept_cd = b.concept_cd and concept_path like ''\i2b2\Diagnoses\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc', GETDATE());
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_INOUT_XML','select INOUT_CD as patient_range, count(distinct a.patient_num) as patient_count from {{{DATABASE_NAME}}}.visit_dimension a, {{{DATABASE_NAME}}}.#DX b where a.patient_num = b.patient_num group by a.INOUT_CD order by 1', GETDATE());


-- Insert new SQL breakdowns into QT_QUERY_RESULT_TYPE table

insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(10,'PATIENT_LOS_XML','DATA_LDS','Length of stay breakdown','CATNUM','LA');
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(11,'PATIENT_TOP20MEDS_XML','DATA_LDS','Top 20 medications breakdown','CATNUM','LA');
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(12,'PATIENT_TOP20DIAG_XML','DATA_LDS','Top 20 diagnoses breakdown','CATNUM','LA');
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(13,'PATIENT_INOUT_XML','DATA_LDS','Inpatient and outpatient breakdown','CATNUM','LA');
