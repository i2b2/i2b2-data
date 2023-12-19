create or replace PROCEDURE  "SYNC_CLEAR_PROVIDER_TABLE" (tempProviderTableName in VARCHAR, backupProviderTableName IN VARCHAR, uploadId in NUMBER, errorMsg OUT VARCHAR ) 
IS 

interProviderTableName  varchar2(400);

BEGIN 
	interProviderTableName := backupProviderTableName || '_inter';
	
		--Delete duplicate rows with same encounter and patient combination
	execute immediate 'DELETE FROM ' || tempProviderTableName || ' t1 WHERE rowid > 
					   (SELECT  min(rowid) FROM ' || tempProviderTableName || ' t2
					     WHERE t1.provider_id = t2.provider_id 
                                            AND t1.provider_path = t2.provider_path
                                            )';

    execute immediate 'create table ' ||  interProviderTableName || ' (
    PROVIDER_ID         VARCHAR2(50) NOT NULL,
	PROVIDER_PATH       VARCHAR2(700) NOT NULL,
	NAME_CHAR       	VARCHAR2(850) NULL,
	PROVIDER_BLOB       CLOB NULL,
	UPDATE_DATE     	DATE NULL,
	DOWNLOAD_DATE       DATE NULL,
	IMPORT_DATE         DATE NULL,
	SOURCESYSTEM_CD     VARCHAR2(50) NULL,
	UPLOAD_ID        	NUMBER(38,0) NULL ,
    CONSTRAINT  ' || interProviderTableName || '_pk PRIMARY KEY(PROVIDER_PATH,provider_id)
	 )';
    
    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
	-- in patient_mapping table.
	execute immediate 'insert into ' ||  interProviderTableName || ' (provider_id,provider_path,name_char,provider_blob,update_date,download_date,import_date,sourcesystem_cd,upload_id)
			    select  provider_id,provider_path, 
                        name_char,provider_blob,
                        update_date,download_date,
                        sysdate,sourcesystem_cd, ' || uploadId || '
	                     from ' || tempProviderTableName || '  temp ';
					
	--backup the concept_dimension table before creating a new one
	execute immediate 'alter table provider_dimension rename to ' || backupProviderTableName  ||'' ;
    
	-- add index on provider_id, name_char 
    execute immediate 'CREATE INDEX ' || interProviderTableName || '_id_idx ON ' || interProviderTableName  || '(Provider_Id,name_char)';
    execute immediate 'CREATE INDEX ' || interProviderTableName || '_uid_idx ON ' || interProviderTableName  || '(UPLOAD_ID)';

	--backup the concept_dimension table before creating a new one
	execute immediate 'alter table ' || interProviderTableName  || ' rename to provider_dimension' ;
 
EXCEPTION
	WHEN OTHERS THEN
		raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);	
END;

 
