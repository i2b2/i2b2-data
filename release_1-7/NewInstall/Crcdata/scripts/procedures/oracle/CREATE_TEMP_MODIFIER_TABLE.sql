create or replace PROCEDURE CREATE_TEMP_MODIFIER_TABLE(tempModifierTableName IN VARCHAR, 
  errorMsg OUT VARCHAR) 
IS 

BEGIN 
execute immediate 'create table ' ||  tempModifierTableName || ' (
        MODIFIER_CD VARCHAR2(50) NOT NULL, 
	MODIFIER_PATH VARCHAR2(900) NOT NULL , 
	NAME_CHAR VARCHAR2(2000), 
	MODIFIER_BLOB CLOB, 
	UPDATE_DATE date, 
	DOWNLOAD_DATE DATE, 
	IMPORT_DATE DATE, 
	SOURCESYSTEM_CD VARCHAR2(50)
	 )';

 execute immediate 'CREATE INDEX idx_' || tempModifierTableName || '_pat_id ON ' || tempModifierTableName || '  (MODIFIER_PATH)';
  
   

EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;

