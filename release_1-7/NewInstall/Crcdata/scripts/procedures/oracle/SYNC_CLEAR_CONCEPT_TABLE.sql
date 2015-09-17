create or replace PROCEDURE  "SYNC_CLEAR_CONCEPT_TABLE" (tempConceptTableName in VARCHAR, backupConceptTableName IN VARCHAR, uploadId in NUMBER, errorMsg OUT VARCHAR ) 
IS 

interConceptTableName  varchar2(400);

BEGIN 
	interConceptTableName := backupConceptTableName || '_inter';
	
		--Delete duplicate rows with same encounter and patient combination
	execute immediate 'DELETE FROM ' || tempConceptTableName || ' t1 WHERE rowid > 
					   (SELECT  min(rowid) FROM ' || tempConceptTableName || ' t2
					     WHERE t1.concept_cd = t2.concept_cd 
                                            AND t1.concept_path = t2.concept_path
                                            )';

    execute immediate 'create table ' ||  interConceptTableName || ' (
    CONCEPT_CD          VARCHAR2(50) NOT NULL,
	CONCEPT_PATH    	VARCHAR2(700) NOT NULL,
	NAME_CHAR       	VARCHAR2(2000) NULL,
	CONCEPT_BLOB        CLOB NULL,
	UPDATE_DATE         DATE NULL,
	DOWNLOAD_DATE       DATE NULL,
	IMPORT_DATE         DATE NULL,
	SOURCESYSTEM_CD     VARCHAR2(50) NULL,
	UPLOAD_ID       	NUMBER(38,0) NULL,
    CONSTRAINT '|| interConceptTableName ||'_pk  PRIMARY KEY(CONCEPT_PATH)
	 )';
    
    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
	-- in patient_mapping table.
	execute immediate 'insert into '|| interConceptTableName ||'  (concept_cd,concept_path,name_char,concept_blob,update_date,download_date,import_date,sourcesystem_cd,upload_id)
			    select  concept_cd, substr(concept_path,1,700),
                        name_char,concept_blob,
                        update_date,download_date,
                        sysdate,sourcesystem_cd,
                         ' || uploadId || '  from ' || tempConceptTableName || '  temp ';
	--backup the concept_dimension table before creating a new one
	execute immediate 'alter table concept_dimension rename to ' || backupConceptTableName  ||'' ;
    
	-- add index on upload_id 
    execute immediate 'CREATE INDEX ' || interConceptTableName || '_uid_idx ON ' || interConceptTableName || '(UPLOAD_ID)';

    -- add index on upload_id 
    execute immediate 'CREATE INDEX ' || interConceptTableName || '_cd_idx ON ' || interConceptTableName || '(concept_cd)';

    
    --backup the concept_dimension table before creating a new one
	execute immediate 'alter table ' || interConceptTableName  || ' rename to concept_dimension' ;
 
EXCEPTION
	WHEN OTHERS THEN
		raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);	
END;

 
