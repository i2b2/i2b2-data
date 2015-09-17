create 
PROCEDURE SYNC_CLEAR_MODIFIER_TABLE (@tempModifierTableName varchar(500), @backupModifierTableName VARCHAR(500), @upload_id INT, @errorMsg varchar(max) = NULL OUTPUT) 
as

BEGIN 
declare @exec_str nvarchar(MAX);
declare @interModifierDimensionTableName nvarchar(MAX);
declare  @deleteDuplicateSql nvarchar(MAX);
BEGIN TRY
BEGIN TRANSACTION

	--Delete duplicate rows with same modifier path and modifier cd
	set @deleteDuplicateSql = 'with deleteTempDup as (SELECT *,ROW_NUMBER() OVER 
( PARTITION BY modifier_path,modifier_cd ORDER BY modifier_path,modifier_cd ) AS RNUM FROM ' + @tempModifierTableName +') 
delete  from deleteTempDup where rnum>1';
	exec sp_executesql @deleteDuplicateSql;
	
set @interModifierDimensionTableName = @backupModifierTableName + '_inter'; 

-- create new table and indexes
set @exec_str = ' create table '  + @interModifierDimensionTableName  +' (
    modifier_path   	varchar(700) NOT NULL,
    modifier_cd     	varchar(50) NULL,
	name_char      	varchar(2000) NULL,
	modifier_blob   	text NULL,
	update_date    	datetime NULL,
	download_date  	datetime NULL,
	import_date    	datetime NULL,
	sourcesystem_cd	varchar(50) NULL,
      UPLOAD_ID       INT NULL,
    CONSTRAINT '+ @interModifierDimensionTableName +'_PK PRIMARY KEY(modifier_path)
	 )';
exec sp_executesql  @exec_str; 

-- insert temp to new table 
set @exec_str = ' insert into ' +  @interModifierDimensionTableName + ' (modifier_cd, modifier_path,name_char,modifier_blob,update_date, download_date, import_date, sourcesystem_cd,upload_id)   select  ' +
 ' modifier_cd, modifier_path,name_char,modifier_blob,update_date, download_date, import_date, sourcesystem_cd,' + convert(nvarchar,@upload_id) + ' from ' + @tempModifierTableName ;
exec  sp_executesql  @exec_str;

--rename concept table to backup table 
exec sp_rename 'modifier_dimension', @backupModifierTableName;

set  @exec_str = 'CREATE INDEX idx_' + @interModifierDimensionTableName + '_uid ON ' 
      +  @interModifierDimensionTableName + '  (upload_id)';
exec  sp_executesql  @exec_str;  

set  @exec_str = 'CREATE INDEX idx_' + @interModifierDimensionTableName + '_mpmd ON ' 
      +  @interModifierDimensionTableName + '  (modifier_path,modifier_cd)';
exec  sp_executesql  @exec_str;  
      
--rename new table to concept table
exec sp_rename @interModifierDimensionTableName, 'modifier_dimension';

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
