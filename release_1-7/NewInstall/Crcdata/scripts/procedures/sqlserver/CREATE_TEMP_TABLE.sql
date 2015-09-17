create  PROCEDURE CREATE_TEMP_TABLE(@tempTableName  VARCHAR(500), @errorMsg varchar(max)  = NULL OUTPUT) 
AS 

BEGIN 
  declare @createSql nvarchar(MAX),@createIndexSql nvarchar(MAX);
 BEGIN TRY
BEGIN TRANSACTION
	set @createSql = 'create table '+ @tempTableName +'  (
		encounter_num  INT,
		encounter_id varchar(200) not null, 
        encounter_id_source varchar(50) not null,
		concept_cd 	 VARCHAR(50) not null, 
        patient_num INT, 
		patient_id  varchar(200) not null,
        patient_id_source  varchar(50) not null,
	    Provider_Id    	varchar(50) NOT NULL,
	    Start_Date     	datetime NOT NULL,
	    Modifier_Cd    	varchar(100) NOT NULL,
		instance_num    int,
	    ValType_Cd     	varchar(50) NULL,
	   TVal_Char      	varchar(255) NULL,
	   NVal_Num       	decimal(18,5) NULL,
	   ValueFlag_Cd   	varchar(50) NULL,
	   Quantity_Num   	decimal(18,5) NULL,
	   Units_Cd       	varchar(50) NULL,
	   End_Date       	datetime NULL,
	   Location_Cd    	varchar(50) NULL,
	   Observation_Blob text NULL,
	   Confidence_Num 	decimal(18,5) NULL,
 	   update_date  DATETIME,
	   download_date DATETIME,
 	   import_date DATETIME,
	   sourcesystem_cd VARCHAR(50),
 	   upload_id INT
	)';

  exec  sp_executesql @createSql;


   
   set @createIndexSql =  'CREATE INDEX idx_' + @tempTableName + '_pk ON ' + @tempTableName + '  ( encounter_num,patient_num,concept_cd,provider_id,start_date,modifier_cd,instance_num )';
   exec  sp_executesql @createIndexSql;
   
    set @createIndexSql =  'CREATE INDEX idx_' + @tempTableName + '_enc_pat_id ON ' + @tempTableName + '  (encounter_id,encounter_id_source, patient_id,patient_id_source )';
       exec  sp_executesql @createIndexSql;
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
