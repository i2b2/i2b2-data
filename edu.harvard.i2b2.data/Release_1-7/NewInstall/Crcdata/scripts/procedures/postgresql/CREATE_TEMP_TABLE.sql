CREATE OR REPLACE FUNCTION create_temp_table (tempTableName IN text, errorMsg OUT text) 
RETURNS text AS $body$
BEGIN 
    EXECUTE 'create table ' ||  tempTableName || '  (
        encounter_num  numeric(38,0),
        encounter_id varchar(200) not null, 
        encounter_id_source varchar(50) not null,
        concept_cd       varchar(50) not null, 
        patient_num numeric(38,0), 
        patient_id  varchar(200) not null,
        patient_id_source  varchar(50) not null,
        provider_id   varchar(50),
        start_date   timestamp, 
        modifier_cd varchar(100),
        instance_num numeric(18,0),
        valtype_cd varchar(50),
        tval_char varchar(255),
        nval_num numeric(18,5),
        valueflag_cd char(50),
        quantity_num numeric(18,5),
        confidence_num numeric(18,0),
        observation_blob text,
        units_cd varchar(50),
        end_date    timestamp,
        location_cd varchar(50),
        update_date  timestamp,
        download_date timestamp,
        import_date timestamp,
        sourcesystem_cd varchar(50) ,
        upload_id integer
    ) WITH OIDS';
    EXECUTE 'CREATE INDEX idx_' || tempTableName || '_pk ON ' || tempTableName || '  ( encounter_num,patient_num,concept_cd,provider_id,start_date,modifier_cd,instance_num)';
    EXECUTE 'CREATE INDEX idx_' || tempTableName || '_enc_pat_id ON ' || tempTableName || '  (encounter_id,encounter_id_source, patient_id,patient_id_source )';
    EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM; 
END;
$body$
LANGUAGE PLPGSQL;
