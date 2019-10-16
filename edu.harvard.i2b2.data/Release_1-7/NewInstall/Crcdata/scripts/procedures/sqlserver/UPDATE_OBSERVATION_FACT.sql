create  PROCEDURE  UPDATE_OBSERVATION_FACT (@upload_temptable_name VARCHAR(500), @upload_id int, @appendFlag int, 
   @errorMsg varchar(max)  = NULL OUTPUT)
AS
BEGIN
 declare @deleteDuplicateSql nvarchar(MAX), @deleteNullStartDateSql nvarchar(MAX);
 declare @insertSql nvarchar(MAX), @updateSql nvarchar(MAX),@deleteSql nvarchar(MAX);
BEGIN TRY
  BEGIN TRANSACTION
--Delete duplicate records(encounter_ide,patient_ide,concept_cd,start_date,modifier_cd,provider_id)
set @deleteDuplicateSql = 'with deleteTempDup as (SELECT *,ROW_NUMBER() OVER 
( PARTITION BY encounter_id,encounter_id_source,patient_id,patient_id_source,
  concept_cd,start_date,modifier_cd,provider_id,instance_num ORDER BY encounter_id,encounter_id_source ) AS RNUM FROM ' + @upload_temptable_name +') 
delete  from deleteTempDup where rnum>1';

exec sp_executesql @deleteDuplicateSql;

--Delete records having null in start_date
set @deleteNullStartDateSql =  'DELETE FROM ' + @upload_temptable_name + '             
 where start_date is null';
exec sp_executesql @deleteNullStartDateSql;

           
           
--One time lookup on encounter_ide to get encounter_num jk: added dummy project id
-- jgk 10/13/14: site encounter #s are only distinct per patient
set @updateSql =  'UPDATE ' +  @upload_temptable_name
 + ' SET encounter_num = (SELECT distinct em.encounter_num
		     FROM encounter_mapping em
		     WHERE em.encounter_ide = ' + @upload_temptable_name + '.encounter_id
                     and em.encounter_ide_source = '+ @upload_temptable_name + '.encounter_id_source
					 and em.project_id=''@'' and em.patient_ide = ' + @upload_temptable_name +'.patient_id
                     and em.patient_ide_source = ' + @upload_temptable_name + '.patient_id_source
	 	    )
	 	
WHERE EXISTS (SELECT distinct em.encounter_num
		     FROM encounter_mapping em
		     WHERE em.encounter_ide = ' + @upload_temptable_name +'.encounter_id
                     and em.encounter_ide_source = ' + @upload_temptable_name +'.encounter_id_source
					 and em.project_id=''@'' 
                     and em.patient_ide = '  + @upload_temptable_name + '.patient_id
                     and em.patient_ide_source = '+ @upload_temptable_name +'.patient_id_source)';					 

exec sp_executesql @updateSql;

             
--One time lookup on patient_ide to get patient_num jk: added dummy project id
set @updateSql = 'UPDATE ' + @upload_temptable_name + 
  ' SET patient_num = (SELECT distinct pm.patient_num
		     FROM patient_mapping pm
		     WHERE pm.patient_ide = ' +  @upload_temptable_name +'.patient_id
                     and pm.patient_ide_source = '+ @upload_temptable_name+'.patient_id_source
					 and pm.project_id=''@''
	 	    )
WHERE EXISTS (SELECT distinct pm.patient_num 
		     FROM patient_mapping pm
		     WHERE pm.patient_ide = '+ @upload_temptable_name+'.patient_id
                     and pm.patient_ide_source = '+ @upload_temptable_name+'.patient_id_source
					 and pm.project_id=''@'')';		     
exec sp_executesql @updateSql;



IF @appendFlag = 0 BEGIN
--Archive records which are to be deleted in observation_fact table
set @insertSql =  'INSERT  INTO  archive_observation_fact (encounter_num,patient_num,concept_Cd,provider_id,start_date, 
modifier_cd,valtype_cd,tval_char,nval_num,valueflag_cd,quantity_num,units_cd,end_date,location_cd,confidence_num,instance_num,
observation_blob,update_date,download_date,import_date,sourcesystem_cd,archive_upload_id)
		SELECT obsfact.encounter_num,obsfact.patient_num,obsfact.concept_Cd,obsfact.provider_id,obsfact.start_date, 
obsfact.modifier_cd,obsfact.valtype_cd,obsfact.tval_char,obsfact.nval_num,obsfact.valueflag_cd,obsfact.quantity_num,
obsfact.units_cd,obsfact.end_date,obsfact.location_cd,obsfact.confidence_num,obsfact.instance_num,
obsfact.observation_blob,obsfact.update_date,obsfact.download_date,obsfact.import_date,obsfact.sourcesystem_cd, ' + convert(nvarchar,@upload_id) +' archive_upload_id 
		FROM observation_fact obsfact
		WHERE obsfact.encounter_num IN 
			(SELECT temp_obsfact.encounter_num
			FROM  ' + @upload_temptable_name +' temp_obsfact
                        group by  temp_obsfact.encounter_num  
            )';

