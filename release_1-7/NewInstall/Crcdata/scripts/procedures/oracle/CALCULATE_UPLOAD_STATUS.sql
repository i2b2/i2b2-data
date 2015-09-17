--procedure to update upload_status table after upload is completed.
CREATE OR REPLACE PROCEDURE CALCULATE_UPLOAD_STATUS(uploadId IN NUMBER) 
IS 
BEGIN 
	-- update upload_status loaded record
	execute immediate '	UPDATE upload_status SET loaded_record = (
							SELECT count(1) FROM observation_fact obsfact where obsfact.upload_id= ' || uploadId ||')
							WHERE upload_status.upload_id = '|| uploadId ||'';
	
	-- update upload_status no_of_record based on uploadid
	execute immediate 'UPDATE upload_status SET no_of_record = (
					select count(1) from temp_obsfact_'|| uploadId ||')
		WHERE upload_status.upload_id = ' || uploadId ||'';
	
	-- update upload_status delete_record based on uploadid
	execute immediate 'UPDATE upload_status SET deleted_record = (
					select count(1) from archive_observation_fact archiveobsfact where archiveobsfact.archive_upload_id= ' || uploadId ||')
		WHERE upload_status.upload_id = ' || uploadId ||'';
    
EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;