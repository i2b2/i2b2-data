create or replace PROCEDURE CREATE_TEMP_PATIENT_TABLE(tempPatientDimensionTableName IN VARCHAR, 
    errorMsg OUT VARCHAR ) 
IS 

BEGIN 
	-- Create temp table to store encounter/visit information
	execute immediate 'create table ' ||  tempPatientDimensionTableName || ' (
		PATIENT_ID VARCHAR2(200), 
		PATIENT_ID_SOURCE VARCHAR2(50),
		PATIENT_NUM NUMBER(38,0),
	    VITAL_STATUS_CD VARCHAR2(50), 
	    BIRTH_DATE DATE, 
	    DEATH_DATE DATE, 
	    SEX_CD CHAR(50), 
	    AGE_IN_YEARS_NUM NUMBER(5,0), 
	    LANGUAGE_CD VARCHAR2(50), 
		RACE_CD VARCHAR2(50 ), 
		MARITAL_STATUS_CD VARCHAR2(50), 
		RELIGION_CD VARCHAR2(50), 
		ZIP_CD VARCHAR2(50), 
		STATECITYZIP_PATH VARCHAR2(700), 
		PATIENT_BLOB CLOB, 
		UPDATE_DATE DATE, 
		DOWNLOAD_DATE DATE, 
		IMPORT_DATE DATE, 
		SOURCESYSTEM_CD VARCHAR2(50)
	)';

execute immediate 'CREATE INDEX idx_' || tempPatientDimensionTableName || '_pat_id ON ' || tempPatientDimensionTableName || '  (PATIENT_ID, PATIENT_ID_SOURCE,PATIENT_NUM)';
  
     
    
EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;

