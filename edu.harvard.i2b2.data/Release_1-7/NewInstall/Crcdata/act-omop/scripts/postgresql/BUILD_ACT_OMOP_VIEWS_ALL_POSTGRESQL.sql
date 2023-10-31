drop view if exists VISIT_DIMENSION;
drop view if exists PATIENT_DIMENSION;
drop view if exists DEVICE_VIEW;
drop view if exists DRUG_VIEW;
drop view if exists COVID_LAB_VIEW;
drop view if exists PROCEDURE_VIEW;
drop view if exists OBSERVATION_VIEW;
drop view if exists MEASUREMENT_VIEW;
drop view if exists ZIPCODE_VIEW;
drop view if exists CONDITION_VIEW;
drop view if exists VISIT_NS_VIEW;
drop view if exists CONDITION_NS_VIEW;
DROP VIEW if exists  DRUG_NS_VIEW;
DROP VIEW if exists  MEASUREMENT_NS_VIEW;
DROP VIEW if exists  OBSERVATION_NS_VIEW;
DROP VIEW if exists  COVID_LAB_NS_VIEW;
DROP VIEW if exists DEVICE_NS_VIEW;
DROP VIEW if exists PROCEDURE_NS_VIEW;

DROP TABLE IF EXISTS EMPTY_VIEW;
CREATE TABLE EMPTY_VIEW
   (
    ENCOUNTER_NUM INT ,
	PATIENT_NUM INT ,
	CONCEPT_CD VARCHAR(50) ,
	PROVIDER_ID VARCHAR(50) ,
	START_DATE DATE ,
	END_DATE timestamp,
	MODIFIER_CD VARCHAR(100) ,
	INSTANCE_NUM INT ,
	VALTYPE_CD VARCHAR(50),
	LOCATION_CD VARCHAR(50),
	TVAL_CHAR VARCHAR(255),
	NVAL_NUM INT ,
	VALUEFLAG_CD VARCHAR(50),
	UNITS_CD VARCHAR(50),
	CONFIDENCE_NUM FLOAT,
	SOURCESYSTEM_CD VARCHAR(50),
	UPDATE_DATE timestamp,
	DOWNLOAD_DATE timestamp,
	IMPORT_DATE timestamp,
	OBSERVATION_BLOB   text,
	UPLOAD_ID INT,
	QUANTITY_NUM INT ,
    SOURCE_CONCEPT_ID INT,
    SOURCE_VALUE VARCHAR(50),
    DOMAIN_ID VARCHAR(20)
   );

create or replace view  VISIT_DIMENSION
(encounter_num, patient_num, active_status_cd, start_date, end_date, inout_cd, location_cd, location_path,
length_of_stay, visit_blob, update_date, download_date, import_date, sourcesystem_cd, upload_id)
as
SELECT
visit_occurrence_id AS encounter_num,
person_id AS patient_num,
NULL AS active_status_cd,
visit_start_date AS start_date,
visit_end_date AS end_date,
visit_concept_id AS inout_cd,
care_site_id AS location_cd,
NULL AS location_path,
(VISIT_END_DATE::date-VISIT_START_DATE::date) as length_of_stay,
NULL AS visit_blob,
NULL AS update_date,
NULL AS download_date,
NULL AS import_date,
CAST(NULL as varchar(50)) AS SOURCESYSTEM_CD,
NULL AS upload_id
FROM visit_occurrence;

create or replace view PATIENT_DIMENSION
(patient_num, vital_status_cd, birth_date, death_date, sex_cd, age_in_years_num, language_cd, race_cd,
marital_status_cd, religion_cd, zip_cd, statecityzip_path, income_cd, patient_blob, update_date,
download_date, import_date, sourcesystem_cd, upload_id, ethnicity_cd)
as
SELECT person_id AS patient_num,
CASE
WHEN year_of_birth IS NULL THEN 'Y'
ELSE 'N'
END AS vital_status_cd,
concat(year_of_birth, '-', month_of_birth, '-', day_of_birth) AS birth_date,
NULL AS death_date,
to_char(gender_concept_id, '9') AS sex_cd,
date_part('epoch', birth_datetime - CURRENT_DATE) /
3600 AS age_in_years_num,
NULL AS language_cd,
race_concept_id AS race_cd,
NULL AS marital_status_cd,
NULL AS religion_cd,
NULL AS zip_cd,
NULL AS statecityzip_path,
NULL AS income_cd,
NULL AS patient_blob,
NULL AS update_date,
NULL AS download_date,
NULL AS import_date,
CAST(NULL as varchar(50)) AS SOURCESYSTEM_CD,
NULL AS upload_id,
ethnicity_concept_id AS ethnicity_cd
FROM person;

