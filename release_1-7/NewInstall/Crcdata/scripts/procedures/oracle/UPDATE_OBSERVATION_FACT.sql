CREATE OR REPLACE PROCEDURE UPDATE_OBSERVATION_FACT (upload_temptable_name IN VARCHAR, upload_id IN NUMBER, appendFlag IN NUMBER,
   errorMsg OUT VARCHAR)
IS
BEGIN



--Delete duplicate records(encounter_ide,patient_ide,concept_cd,start_date,modifier_cd,provider_id)
execute immediate 'DELETE FROM ' || upload_temptable_name ||'  t1 
  where rowid > (select min(rowid) from ' || upload_temptable_name ||' t2 
    where t1.encounter_id = t2.encounter_id  
          and
          t1.encounter_id_source = t2.encounter_id_source
          and
          t1.patient_id = t2.patient_id 
          and 
          t1.patient_id_source = t2.patient_id_source
          and 
          t1.concept_cd = t2.concept_cd
          and 
          t1.start_date = t2.start_date
          and 
          nvl(t1.modifier_cd,''xyz'') = nvl(t2.modifier_cd,''xyz'')
		  and 
		  t1.instance_num = t2.instance_num
          and 
          t1.provider_id = t2.provider_id)';

          
--Delete records having null in start_date
execute immediate 'DELETE FROM ' || upload_temptable_name ||'  t1           
 where t1.start_date is null';
           
           
--One time lookup on encounter_ide to get encounter_num jk: added dummy project id
-- jgk 8/13/14: site encounter #s are only distinct per patient
-- jgk 10/13/14: bugfix
execute immediate 'UPDATE ' ||  upload_temptable_name
 || ' SET encounter_num = (SELECT em.encounter_num
		     FROM encounter_mapping em
		     WHERE em.encounter_ide = ' || upload_temptable_name||'.encounter_id
                     and em.encounter_ide_source = '|| upload_temptable_name||'.encounter_id_source
                     and em.project_id=''@'' and em.patient_ide = ' || upload_temptable_name||'.patient_id
                     and em.patient_ide_source = '|| upload_temptable_name||'.patient_id_source
	 	    )
WHERE EXISTS (SELECT em.encounter_num
		     FROM encounter_mapping em
		     WHERE em.encounter_ide = '|| upload_temptable_name||'.encounter_id
                     and em.encounter_ide_source = '||upload_temptable_name||'.encounter_id_source
                     and em.project_id=''@'' and em.patient_ide = ' || upload_temptable_name||'.patient_id
                     and em.patient_ide_source = '|| upload_temptable_name||'.patient_id_source)';		     




             
--One time lookup on patient_ide to get patient_num jk: added dummy project id below jk: added dummy project id
execute immediate 'UPDATE ' ||  upload_temptable_name
 || ' SET patient_num = (SELECT pm.patient_num 
		     FROM patient_mapping pm
		     WHERE pm.patient_ide = '|| upload_temptable_name||'.patient_id
                     and pm.patient_ide_source = '|| upload_temptable_name||'.patient_id_source
                     and pm.project_id=''@''
	 	    )
WHERE EXISTS (SELECT pm.patient_num 
		     FROM patient_mapping pm
		     WHERE pm.patient_ide = '|| upload_temptable_name||'.patient_id
                     and pm.patient_ide_source = '||upload_temptable_name||'.patient_id_source
                     and pm.project_id=''@'')';		     



IF (appendFlag = 0) THEN
--Archive records which are to be deleted in observation_fact table
execute immediate 'INSERT ALL INTO  archive_observation_fact 
		SELECT obsfact.*, ' || upload_id ||' archive_upload_id 
		FROM observation_fact obsfact
		WHERE obsfact.encounter_num IN 
			(SELECT temp_obsfact.encounter_num
			FROM  ' ||upload_temptable_name ||' temp_obsfact
                        group by temp_obsfact.encounter_num  
            )';


--Delete above archived row from observation_fact
execute immediate 'DELETE  observation_fact 
					WHERE EXISTS (
					SELECT archive.encounter_num
					FROM archive_observation_fact  archive
					where archive.archive_upload_id = '||upload_id ||'
                                         AND archive.encounter_num=observation_fact.encounter_num
										 AND archive.concept_cd = observation_fact.concept_cd
										 AND archive.start_date = observation_fact.start_date
                    )';
END IF;

-- if the append is true, then do the update else do insert all
IF (appendFlag = 0) THEN

--Transfer all rows from temp_obsfact to observation_fact
execute immediate 'INSERT ALL INTO observation_fact(encounter_num,concept_cd, patient_num,provider_id, start_date,modifier_cd,instance_num,valtype_cd,tval_char,nval_num,valueflag_cd,
quantity_num,confidence_num,observation_blob,units_cd,end_date,location_cd, update_date,download_date,import_date,sourcesystem_cd,
upload_id) 
SELECT encounter_num,concept_cd, patient_num,provider_id, start_date,modifier_cd,instance_num,valtype_cd,tval_char,nval_num,valueflag_cd,
quantity_num,confidence_num,observation_blob,units_cd,end_date,location_cd, update_date,download_date,sysdate import_date,sourcesystem_cd,
temp.upload_id 
FROM ' || upload_temptable_name ||' temp
where temp.patient_num is not null and  temp.encounter_num is not null';

ELSE
execute immediate '  MERGE INTO observation_fact
USING ' || upload_temptable_name ||' temp
ON (temp.encounter_num = observation_fact.encounter_num 
				    and temp.patient_num = observation_fact.patient_num
                                    and temp.concept_cd = observation_fact.concept_cd
					and temp.start_date = observation_fact.start_date
		            and temp.provider_id = observation_fact.provider_id
			 		and temp.modifier_cd = observation_fact.modifier_cd 
					and temp.instance_num = observation_fact.instance_num
					)
  when matched then 
  update set valtype_cd = temp.valtype_cd ,
    tval_char=temp.tval_char, 
    nval_num = temp.nval_num,
    valueflag_cd=temp.valueflag_cd,
    quantity_num=temp.quantity_num,
	confidence_num=temp.confidence_num,
	observation_blob =temp.observation_blob,
	units_cd=temp.units_cd,
	end_date=temp.end_date,
	location_cd =temp.location_cd,
	update_date=temp.update_date ,
	download_date =temp.download_date,
	import_date=temp.import_date,
	sourcesystem_cd =temp.sourcesystem_cd,
	upload_id = temp.upload_id 
    where nvl(observation_fact.update_date,to_date(''01-JAN-1900'',''DD-MON-YYYY''))<= nvl(temp.update_date,to_date(''01-JAN-1900'',''DD-MON-YYYY'')) 
     when not matched then 
			 	insert (encounter_num, 
					concept_cd, 
		 			patient_num,
		 			provider_id,
 					start_date, 
		 			modifier_cd,
					instance_num,
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
					temp.instance_num,
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
 				) where temp.patient_num is not null and  temp.encounter_num is not null';

END IF;

EXCEPTION
	WHEN OTHERS THEN
        --DBMS_OUTPUT.put_line(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        --DBMS_OUTPUT.put_line('An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
		raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);	
END;