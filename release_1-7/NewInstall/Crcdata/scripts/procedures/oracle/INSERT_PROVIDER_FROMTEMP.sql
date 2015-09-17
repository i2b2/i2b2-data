create or replace PROCEDURE  "INSERT_PROVIDER_FROMTEMP" (tempProviderTableName IN VARCHAR, upload_id IN NUMBER,
   errorMsg OUT VARCHAR)

IS 

BEGIN 
	--Delete duplicate rows with same encounter and patient combination
	execute immediate 'DELETE FROM ' || tempProviderTableName || ' t1 WHERE rowid > 
					   (SELECT  min(rowid) FROM ' || tempProviderTableName || ' t2
					     WHERE t1.provider_id = t2.provider_id 
                                            AND t1.provider_path = t2.provider_path
                                            )';
	
	

 execute immediate ' UPDATE provider_dimension  set  (provider_id,
                        name_char,provider_blob,
                        update_date,download_date,
                        import_date,sourcesystem_cd,
			     	UPLOAD_ID) = (select temp.provider_id, temp.name_char,temp.provider_blob,temp.update_date,temp.DOWNLOAD_DATE,sysdate,temp.SOURCESYSTEM_CD,
			     	' || UPLOAD_ID  || ' from ' || tempProviderTableName || '  temp   where 
					temp.provider_path = provider_dimension.provider_path and temp.update_date >= provider_dimension.update_date) 
					where exists (select 1 from ' || tempProviderTableName || ' temp  where temp.provider_path = provider_dimension.provider_path 
					and temp.update_date >= provider_dimension.update_date) ';

   
    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
	-- in patient_mapping table.
	execute immediate 'insert into provider_dimension  (provider_id,provider_path,name_char,provider_blob,update_date,download_date,import_date,sourcesystem_cd,upload_id)
			    select  provider_id,provider_path, 
                        name_char,provider_blob,
                        update_date,download_date,
                        sysdate,sourcesystem_cd, ' || upload_id || '
	                    
                         from ' || tempProviderTableName || '  temp
					where not exists (select provider_id from provider_dimension pd where pd.provider_path = temp.provider_path )';
	
	
    
    
EXCEPTION
	WHEN OTHERS THEN
		raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);	
END;
 

