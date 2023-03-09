If OBJECT_ID('CONDITION_VIEW','V') is not null
DROP VIEW  CONDITION_VIEW;
If OBJECT_ID('DRUG_VIEW','V') is not null
DROP VIEW DRUG_VIEW;
If OBJECT_ID('MEASUREMENT_VIEW','V') is not null
DROP VIEW MEASUREMENT_VIEW;
If OBJECT_ID('OBSERVATION_VIEW','V') is not null
DROP VIEW OBSERVATION_VIEW;
If OBJECT_ID('PROCEDURE_VIEW','V') is not null
DROP VIEW PROCEDURE_VIEW;
If OBJECT_ID('COVID_LAB_VIEW','V') is not null
DROP VIEW COVID_LAB_VIEW;
If OBJECT_ID('ALL_SOURCE_CONCEPTS','V') is not null
DROP VIEW ALL_SOURCE_CONCEPTS;
If OBJECT_ID('PATIENT_DIMENSION','V') is not null
DROP VIEW PATIENT_DIMENSION;
If OBJECT_ID('VISIT_DIMENSION','V') is not null
DROP VIEW VISIT_DIMENSION;
If OBJECT_ID('DEVICE_VIEW','V') is not null
DROP VIEW DEVICE_VIEW;

If OBJECT_ID('DX_SOURCE_CONCEPTS','V') is not null
DROP VIEW  DX_SOURCE_CONCEPTS;
If OBJECT_ID('DRUG_SOURCE_CONCEPTS','V') is not null
DROP VIEW DRUG_SOURCE_CONCEPTS;
If OBJECT_ID('MEASUREMENT_SOURCE_CONCEPTS','V') is not null
DROP VIEW MEASUREMENT_SOURCE_CONCEPTS;
If OBJECT_ID('OBSERVATION_SOURCE_CONCEPTS','V') is not null
DROP VIEW OBSERVATION_SOURCE_CONCEPTS;
If OBJECT_ID('PROCEDURE_SOURCE_CONCEPTS','V') is not null
DROP VIEW PROCEDURE_SOURCE_CONCEPTS;
If OBJECT_ID('COVID_LAB_SOURCE_CONCEPTS','V') is not null
DROP VIEW COVID_LAB_SOURCE_CONCEPTS;
If OBJECT_ID('DEVICE_SOURCE_CONCEPTS','V') is not null
DROP VIEW DEVICE_SOURCE_CONCEPTS;

/****** Object:  View ALL_SOURCE_CONCEPTS  ******/

CREATE  VIEW ALL_SOURCE_CONCEPTS (ENCOUNTER_NUM, PATIENT_NUM, CONCEPT_CD, PROVIDER_ID, START_DATE, MODIFIER_CD, 
INSTANCE_NUM, VALTYPE_CD, TVAL_CHAR, NVAL_NUM, VALUEFLAG_CD,  quantity_num, UNITS_CD,  END_DATE, LOCATION_CD,  OBSERVATION_BLOB, CONFIDENCE_NUM, update_date, download_date, import_date, SOURCESYSTEM_CD,   UPLOAD_ID, text_search_index) AS 

SELECT        ENCOUNTER_NUM, PATIENT_NUM, CONCEPT_CD, PROVIDER_ID, START_DATE, END_DATE, MODIFIER_CD, INSTANCE_NUM, valtype_cd, location_cd, tval_char, nval_num, valueflag_cd,  units_cd,  OBSERVATION_BLOB, 
                          SOURCESYSTEM_CD , UPLOAD_ID  , null as quanity_num, null as text_search_index, null as update_date, null as download_date, null as import_date, null as CONFIDENCE_NUM
