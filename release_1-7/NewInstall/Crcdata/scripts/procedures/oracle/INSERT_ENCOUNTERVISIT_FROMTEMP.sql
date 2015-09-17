create or replace PROCEDURE          "INSERT_ENCOUNTERVISIT_FROMTEMP" (tempTableName IN VARCHAR, upload_id IN NUMBER,
  errorMsg OUT VARCHAR) 
IS 
maxEncounterNum number; 
BEGIN 

     --Delete duplicate rows with same encounter and patient combination
	execute immediate 'DELETE FROM ' || tempTableName || ' t1 WHERE rowid > 
					   (SELECT  min(rowid) FROM ' || tempTableName || ' t2
					     WHERE t1.encounter_id = t2.encounter_id 
                                            AND t1.encounter_id_source = t2.encounter_id_source
                                            AND nvl(t1.patient_id,'''') = nvl(t2.patient_id,'''')
                                            AND nvl(t1.patient_id_source,'''') = nvl(t2.patient_id_source,''''))';

	 LOCK TABLE  encounter_mapping IN EXCLUSIVE MODE NOWAIT;
    -- select max(encounter_num) into maxEncounterNum from encounter_mapping ;

	 --Create new patient(patient_mapping) if temp table patient_ide does not exists 
	-- in patient_mapping table. -- jk added project id
     execute immediate ' insert into encounter_mapping (encounter_ide,encounter_ide_source,encounter_num,patient_ide,patient_ide_source,encounter_ide_status, project_id,upload_id)
     	(select distinctTemp.encounter_id, distinctTemp.encounter_id_source, distinctTemp.encounter_id,  distinctTemp.patient_id,distinctTemp.patient_id_source,''A'',''@'' project_id, '|| upload_id ||'
				from 
					(select distinct encounter_id, encounter_id_source,patient_id,patient_id_source from ' || tempTableName || '  temp
					where 
				     not exists (select encounter_ide from encounter_mapping em where em.encounter_ide = temp.encounter_id and em.encounter_ide_source = temp.encounter_id_source)
					 and encounter_id_source = ''HIVE'' )   distinctTemp) ' ;

	
	
	-- update patient_num for temp table
execute immediate ' UPDATE ' ||  tempTableName
 || ' SET encounter_num = (SELECT em.encounter_num
		     FROM encounter_mapping em
		     WHERE em.encounter_ide = '|| tempTableName ||'.encounter_id
                     and em.encounter_ide_source = '|| tempTableName ||'.encounter_id_source 
					 and nvl(em.patient_ide_source,'''') = nvl('|| tempTableName ||'.patient_id_source,'''')
				     and nvl(em.patient_ide,'''')= nvl('|| tempTableName ||'.patient_id,'''')
	 	    )
WHERE EXISTS (SELECT em.encounter_num 
		     FROM encounter_mapping em
		     WHERE em.encounter_ide = '|| tempTableName ||'.encounter_id
                     and em.encounter_ide_source = '||tempTableName||'.encounter_id_source
					 and nvl(em.patient_ide_source,'''') = nvl('|| tempTableName ||'.patient_id_source,'''')
				     and nvl(em.patient_ide,'''')= nvl('|| tempTableName ||'.patient_id,''''))';	

	 execute immediate ' UPDATE visit_dimension  set  (	START_DATE,END_DATE,INOUT_CD,LOCATION_CD,VISIT_BLOB,UPDATE_DATE,DOWNLOAD_DATE,IMPORT_DATE,SOURCESYSTEM_CD, UPLOAD_ID ) 
			= (select temp.START_DATE,temp.END_DATE,temp.INOUT_CD,temp.LOCATION_CD,temp.VISIT_BLOB,temp.update_date,temp.DOWNLOAD_DATE,sysdate,temp.SOURCESYSTEM_CD,
			     	' || UPLOAD_ID  || ' from ' || tempTableName || '  temp   where 
					temp.encounter_num = visit_dimension.encounter_num and temp.update_date >= visit_dimension.update_date) 
					where exists (select 1 from ' || tempTableName || ' temp  where temp.encounter_num = visit_dimension.encounter_num 
					and temp.update_date >= visit_dimension.update_date) ';

   -- jk: added project_id='@' to WHERE clause... need to support projects...
   execute immediate 'insert into visit_dimension  (encounter_num,patient_num,START_DATE,END_DATE,INOUT_CD,LOCATION_CD,VISIT_BLOB,UPDATE_DATE,DOWNLOAD_DATE,IMPORT_DATE,SOURCESYSTEM_CD, UPLOAD_ID)
	               select temp.encounter_num, pm.patient_num,
					temp.START_DATE,temp.END_DATE,temp.INOUT_CD,temp.LOCATION_CD,temp.VISIT_BLOB,
					temp.update_date,
					temp.download_date,
					sysdate, -- import date
					temp.sourcesystem_cd,
		            '|| upload_id ||'
			from 
				' || tempTableName || '  temp , patient_mapping pm 
			where 
                 temp.encounter_num is not null and 
		      	 not exists (select encounter_num from visit_dimension vd where vd.encounter_num = temp.encounter_num) and 
				 pm.patient_ide = temp.patient_id and pm.patient_ide_source = temp.patient_id_source 
                 and pm.project_id=''@''
	 ';
commit;
		        
EXCEPTION
	WHEN OTHERS THEN
		rollback;
		raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);	
END;
 

