create 
PROCEDURE SYNC_CLEAR_CONCEPT_TABLE (@tempConceptTableName varchar(500), @backupConceptTableName VARCHAR(500), @upload_id INT, @errorMsg varchar(max) = NULL OUTPUT) 
as

BEGIN 
declare @exec_str nvarchar(MAX);
declare @interConceptDimensionTableName nvarchar(MAX);
declare  @deleteDuplicateSql nvarchar(MAX);
BEGIN TRY
BEGIN TRANSACTION

	--Delete duplicate rows with same encounter and patient combination
	set @deleteDuplicateSql = 'with deleteTempDup as (SELECT *,ROW_NUMBER() OVER 
( PARTITION BY concept_path,concept_cd ORDER BY concept_path,concept_cd ) AS RNUM FROM ' + @tempConceptTableName +') 
delete  from deleteTempDup where rnum>1';
	exec sp_executesql @deleteDuplicateSql;
	
set @interConceptDimensionTableName = @backupConceptTableName + '_inter'; 

-- create new table and indexes
set @exec_str = ' create table '  + @interConceptDimensionTableName  +' (
    concept_path   	varchar(700) NOT NULL,
	concept_cd     	varchar(50) NULL,
	name_char      	varchar(2000) NULL,
	concept_blob   	text NULL,
	update_date    	datetime NULL,
	download_date  	datetime NULL,
	import_date    	datetime NULL,
	sourcesystem_cd	varchar(50) NULL,
      UPLOAD_ID       INT NULL,
    CONSTRAINT '+ @interConceptDimensionTableName +'_PK PRIMARY KEY(concept_path)
	 )';
exec sp_executesql  @exec_str; 

-- insert temp to new table 
set @exec_str = ' insert into ' +  @interConceptDimensionTableName + ' (concept_cd, concept_path,name_char,concept_blob,update_date, download_date, import_date, sourcesystem_cd,upload_id)   select  ' +
 ' concept_cd, concept_path,name_char,concept_blob,update_date, download_date, import_date, sourcesystem_cd,' + convert(nvarchar,@upload_id) + ' from ' + @tempConceptTableName ;
exec  sp_executesql  @exec_str;

--rename concept table to backup table 
exec sp_rename 'concept_dimension', @backupConceptTableName;

set  @exec_str = 'CREATE INDEX idx_' + @interConceptDimensionTableName + '_uid ON ' 
      +  @interConceptDimensionTableName + '  (upload_id)';
exec  sp_executesql  @exec_str;  

set  @exec_str = 'CREATE INDEX idx_' + @interConceptDimensionTableName + '_cpcd ON ' 
      +  @interConceptDimensionTableName + '  (concept_path,concept_cd)';
exec  sp_executesql  @exec_str;  
      
--rename new table to concept table
exec sp_rename @interConceptDimensionTableName, 'concept_dimension';

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
