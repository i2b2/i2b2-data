--==============================================================
-- Database Script to upgrade CRC from 1.7.09c to 1.7.10                  
--==============================================================

-- New column added to support new SQL breakdowns - roles based access
alter table QT_QUERY_RESULT_TYPE add (USER_ROLE_CD VARCHAR2(255))
;

-- Insert new SQL breakdowns into QT_BREAKDOWN_PATH table

insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_LOS_XML','select length_of_stay as patient_range, count(distinct a.PATIENT_num) as patient_count from visit_dimension a, DX b where a.patient_num = b.patient_num group by a.length_of_stay order by 1', SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_TOP20MEDS_XML','select * from (select b.name_char as patient_range, count(distinct a.patient_num) as patient_count from observation_fact a, concept_dimension b, DX c where a.concept_cd = b.concept_cd and concept_path like ''\i2b2\Medications\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc ) where rownum <= 20',SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_TOP20DIAG_XML','select * from (select b.name_char as patient_range, count(distinct a.patient_num) as patient_count from observation_fact a, concept_dimension b, DX c where a.concept_cd = b.concept_cd and concept_path like ''\i2b2\Diagnoses\%'' and a.patient_num = c.patient_num   group by name_char order by patient_count desc ) where rownum <= 20',SYSDATE);
insert into qt_breakdown_path (name, value, create_date) values ('PATIENT_INOUT_XML','select INOUT_CD as patient_range, count(distinct a.patient_num) as patient_count from visit_dimension a, DX b where a.patient_num = b.patient_num group by a.INOUT_CD order by 1',SYSDATE);


-- Insert new SQL breakdowns into QT_QUERY_RESULT_TYPE table

insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(10,'PATIENT_LOS_XML','DATA_LDS','Length of stay breakdown','CATNUM','LA');
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(11,'PATIENT_TOP20MEDS_XML','DATA_LDS','Top 20 medications breakdown','CATNUM','LA');
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(12,'PATIENT_TOP20DIAG_XML','DATA_LDS','Top 20 diagnoses breakdown','CATNUM','LA');
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,USER_ROLE_CD,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(13,'PATIENT_INOUT_XML','DATA_LDS','Inpatient and outpatient breakdown','CATNUM','LA');
