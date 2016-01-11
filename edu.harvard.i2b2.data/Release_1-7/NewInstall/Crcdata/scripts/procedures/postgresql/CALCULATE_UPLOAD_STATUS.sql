CREATE OR REPLACE FUNCTION calculate_upload_status (uploadId IN bigint) 
RETURNS VOID AS $body$
BEGIN 
    -- update upload_status loaded record
    EXECUTE '       UPDATE upload_status 
    SET loaded_record = (
        SELECT count(1) 
        FROM observation_fact obsfact 
        WHERE obsfact.upload_id= ' || uploadId ||')
    WHERE upload_status.upload_id = '|| uploadId ||'';
    -- update upload_status no_of_record based on uploadid
    EXECUTE 'UPDATE upload_status 
    SET no_of_record = (
        SELECT count(1) 
        FROM temp_obsfact_'|| uploadId ||'
    )
    WHERE upload_status.upload_id = ' || uploadId ||'';
    -- update upload_status delete_record based on uploadid
    EXECUTE 'UPDATE upload_status 
    SET deleted_record = (
        SELECT count(1) 
        FROM archive_observation_fact archiveobsfact 
        WHERE archiveobsfact.archive_upload_id= ' || uploadId ||'
    )
    WHERE upload_status.upload_id = ' || uploadId ||'';
    EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;                
END;
$body$
LANGUAGE PLPGSQL;