/******* OMOP FACT TABLE VIEWS ************/

CREATE  VIEW CONDITION_VIEW AS 
SELECT  
			visit_occurrence_id AS ENCOUNTER_NUM, 
 			PERSON_ID AS PATIENT_NUM, 
   			cast(condition_concept_id as varchar(50)) AS CONCEPT_CD, 
   		COALESCE(provider_id::character varying(50), '@'::character varying)  AS provider_id,
   			condition_start_datetime AS START_DATE, 
			condition_end_datetime AS END_DATE, 
            '@' AS MODIFIER_CD,
            1 AS INSTANCE_NUM,
            CAST(NULL as varchar(50)) AS valtype_cd,
            NULL AS location_cd,
            CAST(NULL as varchar(255)) AS tval_char,
            NULL AS nval_num,
            CAST(NULL as varchar(50)) AS valueflag_cd,
            CAST(NULL as varchar(50)) AS units_cd,
            NULL CONFIDENCE_NUM, 
            CAST(NULL as varchar(50)) AS SOURCESYSTEM_CD, 
            NULL UPDATE_DATE, 
            NULL DOWNLOAD_DATE, 
            NULL IMPORT_DATE, 
            NULL OBSERVATION_BLOB,
            NULL UPLOAD_ID,
            NULL as quantity_num,
   			condition_SOURCE_concept_id AS SOURCE_CONCEPT_ID,
            condition_source_value AS SOURCE_VALUE,
            'CONDITION' AS DOMAIN_ID
FROM CONDITION_OCCURRENCE;


create or replace view  DEVICE_VIEW
(encounter_num, patient_num, concept_cd, provider_id, start_date, end_date, modifier_cd, instance_num,
valtype_cd, location_cd, tval_char, nval_num, valueflag_cd, units_cd, confidence_num, sourcesystem_cd,
update_date, download_date, import_date, observation_blob, upload_id, quantity_num, source_concept_id,
source_value, domain_id)
as
SELECT visit_occurrence_id AS encounter_num,
person_id AS patient_num,
device_exposure_id AS concept_cd,
COALESCE(provider_id::character varying(50), '@'::character varying)  AS provider_id,
device_exposure_start_datetime AS start_date,
device_exposure_end_datetime AS end_date,
COALESCE(device_type_concept_id::character varying(50), '@'::character varying)  AS modifier_cd,
1 AS instance_num,
CAST(NULL as varchar(50)) AS valtype_cd,
NULL AS location_cd,
CAST(NULL as varchar(255)) AS tval_char,
NULL AS nval_num,
CAST(NULL as varchar(50)) AS valueflag_cd,
CAST(NULL as varchar(50)) AS units_cd,
NULL AS confidence_num,
CAST(NULL as varchar(50)) AS SOURCESYSTEM_CD,
NULL AS update_date,
NULL AS download_date,
NULL AS import_date,
NULL AS observation_blob,
NULL AS upload_id,
NULL AS quantity_num,
device_source_concept_id AS source_concept_id,
device_source_value AS source_value,
'DEVICE' AS domain_id
FROM device_exposure;

create or replace view  DRUG_VIEW
(encounter_num, patient_num, concept_cd, provider_id, start_date, end_date, modifier_cd, instance_num,
valtype_cd, location_cd, tval_char, nval_num, valueflag_cd, units_cd, confidence_num, sourcesystem_cd,
update_date, download_date, import_date, observation_blob, upload_id, quantity_num, source_concept_id,
source_value, domain_id)
as
SELECT visit_occurrence_id AS encounter_num,
person_id AS patient_num,
drug_concept_id AS concept_cd,
COALESCE(provider_id::character varying(50), '@'::character varying)  AS provider_id,
drug_exposure_start_datetime AS start_date,
drug_exposure_end_datetime AS end_date,
'@' AS modifier_cd,
1 AS instance_num,
CAST(NULL as varchar(50)) AS valtype_cd,
NULL AS location_cd,
CAST(NULL as varchar(255)) AS tval_char,
NULL AS nval_num,
CAST(NULL as varchar(50)) AS valueflag_cd,
CAST(NULL as varchar(50)) AS units_cd,
NULL AS confidence_num,
CAST(NULL as varchar(50)) AS SOURCESYSTEM_CD,
NULL AS update_date,
NULL AS download_date,
NULL AS import_date,
NULL AS observation_blob,
NULL AS upload_id,
NULL AS quantity_num,
drug_source_concept_id AS source_concept_id,
drug_source_value AS source_value,
'DRUG' AS domain_id
FROM drug_exposure;