FROM            (SELECT        visit_occurrence_id AS ENCOUNTER_NUM, person_id AS PATIENT_NUM, CAST(condition_source_concept_id AS varchar(50)) AS CONCEPT_CD, isnull(CAST(provider_id AS VARCHAR(50)),'@') AS PROVIDER_ID, 
                                                    condition_start_datetime AS START_DATE, condition_end_datetime AS END_DATE, '@' AS MODIFIER_CD, 1 AS INSTANCE_NUM, NULL AS valtype_cd, NULL AS location_cd, NULL AS tval_char, NULL 
                                                    AS nval_num, NULL AS valueflag_cd, NULL AS units_cd, condition_concept_id AS OBSERVATION_BLOB, condition_source_value AS SOURCESYSTEM_CD, 1 AS UPLOAD_ID, null as quantity_num, null as text_search_index, null as update_date, null as download_date, null as import_date, null as confidence_num
                          FROM            CONDITION_OCCURRENCE AS x
                          UNION
                          SELECT        visit_occurrence_id AS ENCOUNTER_NUM, person_id AS PATIENT_NUM, CAST(drug_source_concept_id AS varchar(50)) AS CONCEPT_CD, isnull(CAST(provider_id AS VARCHAR(50)),'@') AS PROVIDER_ID, 
                                                   drug_exposure_start_datetime AS START_DATE, drug_exposure_end_datetime AS END_DATE, '@' AS MODIFIER_CD, 1 AS INSTANCE_NUM, NULL AS valtype_cd, NULL AS location_cd, NULL 
                                                   AS tval_char, NULL AS nval_num, NULL AS valueflag_cd, NULL AS units_cd, drug_concept_id AS OBSERVATION_BLOB, drug_source_value AS SOURCESYSTEM_CD, 1 AS UPLOAD_ID, null as quantity_num, null as text_search_index, null as update_date, null as download_date, null as import_date, null as confidence_num
                          FROM            DRUG_EXPOSURE
                          UNION
                          SELECT        visit_occurrence_id AS ENCOUNTER_NUM, person_id AS PATIENT_NUM, CAST(procedure_source_concept_id AS varchar(50)) AS CONCEPT_CD, isnull(CAST(provider_id AS VARCHAR(50)),'@') AS PROVIDER_ID, 
                                                   procedure_datetime AS START_DATE, NULL AS END_DATE, '@' AS MODIFIER_CD, 1 AS INSTANCE_NUM, NULL AS valtype_cd, NULL AS location_cd, NULL AS tval_char, NULL AS nval_num, NULL 
                                                   AS valueflag_cd, NULL AS units_cd, procedure_concept_id AS OBSERVATION_BLOB, procedure_source_value AS SOURCESYSTEM_CD, 1 AS UPLOAD_ID, null as quantity_num, null as text_search_index, null as update_date, null as download_date, null as import_date, null as confidence_num
                          FROM            PROCEDURE_OCCURRENCE
                          UNION
                          SELECT        visit_occurrence_id AS ENCOUNTER_NUM, person_id AS PATIENT_NUM, CAST(device_source_concept_id AS varchar(50)) AS CONCEPT_CD, isnull(CAST(provider_id AS VARCHAR(50)),'@') AS PROVIDER_ID, 
                                                   device_exposure_start_datetime AS START_DATE, device_exposure_end_datetime AS END_DATE, CAST(device_type_concept_id AS VARCHAR(50)) AS MODIFIER_CD, 1 AS INSTANCE_NUM, NULL 
                                                   AS valtype_cd, NULL AS location_cd, NULL AS tval_char, NULL AS nval_num, NULL AS valueflag_cd, NULL AS units_cd, device_exposure_id AS OBSERVATION_BLOB, device_source_value AS SOURCESYSTEM_CD, 
                                                   1 AS UPLOAD_ID, null as quantity_num, null as text_search_index, null as update_date, null as download_date, null as import_date, null as confidence_num
                          FROM            DEVICE_EXPOSURE
                          UNION
                          SELECT        visit_occurrence_id AS ENCOUNTER_NUM, person_id AS PATIENT_NUM, CAST(measurement_source_concept_id AS varchar(50)) AS CONCEPT_CD, isnull(CAST(provider_id AS VARCHAR(50)),'@') AS PROVIDER_ID, 
                                                   measurement_datetime AS START_DATE, NULL AS END_DATE, CAST(measurement_type_concept_id AS varchar(50)) AS MODIFIER_CD, 1 AS INSTANCE_NUM, CASE WHEN VALUE_AS_NUMBER IS NOT NULL 
                                                   THEN 'N' ELSE 'T' END AS valtype_cd, NULL AS location_cd, 
                                                   CASE WHEN OPERATOR_CONCEPT_ID = 4172703 THEN 'E' WHEN OPERATOR_CONCEPT_ID = 4171756 THEN 'LT' WHEN OPERATOR_CONCEPT_ID = 4172704 THEN 'GT' WHEN OPERATOR_CONCEPT_ID = 4171754
                                                    THEN 'LE' WHEN OPERATOR_CONCEPT_ID = 4171755 THEN 'GE' WHEN OPERATOR_CONCEPT_ID IS NULL AND VALUE_AS_NUMBER IS NOT NULL THEN 'E' ELSE VALUE_SOURCE_VALUE END AS TVAL_CHAR, 
                                                   value_as_number AS NVAL_NUM, CAST(value_as_concept_id AS VARCHAR(50)) AS VALUEFLAG_CD, unit_source_value AS UNITS_CD, measurement_concept_id AS OBSERVATION_BLOB, 
                                                   measurement_source_value AS SOURCESYSTEM_CD, 1  AS UPLOAD_ID, null as quantity_num, null as text_search_index, null as update_date, null as download_date, null as import_date, null as confidence_num
                          FROM            MEASUREMENT
                          UNION
                          SELECT        visit_occurrence_id AS ENCOUNTER_NUM, person_id AS PATIENT_NUM, CAST(observation_source_concept_id AS VARCHAR(50)) AS CONCEPT_CD, isnull(CAST(provider_id AS VARCHAR(50)),'@') AS PROVIDER_ID, 
                                                   observation_datetime AS START_DATE, NULL AS END_DATE, CAST(observation_type_concept_id AS VARCHAR(50)) AS MODIFIER_CD, 1 AS INSTANCE_NUM, CASE WHEN VALUE_AS_NUMBER IS NOT NULL 
                                                   THEN 'N' ELSE 'T' END AS valtype_cd, NULL AS location_cd, value_as_string AS TVAL_CHAR, value_as_number AS NVAL_NUM, CAST(qualifier_concept_id AS VARCHAR(50)) AS VALUEFLAG_CD, 
                                                   unit_source_value AS UNITS_CD, observation_concept_id AS OBSERVATION_BLOB, observation_source_value AS SOURCESYSTEM_CD, 1 AS UPLOAD_ID,  null as quantity_num, null as text_search_index, null as update_date, null as download_date, null as import_date, null as confidence_num
                          FROM            OBSERVATION) AS x
