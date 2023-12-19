create or replace PROCEDURE CREATE_TEMP_PROVIDER_TABLE(tempProviderTableName IN VARCHAR, 
   errorMsg OUT VARCHAR) 
IS 

BEGIN 

execute immediate 'create table ' ||  tempProviderTableName || ' (
    PROVIDER_ID VARCHAR2(50) NOT NULL, 
	PROVIDER_PATH VARCHAR2(700) NOT NULL, 
	NAME_CHAR VARCHAR2(2000), 
	PROVIDER_BLOB CLOB, 
	UPDATE_DATE DATE, 
	DOWNLOAD_DATE DATE, 
	IMPORT_DATE DATE, 
	SOURCESYSTEM_CD VARCHAR2(50), 
	UPLOAD_ID NUMBER(*,0)
	 )';
 execute immediate 'CREATE INDEX idx_' || tempProviderTableName || '_ppath_id ON ' || tempProviderTableName || '  (PROVIDER_PATH)';


 
   

EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;

