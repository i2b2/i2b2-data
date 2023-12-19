create or replace PROCEDURE CREATE_TEMP_EID_TABLE(tempPatientMappingTableName IN VARCHAR ,errorMsg OUT VARCHAR) 
IS 

BEGIN 
execute immediate 'create table ' ||  tempPatientMappingTableName || ' (
	ENCOUNTER_MAP_ID       	VARCHAR2(200) NOT NULL,
    ENCOUNTER_MAP_ID_SOURCE	VARCHAR2(50) NOT NULL,
    PATIENT_MAP_ID          VARCHAR2(200), 
	PATIENT_MAP_ID_SOURCE   VARCHAR2(50), 
    ENCOUNTER_ID       	    VARCHAR2(200) NOT NULL,
    ENCOUNTER_ID_SOURCE     VARCHAR2(50) ,
    ENCOUNTER_NUM           NUMBER, 
    ENCOUNTER_MAP_ID_STATUS    VARCHAR2(50),
    PROCESS_STATUS_FLAG     CHAR(1),
	UPDATE_DATE DATE, 
	DOWNLOAD_DATE DATE, 
	IMPORT_DATE DATE, 
	SOURCESYSTEM_CD VARCHAR2(50)
)';

execute immediate 'CREATE INDEX idx_' || tempPatientMappingTableName || '_eid_id ON ' || tempPatientMappingTableName || '  (ENCOUNTER_ID, ENCOUNTER_ID_SOURCE, ENCOUNTER_MAP_ID, ENCOUNTER_MAP_ID_SOURCE, ENCOUNTER_NUM)';

 execute immediate 'CREATE INDEX idx_' || tempPatientMappingTableName || '_stateid_eid_id ON ' || tempPatientMappingTableName || '  (PROCESS_STATUS_FLAG)';  
EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;