;

CREATE  VIEW VISIT_DIMENSION
	(
		ENCOUNTER_NUM,
		PATIENT_NUM,
		ACTIVE_STATUS_CD,
		START_DATE,
		END_DATE,
		INOUT_CD,
		LOCATION_CD,
		LOCATION_PATH,
		LENGTH_OF_STAY,
		VISIT_BLOB,
		UPDATE_DATE,
		DOWNLOAD_DATE,
		IMPORT_DATE,
		SOURCESYSTEM_CD,
		UPLOAD_ID 
	)
	AS 
SELECT
	VISIT_OCCURRENCE_ID,
	PERSON_ID,
	NULL,
	VISIT_START_DATE,
	VISIT_END_DATE,
	VISIT_CONCEPT_ID,
	CARE_SITE_ID,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL 
FROM
	VISIT_OCCURRENCE;


CREATE  VIEW PATIENT_DIMENSION
    (
        PATIENT_NUM,
        VITAL_STATUS_CD,
        BIRTH_DATE,
        DEATH_DATE,
        SEX_CD,
        AGE_IN_YEARS_NUM,
        LANGUAGE_CD,
        RACE_CD,
        MARITAL_STATUS_CD,
        RELIGION_CD,
        ZIP_CD,
        STATECITYZIP_PATH,
        INCOME_CD,
        PATIENT_BLOB,
        UPDATE_DATE,
        DOWNLOAD_DATE,
        IMPORT_DATE,
        SOURCESYSTEM_CD,
        UPLOAD_ID,
        ETHNICITY_CD
    )
    AS

SELECT        person_id AS PATIENT_NUM, CASE WHEN year_of_birth IS  NULL THEN 'Y' else 'N' END AS VITAL_STATUS_CD,
(CONCAT(YEAR_OF_BIRTH,'-',  MONTH_OF_BIRTH,'-',day_of_birth) )AS BIRTH_DATE,
cast (null as date) AS DEATH_DATE, CONVERT(char, gender_concept_id) AS SEX_CD,
DATEDIFF(hour, birth_datetime,
 getdate() )/8766 
                         AS AGE_IN_YEARS_NUM, NULL AS LANGUAGE_CD,CONVERT(char, RACE_CONCEPT_ID) AS RACE_CD, NULL AS MARITAL_STATUS_CD,
						 NULL AS RELIGION_CD, NULL AS ZIP_CD, NULL AS STATECITYZIP_PATH, NULL AS INCOME_CD, NULL 
                         AS PATIENT_BLOB, CAST(NULL AS DATE) AS UPDATE_DATE, CAST(NULL AS DATE) AS DOWNLOAD_DATE, CAST(NULL AS DATE) 
						 AS IMPORT_DATE, NULL AS SOURCESYSTEM_CD, NULL AS UPLOAD_ID, 
                        CONVERT(char, ethnicity_concept_id) AS ETHNICITY_CD
FROM            PERSON
;

/******* OMOP FACT TABLE VIEWS ************/

CREATE  VIEW CONDITION_VIEW AS 
SELECT  
			visit_occurrence_id AS ENCOUNTER_NUM, 
 			PERSON_ID AS PATIENT_NUM, 
   			cast(condition_concept_id as varchar(50)) AS CONCEPT_CD, 
   			isnull(CAST(provider_id AS VARCHAR(50)),'@') AS PROVIDER_ID, 
   			condition_start_datetime AS START_DATE, 
			condition_end_datetime AS END_DATE, 
            '@' AS MODIFIER_CD,
            1 AS INSTANCE_NUM,
            NULL AS valtype_cd,
            NULL AS location_cd,
            NULL AS tval_char,
            NULL AS nval_num,
            NULL AS valueflag_cd,
            NULL AS units_cd,
            NULL CONFIDENCE_NUM, 
            NULL SOURCESYSTEM_CD, 
            NULL UPDATE_DATE, 
            NULL DOWNLOAD_DATE, 
            NULL IMPORT_DATE, 
            NULL OBSERVATION_BLOB,
            NULL UPLOAD_ID,
            NULL as quantity_num,
   			condition_SOURCE_concept_id AS SOURCE_CONCEPT_ID,
            condition_source_value AS SOURCE_VALUE,
            'CONDITION' AS DOMAIN_ID
--			condition_occurrence_id integer NOT NULL, 
--			condition_start_datetime TIMESTAMP NULL, 
--			condition_end_datetime TIMESTAMP NULL, 
--			condition_type_concept_id integer NOT NULL, --modifier?
--			stop_reason varchar(20) NULL, 
--			visit_detail_id integer NULL, 
--			condition_status_source_value varchar(50) NULL );  
FROM CONDITION_OCCURRENCE;

