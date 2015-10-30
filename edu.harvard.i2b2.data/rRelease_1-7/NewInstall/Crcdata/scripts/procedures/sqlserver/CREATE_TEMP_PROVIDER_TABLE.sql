create PROCEDURE CREATE_TEMP_PROVIDER_TABLE(@tempProviderTableName  VARCHAR(500),
    @errorMsg varchar(max)  = NULL OUTPUT) 
AS 

BEGIN 
 declare @createSql nvarchar(MAX);
BEGIN TRY
BEGIN TRANSACTION
set @createSql =  'create table ' +  @tempProviderTableName + ' (
  PROVIDER_ID VARCHAR(50) NOT NULL, 
	PROVIDER_PATH VARCHAR(700) NOT NULL, 
	NAME_CHAR VARCHAR(2000), 
	PROVIDER_BLOB TEXT, 
	UPDATE_DATE DATETIME, 
	DOWNLOAD_DATE DATETIME, 
	IMPORT_DATE DATETIME, 
	SOURCESYSTEM_CD VARCHAR(50), 
	UPLOAD_ID INT
)';
exec  sp_executesql @createSql;

set @createSql =  'CREATE INDEX idx_' + @tempProviderTableName + '_ppath_id ON ' + @tempProviderTableName + '  (PROVIDER_PATH)';

exec  sp_executesql @createSql;

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