create  PROCEDURE CREATE_TEMP_VISIT_TABLE(@tempTableName  VARCHAR(500), @errorMsg varchar(max) = NULL OUTPUT) 
AS 

BEGIN 
  declare @createSql nvarchar(MAX),@createIndexSql nvarchar(MAX);
  
 BEGIN TRY
BEGIN TRANSACTION
	-- Create temp table to store encounter/visit information
	set @createSql =  'create table ' +  @tempTableName + ' (
		encounter_id 			VARCHAR(200) not null,
		encounter_id_source 	VARCHAR(50) not null, 
		patient_id  			VARCHAR(200) not null,
		patient_id_source 		VARCHAR(50) not null,
		encounter_num	 		    INT, 
		inout_cd   			VARCHAR(50),
		location_cd 			VARCHAR(50),
		location_path 			VARCHAR(900),
 		start_date   			DATETIME, 
 		end_date    			DATETIME,
 		visit_blob 				TEXT,
 		update_date  			DATETIME,
		download_date 			DATETIME,
 		import_date 			DATETIME,
		sourcesystem_cd 		VARCHAR(50)
	)';

	exec sp_executesql @createSql;
	
    set @createIndexSql = 'CREATE INDEX idx_' + @tempTableName + '_enc_id ON ' + @tempTableName + '  (  encounter_id,encounter_id_source,patient_id,patient_id_source )';
    
    exec sp_executesql @createIndexSql;
    
    set @createIndexSql =  'CREATE INDEX idx_' + @tempTableName + '_patient_id ON ' + @tempTableName + '  ( patient_id,patient_id_source )';
    exec sp_executesql @createIndexSql;
    
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