CREATE  VIEW DEVICE_VIEW AS 
SELECT 
			visit_occurrence_id AS ENCOUNTER_NUM, 
 			PERSON_ID AS PATIENT_NUM,
   			CAST(device_exposure_id AS VARCHAR(50)) AS CONCEPT_CD, 
   			isnull(CAST(provider_id AS VARCHAR(50)),'@') AS PROVIDER_ID, 
   			device_exposure_start_datetime AS START_DATE, 
			device_exposure_end_datetime AS END_DATE, 
            isnull(CAST(device_type_concept_id AS VARCHAR(50)),'@') AS MODIFIER_CD,
            1 AS INSTANCE_NUM,
            NULL AS valtype_cd,
            NULL AS location_cd,
            NULL AS tval_char,
            NULL AS nval_num,
            NULL AS valueflag_cd,
            NULL AS units_cd,
            NULL CONFIDENCE_NUM, 
            NULL SOURCESYSTEM_CD, 
            NULL UPDATE_DATE, 
            NULL DOWNLOAD_DATE, 
            NULL IMPORT_DATE, 
            NULL OBSERVATION_BLOB,
            NULL UPLOAD_ID,
            NULL as quantity_num,
   			DEVICE_SOURCE_CONCEPT_ID AS SOURCE_CONCEPT_ID, --device_concept_id??
            device_source_value AS SOURCE_VALUE,
            'DEVICE' AS DOMAIN_ID
--			device_exposure_start_datetime TIMESTAMP NULL, 
--			device_exposure_end_datetime TIMESTAMP NULL, 
--			unique_device_id varchar(50) NULL, 
--			quantity integer NULL, 
--			visit_detail_id integer NULL, 
FROM DEVICE_EXPOSURE;

CREATE  VIEW DRUG_VIEW AS 
SELECT 
 			visit_occurrence_id AS ENCOUNTER_NUM, 
 			PERSON_ID AS PATIENT_NUM, 
   			cast(drug_concept_id as varchar(50)) AS CONCEPT_CD, 
   			isnull(CAST(provider_id AS VARCHAR(50)),'@') AS PROVIDER_ID, 
   			drug_exposure_start_datetime AS START_DATE, 
			drug_exposure_END_datetime AS END_DATE, 
            '@' AS MODIFIER_CD,
            1 AS INSTANCE_NUM,
            NULL AS valtype_cd,
            NULL AS location_cd,
            NULL AS tval_char,
            NULL AS nval_num,
            NULL AS valueflag_cd,
            NULL AS units_cd,
            NULL CONFIDENCE_NUM, 
            NULL SOURCESYSTEM_CD, 
            NULL UPDATE_DATE, 
            NULL DOWNLOAD_DATE, 
            NULL IMPORT_DATE, 
            NULL OBSERVATION_BLOB,
            NULL UPLOAD_ID,
            NULL as quantity_num,
   			drug_source_concept_id AS SOURCE_CONCEPT_ID,
            drug_source_value AS SOURCE_VALUE,
            'DRUG' AS DOMAIN_ID
--			drug_exposure_start_datetime TIMESTAMP NULL, 
--			drug_exposure_end_datetime TIMESTAMP NULL, 
--			verbatim_end_date date NULL, 
--			drug_type_concept_id integer NOT NULL, 
--			stop_reason varchar(20) NULL, 
--			refills integer NULL, 
--			quantity float NULL, 
--			days_supply integer NULL, 
--			sig CLOB NULL, 
--			route_concept_id integer NULL, 
--			lot_number varchar(50) NULL, 
--			visit_detail_id integer NULL, 
--			route_source_value varchar(50) NULL, 
--			dose_unit_source_value varchar(50) NULL );  
FROM DRUG_EXPOSURE;

 CREATE  VIEW MEASUREMENT_VIEW as
  SELECT
	VISIT_OCCURRENCE_ID ENCOUNTER_NUM,
	PERSON_ID PATIENT_NUM,
	CAST(MEASUREMENT_CONCEPT_ID AS VARCHAR(50)) CONCEPT_CD,
	isnull(CAST(provider_id AS VARCHAR(50)),'@') AS PROVIDER_ID, 
	MEASUREMENT_DATE AS START_DATE,
    NULL AS end_DATE,
	'@' AS MODIFIER_CD,
	1 INSTANCE_NUM,
	CASE 
		WHEN VALUE_AS_NUMBER IS NOT NULL 
		THEN 'N' 
		ELSE 'T' 
	END AS VALTYPE_CD,
    NULL AS LOCATION_CD,
	CASE 
		WHEN OPERATOR_CONCEPT_ID = 4172703 
		THEN 'E' 
		WHEN OPERATOR_CONCEPT_ID = 4171756 
		THEN 'LT' 
		WHEN OPERATOR_CONCEPT_ID = 4172704 
		THEN 'GT' 
		WHEN OPERATOR_CONCEPT_ID = 4171754 
		THEN 'LE' 
		WHEN OPERATOR_CONCEPT_ID = 4171755 
		THEN 'GE' 
		WHEN OPERATOR_CONCEPT_ID IS NULL 
		THEN 'E' 
		ELSE NULL 
	END AS TVAL_CHAR ,
	VALUE_AS_NUMBER AS NVAL_NUM,
   	CAST(VALUE_AS_CONCEPT_ID AS VARCHAR(50)) AS VALUEFLAG_CD,
    UNIT_SOURCE_VALUE AS UNITS_CD, 
    NULL CONFIDENCE_NUM, 
    NULL SOURCESYSTEM_CD, 
    NULL UPDATE_DATE, 
    NULL DOWNLOAD_DATE, 
    NULL IMPORT_DATE, 
    NULL OBSERVATION_BLOB,
    NULL UPLOAD_ID,
    NULL as quantity_num,
	measurement_source_concept_id AS SOURCE_CONCEPT_ID, 
    measurement_source_value AS SOURCE_VALUE,
    'MEASUREMENT' AS DOMAIN_ID