create or replace view  measurement_view
(encounter_num, patient_num, concept_cd, provider_id, start_date, end_date, modifier_cd, instance_num,
valtype_cd, location_cd, tval_char, nval_num, valueflag_cd, units_cd, confidence_num, sourcesystem_cd,
update_date, download_date, import_date, observation_blob, upload_id, quantity_num, source_concept_id,
source_value, domain_id)
as
SELECT visit_occurrence_id AS encounter_num,
person_id AS patient_num,
measurement_concept_id AS concept_cd,
COALESCE(provider_id::character varying(50), '@'::character varying)  AS provider_id,
measurement_date AS start_date,
NULL AS end_date,
'@' AS modifier_cd,
1 AS instance_num,
CASE
WHEN value_as_number IS NOT NULL THEN 'N'
ELSE 'T'
END AS valtype_cd,
NULL AS location_cd,
CASE
WHEN operator_concept_id = 4172703 THEN 'E'
WHEN operator_concept_id = 4171756 THEN 'LT'
WHEN operator_concept_id = 4172704 THEN 'GT'
WHEN operator_concept_id = 4171754 THEN 'LE'
WHEN operator_concept_id = 4171755 THEN 'GE'
WHEN operator_concept_id IS NULL THEN 'E'
ELSE NULL
END AS tval_char,
value_as_number AS nval_num,
value_as_concept_id AS valueflag_cd,
unit_source_value AS units_cd,
NULL AS confidence_num,
CAST(NULL as varchar(50)) AS SOURCESYSTEM_CD,
NULL AS update_date,
NULL AS download_date,
NULL AS import_date,
NULL AS observation_blob,
NULL AS upload_id,
NULL AS quantity_num,
measurement_source_concept_id AS source_concept_id,
measurement_source_value AS source_value,
'MEASUREMENT' AS domain_id
FROM measurement;

create or replace view  observation_view
(encounter_num, patient_num, concept_cd, provider_id, start_date, end_date, modifier_cd, instance_num,
valtype_cd, location_cd, tval_char, nval_num, valueflag_cd, units_cd, confidence_num, sourcesystem_cd,
update_date, download_date, import_date, observation_blob, upload_id, quantity_num, source_concept_id,
source_value, domain_id)
as
SELECT visit_occurrence_id AS encounter_num,
person_id AS patient_num,
cast(observation_concept_id as varchar(50)) AS CONCEPT_CD,
COALESCE(provider_id::character varying(50), '@'::character varying)  AS provider_id,
observation_date AS start_date,
NULL AS end_date,
'@' AS modifier_cd,
1 AS instance_num,
CASE
WHEN value_as_number IS NOT NULL THEN 'N'
ELSE 'T'
END AS valtype_cd,
NULL AS location_cd,
CASE
WHEN value_as_number IS NOT NULL THEN 'E'
ELSE value_as_string
END AS tval_char,
value_as_number AS nval_num,
value_as_concept_id AS valueflag_cd,
unit_source_value AS units_cd,
NULL AS confidence_num,
CAST(NULL as varchar(50)) AS SOURCESYSTEM_CD,
NULL AS update_date,
NULL AS download_date,
NULL AS import_date,
NULL AS observation_blob,
NULL AS upload_id,
NULL AS quantity_num,
observation_source_concept_id AS source_concept_id,
observation_source_value AS source_value,
'OBSERVATION' AS domain_id
FROM observation;

