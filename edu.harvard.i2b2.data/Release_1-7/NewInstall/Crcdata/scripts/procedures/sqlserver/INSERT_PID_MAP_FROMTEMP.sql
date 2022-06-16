IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'INSERT_PID_MAP_FROMTEMP')
                    AND type IN ( N'P', N'PC' ) ) 
DROP PROCEDURE INSERT_PID_MAP_FROMTEMP;
GO

create PROCEDURE  INSERT_PID_MAP_FROMTEMP (@tempPatientMapTableName VARCHAR(500), @upload_id INT, 
   @errorMsg varchar(max)  = NULL OUTPUT) 
AS 

BEGIN 
  declare @deleteDuplicateSql nvarchar(MAX),
    @insertSql nvarchar(MAX); 

declare  @existingPatientNum nvarchar(32);
declare @maxPatientNum int;
declare @disPatientId nvarchar(200); 
declare @disPatientIdSource nvarchar(50);
declare @sql nvarchar(MAX);
BEGIN TRY
   

	--Delete duplicate rows with same patient combination
	set @deleteDuplicateSql = 'with deleteTempDup as (SELECT *,ROW_NUMBER() OVER 
( PARTITION BY patient_map_id,patient_map_id_source,patient_id,patient_id_source 
  ORDER BY patient_map_id,patient_map_id_source,patient_id,patient_id_source ) AS RNUM FROM ' + @tempPatientMapTableName +') 
delete  from deleteTempDup where rnum>1';

exec sp_executesql @deleteDuplicateSql;
	 
--get max patient_num from patient_mapping table
select @maxPatientNum = isnull(max(patient_num),0) from patient_mapping with (UPDLOCK); 
-- create cursor to iterate distinct event_id,event_id_source combination 
SELECT @sql = 'DECLARE my_cur INSENSITIVE CURSOR FOR ' +
              ' SELECT distinct patient_id,patient_id_source from ' +  @tempPatientMapTableName  ;
EXEC sp_executesql @sql

OPEN my_cur

FETCH NEXT FROM my_cur into @disPatientId, @disPatientIdSource ;
 WHILE @@FETCH_STATUS = 0

 BEGIN 