FROM
	MEASUREMENT;

CREATE  VIEW OBSERVATION_VIEW AS
SELECT
	VISIT_OCCURRENCE_ID AS ENCOUNTER_NUM,
	PERSON_ID AS PATIENT_NUM,
    CAST(OBSERVATION_CONCEPT_ID AS VARCHAR(50)) AS CONCEPT_CD, 
    isnull(CAST(provider_id AS VARCHAR(50)),'@') AS PROVIDER_ID, 
	OBSERVATION_DATE AS START_DATE,
    NULL AS END_DATE,
	'@' AS MODIFIER_CD,
	1 as INSTANCE_NUM,
    CASE 
       WHEN VALUE_AS_NUMBER IS NOT NULL 
       THEN 'N' 
       ELSE 'T' 
    END AS valtype_cd, --DECODE THIS IS THE FUTURE operator_concept_id
	NULL AS LOCATION_CD,
    CASE 
        WHEN VALUE_AS_NUMBER IS NOT NULL THEN 'E' 
        ELSE VALUE_AS_STRING 
        END AS TVAL_CHAR,
    VALUE_AS_NUMBER AS NVAL_NUM,
    CAST(VALUE_AS_CONCEPT_ID AS VARCHAR(50)) AS VALUEFLAG_CD,
    UNIT_SOURCE_VALUE AS UNITS_CD,
    NULL CONFIDENCE_NUM, 
            NULL SOURCESYSTEM_CD, 
            NULL UPDATE_DATE, 
            NULL DOWNLOAD_DATE, 
            NULL IMPORT_DATE, 
            NULL OBSERVATION_BLOB,
            NULL UPLOAD_ID,
            NULL quantity_num,
    observation_SOURCE_concept_id AS SOURCE_CONCEPT_ID, 
    observation_source_value AS SOURCE_VALUE,
    'OBSERVATION' AS DOMAIN_ID
FROM
	OBSERVATION;

CREATE  VIEW PROCEDURE_VIEW AS 
SELECT
 			visit_occurrence_id AS ENCOUNTER_NUM, 
 			PERSON_ID AS PATIENT_NUM, 
   			cast(procedure_concept_id as varchar(50)) AS CONCEPT_CD, 
   			isnull(CAST(provider_id AS VARCHAR(50)),'@') AS PROVIDER_ID, 
   			procedure_datetime AS START_DATE, 
			NULL AS END_DATE, 
            '@' AS MODIFIER_CD,
            1 AS INSTANCE_NUM,
            NULL AS valtype_cd,
            NULL AS location_cd,
            NULL AS tval_char,
            NULL AS nval_num,
            NULL AS valueflag_cd,
            NULL AS units_cd,
            NULL CONFIDENCE_NUM, 
            NULL SOURCESYSTEM_CD, 
            NULL UPDATE_DATE, 
            NULL DOWNLOAD_DATE, 
            NULL IMPORT_DATE, 
            NULL UPLOAD_ID,
            NULL OBSERVATION_BLOB,
    		NULL quantity_num,
            procedure_source_concept_id AS SOURCE_CONCEPT_ID,
            procedure_source_value AS SOURCE_VALUE,
            'PROCEDURE' AS DOMAIN_ID
--			procedure_occurrence_id integer NOT NULL, 
--			procedure_datetime TIMESTAMP NULL, 
--			procedure_type_concept_id integer NOT NULL, 
--			modifier_concept_id integer NULL, 
--			quantity integer NULL, 
--			visit_detail_id integer NULL, 
--			modifier_source_value varchar(50) NULL );  
FROM PROCEDURE_OCCURRENCE;

