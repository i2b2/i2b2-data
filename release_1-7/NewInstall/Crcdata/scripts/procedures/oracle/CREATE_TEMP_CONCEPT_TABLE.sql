create or replace PROCEDURE CREATE_TEMP_CONCEPT_TABLE(tempConceptTableName IN VARCHAR, 
  errorMsg OUT VARCHAR) 
IS 

BEGIN 
execute immediate 'create table ' ||  tempConceptTableName || ' (
        CONCEPT_CD VARCHAR2(50) NOT NULL, 
	CONCEPT_PATH VARCHAR2(900) NOT NULL , 
	NAME_CHAR VARCHAR2(2000), 
	CONCEPT_BLOB CLOB, 
	UPDATE_DATE date, 
	DOWNLOAD_DATE DATE, 
	IMPORT_DATE DATE, 
	SOURCESYSTEM_CD VARCHAR2(50)
	 )';

 execute immediate 'CREATE INDEX idx_' || tempConceptTableName || '_pat_id ON ' || tempConceptTableName || '  (CONCEPT_PATH)';
  
   

EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;