create or replace view  procedure_view
(encounter_num, patient_num, concept_cd, provider_id, start_date, end_date, modifier_cd, instance_num,
valtype_cd, location_cd, tval_char, nval_num, valueflag_cd, units_cd, confidence_num, sourcesystem_cd,
update_date, download_date, import_date, upload_id, observation_blob, quantity_num, source_concept_id,
source_value, domain_id)
as
SELECT visit_occurrence_id AS encounter_num,
person_id AS patient_num,
cast(procedure_concept_id as varchar(50)) AS CONCEPT_CD,
COALESCE(provider_id::character varying(50), '@'::character varying)  AS provider_id,
procedure_datetime AS start_date,
NULL AS end_date,
'@' AS modifier_cd,
1 AS instance_num,
CAST(NULL as varchar(50)) AS valtype_cd,
NULL AS location_cd,
CAST(NULL as varchar(255)) AS tval_char,
NULL AS nval_num,
CAST(NULL as varchar(50)) AS valueflag_cd,
CAST(NULL as varchar(50)) AS units_cd,
NULL AS confidence_num,
CAST(NULL as varchar(50)) AS SOURCESYSTEM_CD,
NULL AS update_date,
NULL AS download_date,
NULL AS import_date,
NULL AS upload_id,
NULL AS observation_blob,
NULL AS quantity_num,
procedure_source_concept_id AS source_concept_id,
procedure_source_value AS source_value,
'PROCEDURE' AS domain_id
FROM procedure_occurrence;

create or replace view  COVID_LAB_VIEW
(patient_num, concept_cd, encounter_num, instance_num, provider_id, start_date, modifier_cd,
observation_blob, valtype_cd, tval_char, nval_num, valueflag_cd, quantity_num, units_cd, end_date,
location_cd, confidence_num, sourcesystem_cd, update_date, download_date, import_date, upload_id,
standard_concept_id, source_value, domain_id)
as
SELECT person_id AS patient_num,
CONCAT(CAST(measurement_source_concept_id AS VARCHAR(25)),' ',CAST(VALUE_AS_CONCEPT_ID AS VARCHAR(24))) AS CONCEPT_CD,
visit_occurrence_id AS encounter_num,
1 AS instance_num,
COALESCE(provider_id::character varying(50), '@'::character varying)  AS provider_id,
measurement_datetime AS start_date,
'@' AS modifier_cd,
NULL AS observation_blob,
CASE
WHEN value_as_number IS NOT NULL THEN 'N'
ELSE 'T'
END AS valtype_cd,
CASE
WHEN operator_concept_id = 4172703 THEN 'E'
WHEN operator_concept_id = 4171756 THEN 'LT'
WHEN operator_concept_id = 4172704 THEN 'GT'
WHEN operator_concept_id = 4171754 THEN 'LE'
WHEN operator_concept_id = 4171755 THEN 'GE'
WHEN operator_concept_id IS NULL AND value_as_number IS NOT NULL
THEN 'E'
ELSE value_source_value
END AS tval_char,
value_as_number AS nval_num,
value_as_concept_id AS valueflag_cd,
NULL AS quantity_num,
unit_source_value AS units_cd,
NULL AS end_date,
NULL AS location_cd,
NULL AS confidence_num,
CAST(NULL as varchar(50)) AS SOURCESYSTEM_CD,
NULL AS update_date,
NULL AS download_date,
NULL AS import_date,
NULL AS upload_id,
measurement_concept_id AS standard_concept_id,
measurement_source_value AS source_value,
'MEASUREMENT' AS domain_id
FROM measurement
WHERE cast(measurement_source_concept_id as varchar(50)) IN
('586515', '586516', '586517', '586518', '586519', '586520', '586521', '586522', '586523', '586524', '586525', '586526', '586527',
 '586528', '586529', '706154', '706155', '706156', '706157', '706159', '706160', '706161', '706163', '706165', '706166', '706167',
  '706168', '706170', '706171', '706172', '706173', '706174', '706175', '706177', '706178', '706180', '706181', '715260', '715261', '715262',
   '715272', '723459', '723463', '723464', '723465', '723466', '723467', '723468', '723469', '723470', '723471', '723472', '723473', '723474',
    '723475', '723476', '723477', '723478', '723479', '723480', '757677', '757678', '757679', '757680', '757685', '757686', '36659631', '36661369',
     '36661370', '36661371', '36661372', '36661373', '36661374', '36661375', '36661377', '36661378');

/************************ OMOP_SOURCE_FACT TABLE VIEWS ***************************/


