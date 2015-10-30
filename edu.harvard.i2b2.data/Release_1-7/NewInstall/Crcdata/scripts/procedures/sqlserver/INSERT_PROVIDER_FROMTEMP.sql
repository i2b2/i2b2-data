create  PROCEDURE  "INSERT_PROVIDER_FROMTEMP" (@tempProviderTableName VARCHAR(500), @upload_id INT,
  @errorMsg varchar(max)  = NULL OUTPUT) 
AS 

BEGIN 
  declare @deleteDuplicateSql nvarchar(MAX), @insertSql nvarchar(MAX),@updateSql nvarchar(MAX); 
BEGIN TRY
BEGIN TRANSACTION
	--Delete duplicate rows with same encounter and patient combination
	set @deleteDuplicateSql = 'with deleteTempDup as (SELECT *,ROW_NUMBER() OVER 
( PARTITION BY provider_path 
  ORDER BY provider_path ) AS RNUM FROM ' + @tempProviderTableName +') 
delete  from deleteTempDup where rnum>1';

exec sp_executesql @deleteDuplicateSql;
	
set @updateSql = ' UPDATE patient_dimension  set 
			 	    provider_id = temp.provider_id,
                    name_char = temp.name_char,
				    provider_blob = provider_blob,
                    IMPORT_DATE=getdate(),
                 	UPDATE_DATE=temp.UPDATE_DATE,
					DOWNLOAD_DATE=temp.DOWNLOAD_DATE,
					SOURCESYSTEM_CD=temp.SOURCESYSTEM_CD,
					UPLOAD_ID = '+ convert(nvarchar,@upload_id)+ '
					from provider_dimension pd 
                    inner join ' + @tempProviderTableName + ' temp
                    on  pd.provider_path = temp.provider_path
                    where temp.update_date >= pd.update_date
';

print @updateSql;

   
    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
	-- in patient_mapping table.
		set @insertSql =  'insert into provider_dimension  (provider_id,provider_path,name_char,provider_blob,update_date,download_date,import_date,sourcesystem_cd,upload_id)
			    select  provider_id,provider_path, 
                        name_char,provider_blob,
                        update_date,download_date,
                        getdate(),sourcesystem_cd, ' + convert(nvarchar,@upload_id) +  '
	                    from ' + @tempProviderTableName + '  temp
					where not exists (select provider_id from provider_dimension pd where pd.provider_path = temp.provider_path)
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
 
 
