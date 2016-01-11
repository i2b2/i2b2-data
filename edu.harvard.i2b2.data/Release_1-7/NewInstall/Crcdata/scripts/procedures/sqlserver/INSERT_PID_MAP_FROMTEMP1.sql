
create PROCEDURE  INSERT_PID_MAP_FROMTEMP (@tempPatientMapTableName VARCHAR(500), @upload_id INT) 
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
   

	--Delete duplicate rows with same encounter and patient combination
	set @deleteDuplicateSql = 'with deleteTempDup as (SELECT *,ROW_NUMBER() OVER 
( PARTITION BY patient_id,patient_id_source,patient_num 
  ORDER BY patient_id,patient_id_source,patient_num ) AS RNUM FROM ' + @tempPatientMapTableName +') 
delete  from deleteTempDup where rnum>1';

exec sp_executesql @deleteDuplicateSql;
	 

  select @maxPatientNum = max(patient_num) from patient_mapping with (UPDLOCK); 
 
 SELECT @sql = 'DECLARE my_cur INSENSITIVE CURSOR FOR ' +
              ' SELECT distinct patient_id,patient_id_source from ' +  @tempPatientMapTableName  ;
EXEC sp_executesql @sql

OPEN my_cur

FETCH NEXT FROM my_cur into @disPatientId, @disPatientIdSource ;
 WHILE @@FETCH_STATUS = 0

 BEGIN 
BEGIN TRANSACTION
  print @disPatientId + ' ' + @disPatientIdSource      
  if  @disPatientIdSource = 'HIVE'  
  begin
     --check if hive number exist, if so assign that number to reset of map_id's within that pid
     select @existingPatientNum  = patient_num  from patient_mapping where patient_num = @disPatientId and patient_ide_source = 'HIVE';
   
     if @existingPatientNum IS NOT NULL
     begin 
        print 'not null'
        set @sql = ' update ' + @tempPatientMapTableName + ' set patient_num = patient_id, process_status_flag = ''P'' ' + 
        ' where patient_id =  @pdisPatientId   and not exists (select 1 from patient_mapping pm where pm.patient_ide = patient_map_id ' + 
        ' and pm.patient_ide_source = patient_map_id_source)' ;  
        EXEC sp_executesql @sql, N'@pdisPatientId nvarchar(200)',  @pdisPatientId = @disPatientId; 
        --EXEC sp_executesql @sql;
        select @disPatientId;
     end
     else 
     begin
        print 'null not exist HIVE' + @disPatientId
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
        patient_ide_source = @disPatientIdSource and patient_ide_status = 'A'; 

       -- test if record fetched. 
      
       if @existingPatientNum is not null 
       begin
          set @sql = ' update ' + @tempPatientMapTableName +' set patient_num = @pexistingPatientNum , process_status_flag = ''P'' ' + 
            ' where patient_id = @pdisPatientId and not exists (select 1 from patient_mapping pm where pm.patient_ide = patient_map_id ' + 
            ' and pm.patient_ide_source = patient_map_id_source)' ; 
            EXEC sp_executesql @sql,N'@pexistingPatientNum int, @pdisPatientId nvarchar(200)',@pexistingPatientNum=@existingPatientNum,@pdisPatientId=disPatientId;
       end
       else 
       begin
              print ' NOT HIVE and not present ' + @disPatientId;
             set @maxPatientNum = @maxPatientNum + 1 ;
             set @sql = 'insert into ' + @tempPatientMapTableName + ' (patient_map_id,patient_map_id_source,patient_id,patient_id_source,patient_num,process_status_flag ' + 
             ' ) ' +  
             ' values(@pmaxPatientNum1,''HIVE'',@pmaxPatientNum2,''HIVE'',@pmaxPatientNum3,''P'')' ;  
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
set @sql = ' insert into patient_mapping (patient_ide,patient_ide_source,patient_ide_status,patient_num,update_date,download_date,import_date,sourcesystem_cd,upload_id) ' + 
    ' select patient_map_id,patient_map_id_source,''A'',patient_num,update_date,download_date,import_date,sourcesystem_cd,' + convert(nvarchar,@upload_id) + ' from '+@tempPatientMapTableName+  
    ' where process_status_flag = ''P'' ' ;
EXEC sp_executesql @sql;
commit;
 
 END TRY
BEGIN CATCH
   if @@TRANCOUNT > 0 
  begin
     ROLLBACK
   end
   deallocate my_cur;
   declare @errMsg nvarchar(4000), @errSeverity int
   select @errMsg = ERROR_MESSAGE(), @errSeverity = ERROR_SEVERITY();
   RAISERROR(@errMsg,@errSeverity,1); 
 END CATCH
END;