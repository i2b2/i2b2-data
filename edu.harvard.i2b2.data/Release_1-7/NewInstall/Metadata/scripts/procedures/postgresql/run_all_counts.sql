-----------------------------------------------------------------------------------------------------------------
-- Function to run totalnum counts on all tables in table_access 
-- 6/8/2016 - modified for PostgreSQL by Dan Vianello, Center for Biomedical Informatics, Washington University in St. Louis
-- 2019 - Modified for i2b2 1.7.12 release by Mike Mendis, Partners Healthcare
-- 2020 - Updated to support reporting and single-table runs by Jeff Klann, Massachusetts General Hospital

-- Usage example:
--     select runtotalnum('observation_fact','public')
--   (replace 'public' by the schema name for the fact table)
-- If using a schema other than public for metadata, you might need to run "set search_path to 'i2b2metadata','public' " first as well
-- You can optionally specify a single table name, to count using only one ontology table. This is case sensitive.
-----------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION runtotalnum(observationTable text, schemaName text, tableName text default '@')
  RETURNS void AS
$BODY$
DECLARE 
    curRecord RECORD;
    v_sqlstring text = '';
    v_union text = '';
    v_numpats integer;
    v_startime timestamp;
    v_duration text = '';
begin
    raise info 'At %, running RunTotalnum()',clock_timestamp();
    v_startime := clock_timestamp();

    for curRecord IN 
        select distinct c_table_name as sqltext
        from TABLE_ACCESS 
        where c_visualattributes like '%A%' 
    LOOP 
        raise info 'At %: Running: %',clock_timestamp(), curRecord.sqltext;

        IF tableName='@' OR tableName=curRecord.sqltext THEN
            v_sqlstring := 'select  PAT_COUNT_VISITS( '''||curRecord.sqltext||''' ,'''||schemaName||'''   )';
            execute v_sqlstring;
            v_duration := clock_timestamp()-v_startime;
            raise info '(BENCH) %,PAT_COUNT_VISITS,%',curRecord,v_duration;
            v_startime := clock_timestamp();
            
            v_sqlstring := 'select PAT_COUNT_DIMENSIONS( '''||curRecord.sqltext||''' ,'''||schemaName||''' , '''||observationTable||''' ,  ''concept_cd'', ''concept_dimension'', ''concept_path''  )';
            execute v_sqlstring;
            v_duration :=  clock_timestamp()-v_startime;
            raise info '(BENCH) %,PAT_COUNT_concept_dimension,%',curRecord,v_duration;
            v_startime := clock_timestamp();
            
            v_sqlstring := 'select PAT_COUNT_DIMENSIONS( '''||curRecord.sqltext||''' ,'''||schemaName||''' , '''||observationTable||''' ,  ''provider_id'', ''provider_dimension'', ''provider_path''  )';
            execute v_sqlstring;
            v_duration := clock_timestamp()-v_startime;
            raise info '(BENCH) %,PAT_COUNT_provider_dimension,%',curRecord,v_duration;
            v_startime := clock_timestamp();
            
            v_sqlstring := 'select PAT_COUNT_DIMENSIONS( '''||curRecord.sqltext||''' ,'''||schemaName||''' , '''||observationTable||''' ,  ''modifier_cd'', ''modifier_dimension'', ''modifier_path''  )';
            execute v_sqlstring;
            v_duration := clock_timestamp()-v_startime;
            raise info '(BENCH) %,PAT_COUNT_modifier_dimension,%',curRecord,v_duration;
            v_startime := clock_timestamp();
        END IF;

    END LOOP;
    
    select BuildTotalnumReport(10, 6.5);
    
end; 
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;
