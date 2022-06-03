IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(INSERT_ENCOUNTERVISIT_FROMTEMP')
                    AND type IN ( N'P', N'PC' ) ) 
DROP PROCEDURE INSERT_ENCOUNTERVISIT_FROMTEMP;
GO

create  PROCEDURE   "INSERT_ENCOUNTERVISIT_FROMTEMP" (@tempTableName  VARCHAR(500), @upload_id int ,
 @errorMsg varchar(max) = NULL OUTPUT) 
AS 

BEGIN 
declare @deleteDuplicateSql nvarchar(MAX), 
 @insertSql nvarchar(MAX) ,
 @updateSql nvarchar(MAX);

BEGIN TRY
  BEGIN TRANSACTION
  --set IDENTITY_INSERT encounter_mapping on
  select max(encounter_num) from encounter_mapping with (UPDLOCK); 

--Delete duplicate rows with same encounter and patient combination
set @deleteDuplicateSql = 'with deleteTempDup as (SELECT *,ROW_NUMBER() OVER 
( PARTITION BY encounter_id,encounter_id_source,patient_id,patient_id_source 
  ORDER BY encounter_id,encounter_id_source ) AS RNUM FROM ' + @tempTableName +') 
delete  from deleteTempDup where rnum>1';

exec sp_executesql @deleteDuplicateSql;
	
	 --Create new patient(patient_mapping) if temp table patient_ide does not exists 
	-- in patient_mapping table. - jk: changed project id to @ for consistency; will need to eventually support projects
     set @insertSql = ' insert into encounter_mapping (encounter_ide,encounter_ide_source,encounter_num,patient_ide,patient_ide_source,encounter_ide_status,project_id, upload_id)
     	(select distinctTemp.encounter_id, distinctTemp.encounter_id_source, distinctTemp.encounter_id,  distinctTemp.patient_id,distinctTemp.patient_id_source,''A'',''@'',  ' + convert(nvarchar,@upload_id) + '
				from 
					(select distinct encounter_id, encounter_id_source,patient_id,patient_id_source from ' + @tempTableName + '  temp
					where 
				     not exists (select encounter_ide from encounter_mapping em where em.encounter_ide = temp.encounter_id and em.encounter_ide_source = temp.encounter_id_source)
					 and encounter_id_source = ''HIVE'' )   distinctTemp) ' ;

    exec sp_executesql @insertSql;
    	

    	
	-- update patient_num for temp table
 set @updateSql =  ' UPDATE ' +  @tempTableName + ' SET encounter_num = (SELECT em.encounter_num
		     FROM encounter_mapping em
		     WHERE em.encounter_ide = '+  @tempTableName + '.encounter_id
                     and em.encounter_ide_source = '+ @tempTableName +'.encounter_id_source 
					 and isnull(em.patient_ide_source,'''') = isnull('+ @tempTableName +'.patient_id_source,'''')
				     and isnull(em.patient_ide,'''')= isnull('+ @tempTableName +'.patient_id,'''')
	 	    )
WHERE EXISTS (SELECT em.encounter_num 
		     FROM encounter_mapping em
		     WHERE em.encounter_ide = '+ @tempTableName +'.encounter_id
                     and em.encounter_ide_source = '+ @tempTableName +'.encounter_id_source
					 and isnull(em.patient_ide_source,'''') = isnull('+ @tempTableName +'.patient_id_source,'''')
				     and isnull(em.patient_ide,'''')= isnull('+ @tempTableName +'.patient_id,''''))';	     

exec sp_executesql @updateSql;



exec sp_executesql @updateSql;
set @updateSql = ' UPDATE visit_dimension  set 
			 		inout_cd = temp.inout_cd,
			 		location_cd = temp.location_cd,
			 		location_path = temp.location_path,
			 		start_date = temp.start_date,
			 		end_date = temp.end_date,
			 		visit_blob = temp.visit_blob,
			 		update_date = temp.update_date,
			 		download_date = temp.download_date,
			 		import_date = getdate(),
			 		sourcesystem_cd = temp.sourcesystem_cd
                    from visit_dimension vd 
                    inner join ' + @tempTableName + ' temp
                    on  vd.encounter_num = temp.encounter_num
				    where temp.update_date >= vd.update_date
';
exec sp_executesql @updateSql;

 -- jk: added project_id='@' to WHERE clause... need to support projects...
 set @insertSql =  ' insert into visit_dimension  (encounter_num,patient_num,START_DATE,END_DATE,INOUT_CD,LOCATION_CD,VISIT_BLOB,UPDATE_DATE,DOWNLOAD_DATE,IMPORT_DATE,SOURCESYSTEM_CD, UPLOAD_ID)
	               select temp.encounter_num, pm.patient_num,
					temp.START_DATE,temp.END_DATE,temp.INOUT_CD,temp.LOCATION_CD,temp.VISIT_BLOB,
					temp.update_date,
					temp.download_date,
					getdate(), -- import date
					temp.sourcesystem_cd,
		            '+ convert(nvarchar,@upload_id) +'
			from 
				' + @tempTableName + '  temp , patient_mapping pm 
			where 
                 temp.encounter_num is not null and 
		      	 not exists (select encounter_num from visit_dimension vd where vd.encounter_num = temp.encounter_num) and 
				 pm.patient_ide = temp.patient_id and pm.patient_ide_source = temp.patient_id_source
				 and pm.project_id=''@''
	 ';

exec sp_executesql @insertSql;

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
 
 
