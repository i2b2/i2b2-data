
create   PROCEDURE  INSERT_MODIFIER_FROMTEMP (@tempModifierTableName VARCHAR(500), @upload_id int,
@errorMsg VARCHAR(MAX) = NULL OUTPUT) 
AS 

BEGIN 
 declare @deleteDuplicateSql nvarchar(max);
 declare @insertSql nvarchar(max);
 declare @updateSql nvarchar(max);
BEGIN TRY
  BEGIN TRANSACTION
	--Delete duplicate rows 

	set @deleteDuplicateSql = 'with deleteTempDup as (SELECT *,ROW_NUMBER() OVER 
( PARTITION BY modifier_path,modifier_cd ORDER BY modifier_path,modifier_cd ) AS RNUM FROM ' + @tempModifierTableName +') 
delete  from deleteTempDup where rnum>1';
	exec sp_executesql @deleteDuplicateSql;




set @updateSql = ' UPDATE modifier_dimension  set 
			 		name_char= temp.name_char,
                    modifier_blob= temp.modifier_blob,
                    update_date= temp.update_date,
                    import_date = getdate(),
                    DOWNLOAD_DATE=temp.DOWNLOAD_DATE,
					SOURCESYSTEM_CD=temp.SOURCESYSTEM_CD,
					UPLOAD_ID = '+ convert(nvarchar,@upload_id)+ '
					from modifier_dimension cd 
                    inner join ' + @tempModifierTableName + ' temp
                    on  cd.modifier_path = temp.modifier_path
                    where temp.update_date >= cd.update_date';

      exec sp_executesql @updateSql;
   
  
	set @insertSql = 'insert into modifier_dimension(modifier_cd,modifier_path,name_char,modifier_blob, ' + 
                     ' update_date,download_date,import_date,sourcesystem_cd,upload_id)  ' + 
			         ' select  modifier_cd, modifier_path,name_char,modifier_blob, update_date,download_date, ' + 
                        ' getdate(),sourcesystem_cd,'+ convert(nvarchar,@upload_id) + ' from  ' + @tempModifierTableName +  ' temp ' +
					' where not exists (select modifier_cd from modifier_dimension cd where ' + 
				    ' cd.modifier_path = temp.modifier_path) ';

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
 
 



