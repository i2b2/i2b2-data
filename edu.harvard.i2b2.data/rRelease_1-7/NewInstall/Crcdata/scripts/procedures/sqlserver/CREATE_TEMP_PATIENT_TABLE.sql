create 
PROCEDURE CREATE_TEMP_PATIENT_TABLE(@tempPatientDimensionTableName  VARCHAR(500),
   @errorMsg varchar(max) = NULL OUTPUT) 
AS 

BEGIN 
    declare @createSql  nvarchar(MAX);

BEGIN TRY
BEGIN TRANSACTION
	-- Create temp table to store encounter/visit information
	set @createSql =  'create table ' +  @tempPatientDimensionTableName + ' (
		PATIENT_ID VARCHAR(200), 
		PATIENT_ID_SOURCE VARCHAR(50),
		PATIENT_NUM INT,
	    VITAL_STATUS_CD VARCHAR(50), 
	    BIRTH_DATE DATETIME, 
	    DEATH_DATE DATETIME, 
	    SEX_CD VARCHAR(50), 
	    AGE_IN_YEARS_NUM INT, 
	    LANGUAGE_CD VARCHAR(50), 
		RACE_CD VARCHAR(50), 
		MARITAL_STATUS_CD VARCHAR(50), 
		RELIGION_CD VARCHAR(50), 
		ZIP_CD VARCHAR(10), 
		STATECITYZIP_PATH VARCHAR(700), 
		PATIENT_BLOB TEXT, 
		UPDATE_DATE DATETIME, 
		DOWNLOAD_DATE DATETIME, 
		IMPORT_DATE DATETIME, 
		SOURCESYSTEM_CD VARCHAR(50)
	)';


 exec sp_executesql  @createSql; 

set  @createSql  = 'CREATE INDEX idx_' + @tempPatientDimensionTableName + '_pat_id ON ' 
      +  @tempPatientDimensionTableName + '  (PATIENT_ID,PATIENT_ID_SOURCE,PATIENT_NUM)';

exec sp_executesql  @createSql; 
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