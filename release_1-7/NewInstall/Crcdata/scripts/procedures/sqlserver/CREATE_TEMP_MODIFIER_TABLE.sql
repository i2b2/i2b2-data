create 
PROCEDURE CREATE_TEMP_MODIFIER_TABLE (@tempModifierTableName VARCHAR(500), @errorMsg varchar(max) = NULL OUTPUT) 
as

BEGIN 
declare @exec_str nvarchar(MAX);

BEGIN TRY
BEGIN TRANSACTION
print @tempModifierTableName

set @exec_str = ' create table '  + @tempModifierTableName  +' (
        MODIFIER_CD VARCHAR(50) NOT NULL , 
	MODIFIER_PATH VARCHAR(700) NOT NULL , 
	NAME_CHAR VARCHAR(2000), 
	MODIFIER_BLOB text, 
	UPDATE_DATE datetime, 
	DOWNLOAD_DATE DATEtime, 
	IMPORT_DATE DATEtime, 
	SOURCESYSTEM_CD VARCHAR(50)
	 )';


exec sp_executesql  @exec_str; 

set  @exec_str = 'CREATE INDEX idx_' + @tempModifierTableName + '_pat_id ON ' 
      +  @tempModifierTableName + '  (MODIFIER_PATH)';

exec sp_executesql  @exec_str;

print @tempModifierTableName

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
