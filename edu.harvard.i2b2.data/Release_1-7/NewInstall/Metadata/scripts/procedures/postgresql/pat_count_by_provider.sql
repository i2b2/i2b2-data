---------------------------------------------------------------
-- pat_count_by_provider(metadatatable)
---------------------------------------------------------------
CREATE OR REPLACE FUNCTION pat_count_by_provider(metadatatable character varying, observationtable character varying)
  RETURNS void AS
$BODY$
declare 
    -- see all notes listed in pat_count_by_concept().  The methodolgy of the code here is the same
    v_sqlstr text;
    v_num integer;
BEGIN
    raise info 'At %, running PAT_COUNT_BY_PROVIDER(''%'')',clock_timestamp(), metadataTable;

    DISCARD TEMP;
    -- Modify this query to select a list of all your ontology paths and basecodes.

    v_sqlstr := 'create temp table provider_ont AS '
             || ' select c_fullname, c_basecode '
             || ' from ' || metadataTable  
             || ' where lower(c_facttablecolumn) = ''provider_id'' '
             || ' and lower(c_tablename) = ''provider_dimension'' '
             || ' and lower(c_columnname) = ''provider_path'' '
             || ' and lower(c_synonym_cd) = ''n'' '
             || ' and lower(c_columndatatype) = ''t'' '
             || ' and lower(c_operator) = ''like'' '
             || ' and m_applied_path = ''@'' '
		     || ' and coalesce(c_fullname, '''') <> '''' ';
             
    execute v_sqlstr;

    create index on provider_ont using spgist (c_fullname);

    create temp table providerOntWithFolders AS
        select distinct p1.c_fullname, p2.c_basecode
        from provider_ont p1
        inner join provider_ont p2 
            on p2.c_fullname like p1.c_fullname || '%' escape '&';

    create index on providerOntWithFolders using btree (c_basecode);

    v_sqlstr := ' create temp table finalProviderCounts AS '
        || ' select p1.c_fullname, count(distinct patient_num) as num_patients '
        || ' from providerOntWithFolders p1 '
        || ' left join ' || observationtable || ' o 
        || '     on p1.c_basecode = o.provider_id ' --provider id
        || '     and coalesce(p1.c_basecode, '''') <> ''''
        || ' group by p1.c_fullname';

	execute v_sqlstr;

    create index on finalProviderCounts using btree (c_fullname);

    v_sqlstr := ' update ' || metadataTable || ' a set c_totalnum=b.num_patients '
             || ' from finalProviderCounts b '
             || ' where a.c_fullname=b.c_fullname ';

    select count(*) into v_num from finalProviderCounts where num_patients is not null and num_patients <> 0;
    raise info 'At %, updating c_totalnum in % %',clock_timestamp(), metadataTable, v_num;
    
	execute v_sqlstr;
    discard temp;
END; 
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;
