IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'INSERT_EID_MAP_FROMTEMP')
                    AND type IN ( N'P', N'PC' ) ) 
DROP PROCEDURE INSERT_EID_MAP_FROMTEMP;


CREATE PROCEDURE INSERT_EID_MAP_FROMTEMP (@tempEidTableName VARCHAR(500),  @upload_id INT,
@errorMsg VARCHAR(MAX) = NULL OUTPUT) 
AS
BEGIN
 declare @existingEncounterNum varchar(32);
 declare  @maxEncounterNum int;
 declare @deleteDuplicateSql nvarchar(MAX);

declare  @sql_stmt  nvarchar(MAX);
 
declare  @disEncounterId varchar(200); 
declare  @disEncounterIdSource varchar(50);
declare  @disPatientId varchar(100);
declare  @disPatientIdSource varchar(100);


 BEGIN TRY

--Delete duplicate rows with same encounter and patient combination
set @deleteDuplicateSql = 'with deleteTempDup as (SELECT *,ROW_NUMBER() OVER 
( PARTITION BY encounter_map_id,encounter_map_id_source,encounter_id,encounter_id_source 
  ORDER BY encounter_map_id,encounter_map_id_source,encounter_id,encounter_id_source ) AS RNUM FROM ' + @tempEidTableName +') 
delete  from deleteTempDup where rnum>1';
exec sp_executesql @deleteDuplicateSql;


--set IDENTITY_INSERT encounter_mapping ON; 
 -- get max encounter num
 select @maxEncounterNum = isnull(max(encounter_num),0) from encounter_mapping with (UPDLOCK); 
 -- cursor which iterates distinct encounter_id,encounter_id_source compination
 SELECT @sql_stmt = 'DECLARE my_cur INSENSITIVE CURSOR FOR ' +
              ' SELECT distinct encounter_id,encounter_id_source,patient_map_id,patient_map_id_source from ' +  @tempEidTableName  ;
EXEC sp_executesql @sql_stmt;

OPEN my_cur;

-- jgk 10/13/14: Fixes to handle non-globally unique non-HIVE encounter ids
FETCH NEXT FROM my_cur into @disEncounterId, @disEncounterIdSource, @disPatientId,@disPatientIdSource ;
 WHILE @@FETCH_STATUS = 0
 
 BEGIN 
 BEGIN TRANSACTION
  if  @disEncounterIdSource = 'HIVE'   
   begin
    --check if hive number exist, if so assign that number to reset of map_id's within that pid
    select @existingEncounterNum = encounter_num from encounter_mapping where encounter_num = @disEncounterId and encounter_ide_source = 'HIVE';
    
   if @existingEncounterNum is not NULL 
   begin
        set @sql_stmt =  ' update ' + @tempEidTableName  + ' set encounter_num = encounter_id, process_status_flag = ''P'' ' + 
        ' where encounter_id = @pdisEncounterId and not exists (select 1 from encounter_mapping em where em.encounter_ide = encounter_map_id ' + 
        ' and em.encounter_ide_source = encounter_map_id_source)'; 
        EXEC sp_executesql @sql_stmt,N'@pdisEncounterId nvarchar(200)', @pdisEncounterId = @disEncounterId;
    end
    else 
    begin
        -- generate new patient_num i.e. take max(_num) + 1 
        if @maxEncounterNum < @disEncounterId 
        begin
            set @maxEncounterNum = @disEncounterId;
        end;
        set @sql_stmt = ' update ' + @tempEidTableName + ' set encounter_num = encounter_id, process_status_flag = ''P'' where ' +
        ' encounter_id =  @pdisEncounterId and encounter_id_source = ''HIVE'' and not exists (select 1 from encounter_mapping em where em.encounter_ide = encounter_map_id ' +
        ' and em.encounter_ide_source = encounter_map_id_source)'; 
        EXEC sp_executesql @sql_stmt, N'@pdisEncounterId nvarchar(200)',@pdisEncounterId=@disEncounterId ;
     end;    
    -- print ' HIVE ';
 end
 else 
 begin
		-- jgk 10/13/14: non hive encounter #s do not need to be globally unique (3 changes in lines below)
       select @existingEncounterNum = encounter_num  from encounter_mapping where encounter_ide = @disEncounterId and 
        encounter_ide_source = @disEncounterIdSource and patient_ide=@disPatientId and patient_ide_source=@disPatientIdSource; 

       
       if @existingEncounterNum is not  NULL
       begin
            set @sql_stmt =  ' update ' + @tempEidTableName + ' set encounter_num = @pexistingEncounterNum, process_status_flag = ''P'' ' + 
            ' where encounter_id = @pdisEncounterId and not exists (select 1 from encounter_mapping em where em.encounter_ide = encounter_map_id ' +
            ' and em.encounter_ide_source = encounter_map_id_source and em.patient_ide_source = patient_map_id_source and em.patient_ide=patient_map_id)' ;
        EXEC sp_executesql @sql_stmt,N'@pexistingEncounterNum int, @pdisEncounterId nvarchar(200)',@pexistingEncounterNum=@existingEncounterNum ,
          @pdisEncounterId=@disEncounterId;
       end
       else
       begin
            -- jgk 10/16/14: Upate HIVE insert to include patient info
            set @maxEncounterNum = @maxEncounterNum + 1 ;
             set @sql_stmt =   ' insert into ' + @tempEidTableName + ' (patient_map_id,patient_map_id_source,encounter_map_id,encounter_map_id_source,encounter_id,encounter_id_source,encounter_num,process_status_flag
             ,encounter_map_id_status,update_date,download_date,import_date,sourcesystem_cd) 
             values(@pdisPatientId,@pdisPatientIdSource,@pmaxEncounterNum1,''HIVE'',@pmaxEncounterNum2,''HIVE'',@pmaxEncounterNum3,''P'',''A'',getdate(),getdate(),getdate(),''edu.harvard.i2b2.crc'')' ;
            EXEC sp_executesql @sql_stmt, N'@pdisPatientId nvarchar(200),@pdisPatientIdSource nvarchar(200),@pmaxEncounterNum1 int,@pmaxEncounterNum2 int, @pmaxEncounterNum3 int', 
            @pdisPatientid=@disPatientId,@pdisPatientIdSource=@disPatientIdSource,@pmaxEncounterNum1=@maxEncounterNum,@pmaxEncounterNum2=@maxEncounterNum,@pmaxEncounterNum3=@maxEncounterNum; 
            
			 set @sql_stmt =   ' update ' + @tempEidTableName +' set encounter_num = @pmaxEncounterNum , process_status_flag = ''P'' ' +  
             ' where encounter_id = @pdisEncounterId and  not exists (select 1 from ' + 
             ' encounter_mapping em where em.encounter_ide = encounter_map_id ' + 
             ' and em.encounter_ide_source = encounter_map_id_source and em.patient_ide_source = patient_map_id_source ' +
			 ' and em.patient_ide=patient_map_id)' ; 
            EXEC sp_executesql @sql_stmt,N'@pmaxEncounterNum int,@pdisEncounterId nvarchar(200)',@pmaxEncounterNum=@maxEncounterNum , @pdisEncounterId=@disEncounterId;
            
       end  ;
    
      -- print ' NOT HIVE ';
 end ; 
