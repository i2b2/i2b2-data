--==============================================================
-- Database Script to upgrade CRC from 1.7.12a to 1.7.13            
--==============================================================
 
 -- Set age_in_num_years values in PATIENT_DIMENSION
UPDATE PATIENT_DIMENSION
Set AGE_IN_YEARS_NUM=
--select age_in_years_num, trunc((( sysdate - birth_date)*24)/8766),
case when DEATH_DATE is null then
trunc((( sysdate - birth_date)*24)/8766)
else
trunc((( death_date - birth_date)*24)/8766)
end
;
