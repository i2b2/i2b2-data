create or replace PROCEDURE CREATE_TEMP_TABLE(tempTableName IN VARCHAR, errorMsg OUT VARCHAR) 
IS 

BEGIN 
	execute immediate 'create table ' ||  tempTableName || '  (
		encounter_num  NUMBER(38,0),
		encounter_id varchar(200) not null, 
        encounter_id_source varchar(50) not null,
		concept_cd 	 VARCHAR(50) not null, 
                patient_num number(38,0), 
		patient_id  varchar(200) not null,
        patient_id_source  varchar(50) not null,
		provider_id   VARCHAR(50),
 		start_date   DATE, 
		modifier_cd VARCHAR2(100),
	    instance_num number(18,0),
 		valtype_cd varchar2(50),
		tval_char varchar(255),
 		nval_num NUMBER(18,5),
		valueflag_cd CHAR(50),
 		quantity_num NUMBER(18,5),
		confidence_num NUMBER(18,0),
 		observation_blob CLOB,
		units_cd VARCHAR2(50),
 		end_date    DATE,
		location_cd VARCHAR2(50),
 		update_date  DATE,
		download_date DATE,
 		import_date DATE,
		sourcesystem_cd VARCHAR2(50) ,
 		upload_id INTEGER
	) NOLOGGING';

    
    execute immediate 'CREATE INDEX idx_' || tempTableName || '_pk ON ' || tempTableName || '  ( encounter_num,patient_num,concept_cd,provider_id,start_date,modifier_cd,instance_num)';
    execute immediate 'CREATE INDEX idx_' || tempTableName || '_enc_pat_id ON ' || tempTableName || '  (encounter_id,encounter_id_source, patient_id,patient_id_source )';
    
EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;

