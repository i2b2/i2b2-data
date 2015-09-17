create or replace PROCEDURE CREATE_TEMP_PID_TABLE(tempPatientMappingTableName IN VARCHAR,
    errorMsg OUT VARCHAR ) 
IS 

BEGIN 
execute immediate 'create table ' ||  tempPatientMappingTableName || ' (
	   	PATIENT_MAP_ID VARCHAR2(200), 
		PATIENT_MAP_ID_SOURCE VARCHAR2(50), 
		PATIENT_ID_STATUS VARCHAR2(50), 
		PATIENT_ID  VARCHAR2(200),
	    PATIENT_ID_SOURCE varchar(50),
		PATIENT_NUM NUMBER(38,0),
	    PATIENT_MAP_ID_STATUS VARCHAR2(50), 
		PROCESS_STATUS_FLAG CHAR(1), 
		UPDATE_DATE DATE, 
		DOWNLOAD_DATE DATE, 
		IMPORT_DATE DATE, 
		SOURCESYSTEM_CD VARCHAR2(50)

	 )';

execute immediate 'CREATE INDEX idx_' || tempPatientMappingTableName || '_pid_id ON ' || tempPatientMappingTableName || '  ( PATIENT_ID, PATIENT_ID_SOURCE )';

execute immediate 'CREATE INDEX idx_' || tempPatientMappingTableName || 'map_pid_id ON ' || tempPatientMappingTableName || '  
( PATIENT_ID, PATIENT_ID_SOURCE,PATIENT_MAP_ID, PATIENT_MAP_ID_SOURCE,  PATIENT_NUM )';
 
execute immediate 'CREATE INDEX idx_' || tempPatientMappingTableName || 'stat_pid_id ON ' || tempPatientMappingTableName || '  
(PROCESS_STATUS_FLAG)';


EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;