/****** Object:  View COVID_LAB_VIEW ******/
/* Columns are not in the right order */
CREATE  VIEW COVID_LAB_VIEW 
(PATIENT_NUM, CONCEPT_CD, ENCOUNTER_NUM, INSTANCE_NUM, PROVIDER_ID, START_DATE, MODIFIER_CD, 
OBSERVATION_BLOB, VALTYPE_CD, TVAL_CHAR, 
NVAL_NUM, VALUEFLAG_CD, QUANTITY_NUM, UNITS_CD, 
END_DATE, LOCATION_CD, CONFIDENCE_NUM, SOURCESYSTEM_CD, UPDATE_DATE, DOWNLOAD_DATE, IMPORT_DATE, UPLOAD_ID, STANDARD_CONCEPT_ID, SOURCE_VALUE, DOMAIN_ID) as
SELECT
 			PERSON_ID AS PATIENT_NUM, 
   			CONCAT(CAST(measurement_source_concept_id AS VARCHAR(25)),' ',CAST(VALUE_AS_CONCEPT_ID AS VARCHAR(24))) AS CONCEPT_CD,
            visit_occurrence_id AS ENCOUNTER_NUM, 
            1 AS INSTANCE_NUM,
   			isnull(CAST(provider_id AS VARCHAR(50)),'@') AS PROVIDER_ID, 
   			measurement_datetime AS START_DATE,
            '@' AS MODIFIER_CD, --measurement_type_concept_id
            NULL AS OBSERVATION_BLOB,
            CASE 
               WHEN VALUE_AS_NUMBER IS NOT NULL 
               THEN 'N' 
               ELSE 'T' 
            END AS valtype_cd, --DECODE THIS IS THE FUTURE operator_concept_id
            CASE 
                WHEN OPERATOR_CONCEPT_ID = 4172703 THEN 'E' 
                WHEN OPERATOR_CONCEPT_ID = 4171756 THEN 'LT' 
                WHEN OPERATOR_CONCEPT_ID = 4172704 THEN 'GT' 
                WHEN OPERATOR_CONCEPT_ID = 4171754 THEN 'LE' 
                WHEN OPERATOR_CONCEPT_ID = 4171755 THEN 'GE' 
                WHEN OPERATOR_CONCEPT_ID IS NULL AND VALUE_AS_NUMBER IS NOT NULL THEN 'E' 
                ELSE VALUE_SOURCE_VALUE 
            END AS TVAL_CHAR,
            VALUE_AS_NUMBER AS NVAL_NUM,
           	CAST(VALUE_AS_CONCEPT_ID AS VARCHAR(50)) AS VALUEFLAG_CD,
            NULL AS QUANTITY_NUM,
            UNIT_SOURCE_VALUE AS UNITS_CD, -- DECODE THIS TO QUERY BY VALUE unit_concept_id IN THE FUTURE FOR NOW JUST USE THE UNIT SOURCE VALUE
            NULL END_DATE, 
            NULL LOCATION_CD, 
            NULL CONFIDENCE_NUM, 
            NULL SOURCESYSTEM_CD, 
            NULL UPDATE_DATE, 
            NULL DOWNLOAD_DATE, 
            NULL IMPORT_DATE, 
            NULL OBSERVATION_BLOB,
            NULL UPLOAD_ID,
           	measurement_concept_id AS STANDARD_CONCEPT_ID, 
            measurement_source_value AS SOURCE_VALUE,
            'MEASUREMENT' AS DOMAIN_ID  
FROM MEASUREMENT 
WHERE MEASUREMENT_SOURCE_CONCEPT_ID IN (586515,586516,586517,586518,586519,586520,586521,586522,586523,586524,586525,586526,
586527,586528,586529,706154,706155,706156,706157,706159,706160,706161,706163,706165,706166,706167,706168,706170,706171,706172,
706173,706174,706175,706177,706178,706180,706181,715260,715261,715262,715272,723459,723463,723464,723465,723466,723467,723468,
723469,723470,723471,723472,723473,723474,723475,723476,723477,723478,723479,723480,757677,757678,757679,757680,757685,757686,
36659631,36661369,36661370,36661371,36661372,36661373,36661374,36661375,36661377,36661378) ;

/************************ OMOP_SOURCE_FACT TABLE VIEWS ***************************/
CREATE  VIEW DX_SOURCE_CONCEPTS AS 
SELECT  
			visit_occurrence_id AS ENCOUNTER_NUM, 
 			PERSON_ID AS PATIENT_NUM, 
   			cast(condition_source_concept_id as varchar(50)) AS CONCEPT_CD, 
   			isnull(CAST(provider_id AS VARCHAR(50)),'@') AS PROVIDER_ID, 
   			condition_start_datetime AS START_DATE, 
			condition_end_datetime AS END_DATE, 
            '@' AS MODIFIER_CD,
            1 AS INSTANCE_NUM,
            NULL AS valtype_cd,
            NULL AS location_cd,
            NULL AS tval_char,
            NULL AS nval_num,
            NULL AS valueflag_cd,
            NULL AS units_cd,
            NULL CONFIDENCE_NUM, 
            NULL SOURCESYSTEM_CD, 
            NULL UPDATE_DATE, 
            NULL DOWNLOAD_DATE, 
            NULL IMPORT_DATE, 
            NULL OBSERVATION_BLOB,
            NULL UPLOAD_ID,
            NULL as quantity_num,
   			condition_SOURCE_concept_id AS SOURCE_CONCEPT_ID,
            condition_source_value AS SOURCE_VALUE,
            'CONDITION' AS DOMAIN_ID
