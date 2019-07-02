CREATE OR REPLACE FUNCTION runtotalnum(observationTable text, schemaName text)
  RETURNS void AS
$BODY$
DECLARE 
    curRecord RECORD;
    v_sqlstring text = '';
    v_union text = '';
    v_numpats integer;
begin
    raise info 'At %, running RunTotalnum()',clock_timestamp();

    for curRecord IN 
        select distinct c_table_name as sqltext
        from TABLE_ACCESS 
        where c_visualattributes like '%A%' 
    LOOP 
        raise info 'At %: Running: %',clock_timestamp(), curRecord.sqltext;

        v_sqlstring := 'select  PAT_COUNT_VISITS( '''||curRecord.sqltext||''' ,'''||schemaName||'''   )';
		execute v_sqlstring;
        v_sqlstring := 'select PAT_COUNT_DIMENSIONS( '''||curRecord.sqltext||''' ,'''||schemaName||''' , '''||observationTable||''' ,  ''concept_cd'', ''concept_dimension'', ''concept_path''  )';
		execute v_sqlstring;
        v_sqlstring := 'select PAT_COUNT_DIMENSIONS( '''||curRecord.sqltext||''' ,'''||schemaName||''' , '''||observationTable||''' ,  ''provider_id'', ''provider_dimension'', ''provider_path''  )';
		execute v_sqlstring;
        v_sqlstring := 'select PAT_COUNT_DIMENSIONS( '''||curRecord.sqltext||''' ,'''||schemaName||''' , '''||observationTable||''' ,  ''modifier_cd'', ''modifier_dimension'', ''modifier_path''  )';
		execute v_sqlstring;

    END LOOP;
end; 
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;