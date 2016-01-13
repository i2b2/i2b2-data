create 
PROCEDURE CREATE_TEMP_PID_TABLE(@tempPatientMappingTableName  VARCHAR(500), @errorMsg varchar(max)  = NULL OUTPUT) 
AS 

BEGIN 
declare @createSql nvarchar(MAX), @createIndexSql nvarchar(MAX);
BEGIN TRY
BEGIN TRANSACTION
set @createSql =  'create table ' +  @tempPatientMappingTableName + ' (
	    PATIENT_MAP_ID VARCHAR(200), 
		PATIENT_MAP_ID_SOURCE VARCHAR(50), 
		PATIENT_ID_STATUS VARCHAR(50), 
		PATIENT_ID  VARCHAR(200),
	    PATIENT_ID_SOURCE varchar(50),
		PATIENT_NUM INT, 
        PATIENT_MAP_ID_STATUS VARCHAR(50),
		PROCESS_STATUS_FLAG CHAR(1), 
		UPDATE_DATE DATETIME, 
		DOWNLOAD_DATE DATETIME, 
		IMPORT_DATE DATETIME, 
		SOURCESYSTEM_CD VARCHAR(50)
	 )';
exec sp_executesql @createSql; 

set @createIndexSql =  'CREATE INDEX idx_' + @tempPatientMappingTableName + '_pid_id ON ' + @tempPatientMappingTableName + '  ( PATIENT_ID, PATIENT_ID_SOURCE )';
exec sp_executesql @createIndexSql;

set @createIndexSql =  'CREATE INDEX idx_' + @tempPatientMappingTableName + 'map_pid_id ON ' + @tempPatientMappingTableName + '  ( PATIENT_ID,PATIENT_ID_SOURCE,PATIENT_MAP_ID, PATIENT_MAP_ID_SOURCE,PATIENT_NUM )';
exec sp_executesql @createIndexSql;


set @createIndexSql =  'CREATE CLUSTERED INDEX idx_' + @tempPatientMappingTableName + 'stat_pid_id ON ' + @tempPatientMappingTableName + '  ( process_status_flag )';
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