--			condition_occurrence_id integer NOT NULL, 
--			condition_start_datetime TIMESTAMP NULL, 
--			condition_end_datetime TIMESTAMP NULL, 
--			condition_type_concept_id integer NOT NULL, --modifier?
--			stop_reason varchar(20) NULL, 
--			visit_detail_id integer NULL, 
--			condition_status_source_value varchar(50) NULL );  
FROM CONDITION_OCCURRENCE;

CREATE  VIEW DEVICE_SOURCE_CONCEPTS AS 
SELECT 
			visit_occurrence_id AS ENCOUNTER_NUM, 
 			PERSON_ID AS PATIENT_NUM,
   			CAST(device_source_concept_id AS VARCHAR(50)) AS CONCEPT_CD, 
   			isnull(CAST(provider_id AS VARCHAR(50)),'@') AS PROVIDER_ID, 
   			device_exposure_start_datetime AS START_DATE, 
			device_exposure_end_datetime AS END_DATE, 
            isnull(CAST(device_type_concept_id AS VARCHAR(50)),'@') AS MODIFIER_CD,
            1 AS INSTANCE_NUM,
            NULL AS valtype_cd,
            NULL AS location_cd,
            NULL AS tval_char,
            NULL AS nval_num,
            NULL AS valueflag_cd,
            NULL AS units_cd,
            NULL CONFIDENCE_NUM, 
            NULL SOURCESYSTEM_CD, 
            NULL UPDATE_DATE, 
            NULL DOWNLOAD_DATE, 
            NULL IMPORT_DATE, 
            NULL OBSERVATION_BLOB,
            NULL UPLOAD_ID,
            NULL as quantity_num,
   			DEVICE_SOURCE_CONCEPT_ID AS SOURCE_CONCEPT_ID, --device_concept_id??
            device_source_value AS SOURCE_VALUE,
            'DEVICE' AS DOMAIN_ID
--			device_exposure_start_datetime TIMESTAMP NULL, 
--			device_exposure_end_datetime TIMESTAMP NULL, 
--			unique_device_id varchar(50) NULL, 
--			quantity integer NULL, 
--			visit_detail_id integer NULL, 
FROM DEVICE_EXPOSURE;

CREATE  VIEW DRUG_SOURCE_CONCEPTS AS 
SELECT 
 			visit_occurrence_id AS ENCOUNTER_NUM, 
 			PERSON_ID AS PATIENT_NUM, 
   			cast(drug_source_concept_id as varchar(50)) AS CONCEPT_CD, 
   			isnull(CAST(provider_id AS VARCHAR(50)),'@') AS PROVIDER_ID, 
   			drug_exposure_start_datetime AS START_DATE, 
			drug_exposure_END_datetime AS END_DATE, 
            '@' AS MODIFIER_CD,
            1 AS INSTANCE_NUM,
            NULL AS valtype_cd,
            NULL AS location_cd,
            NULL AS tval_char,
            NULL AS nval_num,
            NULL AS valueflag_cd,
            NULL AS units_cd,
            NULL CONFIDENCE_NUM, 
            NULL SOURCESYSTEM_CD, 
            NULL UPDATE_DATE, 
            NULL DOWNLOAD_DATE, 
            NULL IMPORT_DATE, 
            NULL OBSERVATION_BLOB,
            NULL UPLOAD_ID,
            NULL as quantity_num,
   			drug_source_concept_id AS SOURCE_CONCEPT_ID,
            drug_source_value AS SOURCE_VALUE,
            'DRUG' AS DOMAIN_ID
--			drug_exposure_start_datetime TIMESTAMP NULL, 
--			drug_exposure_end_datetime TIMESTAMP NULL, 
--			verbatim_end_date date NULL, 
--			drug_type_concept_id integer NOT NULL, 
--			stop_reason varchar(20) NULL, 
--			refills integer NULL, 
--			quantity float NULL, 
--			days_supply integer NULL, 
--			sig CLOB NULL, 
--			route_concept_id integer NULL, 
--			lot_number varchar(50) NULL, 
--			visit_detail_id integer NULL, 
--			route_source_value varchar(50) NULL, 
--			dose_unit_source_value varchar(50) NULL );  
FROM DRUG_EXPOSURE;

 CREATE  VIEW MEASUREMENT_SOURCE_CONCEPTS as
  SELECT
	VISIT_OCCURRENCE_ID ENCOUNTER_NUM,
	PERSON_ID PATIENT_NUM,
	CAST(MEASUREMENT_SOURCE_CONCEPT_ID AS VARCHAR(50)) CONCEPT_CD,
	isnull(CAST(provider_id AS VARCHAR(50)),'@') AS PROVIDER_ID, 
	MEASUREMENT_DATE AS START_DATE,
    NULL AS end_DATE,
	'@' AS MODIFIER_CD,
	1 INSTANCE_NUM,
	CASE 
		WHEN VALUE_AS_NUMBER IS NOT NULL 
		THEN 'N' 
		ELSE 'T' 
	END AS VALTYPE_CD,
    NULL AS LOCATION_CD,
	CASE 
		WHEN OPERATOR_CONCEPT_ID = 4172703 
		THEN 'E' 
		WHEN OPERATOR_CONCEPT_ID = 4171756 
		THEN 'LT' 
		WHEN OPERATOR_CONCEPT_ID = 4172704 
		THEN 'GT' 
		WHEN OPERATOR_CONCEPT_ID = 4171754 
		THEN 'LE' 
		WHEN OPERATOR_CONCEPT_ID = 4171755 
		THEN 'GE' 
		WHEN OPERATOR_CONCEPT_ID IS NULL 
		THEN 'E' 
		ELSE NULL 
	END AS TVAL_CHAR ,
	VALUE_AS_NUMBER AS NVAL_NUM,
   	CAST(VALUE_AS_CONCEPT_ID AS VARCHAR(50)) AS VALUEFLAG_CD,
    UNIT_SOURCE_VALUE AS UNITS_CD, 
    NULL CONFIDENCE_NUM, 
    NULL SOURCESYSTEM_CD, 
    NULL UPDATE_DATE, 
    NULL DOWNLOAD_DATE, 
    NULL IMPORT_DATE,  
    NULL OBSERVATION_BLOB, 
    NULL UPLOAD_ID,
    NULL as quantity_num,
	measurement_source_concept_id AS SOURCE_CONCEPT_ID, 
    measurement_source_value AS SOURCE_VALUE,
    'MEASUREMENT' AS DOMAIN_ID
