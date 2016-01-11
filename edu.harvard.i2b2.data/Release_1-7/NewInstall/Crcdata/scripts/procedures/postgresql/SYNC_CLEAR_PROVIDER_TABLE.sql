
CREATE OR REPLACE FUNCTION sync_clear_provider_table (tempProviderTableName in text, backupProviderTableName IN text, uploadId in bigint, errorMsg OUT text ) 
 RETURNS text AS $body$
DECLARE
 
interProviderTableName  varchar(400);

BEGIN 
        interProviderTableName := backupProviderTableName || '_inter';
                --Delete duplicate rows with same encounter and patient combination
        EXECUTE 'DELETE FROM ' || tempProviderTableName || ' t1 WHERE oid > 
                                           (SELECT  min(oid) FROM ' || tempProviderTableName || ' t2
                                             WHERE t1.provider_id = t2.provider_id 
                                            AND t1.provider_path = t2.provider_path
                                            )';
    EXECUTE 'create table ' ||  interProviderTableName || ' (
    PROVIDER_ID         varchar(50) NOT NULL,
        PROVIDER_PATH       varchar(700) NOT NULL,
        NAME_CHAR               varchar(850) NULL,
        PROVIDER_BLOB       text NULL,
        UPDATE_DATE             timestamp NULL,
        DOWNLOAD_DATE       timestamp NULL,
        IMPORT_DATE         timestamp NULL,
        SOURCESYSTEM_CD     varchar(50) NULL,
        UPLOAD_ID               numeric(38,0) NULL ,
    CONSTRAINT  ' || interProviderTableName || '_pk PRIMARY KEY(PROVIDER_PATH,provider_id)
         )';
    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
        -- in patient_mapping table.
        EXECUTE 'insert into ' ||  interProviderTableName || ' (provider_id,provider_path,name_char,provider_blob,update_date,download_date,import_date,sourcesystem_cd,upload_id)
                            PERFORM  provider_id,provider_path, 
                        name_char,provider_blob,
                        update_date,download_date,
                        LOCALTIMESTAMP,sourcesystem_cd, ' || uploadId || '
                             from ' || tempProviderTableName || '  temp ';
        --backup the concept_dimension table before creating a new one
        EXECUTE 'alter table provider_dimension rename to ' || backupProviderTableName  ||'' ;
        -- add index on provider_id, name_char 
    EXECUTE 'CREATE INDEX ' || interProviderTableName || '_id_idx ON ' || interProviderTableName  || '(Provider_Id,name_char)';
    EXECUTE 'CREATE INDEX ' || interProviderTableName || '_uid_idx ON ' || interProviderTableName  || '(UPLOAD_ID)';
        --backup the concept_dimension table before creating a new one
        EXECUTE 'alter table ' || interProviderTableName  || ' rename to provider_dimension' ;
EXCEPTION
        WHEN OTHERS THEN
                RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;      
END;
$body$
LANGUAGE PLPGSQL;

