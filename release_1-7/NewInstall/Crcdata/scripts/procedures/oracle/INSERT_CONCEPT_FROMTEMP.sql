create or replace PROCEDURE  "INSERT_CONCEPT_FROMTEMP" (tempConceptTableName IN VARCHAR, upload_id IN NUMBER, errorMsg OUT VARCHAR ) 
IS 

BEGIN 
	--Delete duplicate rows with same encounter and patient combination
	execute immediate 'DELETE FROM ' || tempConceptTableName || ' t1 WHERE rowid > 
					   (SELECT  min(rowid) FROM ' || tempConceptTableName || ' t2
					     WHERE t1.concept_cd = t2.concept_cd 
                                            AND t1.concept_path = t2.concept_path
                                            )';
	
	   execute immediate ' UPDATE concept_dimension  set  (concept_cd,
                        name_char,concept_blob,
                        update_date,download_date,
                        import_date,sourcesystem_cd,
			     	UPLOAD_ID) = (select temp.concept_cd, temp.name_char,temp.concept_blob,temp.update_date,temp.DOWNLOAD_DATE,sysdate,temp.SOURCESYSTEM_CD,
			     	' || UPLOAD_ID  || ' from ' || tempConceptTableName || '  temp   where 
					temp.concept_path = concept_dimension.concept_path and temp.update_date >= concept_dimension.update_date) 
					where exists (select 1 from ' || tempConceptTableName || ' temp  where temp.concept_path = concept_dimension.concept_path 
					and temp.update_date >= concept_dimension.update_date) ';



   
    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
	-- in patient_mapping table.
	execute immediate 'insert into concept_dimension  (concept_cd,concept_path,name_char,concept_blob,update_date,download_date,import_date,sourcesystem_cd,upload_id)
			    select  concept_cd, concept_path,
                        name_char,concept_blob,
                        update_date,download_date,
                        sysdate,sourcesystem_cd,
                         ' || upload_id || '  from ' || tempConceptTableName || '  temp
					where not exists (select concept_cd from concept_dimension cd where cd.concept_path = temp.concept_path)
					 
	';
	
	
    
    
EXCEPTION
	WHEN OTHERS THEN
		raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);	
END;

 
