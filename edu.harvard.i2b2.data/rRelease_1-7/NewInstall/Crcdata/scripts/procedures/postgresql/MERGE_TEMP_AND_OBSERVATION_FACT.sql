
CREATE OR REPLACE FUNCTION merge_temp_observation_fact (upload_temptable_name text)
 RETURNS VOID AS $body$
BEGIN
        EXECUTE 'MERGE  INTO observation_fact obsfact
                   USING ( select emap.encounter_num,patmap.patient_num, 
                    utemp.concept_cd, 
                                        utemp.provider_id,
                                        utemp.start_date, 
                                        utemp.modifier_cd,
                                        utemp.valtype_cd,
                                        utemp.tval_char,
                                        utemp.nval_num,
                                        utemp.valueflag_cd,
                                        utemp.quantity_num,
                                        utemp.confidence_num,
                                        utemp.observation_blob,
                                        utemp.units_cd,
                                        utemp.end_date,
                                        utemp.location_cd,
                                        utemp.update_date,
                                        utemp.download_date,
                                        utemp.import_date,
                                        utemp.sourcesystem_cd,
                                        utemp.upload_id 
                   from ' || upload_temptable_name  || '  utemp , encounter_mapping emap, patient_mapping patmap 
                   where utemp.encounter_ide = emap.encounter_ide and  utemp.patient_ide = patmap.patient_ide
           ) temp
                   on (
                                temp.encounter_num = obsfact.encounter_num
                                and
                                temp.concept_cd = obsfact.concept_cd
                                and
                                temp.patient_num = obsfact.patient_num
            )    
                        when matched then 
                                update  set 
                                        obsfact.provider_id = temp.provider_id,
                                        obsfact.start_date = temp.start_date,
                                        obsfact.modifier_cd = temp.modifier_cd,
                                        obsfact.valtype_cd = temp.valtype_cd,
                                        obsfact.tval_char = temp.tval_char,
                                        obsfact.nval_num = temp.nval_num,
                                        obsfact.valueflag_cd = temp.valueflag_cd,
                                        obsfact.quantity_num = temp.quantity_num,
                                        obsfact.confidence_num = temp.confidence_num,
                                        obsfact.observation_blob = temp.observation_blob ,
                                        obsfact.units_cd = temp.units_cd,
                                        obsfact.end_date = temp.end_date,
                                        obsfact.location_cd = temp.location_cd,
                                        obsfact.update_date = temp.update_date,
                                        obsfact.download_date = temp.download_date,
                                        obsfact.import_date = temp.import_date,
                                        obsfact.sourcesystem_cd = temp.sourcesystem_cd,
                                        obsfact.upload_id = temp.upload_id
                    where temp.update_date > obsfact.update_date
                         when not matched then 
                                insert (encounter_num, 
                                        concept_cd, 
                                        patient_num,
                                        provider_id,
                                        start_date, 
                                        modifier_cd,
                                        valtype_cd,
                                        tval_char,
                                        nval_num,
                                        valueflag_cd,
                                        quantity_num,
                                        confidence_num,
                                        observation_blob,
                                        units_cd,
                                        end_date,
                                        location_cd,
                                        update_date,
                                        download_date,
                                        import_date,
                                        sourcesystem_cd,
                                        upload_id) 
                                values (
                                        temp.encounter_num, 
                                        temp.concept_cd, 
                                        temp.patient_num,
                                        temp.provider_id,
                                        temp.start_date, 
                                        temp.modifier_cd,
                                        temp.valtype_cd,
                                        temp.tval_char,
                                        temp.nval_num,
                                        temp.valueflag_cd,
                                        temp.quantity_num,
                                        temp.confidence_num,
                                        temp.observation_blob,
                                        temp.units_cd,
                                        temp.end_date,
                                        temp.location_cd,
                                        temp.update_date,
                                        temp.download_date,
                                        temp.import_date,
                                        temp.sourcesystem_cd,
                                        temp.upload_id
                                )';     
        EXCEPTION
        WHEN OTHERS THEN
                RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;      
END;
$body$
LANGUAGE PLPGSQL;