BEGIN TRANSACTION
  -- print @disPatientId + ' ' + @disPatientIdSource      
  if  @disPatientIdSource = 'HIVE'  
  begin
     --check if hive number exist, if so assign that number to reset of map_id's within that pid
     select @existingPatientNum  = patient_num  from patient_mapping where patient_num = @disPatientId and patient_ide_source = 'HIVE';
   
     if @existingPatientNum IS NOT NULL
     begin 
        -- print 'not null'
        set @sql = ' update ' + @tempPatientMapTableName + ' set patient_num = patient_id, process_status_flag = ''P'' ' + 
        ' where patient_id =  @pdisPatientId   and not exists (select 1 from patient_mapping pm where pm.patient_ide = patient_map_id ' + 
        ' and pm.patient_ide_source = patient_map_id_source)' ;  
        EXEC sp_executesql @sql, N'@pdisPatientId nvarchar(200)',  @pdisPatientId = @disPatientId; 
        --EXEC sp_executesql @sql;
        --select @disPatientId;
     end
     else 
     begin
        -- print 'null not exist HIVE' + @disPatientId
        -- generate new patient_num i.e. take max(patient_num) + 1 
        if @maxPatientNum < @disPatientId 
        begin
           set @maxPatientNum = @disPatientId;
        end;
        set @sql = ' update ' + @tempPatientMapTableName +' set patient_num = patient_id, process_status_flag = ''P'' where ' +
        ' patient_id = @pdisPatientId and patient_id_source = ''HIVE'' and not exists (select 1 from patient_mapping pm where pm.patient_ide = patient_map_id ' +
        ' and pm.patient_ide_source = patient_map_id_source)';
        EXEC sp_executesql @sql, N'@pdisPatientId nvarchar(200)', @pdisPatientId=@disPatientId;
      end; 
   -- test if record fectched
   print ' HIVE ';
  end;
 else 
 begin
       select @existingPatientNum = patient_num   from patient_mapping where patient_ide = @disPatientId and 
        patient_ide_source = @disPatientIdSource ; 

       -- test if record fetched. 
      
       if @existingPatientNum is not NULL
       begin
          set @sql = ' update ' + @tempPatientMapTableName +' set patient_num = @pexistingPatientNum , process_status_flag = ''P'' ' + 
            ' where patient_id = @pdisPatientId and not exists (select 1 from patient_mapping pm where pm.patient_ide = patient_map_id ' + 
            ' and pm.patient_ide_source = patient_map_id_source)' ; 
            EXEC sp_executesql @sql,N'@pexistingPatientNum int, @pdisPatientId nvarchar(200)',@pexistingPatientNum=@existingPatientNum,@pdisPatientId=disPatientId;
       end
       else 
       begin
              -- print ' NOT HIVE and not present ' + @disPatientId;
             set @maxPatientNum = @maxPatientNum + 1 ;
             set @sql = 'insert into ' + @tempPatientMapTableName + ' (patient_map_id,patient_map_id_source,patient_id,patient_id_source,patient_num,process_status_flag ' + 
             ',patient_map_id_status,update_date,download_date,import_date,sourcesystem_cd ) ' +  
             ' values(@pmaxPatientNum1,''HIVE'',@pmaxPatientNum2,''HIVE'',@pmaxPatientNum3,''P'',''A'',getdate(),getdate(),getdate(),''edu.harvard.i2b2.crc'')' ;  
             EXEC sp_executesql  @sql ,N'@pmaxPatientNum1 int,@pmaxPatientNum2 int,
			@pmaxPatientNum3 int',@pmaxPatientNum1 = @maxPatientNum ,@pmaxPatientNum2 = @maxPatientNum,@pmaxPatientNum3 = @maxPatientNum; 
            set @sql =  'update ' + @tempPatientMapTableName + ' set patient_num =  @pmaxPatientNum , process_status_flag = ''P'' ' +  
             ' where patient_id = @pdisPatientId and  not exists (select 1 from ' + 
            ' patient_mapping pm where pm.patient_ide = patient_map_id ' + 
            ' and pm.patient_ide_source = patient_map_id_source)' ; 
             EXEC sp_executesql @sql,N'@pmaxPatientNum int,@pdisPatientId nvarchar(200)',@pmaxPatientNum = @maxPatientNum, @pdisPatientId=@disPatientId  ;
          end;
        
 end ;
commit;
 FETCH NEXT FROM my_cur into @disPatientId, @disPatientIdSource ;
END

CLOSE my_cur
DEALLOCATE my_cur
BEGIN TRANSACTION

-- do the mapping update if the update date is old
   set @sql = ' update patient_mapping set patient_num = temp.patient_id,
    	patient_ide_status	= temp.patient_map_id_status  ,
    	update_date = temp.update_date,
    	download_date  = temp.download_date ,
		import_date = getdate() ,
    	sourcesystem_cd  = temp.sourcesystem_cd ,
		upload_id = ' + convert(nvarchar,@upload_id) + ' 
		from patient_mapping pm 
        inner join ' + @tempPatientMapTableName + ' temp
        on  pm.patient_ide = temp.patient_map_id and pm.patient_ide_source = temp.patient_map_id_source
        where temp.patient_id_source = ''HIVE'' and temp.process_status_flag is null  and isnull(temp.update_date,0) >= isnull(pm.update_date,0)';

EXEC sp_executesql @sql;

-- jk: added project id
set @sql = ' insert into patient_mapping (patient_ide,patient_ide_source,patient_ide_status,patient_num,update_date,download_date,import_date,sourcesystem_cd,project_id,upload_id) ' + 
    ' select patient_map_id,patient_map_id_source,patient_map_id_status,patient_num,update_date,download_date,getdate(),sourcesystem_cd,
	''@'' project_id,' + convert(nvarchar,@upload_id) + ' from '+@tempPatientMapTableName+  
    ' where process_status_flag = ''P'' ' ;
EXEC sp_executesql @sql;

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
END;