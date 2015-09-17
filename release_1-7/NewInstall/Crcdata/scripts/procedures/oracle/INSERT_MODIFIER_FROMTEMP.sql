create or replace PROCEDURE  "INSERT_MODIFIER_FROMTEMP" (tempModifierTableName IN VARCHAR, upload_id IN NUMBER, errorMsg OUT VARCHAR ) 
IS 

BEGIN 
	--Delete duplicate rows 
	execute immediate 'DELETE FROM ' || tempModifierTableName || ' t1 WHERE rowid > 
					   (SELECT  min(rowid) FROM ' || tempModifierTableName || ' t2
					     WHERE t1.modifier_cd = t2.modifier_cd 
                                            AND t1.modifier_path = t2.modifier_path
                                            )';
	
	   execute immediate ' UPDATE modifier_dimension  set  (modifier_cd,
                        name_char,modifier_blob,
                        update_date,download_date,
                        import_date,sourcesystem_cd,
			     	UPLOAD_ID) = (select temp.modifier_cd, temp.name_char,temp.modifier_blob,temp.update_date,temp.DOWNLOAD_DATE,sysdate,temp.SOURCESYSTEM_CD,
			     	' || UPLOAD_ID  || ' from ' || tempModifierTableName || '  temp   where 
					temp.modifier_path = modifier_dimension.modifier_path and temp.update_date >= modifier_dimension.update_date) 
					where exists (select 1 from ' || tempModifierTableName || ' temp  where temp.modifier_path = modifier_dimension.modifier_path 
					and temp.update_date >= modifier_dimension.update_date) ';



   
    --Create new modifier if temp table modifier_path does not exists 
	-- in modifier dimension table.
	execute immediate 'insert into modifier_dimension  (modifier_cd,modifier_path,name_char,modifier_blob,update_date,download_date,import_date,sourcesystem_cd,upload_id)
			    select  modifier_cd, modifier_path,
                        name_char,modifier_blob,
                        update_date,download_date,
                        sysdate,sourcesystem_cd,
                         ' || upload_id || '  from ' || tempModifierTableName || '  temp
					where not exists (select modifier_cd from modifier_dimension cd where cd.modifier_path = temp.modifier_path)
					 
	';
	
	
    
    
EXCEPTION
	WHEN OTHERS THEN
		raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);	
END;

 
