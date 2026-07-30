--==============================================================
-- Database Script to upgrade CRC from 1.8.3 to 1.8.4
--==============================================================

ALTER TABLE QT_QUERY_RESULT_TYPE
ADD VISUAL_TYPE VARCHAR2(4000)
;

UPDATE QT_QUERY_RESULT_TYPE
SET VISUAL_TYPE = '{
    "COUNT": true
  }'
WHERE NAME = 'PATIENT_COUNT_XML'
;

UPDATE QT_QUERY_RESULT_TYPE
SET VISUAL_TYPE = '{
    "BARS": true,
    "TABLE": true,
    "DOWNLOAD": true
  }'
WHERE NAME IN (
    'PATIENT_GENDER_COUNT_XML',
    'PATIENT_VITALSTATUS_COUNT_XML',
    'PATIENT_RACE_COUNT_XML',
    'PATIENT_LOS_XML',
    'PATIENT_INOUT_XML'
)
;

UPDATE QT_QUERY_RESULT_TYPE
SET VISUAL_TYPE = '{
    "PIECHART": true,
    "BARS": {
      "maxLabelLength": 15
    },
    "TABLE": true,
    "DOWNLOAD": true
  }'
WHERE NAME = 'PATIENT_AGE_COUNT_XML'
;

UPDATE QT_QUERY_RESULT_TYPE
SET VISUAL_TYPE = '{
    "BARS": true,
    "TABLE": {
      "forceInitialDisplay": true
    },
    "DOWNLOAD": true
  }'
WHERE NAME IN (
    'PATIENT_TOP20MEDS_XML',
    'PATIENT_TOP20DIAG_XML'
)
;
