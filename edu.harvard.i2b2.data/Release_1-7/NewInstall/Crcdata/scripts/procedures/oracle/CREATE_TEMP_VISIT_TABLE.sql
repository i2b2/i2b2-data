create or replace PROCEDURE CREATE_TEMP_VISIT_TABLE(tempTableName IN VARCHAR, errorMsg OUT VARCHAR ) 
IS 

BEGIN 
	-- Create temp table to store encounter/visit information
	execute immediate 'create table ' ||  tempTableName || ' (
		encounter_id 			VARCHAR(200) not null,
		encounter_id_source 	VARCHAR(50) not null, 
		patient_id  			VARCHAR(200) not null,
		patient_id_source 		VARCHAR2(50) not null,
		encounter_num	 		    NUMBER(38,0), 
		inout_cd   			VARCHAR(50),
		location_cd 			VARCHAR2(50),
		location_path 			VARCHAR2(900),
 		start_date   			DATE, 
 		end_date    			DATE,
 		visit_blob 				CLOB,
 		update_date  			DATE,
		download_date 			DATE,
 		import_date 			DATE,
		sourcesystem_cd 		VARCHAR2(50)
	)';

    execute immediate 'CREATE INDEX idx_' || tempTableName || '_enc_id ON ' || tempTableName || '  ( encounter_id,encounter_id_source,patient_id,patient_id_source )';
    execute immediate 'CREATE INDEX idx_' || tempTableName || '_patient_id ON ' || tempTableName || '  ( patient_id,patient_id_source )';
    
EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;

