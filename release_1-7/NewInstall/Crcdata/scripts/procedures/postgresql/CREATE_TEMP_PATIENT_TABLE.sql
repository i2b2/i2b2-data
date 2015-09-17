CREATE OR REPLACE FUNCTION create_temp_patient_table (tempPatientDimensionTableName IN text, 
    errorMsg OUT text ) 
RETURNS text AS $body$
BEGIN 
    -- Create temp table to store encounter/visit information
    EXECUTE 'create table ' ||  tempPatientDimensionTableName || ' (
        patient_id varchar(200), 
        patient_id_source varchar(50),
        patient_num numeric(38,0),
        vital_status_cd varchar(50), 
        birth_date timestamp, 
        death_date timestamp, 
        sex_cd char(50), 
        age_in_years_num numeric(5,0), 
        language_cd varchar(50), 
        race_cd varchar(50 ), 
        marital_status_cd varchar(50), 
        religion_cd varchar(50), 
        zip_cd varchar(50), 
        statecityzip_path varchar(700), 
        patient_blob text, 
        update_date timestamp, 
        download_date timestamp, 
        import_date timestamp, 
        sourcesystem_cd varchar(50)
    )';
    EXECUTE 'CREATE INDEX idx_' || tempPatientDimensionTableName || '_pat_id ON ' || tempPatientDimensionTableName || '  (patient_id, patient_id_source,patient_num)';
    EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '%%%', SQLSTATE,  ' - ' , SQLERRM;
END;
$body$
LANGUAGE PLPGSQL;
