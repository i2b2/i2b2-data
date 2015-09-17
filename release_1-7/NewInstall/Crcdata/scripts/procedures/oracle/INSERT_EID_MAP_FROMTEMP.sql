CREATE OR REPLACE PROCEDURE INSERT_EID_MAP_FROMTEMP (tempEidTableName IN VARCHAR,  upload_id IN NUMBER,
   errorMsg OUT VARCHAR ) 
is
 existingEncounterNum varchar2(32);
 maxEncounterNum number;

 TYPE distinctEIdCurTyp IS REF CURSOR;
distinctEidCur   distinctEIdCurTyp;
 sql_stmt  varchar2(400);
 
disEncounterId varchar2(100); 
disEncounterIdSource varchar2(100);
disPatientId varchar2(100);
disPatientIdSource varchar2(100);

BEGIN
 sql_stmt := ' SELECT distinct encounter_id,encounter_id_source,patient_map_id,patient_map_id_source from ' || tempEidTableName ||' ';
 
  execute immediate ' delete  from ' || tempEidTableName ||  ' t1  where 
rowid > (select min(rowid) from ' || tempEidTableName || ' t2 
where t1.encounter_map_id = t2.encounter_map_id
and t1.encounter_map_id_source = t2.encounter_map_id_source
and t1.encounter_id = t2.encounter_id
and t1.encounter_id_source = t2.encounter_id_source) ';

 LOCK TABLE  encounter_mapping IN EXCLUSIVE MODE NOWAIT;
 select max(encounter_num) into maxEncounterNum from encounter_mapping ; 
 
if maxEncounterNum is null then 
  maxEncounterNum := 0;
end if;

  open distinctEidCur for sql_stmt ;
 
   loop
     FETCH distinctEidCur INTO disEncounterId, disEncounterIdSource,disPatientId,disPatientIdSource;
      EXIT WHEN distinctEidCur%NOTFOUND;
       -- dbms_output.put_line(disEncounterId);
        
  if  disEncounterIdSource = 'HIVE'  THEN 
   begin
    --check if hive number exist, if so assign that number to reset of map_id's within that eid
    select encounter_num into existingEncounterNum from encounter_mapping where encounter_num = disEncounterId and encounter_ide_source = 'HIVE';
    EXCEPTION  
       when NO_DATA_FOUND THEN
           existingEncounterNum := null;
    end;
   if existingEncounterNum is not null then 
        execute immediate ' update ' || tempEidTableName ||' set encounter_num = encounter_id, process_status_flag = ''P''
        where encounter_id = :x and not exists (select 1 from encounter_mapping em where em.encounter_ide = encounter_map_id
        and em.encounter_ide_source = encounter_map_id_source)' using disEncounterId;
	
   else 
        -- generate new encounter_num i.e. take max(_num) + 1 
        if maxEncounterNum < disEncounterId then 
            maxEncounterNum := disEncounterId;
        end if ;
        execute immediate ' update ' || tempEidTableName ||' set encounter_num = encounter_id, process_status_flag = ''P'' where 
        encounter_id =  :x and encounter_id_source = ''HIVE'' and not exists (select 1 from encounter_mapping em where em.encounter_ide = encounter_map_id
        and em.encounter_ide_source = encounter_map_id_source)' using disEncounterId;
      
   end if;    
   
   -- test if record fectched
   -- dbms_output.put_line(' HIVE ');

 else 
    begin
       -- jgk 8/13/14: non hive encounter #s do not need to be globally unique
       select encounter_num into existingEncounterNum from encounter_mapping where encounter_ide = disEncounterId and 
        encounter_ide_source = disEncounterIdSource and patient_ide=disPatientId and patient_ide_source=disPatientIdSource; 

       -- test if record fetched. 
       EXCEPTION
           WHEN NO_DATA_FOUND THEN
           existingEncounterNum := null;
       end;
       if existingEncounterNum is not  null then 
            execute immediate ' update ' || tempEidTableName ||' set encounter_num = :x , process_status_flag = ''P''
            where encounter_id = :y and not exists (select 1 from encounter_mapping em where em.encounter_ide = encounter_map_id
        and em.encounter_ide_source = encounter_map_id_source
        and em.patient_ide_source = patient_map_id_source and em.patient_ide=patient_map_id)' 
        using existingEncounterNum, disEncounterId;
       else 

            maxEncounterNum := maxEncounterNum + 1 ;
			--TODO : add update colunn
             execute immediate ' insert into ' || tempEidTableName ||' (encounter_map_id,encounter_map_id_source,encounter_id,encounter_id_source,encounter_num,process_status_flag
             ,encounter_map_id_status,update_date,download_date,import_date,sourcesystem_cd,patient_map_id,patient_map_id_source) 
             values(:x,''HIVE'',:y,''HIVE'',:z,''P'',''A'',sysdate,sysdate,sysdate,''edu.harvard.i2b2.crc'',:a,:b)' using maxEncounterNum,maxEncounterNum,maxEncounterNum,disPatientId,disPatientIdSource; 
            execute immediate ' update ' || tempEidTableName ||' set encounter_num =  :x , process_status_flag = ''P'' 
            where encounter_id = :y and  not exists (select 1 from 
            encounter_mapping em where em.encounter_ide = encounter_map_id
            and em.encounter_ide_source = encounter_map_id_source
            and em.patient_ide_source = patient_map_id_source and em.patient_ide=patient_map_id)' using maxEncounterNum, disEncounterId;
            
       end if ;
    
      -- dbms_output.put_line(' NOT HIVE ');
 end if; 

END LOOP;
close distinctEidCur ;
commit;
 -- do the mapping update if the update date is old
   execute immediate ' merge into encounter_mapping
      using ' || tempEidTableName ||' temp
      on (temp.encounter_map_id = encounter_mapping.ENCOUNTER_IDE 
  		  and temp.encounter_map_id_source = encounter_mapping.ENCOUNTER_IDE_SOURCE
	   ) when matched then 
  		update set ENCOUNTER_NUM = temp.encounter_id,
    	patient_ide   =   temp.patient_map_id ,
    	patient_ide_source  =	temp.patient_map_id_source ,
    	encounter_ide_status	= temp.encounter_map_id_status  ,
    	update_date = temp.update_date,
    	download_date  = temp.download_date ,
		import_date = sysdate ,
    	sourcesystem_cd  = temp.sourcesystem_cd ,
		upload_id = ' || upload_id ||'  
    	where  temp.encounter_id_source = ''HIVE'' and temp.process_status_flag is null  and
        nvl(encounter_mapping.update_date,to_date(''01-JAN-1900'',''DD-MON-YYYY''))<= nvl(temp.update_date,to_date(''01-JAN-1900'',''DD-MON-YYYY'')) ' ;

-- insert new mapping records i.e flagged P -- jk: added project_id
execute immediate ' insert into encounter_mapping (encounter_ide,encounter_ide_source,encounter_ide_status,encounter_num,patient_ide,patient_ide_source,update_date,download_date,import_date,sourcesystem_cd,project_id,upload_id) 
    select encounter_map_id,encounter_map_id_source,encounter_map_id_status,encounter_num,patient_map_id,patient_map_id_source,update_date,download_date,sysdate,sourcesystem_cd,''@'' project_id,' || upload_id || ' from ' || tempEidTableName || '  
    where process_status_flag = ''P'' ' ; 
commit;
EXCEPTION
   WHEN OTHERS THEN
      if distinctEidCur%isopen then
          close distinctEidCur;
      end if;
      rollback;
      raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
end;