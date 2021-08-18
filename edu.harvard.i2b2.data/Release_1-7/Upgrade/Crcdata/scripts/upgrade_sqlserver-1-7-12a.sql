                                                      
--==============================================================
-- Database Script to upgrade CRC from 1.7.12a to 1.7.13                
--==============================================================
-- if the following command belows fails due to lack of temp space, rename PATIENT_ENC_COLL_ID to QT_PATIENT_ENC_COLLECTION_BAK, create a new table QT_PATIENT_ENC_COLLECTION 
-- and copy data from QT_PATIENT_ENC_COLLECTION_BAK to QT_PATIENT_ENC_COLLECTION
alter table QT_PATIENT_ENC_COLLECTION alter column  PATIENT_ENC_COLL_ID BIGINT NOT NULL
;
                                                                 
