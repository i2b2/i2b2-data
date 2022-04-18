-- By Mike Mendis, Partners Healthcare based on SQL Server code by Griffin Weber, MD, PhD at Harvard Medical School
-- Performance improvements by Jeff Green and Jeff Klann, PhD 03-20
 
-- Count totalnumbers of patients for all metadata tables in table access.
-- The results are in: c_totalnum column of all ontology tables, the totalnum table (keeps a historical record), and the totalnum_report table (most recent run, obfuscated) 
-- Run the procedure like this (but with your schema name instead of i2b2demodata):
--begin
--  runtotalnum('observation_fact','i2b2demodata');
-- end;
-- You can optionally include a table named if you only want to count one ontology table (this IS case sensitive):
--begin
--  runtotalnum('observation_fact','i2b2demodata','I2B2');
-- end;
--   To use with multi-fact setups: Create a fact table view as the union of all your fact tables. (This is essentially going back to a single fact table,  but it is only used
--     for totalnum counting. This is needed to correctly count patients that mention multiple fact tables within a hierarchy.)
--    e.g., 
--       create view observation_fact_view as
--       select * from CONDITION_VIEW 
--       union all
--       select * from drug_view
--    And then run the totalnum counter on that fact table:
--      e.g., runtotalnum('observation_fact_view','i2b2demodata');
--    Note this approach does not work if you have conflicting concept_cds across fact tables.

create or replace PROCEDURE                           runtotalnum  (observationTable IN VARCHAR, schemaName in VARCHAR, tableName IN VARCHAR DEFAULT '@')
AUTHID CURRENT_USER
IS


 TYPE distinctTableCurTyp IS REF CURSOR;
 curRecord   distinctTableCurTyp;
 sql_stmt  varchar2(2000);
 dis_c_table_name varchar2(700);
 denom int;
errorMsg VARCHAR2(700);
    v_startime timestamp;
    v_duration varchar2(30);
    c int;

BEGIN

 -- Cleanup in case last run was unsuccessful
   select count(*) into c from user_tables where table_name = upper('dimCountOnt');
   if c = 1 then
      execute immediate 'drop table dimCountOnt';
   end if;
   select count(*) into c from user_tables where table_name = upper('finalDimCounts');
   if c = 1 then
      execute immediate 'drop table finalDimCounts';
   end if;
   select count(*) into c from user_tables where table_name = upper('dimOntWithFolders');
   if c = 1 then
      execute immediate 'drop table dimOntWithFolders';
   end if;
   select count(*) into c from user_tables where table_name = upper('ontPatVisitDims');
   if c = 1 then
      execute immediate 'drop table ontPatVisitDims';
   end if;

 sql_stmt := 'select distinct c_table_name from TABLE_ACCESS where c_visualattributes like ''%A%''  ';
 

    -- rather than creating cursor and fetching rows into local variables, instead using record variable type to 
    -- access each element of the current row of the cursor
 open curRecord for sql_stmt ;
 
   loop
    FETCH curRecord INTO dis_c_table_name;
      EXIT WHEN curRecord%NOTFOUND;
 
      --DBMS_OUTPUT.PUT_LINE(dis_c_table_name);
IF tableName='@' OR tableName=dis_c_table_name THEN

 EXECUTE IMMEDIATE 'update ' || dis_c_table_name || ' set c_totalnum=null';
 v_startime := CURRENT_TIMESTAMP;
 PAT_COUNT_VISITS( dis_c_table_name , schemaName ,errorMsg  );
 v_duration := ((extract(minute from current_timestamp)-extract(minute from v_startime))*60+extract(second from current_timestamp)-extract(second from v_startime))*1000;
 DBMS_OUTPUT.PUT_LINE('(BENCH) '||dis_c_table_name||',PAT_COUNT_VISITS,'||v_duration); 
 v_startime := CURRENT_TIMESTAMP;
 
 PAT_COUNT_DIMENSIONS( dis_c_table_name , schemaName, observationTable ,  'concept_cd', 'concept_dimension', 'concept_path', errorMsg  );
 v_duration := ((extract(minute from current_timestamp)-extract(minute from v_startime))*60+extract(second from current_timestamp)-extract(second from v_startime))*1000;
 DBMS_OUTPUT.PUT_LINE('(BENCH) '||dis_c_table_name||',PAT_COUNT_concept_dimension,'||v_duration); 
 v_startime := CURRENT_TIMESTAMP;
 
 PAT_COUNT_DIMENSIONS( dis_c_table_name , schemaName,  observationTable ,  'provider_id', 'provider_dimension', 'provider_path', errorMsg  );
 v_duration := ((extract(minute from current_timestamp)-extract(minute from v_startime))*60+extract(second from current_timestamp)-extract(second from v_startime))*1000;
 DBMS_OUTPUT.PUT_LINE('(BENCH) '||dis_c_table_name||',PAT_COUNT_provider_dimension,'||v_duration); 
 v_startime := CURRENT_TIMESTAMP;
 
 PAT_COUNT_DIMENSIONS( dis_c_table_name , schemaName, observationTable ,  'modifier_cd', 'modifier_dimension', 'modifier_path', errorMsg  );
 v_duration := ((extract(minute from current_timestamp)-extract(minute from v_startime))*60+extract(second from current_timestamp)-extract(second from v_startime))*1000;
 DBMS_OUTPUT.PUT_LINE('(BENCH) '||dis_c_table_name||',PAT_COUNT_modifier_dimension,'||v_duration); 
 v_startime := CURRENT_TIMESTAMP;
 
 -- New 11/20 - update counts in top levels (table_access) at the end
 execute immediate 'update table_access set c_totalnum=(select c_totalnum from ' || dis_c_table_name || ' x where x.c_fullname=table_access.c_fullname)';
 -- Null out cases that are actually 0 [1/21]
execute immediate 'update  ' || dis_c_table_name || ' set c_totalnum=null where c_totalnum=0 and c_visualattributes like ''C%''';

END IF;

 END LOOP;
 
  -- Cleanup (1/21)
  update table_access set c_totalnum=null where c_totalnum=0;
  -- Denominator (1/21)
  SELECT count(*) into denom from totalnum where c_fullname='\denominator\facts\' and trunc(agg_date)=trunc(CURRENT_DATE);
  IF denom = 0
  THEN
      execute immediate 'insert into totalnum(c_fullname,agg_date,agg_count,typeflag_cd)
          select ''\denominator\facts\'',CURRENT_DATE,count(distinct patient_num),''PX'' from ' || schemaName || '.' || observationTable;
  END IF;

 BuildTotalnumReport(10, 6.5);
 -- :ERRORMSG := ERRORMSG;
END;