CREATE or replace VIEW VISIT_NS_VIEW
AS
SELECT
	visit_occurrence_id AS ENCOUNTER_NUM,
 	PERSON_ID AS PATIENT_NUM,

   cast(VISIT_SOURCE_concept_id as varchar(50)) AS CONCEPT_CD,
   	COALESCE(provider_id::character varying(50), '@'::character varying)  AS provider_id,
   	VISIT_start_datetime AS START_DATE,
	VISIT_end_datetime AS END_DATE,
    	'@' AS MODIFIER_CD,
     	1 AS INSTANCE_NUM,
        CAST(NULL as varchar(50)) AS valtype_cd,
        CARE_SITE_ID AS location_cd,
        CAST(NULL as varchar(255)) AS tval_char,
        NULL AS nval_num,
        CAST(NULL as varchar(50)) AS valueflag_cd,
        CAST(NULL as varchar(50)) AS units_cd,
        NULL CONFIDENCE_NUM,
        CAST(NULL as varchar(50)) AS SOURCESYSTEM_CD,
        NULL UPDATE_DATE,
        NULL DOWNLOAD_DATE,
        NULL IMPORT_DATE,
        NULL OBSERVATION_BLOB,
        NULL UPLOAD_ID,
        NULL as quantity_num,
   	VISIT_SOURCE_concept_id AS SOURCE_CONCEPT_ID,
        VISIT_source_value AS SOURCE_VALUE,
        'VISIT' AS DOMAIN_ID
FROM
	visit_occurrence
WHERE cast(VISIT_SOURCE_concept_id as varchar(50))
IN ('42733800', '2414356', '2514472', '2514478', '2514492', '2514420', '759714', '2514415', '2514419', '2414357', '2514491', '2514484', '2514486', '42738975', '42738971', '2514607', '2514481', '2514485', '759715', '2514493', '2414398', '2414395', '2414390', '2514487', '42738974', '2514479', '2514488', '42738976', '2514483', '2514494', '2414397', '2414394', '2514399', '2101831', '2514410', '2212758', '2414347', '2212759', '2514422', '2514417', '2514470', '2514474', '2514490', '2514489', '42738973', '42628033', '2514496', '2514495', '42738672', '2414349', '2514473', '42628640', '2414391', '2514510', '40756897', '2101829', '2514433', '42738987', '2514549', '2101773', '2514454', '2514466', '2514457', '2213588', '42738986', '2514548', '1389757', '2514551', '1389758', '2514465', '42738970', '42738966', '2213590', '42738677', '2213578', '2213580', '42738678', '2213596', '2213593', '2213597',
 '42738339', '2514511', '2514437', '2514434', '42738988', '927189', '1389755', '927161', '44816370', '2314339', '2514464', '2514515', '2514514', '2514435', '710059', '44816369', '1389756', '2514459', '2514458', '2514455', '42738968', '2514456', '2213581', '2213583', '2213591', '42738338', '2213585', '2514563', '2213592', '2514566', '2514565', '2514436', '43528028', '927188', '2101774', '2314340', '2314338', '2101832', '42738965', '2213589', '2213595', '42738679', '2213579', '2514562', '42738776', '44816367', '2514460', '42738969', '2213582', '2514567', '2514412', '2213586', '42738336', '42738676', '2414348', '2212760', '2514418', '2514471', '2514482', '2414393', '2414392', '2514424', '2514421', '42738972', '2414345', '2414396', '2314183', '43528027', '2514423', '2514416', '2514480', '2414355', '1389523', '44816368', '2514568', '2414350', '42742446')
;


CREATE or replace  VIEW CONDITION_NS_VIEW AS
SELECT
			visit_occurrence_id AS ENCOUNTER_NUM,
 			PERSON_ID AS PATIENT_NUM,
   			cast(condition_source_concept_id as varchar(50)) AS CONCEPT_CD,
   		COALESCE(provider_id::character varying(50), '@'::character varying)  AS provider_id,
   			condition_start_datetime AS START_DATE,
			condition_end_datetime AS END_DATE,
            '@' AS MODIFIER_CD,
            1 AS INSTANCE_NUM,
            CAST(NULL as varchar(50)) AS valtype_cd,
            NULL AS location_cd,
            CAST(NULL as varchar(255)) AS tval_char,
            NULL AS nval_num,
            CAST(NULL as varchar(50)) AS valueflag_cd,
            CAST(NULL as varchar(50)) AS units_cd,
            NULL CONFIDENCE_NUM,
            CAST(NULL as varchar(50)) AS SOURCESYSTEM_CD,
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

