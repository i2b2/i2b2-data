create or replace PROCEDURE  "SYNC_CLEAR_MODIFIER_TABLE" (tempModifierTableName in VARCHAR, backupModifierTableName IN VARCHAR, uploadId in NUMBER, errorMsg OUT VARCHAR ) 
IS 

interModifierTableName  varchar2(400);

BEGIN 
	interModifierTableName := backupModifierTableName || '_inter';
	
	--Delete duplicate rows with same modifier_path and modifier cd
	execute immediate 'DELETE FROM ' || tempModifierTableName || ' t1 WHERE rowid > 
					   (SELECT  min(rowid) FROM ' || tempModifierTableName || ' t2
					     WHERE t1.modifier_cd = t2.modifier_cd 
                                            AND t1.modifier_path = t2.modifier_path
                                            )';

    execute immediate 'create table ' ||  interModifierTableName || ' (
        MODIFIER_CD          VARCHAR2(50) NOT NULL,
	MODIFIER_PATH    	VARCHAR2(700) NOT NULL,
	NAME_CHAR       	VARCHAR2(2000) NULL,
	MODIFIER_BLOB        CLOB NULL,
	UPDATE_DATE         DATE NULL,
	DOWNLOAD_DATE       DATE NULL,
	IMPORT_DATE         DATE NULL,
	SOURCESYSTEM_CD     VARCHAR2(50) NULL,
	UPLOAD_ID       	NUMBER(38,0) NULL,
    CONSTRAINT '|| interModifierTableName ||'_pk  PRIMARY KEY(MODIFIER_PATH)
	 )';
    
    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
	-- in patient_mapping table.
	execute immediate 'insert into '|| interModifierTableName ||'  (modifier_cd,modifier_path,name_char,modifier_blob,update_date,download_date,import_date,sourcesystem_cd,upload_id)
			    select  modifier_cd, substr(modifier_path,1,700),
                        name_char,modifier_blob,
                        update_date,download_date,
                        sysdate,sourcesystem_cd,
                         ' || uploadId || '  from ' || tempModifierTableName || '  temp ';
	--backup the modifier_dimension table before creating a new one
	execute immediate 'alter table modifier_dimension rename to ' || backupModifierTableName  ||'' ;
    
	-- add index on upload_id 
    execute immediate 'CREATE INDEX ' || interModifierTableName || '_uid_idx ON ' || interModifierTableName || '(UPLOAD_ID)';

    -- add index on upload_id 
    execute immediate 'CREATE INDEX ' || interModifierTableName || '_cd_idx ON ' || interModifierTableName || '(modifier_cd)';

    
       --backup the modifier_dimension table before creating a new one
	execute immediate 'alter table ' || interModifierTableName  || ' rename to modifier_dimension' ;
 
EXCEPTION
	WHEN OTHERS THEN
		raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);	
END;

 
