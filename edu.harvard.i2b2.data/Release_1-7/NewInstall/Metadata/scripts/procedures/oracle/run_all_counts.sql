create or replace PROCEDURE                           runtotalnum  (observationTable IN VARCHAR, schemaName in VARCHAR)
IS


 TYPE distinctTableCurTyp IS REF CURSOR;
 curRecord   distinctTableCurTyp;
 sql_stmt  varchar2(2000);
 dis_c_table_name varchar2(700);
errorMsg VARCHAR2(700);

BEGIN

 sql_stmt := 'select distinct c_table_name from TABLE_ACCESS where c_visualattributes like ''%A%''  ';
 

    -- rather than creating cursor and fetching rows into local variables, instead using record variable type to 
    -- access each element of the current row of the cursor
 open curRecord for sql_stmt ;
 
   loop
    FETCH curRecord INTO dis_c_table_name;
      EXIT WHEN curRecord%NOTFOUND;

 EXECUTE IMMEDIATE 'update ' || dis_c_table_name || ' set c_totalnum=null';
 PAT_COUNT_VISITS( dis_c_table_name , schemaName ,errorMsg  );
 PAT_COUNT_DIMENSIONS( dis_c_table_name , schemaName, observationTable ,  'concept_cd', 'concept_dimension', 'concept_path', errorMsg  );
 PAT_COUNT_DIMENSIONS( dis_c_table_name , schemaName,  observationTable ,  'provider_id', 'provider_dimension', 'provider_path', errorMsg  );
 PAT_COUNT_DIMENSIONS( dis_c_table_name , schemaName, observationTable ,  'modifier_cd', 'modifier_dimension', 'modifier_path', errorMsg  );

 END LOOP;

 -- :ERRORMSG := ERRORMSG;
END;