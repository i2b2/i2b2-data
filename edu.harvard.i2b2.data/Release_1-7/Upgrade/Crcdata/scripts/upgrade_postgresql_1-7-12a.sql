--==============================================================
-- Database Script to upgrade CRC from 1.7.12a to 1.7.13                 
--==============================================================
-- Optional: support larger patient encounter collections
-- You must temorarily disable the primary key and run this line manually
--alter table QT_PATIENT_SET_COLLECTION alter column PATIENT_SET_COLL_ID BIGSERIAL
--;
-- Set age_in_num_years values in PATIENT_DIMENSION 
UPDATE PATIENT_DIMENSION
Set AGE_IN_YEARS_NUM =
case when DEATH_DATE is null then
trunc(EXTRACT(EPOCH FROM (now() - (birth_date))/3600)/8766)
else trunc(EXTRACT(EPOCH FROM (death_date - (birth_date))/3600)/8766)
End
;
