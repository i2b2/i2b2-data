CREATE OR REPLACE FUNCTION insert_provider_fromtemp (tempProviderTableName IN text, upload_id IN bigint,
    errorMsg OUT text)
RETURNS text AS $body$
BEGIN 
    --Delete duplicate rows with same encounter and patient combination
    EXECUTE 'DELETE FROM ' || tempProviderTableName || ' t1 WHERE oid > 
    (SELECT  min(oid) FROM ' || tempProviderTableName || ' t2
        WHERE t1.provider_id = t2.provider_id 
        AND t1.provider_path = t2.provider_path
    )';
    EXECUTE ' UPDATE provider_dimension  SET  
        provider_id =temp.provider_id
        , name_char = temp.name_char
        , provider_blob = temp.provider_blob
        , update_date=temp.update_date
        , download_date=temp.download_date
        , import_date=Now()
        , sourcesystem_cd=temp.sourcesystem_cd
        , upload_id = ' || upload_id || '
        FROM ' || tempProviderTableName || '  temp 
        WHERE 
        temp.provider_path = provider_dimension.provider_path and temp.update_date >= provider_dimension.update_date 
    AND EXISTS (select 1 from ' || tempProviderTableName || ' temp  where temp.provider_path = provider_dimension.provider_path 
        and temp.update_date >= provider_dimension.update_date) ';

    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
    -- in patient_mapping table.
    EXECUTE 'insert into provider_dimension  (provider_id,provider_path,name_char,provider_blob,update_date,download_date,import_date,sourcesystem_cd,upload_id)
    SELECT  provider_id,provider_path, 
    name_char,provider_blob,
    update_date,download_date,
    Now(),sourcesystem_cd, ' || upload_id || '
    FROM ' || tempProviderTableName || '  temp
    WHERE NOT EXISTS (SELECT provider_id 
        FROM provider_dimension pd 
        WHERE pd.provider_path = temp.provider_path 
    )';
    EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;      
END;
$body$
LANGUAGE PLPGSQL;