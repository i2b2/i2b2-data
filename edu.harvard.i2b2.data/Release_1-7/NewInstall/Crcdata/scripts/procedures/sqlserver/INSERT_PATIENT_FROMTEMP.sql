create  PROCEDURE   INSERT_PATIENT_FROMTEMP (@tempPatientTableName  VARCHAR(500),  @upload_id  INT,
 @errorMsg varchar(max)  = NULL OUTPUT) 
AS 

BEGIN 
	declare @insertPmSql nvarchar(MAX), @insertSql nvarchar(MAX); 
	declare @updateSql nvarchar(MAX);
BEGIN TRY
  BEGIN TRANSACTION
  select max(patient_num) from patient_mapping with (UPDLOCK); 

	--Create new patient mapping entry for HIVE patient's if they are not already mapped in mapping table
	set @insertPmSql =  'insert into patient_mapping (patient_ide,patient_ide_source,patient_ide_status,
patient_num,upload_id) 
		select distinct temp.patient_id, temp.patient_id_source,''A'',temp.patient_id , '+ convert(nvarchar,@upload_id)+ ' 
		from ' + @tempPatientTableName +'  temp 
		where temp.patient_id_source = ''HIVE'' and 
   		not exists (select patient_ide from patient_mapping pm where pm.patient_num = temp.patient_id and pm.patient_ide_source = temp.patient_id_source) 
		'; 

   print @insertPmSql;

    --Create new visit for above inserted encounter's
	--If Visit table's encounter and patient num does match temp table,
	--then new visit information is created.

 exec sp_executesql  @insertPmSql;
 
 --One time lookup on patient_ide to get patient_num 
set @updateSql =  'UPDATE ' + @tempPatientTableName + 
  ' SET patient_num = (SELECT pm.patient_num
		     FROM patient_mapping pm
		     WHERE pm.patient_ide = ' +  @tempPatientTableName +'.patient_id
                     and pm.patient_ide_source = '+ @tempPatientTableName+'.patient_id_source
	 	    )
WHERE EXISTS (SELECT pm.patient_num 
		     FROM patient_mapping pm
		     WHERE pm.patient_ide = '+ @tempPatientTableName+'.patient_id
                     and pm.patient_ide_source = '+ @tempPatientTableName+'.patient_id_source)';		     

exec sp_executesql @updateSql;

set @updateSql =  'UPDATE ' +  @tempPatientTableName +
    ' SET patient_num = convert(numeric,patient_id) 
      WHERE patient_id_source = ''HIVE''';

exec sp_executesql @updateSql;

set @updateSql = ' UPDATE patient_dimension  set 
			 		VITAL_STATUS_CD= temp.VITAL_STATUS_CD,
                    BIRTH_DATE= temp.BIRTH_DATE,
                    DEATH_DATE= temp.DEATH_DATE,
                    SEX_CD= temp.SEX_CD,
                    AGE_IN_YEARS_NUM=temp.AGE_IN_YEARS_NUM,
                    LANGUAGE_CD=temp.LANGUAGE_CD,
                    RACE_CD=temp.RACE_CD,
                    MARITAL_STATUS_CD=temp.MARITAL_STATUS_CD,
                    RELIGION_CD=temp.RELIGION_CD,
                    ZIP_CD=temp.ZIP_CD,
					STATECITYZIP_PATH =temp.STATECITYZIP_PATH,
					PATIENT_BLOB=temp.PATIENT_BLOB,
					UPDATE_DATE=temp.UPDATE_DATE,
					DOWNLOAD_DATE=temp.DOWNLOAD_DATE,
					SOURCESYSTEM_CD=temp.SOURCESYSTEM_CD,
					UPLOAD_ID = '+ convert(nvarchar,@upload_id)+ '
					from patient_dimension pd 
                    inner join ' + @tempPatientTableName + ' temp
                    on  pd.patient_num = temp.patient_num
                    where temp.update_date >= pd.update_date
';

print @updateSql;

exec sp_executesql @updateSql;


	set @insertSql = ' insert into patient_dimension(
					PATIENT_NUM,
					VITAL_STATUS_CD,
                    BIRTH_DATE,
                    DEATH_DATE,
                    SEX_CD,
                    AGE_IN_YEARS_NUM,
                    LANGUAGE_CD,
                    RACE_CD,
                    MARITAL_STATUS_CD,
                    RELIGION_CD,
                    ZIP_CD,
					STATECITYZIP_PATH,
					PATIENT_BLOB,
					UPDATE_DATE,
					DOWNLOAD_DATE,
					SOURCESYSTEM_CD,
					import_date,
	                upload_id
 					) 
			 	 select 
 					temp.PATIENT_NUM,
					temp.VITAL_STATUS_CD,
                    temp.BIRTH_DATE,
                    temp.DEATH_DATE,
                    temp.SEX_CD,
                    temp.AGE_IN_YEARS_NUM,
                    temp.LANGUAGE_CD,
                    temp.RACE_CD,
                    temp.MARITAL_STATUS_CD,
                    temp.RELIGION_CD,
                    temp.ZIP_CD,
					temp.STATECITYZIP_PATH,
					temp.PATIENT_BLOB,
					temp.UPDATE_DATE,
					temp.DOWNLOAD_DATE,
					temp.SOURCESYSTEM_CD,
					getdate(),
	     			' + convert(nvarchar,@upload_id)+' 
	     			 from ' + @tempPatientTableName + ' temp
				 where not exists (select pd.patient_num from patient_dimension pd  
                 where temp.patient_num  = pd.patient_num  ) 
                 and temp.patient_num is not null';
                 

print @insertSql;

exec sp_executesql @insertSql;
  COMMIT
 END TRY 
 BEGIN CATCH
   if @@TRANCOUNT > 0 
      ROLLBACK
   declare @errMsg nvarchar(4000), @errSeverity int
   select @errMsg = ERROR_MESSAGE(), @errSeverity = ERROR_SEVERITY();
   RAISERROR(@errMsg,@errSeverity,1); 
 END CATCH
END;
 
 

