create 
PROCEDURE CREATE_TEMP_EID_TABLE(@tempEnconterMappingTableName  VARCHAR(500),
   @errorMsg varchar(max)  = NULL OUTPUT) 
AS 

BEGIN 
declare @createSql nvarchar(MAX), @createIndexSql nvarchar(MAX);
BEGIN TRY
BEGIN TRANSACTION
set @createSql = 'create table ' +  @tempEnconterMappingTableName + ' (
	ENCOUNTER_MAP_ID       	VARCHAR(200) NOT NULL,
    ENCOUNTER_MAP_ID_SOURCE	VARCHAR(50) NOT NULL,
    PATIENT_MAP_ID          VARCHAR(200), 
	PATIENT_MAP_ID_SOURCE   VARCHAR(50), 
    ENCOUNTER_ID       	    VARCHAR(200) NOT NULL,
    ENCOUNTER_ID_SOURCE     VARCHAR(50) ,
    ENCOUNTER_NUM           INT, 
    ENCOUNTER_MAP_ID_STATUS    VARCHAR(50),
    PROCESS_STATUS_FLAG     CHAR(1),
	UPDATE_DATE DATETIME, 
	DOWNLOAD_DATE DATETIME, 
	IMPORT_DATE DATETIME, 
	SOURCESYSTEM_CD VARCHAR(50)
)';

exec sp_executesql @createSql; 

set @createIndexSql =  'CREATE INDEX idx_' + @tempEnconterMappingTableName + '_eid_id ON ' + @tempEnconterMappingTableName + '  (  ENCOUNTER_ID, ENCOUNTER_ID_SOURCE,ENCOUNTER_MAP_ID, ENCOUNTER_MAP_ID_SOURCE,ENCOUNTER_NUM   )';
exec sp_executesql @createIndexSql;

set @createIndexSql =  'CREATE CLUSTERED INDEX idx_' + @tempEnconterMappingTableName + '_stateid_id ON ' + @tempEnconterMappingTableName + '  ( PROCESS_STATUS_FLAG)';
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