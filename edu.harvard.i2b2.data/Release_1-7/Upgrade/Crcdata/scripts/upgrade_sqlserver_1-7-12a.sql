                                                      
--==============================================================
-- Database Script to upgrade CRC from 1.7.12a to 1.7.13                
--==============================================================
-- This line must be executed as follows due to the primary key:
-- rename PATIENT_ENC_COLL_ID to QT_PATIENT_ENC_COLLECTION_BAK, create a new table QT_PATIENT_ENC_COLLECTION 
-- and copy data from QT_PATIENT_ENC_COLLECTION_BAK to QT_PATIENT_ENC_COLLECTION
--alter table QT_PATIENT_ENC_COLLECTION alter column  PATIENT_ENC_COLL_ID BIGINT NOT NULL
--;
                                                                 
-- Set age_in_num_years values in PATIENT_DIMENSION 
UPDATE PATIENT_DIMENSION
Set AGE_IN_YEARS_NUM=
DATEDIFF(hour, BIRTH_DATE,
case when DEATH_DATE is null then getdate() else DEATH_DATE end
)/8766;
