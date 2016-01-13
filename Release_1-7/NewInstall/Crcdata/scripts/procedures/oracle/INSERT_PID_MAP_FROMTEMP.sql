CREATE OR REPLACE PROCEDURE INSERT_PID_MAP_FROMTEMP (tempPidTableName IN VARCHAR,  upload_id IN NUMBER, 
   errorMsg OUT VARCHAR) 
is
 existingPatientNum varchar2(32);
 maxPatientNum number;

 TYPE distinctPidCurTyp IS REF CURSOR;
distinctPidCur   distinctPidCurTyp;
 sql_stmt  varchar2(400);
 
disPatientId varchar2(100); 
disPatientIdSource varchar2(100);

BEGIN
 sql_stmt := ' SELECT distinct patient_id,patient_id_source from ' || tempPidTableName ||' ';
 
  --delete the data if they miss 
  execute immediate ' delete  from ' || tempPidTableName ||  ' t1  where 
rowid > (select min(rowid) from ' || tempPidTableName || ' t2 
where t1.patient_map_id = t2.patient_map_id
and t1.patient_map_id_source = t2.patient_map_id_source) ';
  
 LOCK TABLE  patient_mapping IN EXCLUSIVE MODE NOWAIT;
 select max(patient_num) into maxPatientNum from patient_mapping ; 
 -- set max patient num to zero of the value is null
 if maxPatientNum is null then 
  maxPatientNum := 0;
end if;

  open distinctPidCur for sql_stmt ;
 
   loop
   
     FETCH distinctPidCur INTO disPatientId, disPatientIdSource;
      EXIT WHEN distinctPidCur%NOTFOUND;
        -- dbms_output.put_line(disPatientId);
        
  if  disPatientIdSource = 'HIVE'  THEN 
   begin
    --check if hive number exist, if so assign that number to reset of map_id's within that pid
    select patient_num into existingPatientNum from patient_mapping where patient_num = disPatientId and patient_ide_source = 'HIVE';
    EXCEPTION  
       when NO_DATA_FOUND THEN
           existingPatientNum := null;
    end;
   if existingPatientNum is not null then 
        execute immediate ' update ' || tempPidTableName ||' set patient_num = patient_id, process_status_flag = ''P''
        where patient_id = :x and not exists (select 1 from patient_mapping pm where pm.patient_ide = patient_map_id
        and pm.patient_ide_source = patient_map_id_source)' using disPatientId;
   else 
        -- generate new patient_num i.e. take max(patient_num) + 1 
        if maxPatientNum < disPatientId then 
            maxPatientNum := disPatientId;
        end if ;
        execute immediate ' update ' || tempPidTableName ||' set patient_num = patient_id, process_status_flag = ''P'' where 
        patient_id = :x and patient_id_source = ''HIVE'' and not exists (select 1 from patient_mapping pm where pm.patient_ide = patient_map_id
        and pm.patient_ide_source = patient_map_id_source)' using disPatientId;
   end if;    
    
   -- test if record fectched
   -- dbms_output.put_line(' HIVE ');

 else 
    begin
       select patient_num into existingPatientNum from patient_mapping where patient_ide = disPatientId and 
        patient_ide_source = disPatientIdSource ; 

       -- test if record fetched. 
       EXCEPTION
           WHEN NO_DATA_FOUND THEN
           existingPatientNum := null;
       end;
       if existingPatientNum is not null then 
            execute immediate ' update ' || tempPidTableName ||' set patient_num = :x , process_status_flag = ''P''
            where patient_id = :y and not exists (select 1 from patient_mapping pm where pm.patient_ide = patient_map_id
        and pm.patient_ide_source = patient_map_id_source)' using  existingPatientNum,disPatientId;
       else 

            maxPatientNum := maxPatientNum + 1 ; 
             execute immediate 'insert into ' || tempPidTableName ||' (patient_map_id,patient_map_id_source,patient_id,patient_id_source,patient_num,process_status_flag
             ,patient_map_id_status,update_date,download_date,import_date,sourcesystem_cd) 
             values(:x,''HIVE'',:y,''HIVE'',:z,''P'',''A'',sysdate,sysdate,sysdate,''edu.harvard.i2b2.crc'')' using maxPatientNum,maxPatientNum,maxPatientNum; 
            execute immediate 'update ' || tempPidTableName ||' set patient_num =  :x , process_status_flag = ''P'' 
             where patient_id = :y and  not exists (select 1 from 
            patient_mapping pm where pm.patient_ide = patient_map_id
            and pm.patient_ide_source = patient_map_id_source)' using maxPatientNum, disPatientId  ;
            
       end if ;
    
      -- dbms_output.put_line(' NOT HIVE ');
 end if; 

END LOOP;
close distinctPidCur ;
commit;

-- do the mapping update if the update date is old
   execute immediate ' merge into patient_mapping
      using ' || tempPidTableName ||' temp
      on (temp.patient_map_id = patient_mapping.patient_IDE 
  		  and temp.patient_map_id_source = patient_mapping.patient_IDE_SOURCE
	   ) when matched then 
  		update set patient_num = temp.patient_id,
    	patient_ide_status	= temp.patient_map_id_status  ,
    	update_date = temp.update_date,
    	download_date  = temp.download_date ,
		import_date = sysdate ,
    	sourcesystem_cd  = temp.sourcesystem_cd ,
		upload_id = ' || upload_id ||'  
    	where  temp.patient_id_source = ''HIVE'' and temp.process_status_flag is null  and
        nvl(patient_mapping.update_date,to_date(''01-JAN-1900'',''DD-MON-YYYY''))<= nvl(temp.update_date,to_date(''01-JAN-1900'',''DD-MON-YYYY'')) ' ;

-- insert new mapping records i.e flagged P - jk: added project id
execute immediate ' insert into patient_mapping (patient_ide,patient_ide_source,patient_ide_status,patient_num,update_date,download_date,import_date,sourcesystem_cd, project_id,upload_id) 
    select patient_map_id,patient_map_id_source,patient_map_id_status,patient_num,update_date,download_date,sysdate,sourcesystem_cd,''@'' project_id,' || upload_id ||' from '|| tempPidTableName || ' 
    where process_status_flag = ''P'' ' ; 
commit;
EXCEPTION
   WHEN OTHERS THEN
      if distinctPidCur%isopen then
          close distinctPidCur;
      end if;
      rollback;
      raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
end;

