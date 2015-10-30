create 
PROCEDURE CREATE_TEMP_CONCEPT_TABLE (@tempConceptTableName VARCHAR(500), @errorMsg varchar(max) = NULL OUTPUT) 
as

BEGIN 
declare @exec_str nvarchar(MAX);

BEGIN TRY
BEGIN TRANSACTION
print @tempConceptTableName

set @exec_str = ' create table '  + @tempConceptTableName  +' (
    CONCEPT_CD VARCHAR(50) NOT NULL , 
	CONCEPT_PATH VARCHAR(700) NOT NULL , 
	NAME_CHAR VARCHAR(2000), 
	CONCEPT_BLOB text, 
	UPDATE_DATE datetime, 
	DOWNLOAD_DATE DATEtime, 
	IMPORT_DATE DATEtime, 
	SOURCESYSTEM_CD VARCHAR(50)
	 )';


exec sp_executesql  @exec_str; 

set  @exec_str = 'CREATE INDEX idx_' + @tempConceptTableName + '_pat_id ON ' 
      +  @tempConceptTableName + '  (CONCEPT_PATH)';

exec sp_executesql  @exec_str;

print @tempConceptTableName

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
END