create or replace view  device_NS_view
(encounter_num, patient_num, concept_cd, provider_id, start_date, end_date, modifier_cd, instance_num,
valtype_cd, location_cd, tval_char, nval_num, valueflag_cd, units_cd, confidence_num, sourcesystem_cd,
update_date, download_date, import_date, observation_blob, upload_id, quantity_num, source_concept_id,
source_value, domain_id)
as
SELECT visit_occurrence_id AS encounter_num,
person_id AS patient_num,
cast(device_SOURCE_CONCEPT_ID as varchar(50)) AS CONCEPT_CD,
COALESCE(provider_id::character varying(50), '@'::character varying)  AS provider_id,
device_exposure_start_datetime AS start_date,
device_exposure_end_datetime AS end_date,
COALESCE(device_type_concept_id::character varying(50), '@'::character varying)  AS modifier_cd,
1 AS instance_num,
CAST(NULL as varchar(50)) AS valtype_cd,
NULL AS location_cd,
CAST(NULL as varchar(255)) AS tval_char,
NULL AS nval_num,
CAST(NULL as varchar(50)) AS valueflag_cd,
CAST(NULL as varchar(50)) AS units_cd,
NULL AS confidence_num,
CAST(NULL as varchar(50)) AS SOURCESYSTEM_CD,
NULL AS update_date,
NULL AS download_date,
NULL AS import_date,
NULL AS observation_blob,
NULL AS upload_id,
NULL AS quantity_num,
device_source_concept_id AS source_concept_id,
device_source_value AS source_value,
'DEVICE' AS domain_id
FROM device_exposure;


create or replace view  drug_NS_view
(encounter_num, patient_num, concept_cd, provider_id, start_date, end_date, modifier_cd, instance_num,
valtype_cd, location_cd, tval_char, nval_num, valueflag_cd, units_cd, confidence_num, sourcesystem_cd,
update_date, download_date, import_date, observation_blob, upload_id, quantity_num, source_concept_id,
source_value, domain_id)
as
SELECT visit_occurrence_id AS encounter_num,
person_id AS patient_num,
cast(drug_SOURCE_CONCEPT_ID as varchar(50)) AS CONCEPT_CD,
COALESCE(provider_id::character varying(50), '@'::character varying)  AS provider_id,
drug_exposure_start_datetime AS start_date,
drug_exposure_end_datetime AS end_date,
'@' AS modifier_cd,
1 AS instance_num,
CAST(NULL as varchar(50)) AS valtype_cd,
NULL AS location_cd,
CAST(NULL as varchar(255)) AS tval_char,
NULL AS nval_num,
CAST(NULL as varchar(50)) AS valueflag_cd,
CAST(NULL as varchar(50)) AS units_cd,
NULL AS confidence_num,
CAST(NULL as varchar(50)) AS SOURCESYSTEM_CD,
NULL AS update_date,
NULL AS download_date,
NULL AS import_date,
NULL AS observation_blob,
NULL AS upload_id,
NULL AS quantity_num,
drug_source_concept_id AS source_concept_id,
drug_source_value AS source_value,
'DRUG' AS domain_id
FROM drug_exposure;


create or replace view  measurement_NS_view
(encounter_num, patient_num, concept_cd, provider_id, start_date, end_date, modifier_cd, instance_num,
valtype_cd, location_cd, tval_char, nval_num, valueflag_cd, units_cd, confidence_num, sourcesystem_cd,
update_date, download_date, import_date, observation_blob, upload_id, quantity_num, source_concept_id,
source_value, domain_id)
as
SELECT visit_occurrence_id AS encounter_num,
person_id AS patient_num,
cast(measurement_SOURCE_CONCEPT_ID as varchar(50)) AS CONCEPT_CD,
COALESCE(provider_id::character varying(50), '@'::character varying)  AS provider_id,
measurement_date AS start_date,
NULL AS end_date,
'@' AS modifier_cd,
1 AS instance_num,
CASE
WHEN value_as_number IS NOT NULL THEN 'N'
ELSE 'T'
END AS valtype_cd,
NULL AS location_cd,
CASE
WHEN operator_concept_id = 4172703 THEN 'E'
WHEN operator_concept_id = 4171756 THEN 'LT'
WHEN operator_concept_id = 4172704 THEN 'GT'
WHEN operator_concept_id = 4171754 THEN 'LE'
WHEN operator_concept_id = 4171755 THEN 'GE'
WHEN operator_concept_id IS NULL THEN 'E'
ELSE NULL
END AS tval_char,
value_as_number AS nval_num,
value_as_concept_id AS valueflag_cd,
unit_source_value AS units_cd,
NULL AS confidence_num,
CAST(NULL as varchar(50)) AS SOURCESYSTEM_CD,
NULL AS update_date,
NULL AS download_date,
NULL AS import_date,
NULL AS observation_blob,
NULL AS upload_id,
NULL AS quantity_num,
measurement_source_concept_id AS source_concept_id,
measurement_source_value AS source_value,
'MEASUREMENT' AS domain_id
FROM measurement;


