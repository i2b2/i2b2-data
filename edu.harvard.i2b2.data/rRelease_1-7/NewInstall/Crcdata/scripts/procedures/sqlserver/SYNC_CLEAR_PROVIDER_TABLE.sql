create 
PROCEDURE SYNC_CLEAR_PROVIDER_TABLE (@tempProviderTableName varchar(500), @backupProviderTableName VARCHAR(500), @upload_id INT, @errorMsg varchar(max) = NULL OUTPUT) 
as

BEGIN 
declare @exec_str nvarchar(MAX);
declare @interProviderDimensionTableName nvarchar(MAX);
declare  @deleteDuplicateSql nvarchar(MAX);
BEGIN TRY
BEGIN TRANSACTION

	--Delete duplicate rows with temp provider table
	set @deleteDuplicateSql = 'with deleteTempDup as (SELECT *,ROW_NUMBER() OVER 
( PARTITION BY provider_path,provider_id ORDER BY provider_path,provider_id ) AS RNUM FROM ' + @tempProviderTableName +') 
delete  from deleteTempDup where rnum>1';
	exec sp_executesql @deleteDuplicateSql;
	
set @interProviderDimensionTableName = @backupProviderTableName + '_inter'; 

-- create new table and indexes
set @exec_str = ' create table '  + @interProviderDimensionTableName  +' (
   Provider_Id    	varchar(50) NOT NULL,
	Provider_Path  	varchar(700) NOT NULL,
	Name_Char      	varchar(850) NULL,
	Provider_Blob  	text NULL,
	Update_Date    	datetime NULL,
	Download_Date  	datetime NULL,
	Import_Date    	datetime NULL,
	Sourcesystem_Cd	varchar(50) NULL ,
    UPLOAD_ID         	INT NULL,
    CONSTRAINT '+ @interProviderDimensionTableName +'_PK PRIMARY KEY(provider_path,provider_id)
	 )';
exec sp_executesql  @exec_str; 

-- insert temp to new table 
set @exec_str = ' insert into ' +  @interProviderDimensionTableName + ' (provider_id, provider_path,name_char,provider_blob,update_date, download_date, import_date, sourcesystem_cd,upload_id)   select  ' +
 ' provider_id, provider_path,name_char,provider_blob,update_date, download_date, import_date, sourcesystem_cd,' + convert(nvarchar,@upload_id) + ' from ' + @tempProviderTableName ;
exec  sp_executesql  @exec_str;

--rename concept table to backup table 
exec sp_rename 'provider_dimension', @backupProviderTableName;

--- add index on provider_id, name_char 
set  @exec_str = 'CREATE INDEX idx_' + @interProviderDimensionTableName + '_pid ON ' 
      +  @interProviderDimensionTableName + '  (provider_id,name_char)';
exec  sp_executesql  @exec_str; 


--- add index upload_id 
set  @exec_str = 'CREATE INDEX idx_' + @interProviderDimensionTableName + '_uid ON ' 
      +  @interProviderDimensionTableName + '  (upload_id)';
exec  sp_executesql  @exec_str;  


--rename new table to concept table
exec sp_rename @interProviderDimensionTableName, 'provider_dimension';

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
