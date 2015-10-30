
create   PROCEDURE  INSERT_CONCEPT_FROMTEMP (@tempConceptTableName VARCHAR(500), @upload_id int,
@errorMsg VARCHAR(MAX) = NULL OUTPUT) 
AS 

BEGIN 
 declare @deleteDuplicateSql nvarchar(max);
 declare @insertSql nvarchar(max);
 declare @updateSql nvarchar(max);
BEGIN TRY
  BEGIN TRANSACTION
	--Delete duplicate rows with same encounter and patient combination

	set @deleteDuplicateSql = 'with deleteTempDup as (SELECT *,ROW_NUMBER() OVER 
( PARTITION BY concept_path,concept_cd ORDER BY concept_path,concept_cd ) AS RNUM FROM ' + @tempConceptTableName +') 
delete  from deleteTempDup where rnum>1';
	exec sp_executesql @deleteDuplicateSql;




set @updateSql = ' UPDATE concept_dimension  set 
			 		name_char= temp.name_char,
                    concept_blob= temp.concept_blob,
                    update_date= temp.update_date,
                    import_date = getdate(),
                    DOWNLOAD_DATE=temp.DOWNLOAD_DATE,
					SOURCESYSTEM_CD=temp.SOURCESYSTEM_CD,
					UPLOAD_ID = '+ convert(nvarchar,@upload_id)+ '
					from concept_dimension cd 
                    inner join ' + @tempConceptTableName + ' temp
                    on  cd.concept_path = temp.concept_path
                    where temp.update_date >= cd.update_date';

      exec sp_executesql @updateSql;
   
  
	set @insertSql = 'insert into concept_dimension(concept_cd,concept_path,name_char,concept_blob, ' + 
                     ' update_date,download_date,import_date,sourcesystem_cd,upload_id)  ' + 
			         ' select  concept_cd, concept_path,name_char,concept_blob, update_date,download_date, ' + 
                        ' getdate(),sourcesystem_cd,'+ convert(nvarchar,@upload_id) + ' from  ' + @tempConceptTableName +  ' temp ' +
					' where not exists (select concept_cd from concept_dimension cd where ' + 
				    ' cd.concept_path = temp.concept_path) ';

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
 
 