exec sp_executesql @insertSql; 

--Delete above archived row from observation_fact
set @deleteSql  = 'DELETE  observation_fact 
					WHERE EXISTS (
					SELECT archive.encounter_num
					FROM archive_observation_fact  archive
					where archive.archive_upload_id = '+ convert(nvarchar,@upload_id) +'
                                         AND archive.encounter_num=observation_fact.encounter_num
										 AND archive.concept_cd = observation_fact.concept_cd
										 AND archive.start_date = observation_fact.start_date
                    )';

exec sp_executesql @deleteSql;
END;



IF @appendFlag = 0 begin
--Transfer all rows from temp_obsfact to observation_fact
set @insertSql =  'INSERT  INTO observation_fact(encounter_num,concept_cd, patient_num,provider_id, start_date,modifier_cd,instance_num,valtype_cd,tval_char,nval_num,valueflag_cd,
quantity_num,confidence_num,observation_blob,units_cd,end_date,location_cd, update_date,download_date,import_date,sourcesystem_cd,
upload_id) 
SELECT encounter_num,concept_cd, patient_num,provider_id, start_date,modifier_cd,instance_num,valtype_cd,tval_char,nval_num,valueflag_cd,
quantity_num,confidence_num,observation_blob,units_cd,end_date,location_cd, update_date,download_date,getdate() import_date,sourcesystem_cd,
temp.upload_id 
FROM ' + @upload_temptable_name +' temp
where temp.patient_num is not null and  temp.encounter_num is not null';

exec sp_executesql @insertSql;
end
else 
begin
set @updateSql = ' UPDATE observation_fact  set 
			 		valtype_cd = temp.valtype_cd,
                    tval_char = temp.tval_char,
                    nval_num = temp.nval_num ,
                    valueflag_cd = temp.valueflag_cd,
                    quantity_num = temp.quantity_num,
                    confidence_num = temp.confidence_num ,
                    observation_blob = temp.observation_blob,
                    units_cd = temp.units_cd,
                    end_date = temp.end_date,
                    location_cd = temp.location_cd,
                    update_date= temp.update_date,
                    download_date = temp.download_date,
                    import_date = getdate(),
                    sourcesystem_cd = temp.sourcesystem_cd,
					UPLOAD_ID = '+ convert(nvarchar,@upload_id)+ '
					from observation_fact obsfact 
                    inner join ' + @upload_temptable_name + ' temp
                    on  obsfact.encounter_num = temp.encounter_num 
				    and obsfact.patient_num = temp.patient_num
                    and obsfact.concept_cd = temp.concept_cd
					and obsfact.start_date = temp.start_date
		            and obsfact.provider_id = temp.provider_id
			 		and obsfact.modifier_cd = temp.modifier_cd
					and obsfact.instance_num = temp.instance_num
                    where isnull(obsfact.update_date,0) <= isnull(temp.update_date,0)';

exec sp_executesql @updateSql;

set @insertSql = 'insert into observation_fact(encounter_num,
	patient_num,concept_cd,provider_id,start_date,modifier_cd,instance_num,valtype_cd,tval_char,
	nval_num,valueflag_cd,quantity_num,units_cd,end_date,location_cd ,confidence_num,observation_blob,
	update_date,download_date,import_date,sourcesystem_cd,upload_id)' + 
    ' select  temp.encounter_num, temp.patient_num,temp.concept_cd,temp.provider_id,temp.start_date,temp.modifier_cd,temp.instance_num,temp.valtype_cd,temp.tval_char,
	temp.nval_num,temp.valueflag_cd,temp.quantity_num,temp.units_cd,temp.end_date,temp.location_cd,temp.confidence_num,temp.observation_blob,
	temp.update_date,temp.download_date,getdate(),temp.sourcesystem_cd,'+ convert(nvarchar,@upload_id) + ' from  ' + @upload_temptable_name +  ' temp ' +
					' where temp.patient_num is not null and  temp.encounter_num is not null and not exists (select obsfact.concept_cd from observation_fact obsfact where ' + 
				    ' obsfact.encounter_num = temp.encounter_num 
				      and obsfact.patient_num = temp.patient_num
                      and obsfact.concept_cd = temp.concept_cd
					  and obsfact.start_date = temp.start_date
		              and obsfact.provider_id = temp.provider_id
			 		  and obsfact.modifier_cd = temp.modifier_cd
					  and obsfact.instance_num = temp.instance_num
					) ';

exec sp_executesql @insertSql;
end;

 COMMIT
 END TRY 
 BEGIN CATCH
   if @@TRANCOUNT > 0 
      ROLLBACK
   declare @errMsg nvarchar(4000), @errSeverity int
   select @errMsg = ERROR_MESSAGE(), @errSeverity = ERROR_SEVERITY();
   set @errorMsg = @errMsg;
   RAISERROR(@errMsg,@errSeverity,1); 
 END CATCH


END;
 
