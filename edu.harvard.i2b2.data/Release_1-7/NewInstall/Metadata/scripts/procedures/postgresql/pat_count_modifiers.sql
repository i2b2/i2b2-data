
---------------------------------------------------------------
-- pat_count_modifiers(metadatatable)
---------------------------------------------------------------
CREATE OR REPLACE FUNCTION pat_count_modifiers(metadatatable text, observationtable character varying)
  RETURNS void AS
$BODY$
declare 
    -- see all notes listed in pat_count_by_concept().  The methodolgy of the code here is the same
    v_sqlstr text;
    v_num integer;
BEGIN 
    raise info 'At %, running PAT_COUNT_MODIFIERS(''%'')',clock_timestamp(), metadataTable;

    DISCARD TEMP;
    -- Modify this query to select a list of all your ontology paths and basecodes.

    v_sqlstr := 'create temp table conceptCountOnt AS '
             || ' select c_fullname, c_basecode '
             || ' from ' || metadataTable
             || ' where lower(c_facttablecolumn) = ''modifier_cd'' '
             || ' and lower(c_tablename) = ''modifier_dimension''  '
             || ' and lower(c_columnname) = ''modifier_path'' '
             || ' and lower(c_synonym_cd) = ''n'' '
             || ' and lower(c_columndatatype) = ''t''  '
             || ' and lower(c_operator) = ''like'' '
             || ' and m_applied_path != ''@'' '
             || ' and coalesce(c_fullname, '''') <> '''' ';
    
    execute v_sqlstr;

    create index on conceptCountOnt using spgist (c_fullname);

    create temp table conceptCountOntWithFolders AS
        select c1.c_fullname, c2.c_basecode
        from conceptCountOnt c1
        inner join conceptCountOnt c2
            on c2.c_fullname like c1.c_fullname || '%' escape '&';

    create index on conceptCountOntWithFolders using btree (c_basecode);

    v_sqlstr := ' create temp table finalCountsByConcept AS '
        || ' select c1.c_fullname, count(distinct patient_num) as num_patients '
        || ' from conceptCountOntWithFolders c1 '
        || ' left join ' || observationtable || ' o '
        || '     on c1.c_basecode = o.modifier_cd ' -- modifier code 
        || '     and coalesce(c1.c_basecode, '''') <> '''''
        || ' group by c1.c_fullname';

	execute v_sqlstr;

    create index on finalCountsByConcept using btree (c_fullname);

    v_sqlstr := ' update ' || metadataTable || ' a set c_totalnum=b.num_patients '
             || ' from finalCountsByConcept b ' 
             || ' where a.c_fullname=b.c_fullname ';

    select count(*) into v_num from finalCountsByConcept where num_patients is not null and num_patients <> 0;
    raise info 'At %, updating c_totalnum in % %',clock_timestamp(), metadataTable, v_num;

	execute v_sqlstr;
    DISCARD TEMP;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;
