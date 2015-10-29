CREATE OR REPLACE FUNCTION delete_upload_data (uploadId IN bigint) 
 RETURNS VOID AS $body$
BEGIN 
        -- delete from observation_fact for the given upload_id
        EXECUTE '       DELETE 
    FROM observation_fact 
    WHERE upload_id = '|| uploadId ||'
    ';
        EXECUTE ' DELETE 
    FROM encounter_mapping 
    WHERE encounter_num IN (SELECT encounter_num 
        FROM visit_dimension 
        WHERE upload_id = '|| uploadId ||')
    ';
        EXECUTE ' DELETE 
    FROM visit_dimension 
    WHERE upload_id = '|| uploadId ||'
    ';
        EXECUTE ' UPDATE upload_status 
    SET load_status=''DELETED'' 
    WHERE upload_id = '|| uploadId ||'
    ';
EXCEPTION
        WHEN OTHERS THEN
      RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;                
END;
$body$
LANGUAGE PLPGSQL;