FROM
	MEASUREMENT;

CREATE  VIEW OBSERVATION_SOURCE_CONCEPTS AS
SELECT
	VISIT_OCCURRENCE_ID AS ENCOUNTER_NUM,
	PERSON_ID AS PATIENT_NUM,
    CAST(OBSERVATION_SOURCE_CONCEPT_ID AS VARCHAR(50)) AS CONCEPT_CD, 
    isnull(CAST(provider_id AS VARCHAR(50)),'@') AS PROVIDER_ID, 
	OBSERVATION_DATE AS START_DATE,
    NULL AS END_DATE,
	'@' AS MODIFIER_CD,
	1 as INSTANCE_NUM,
    CASE 
       WHEN VALUE_AS_NUMBER IS NOT NULL 
       THEN 'N' 
       ELSE 'T' 
    END AS valtype_cd, --DECODE THIS IS THE FUTURE operator_concept_id
	NULL AS LOCATION_CD,
    CASE 
        WHEN VALUE_AS_NUMBER IS NOT NULL THEN 'E' 
        ELSE OBSERVATION_SOURCE_VALUE 
        END AS TVAL_CHAR,
    VALUE_AS_NUMBER AS NVAL_NUM,
    CAST(VALUE_AS_CONCEPT_ID AS VARCHAR(50)) AS VALUEFLAG_CD,
    UNIT_SOURCE_VALUE AS UNITS_CD,
    NULL CONFIDENCE_NUM, 
            NULL SOURCESYSTEM_CD, 
            NULL UPDATE_DATE, 
            NULL DOWNLOAD_DATE, 
            NULL IMPORT_DATE,
            NULL OBSERVATION_BLOB, 
            NULL UPLOAD_ID,
            NULL quantity_num,
    observation_SOURCE_concept_id AS SOURCE_CONCEPT_ID, 
    observation_source_value AS SOURCE_VALUE,
    'OBSERVATION' AS DOMAIN_ID
FROM
	OBSERVATION;

CREATE  VIEW PROCEDURE_SOURCE_CONCEPTS AS 
SELECT
 			visit_occurrence_id AS ENCOUNTER_NUM, 
 			PERSON_ID AS PATIENT_NUM, 
   			cast(procedure_source_concept_id as varchar(50)) AS CONCEPT_CD, 
   			isnull(CAST(provider_id AS VARCHAR(50)),'@') AS PROVIDER_ID, 
   			procedure_datetime AS START_DATE, 
			NULL AS END_DATE, 
            '@' AS MODIFIER_CD,
            1 AS INSTANCE_NUM,
            NULL AS valtype_cd,
            NULL AS location_cd,
            NULL AS tval_char,
            NULL AS nval_num,
            NULL AS valueflag_cd,
            NULL AS units_cd,
            NULL CONFIDENCE_NUM, 
            NULL SOURCESYSTEM_CD, 
            NULL UPDATE_DATE, 
            NULL DOWNLOAD_DATE, 
            NULL IMPORT_DATE,
            NULL OBSERVATION_BLOB, 
            NULL UPLOAD_ID,
            NULL quantity_num,
            procedure_source_concept_id AS SOURCE_CONCEPT_ID,
            procedure_source_value AS SOURCE_VALUE,
            'PROCEDURE' AS DOMAIN_ID
--			procedure_occurrence_id integer NOT NULL, 
--			procedure_datetime TIMESTAMP NULL, 
--			procedure_type_concept_id integer NOT NULL, 
--			modifier_concept_id integer NULL, 
--			quantity integer NULL, 
--			visit_detail_id integer NULL, 
--			modifier_source_value varchar(50) NULL );  
FROM PROCEDURE_OCCURRENCE;