CREATE  VIEW OBSERVATION_NS_VIEW AS
SELECT
	VISIT_OCCURRENCE_ID AS ENCOUNTER_NUM,
	PERSON_ID AS PATIENT_NUM,
    CAST(OBSERVATION_SOURCE_CONCEPT_ID AS VARCHAR(50)) AS CONCEPT_CD, 
   COALESCE(provider_id::character varying(50), '@'::character varying)  AS provider_id,
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
            CAST(NULL as varchar(50)) AS SOURCESYSTEM_CD, 
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


create or replace view  procedure_NS_view
(encounter_num, patient_num, concept_cd, provider_id, start_date, end_date, modifier_cd, instance_num,
valtype_cd, location_cd, tval_char, nval_num, valueflag_cd, units_cd, confidence_num, sourcesystem_cd,
update_date, download_date, import_date, upload_id, observation_blob, quantity_num, source_concept_id,
source_value, domain_id)
as
SELECT visit_occurrence_id AS encounter_num,
person_id AS patient_num,
cast(procedure_source_concept_id as varchar(50)) AS CONCEPT_CD,
COALESCE(provider_id::character varying(50), '@'::character varying)  AS provider_id,
procedure_datetime AS start_date,
NULL AS end_date,
'@' AS modifier_cd,
1 AS instance_num,
CAST(NULL as varchar(50)) AS valtype_cd,
NULL AS location_cd,
CAST(NULL as varchar(255)) AS tval_char,
NULL AS nval_num,
CAST(NULL as varchar(50)) AS valueflag_cd,
CAST(NULL as varchar(50)) AS units_cd,
NULL AS confidence_num,
CAST(NULL as varchar(50)) AS SOURCESYSTEM_CD,
NULL AS update_date,
NULL AS download_date,
NULL AS import_date,
NULL AS upload_id,
NULL AS observation_blob,
NULL AS quantity_num,
procedure_source_concept_id AS source_concept_id,
procedure_source_value AS source_value,
'PROCEDURE' AS domain_id
FROM procedure_occurrence;

-- V4.1 ZIPCODE
CREATE or replace VIEW ZIPCODE_VIEW AS
SELECT
0 AS ENCOUNTER_NUM,
PERSON_ID AS PATIENT_NUM,
CASE WHEN LENGTH(L.ZIP) = 3 THEN 'DEM|ZIP3:' || L.ZIP
WHEN LENGTH(L.ZIP) >= 5 THEN 'DEM|ZIPCODE:' || SUBSTRING(L.ZIP,1,5)
END as CONCEPT_CD,
COALESCE(provider_id::character varying(50), '@'::character varying)  AS provider_id,
birth_datetime AS START_DATE,
NULL AS END_DATE,
'@' AS MODIFIER_CD,
1 AS INSTANCE_NUM,
CAST(NULL as varchar(50)) AS valtype_cd,
NULL AS location_cd,
CAST(NULL as varchar(255)) AS tval_char,
NULL AS nval_num,
CAST(NULL as varchar(50)) AS valueflag_cd,
CAST(NULL as varchar(50)) AS units_cd,
NULL AS CONFIDENCE_NUM,
CAST(NULL as varchar(50)) AS SOURCESYSTEM_CD,
NULL AS UPDATE_DATE,
NULL AS DOWNLOAD_DATE,
NULL AS IMPORT_DATE,
NULL AS OBSERVATION_BLOB,
NULL AS UPLOAD_ID,
NULL as quantity_num,
NULL AS SOURCE_CONCEPT_ID,
L.LOCATION_SOURCE_VALUE AS SOURCE_VALUE,
'LOCATION' AS DOMAIN_ID
FROM PERSON P
JOIN LOCATION L ON L.LOCATION_ID = P.LOCATION_ID AND L.ZIP IS NOT NULL;
