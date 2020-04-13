-- By Mike Mendis, Partners Healthcare based on SQL Server code by Griffin Weber, MD, PhD at Harvard Medical School
-- Performance improvements by Jeff Green and Jeff Klann, PhD 03-20
 
-- Count totalnumbers of patients for all metadata tables in table access.
-- Run the procedure like this (but with your schema name instead of i2b2demodata):
--begin
--  runtotalnum('observation_fact','i2b2demodata');
-- end;

create or replace PROCEDURE                           runtotalnum  (observationTable IN VARCHAR, schemaName in VARCHAR)
AUTHID CURRENT_USER
IS


 TYPE distinctTableCurTyp IS REF CURSOR;
 curRecord   distinctTableCurTyp;
 sql_stmt  varchar2(2000);
 dis_c_table_name varchar2(700);
errorMsg VARCHAR2(700);
    v_startime timestamp;
    v_duration varchar2(30);

BEGIN

 sql_stmt := 'select distinct c_table_name from TABLE_ACCESS where c_visualattributes like ''%A%''  ';
 

    -- rather than creating cursor and fetching rows into local variables, instead using record variable type to 
    -- access each element of the current row of the cursor
 open curRecord for sql_stmt ;
 
   loop
    FETCH curRecord INTO dis_c_table_name;
      EXIT WHEN curRecord%NOTFOUND;

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


 END LOOP;

 -- :ERRORMSG := ERRORMSG;
END;