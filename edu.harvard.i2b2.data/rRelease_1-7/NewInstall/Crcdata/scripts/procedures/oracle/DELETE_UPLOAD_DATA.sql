--procedure to update upload_status table after upload is completed.
CREATE OR REPLACE PROCEDURE DELETE_UPLOAD_DATA(uploadId IN NUMBER) 
IS 
BEGIN 
	-- delete from observation_fact for the given upload_id
	
	execute immediate '	delete from observation_fact where upload_id = '|| uploadId ||'';
	execute immediate '	delete encounter_mapping where encounter_num in (select encounter_num from visit_dimension where upload_id = '|| uploadId ||')';
	execute immediate ' delete visit_dimension where upload_id = '|| uploadId ||'';
	execute immediate ' UPDATE upload_status set load_status=''DELETED'' where upload_id = '|| uploadId ||'';
EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;