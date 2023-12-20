-----------------------------------------------------------------------------------------------------------------
/*********************************************************
*         SNOWFLAKE IMPLEMENATION FOR RUNNING runtotalnum FUNCTION
*         Based on implementation from Postgresql
*         MD SABER HOSSAIN	7/14/2023
/*        University of Missouri-Columbia			
**********************************************************/

CREATE OR REPLACE PROCEDURE runtotalnum(
    observationTable TEXT, 
    schemaName TEXT, 
    tableName TEXT
)
RETURNS INTEGER
LANGUAGE SQL
AS
DECLARE 
    cur CURSOR FOR select distinct c_table_name as sqltext from TABLE_ACCESS where c_visualattributes like '%A%';
    v_sqlstring TEXT;
    v_union TEXT;
    v_numpats INTEGER;
    v_startime TIMESTAMP;
    v_duration TEXT;
    denom INTEGER;
    curRecord TEXT;
begin
    -- raise info 'At %, running RunTotalnum()',clock_timestamp();
    v_startime := CURRENT_TIMESTAMP();
    FOR r IN cur DO
        curRecord := r.sqltext;
        --raise info 'At %: Running: %',clock_timestamp(), curRecord;
         IF (tableName='@' OR tableName=curRecord) THEN
            call PAT_COUNT_VISITS(:curRecord,:schemaName);
            --v_duration :=  CURRENT_TIMESTAMP() - v_startime;
            --raise info '(BENCH) %,PAT_COUNT_VISITS,%',curRecord,v_duration;
           -- v_startime := CURRENT_TIMESTAMP();
            
            call PAT_COUNT_DIMENSIONS(:curRecord,:schemaName,:observationTable,'concept_cd', 'concept_dimension', 'concept_path');
            
            --v_duration :=  CURRENT_TIMESTAMP() - v_startime;
            --raise info '(BENCH) %,PAT_COUNT_concept_dimension,%',curRecord,v_duration;
           --  v_startime := CURRENT_TIMESTAMP();
            
            call PAT_COUNT_DIMENSIONS(:curRecord,:schemaName,:observationTable,'provider_id', 'provider_dimension', 'provider_path');
           -- v_duration :=  CURRENT_TIMESTAMP() - v_startime;
            --raise info '(BENCH) %,PAT_COUNT_provider_dimension,%',curRecord,v_duration;
           -- v_startime := CURRENT_TIMESTAMP();
            
            call PAT_COUNT_DIMENSIONS(:curRecord,:schemaName,:observationTable,'modifier_cd','modifier_dimension','modifier_path');
           --  v_duration :=  CURRENT_TIMESTAMP() - v_startime;
            -- raise info '(BENCH) %,PAT_COUNT_modifier_dimension,%',curRecord,v_duration;
           -- v_startime := CURRENT_TIMESTAMP();

              -- New 11/20 - update counts in top levels (table_access) at the end
              -- to avoid 'Unsupported subquery type cannot be evaluated' in snowflake, used min(c_totalnum) where c_fullname is unique
              -- update corresponding metadata table only
            v_sqlstring := 'update table_access set c_totalnum=(select min(c_totalnum) from ' || curRecord || ' x where x.c_fullname=table_access.c_fullname) where c_table_name=' || '''' || curRecord || '''';
            execute immediate :v_sqlstring;
             -- Null out cases that are actually 0 [1/21]
             v_sqlstring := 'update  ' || curRecord || ' set c_totalnum=null where c_totalnum=0';
            execute  immediate :v_sqlstring;
        END IF;
    END FOR;
    
      -- Cleanup (1/21)
      update table_access set c_totalnum=null where c_totalnum=0;
      -- Denominator (1/21)
      SELECT count(*) into :denom from totalnum where c_fullname='\\denominator\\facts\\' and agg_date=CURRENT_DATE;
      IF (denom = 0)
      THEN
          v_sqlstring := 'insert into totalnum(c_fullname,agg_date,agg_count,typeflag_cd)
              select ''\\\\denominator\\\\facts\\\\'',CURRENT_DATE,count(distinct patient_num),''PX'' from ' || lower(schemaName) || '.'|| observationTable;
          execute immediate :v_sqlstring;

      END IF;
    
    call BuildTotalnumReport(10, 6.5);
    
END;