commit;
FETCH NEXT FROM my_cur into @disEncounterId, @disEncounterIdSource, @disPatientId,@disPatientIdSource ;
END ;
CLOSE my_cur
DEALLOCATE my_cur
 BEGIN TRANSACTION 
-- do the mapping update if the update date is old and the encounter_id_source is HIVE
   set @sql_stmt = ' update encounter_mapping set encounter_num = temp.encounter_id,
    	patient_ide   =   temp.patient_map_id ,
    	patient_ide_source  =	temp.patient_map_id_source ,
    	encounter_ide_status	= temp.encounter_map_id_status  ,
    	update_date = temp.update_date,
    	download_date  = temp.download_date ,
		import_date = getdate() ,
    	sourcesystem_cd  = temp.sourcesystem_cd ,
		upload_id = ' + convert(nvarchar,@upload_id) + ' 
		from encounter_mapping em  
         inner join ' + @tempEidTableName + ' temp
                    on em.encounter_ide = temp.encounter_map_id and
			em.encounter_ide_source = temp.encounter_map_id_source 
    	where  temp.encounter_id_source = ''HIVE'' and temp.process_status_flag is null  and
        isnull(em.update_date,0)<= isnull(temp.update_date,0) ' ;
EXEC sp_executesql @sql_stmt;

-- insert new encounters into encounter_mapping  -- jk: added dummy project_id -- jk: insert patient info now
set @sql_stmt =  ' insert into encounter_mapping (encounter_ide,encounter_ide_source,encounter_ide_status,patient_ide,patient_ide_source,encounter_num,update_date,download_date,import_date,sourcesystem_cd,project_id,upload_id) 
    select encounter_map_id,encounter_map_id_source,encounter_map_id_status,patient_map_id,patient_map_id_source,encounter_num,update_date,download_date,getdate(),sourcesystem_cd,
	''@'' project_id,' + convert(nvarchar,@upload_id) + ' from ' + @tempEidTableName + '  
    where process_status_flag = ''P'' ' ; 
EXEC sp_executesql @sql_stmt;
commit;
END TRY

BEGIN CATCH
   if @@TRANCOUNT > 0
   begin
      ROLLBACK
   end
   begin try
   DEALLOCATE my_cur
   end try
   begin catch
   end catch  
   declare @errMsg nvarchar(4000), @errSeverity int
   select @errMsg = ERROR_MESSAGE(), @errSeverity = ERROR_SEVERITY();
   set @errorMsg = @errMsg;
   RAISERROR(@errMsg,@errSeverity,1); 
 END CATCH

end;