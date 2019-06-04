---------------------------------------------------------------
-- pat_count_by_concept(metadatatable)
---------------------------------------------------------------
CREATE OR REPLACE FUNCTION pat_count_by_concept(metadatatable character varying, observationtable character varying)
  RETURNS void AS
$BODY$
declare 
    -- this function is significantly different than the examples provided in github for SCILHS
    v_sqlstr varchar(4000);
    v_num integer;
BEGIN 
    --display count and timing information to the user
    raise info 'At %, running PAT_COUNT_BY_CONCEPT(''%'')',clock_timestamp(), metadataTable;

    --using all temporary tables instead of creating and dropping tables
    DISCARD TEMP;
    -- Modify this query to select a list of all your ontology paths and basecodes.
    -- This query is designed to pull all basecodes that are not synonyms and not modifiers.

    --added limiters to the results returned here by exluding rows with null or empty string values in c_fullname and c_basecode
    --which were excluded later in the process as seen in the original scripts
    v_sqlstr := 'create temp table conceptCountOnt as '
             ||    ' select c_fullname, c_basecode '
             ||    ' from ' || metadatatable 
             ||    ' where lower(c_facttablecolumn) = ''concept_cd''  '
             ||      ' and lower(c_tablename)       = ''concept_dimension''  '
             ||      ' and lower(c_columnname)      = ''concept_path''  '
             ||      ' and lower(c_synonym_cd)      = ''n''  '
             ||      ' and lower(c_columndatatype)  = ''t''  '
             ||      ' and lower(c_operator)        = ''like'' '
             ||      ' and m_applied_path           = ''@'' '
             ||      ' and coalesce(c_fullname, '''') <> '''' ';
             
    execute v_sqlstr;

    --creating indexes rather than primary keys on temporary tables to speed up joining between them
    create index on conceptCountOnt using spgist (c_fullname);

    -- since 'folders' may exist such that a given concept code could be a child of another, query the result
    -- set against itself to generate a list of child codes that reflect themselves as members of the parent 
    -- group. This allows for patient counts to be reflected for each patient in both the child an parent record
    -- so that, for example, one patient who had his/her blood pressure taken on the upper arm to be reflected 
    -- in both the "blood pressure taken on the upper arm" as well as the more generic 
    -- "blood pressure taken." (i.e. location agnostic).  Performing this self join here, between just the 
    -- temporary table and itself, which is much smaller than observation_fact, is faster when done separately
    -- rather than being included in the join against the observation_fact table below.

    create temp table conceptCountOntWithFolders as 
	select distinct c1.c_fullname, c2.c_basecode
        from conceptCountOnt c1 
        inner join conceptCountOnt c2
        on c2.c_fullname like c1.c_fullname || '%' escape '&'; -- expecting that no '&' exist in the data

    create index on conceptCountOntWithFolders using btree (c_basecode);
        
    -- original method consisted on pulling all fullnames, assigning numbers to them, pulling all basecodes
    -- that related to the fullname or to fullname that was a child record of the fullname to get a list
    -- of basecodes and numbers.  Separately a full list of distinct concept codes and patient numbers was
    -- pulled from observation_fact to be joined against even though only a subset of the universe of 
    -- concept codes were being examined.  Then the long list of patients was joined to the limited set of 
    -- concept codes to get the number assigned to the fullname and the count of patients.  The number
    -- assigned to the fullname was then matched back against the fullnames so that the ontology table could 
    -- then be updated.  

    -- new method directly queries observation_fact against the limited set of concept codes to get counts
    -- for each unique concetp code as listed in the tables.  These are held temporarily for later use, seen 
    -- below
   v_sqlstr := ' create temp table finalCountsByConcept AS '
        || ' select c1.c_fullname, count(distinct patient_num) as num_patients '
        || ' from conceptCountOntWithFolders c1 '
        || ' left join ' || observationtable || ' o '
        || '      on c1.c_basecode = o.concept_cd '
        || '     and coalesce(c_basecode, '''') <> ''''' -- we don't want to match on empties themselves, but we did need to pull 
        || ' group by c1.c_fullname';                 -- the parent codes, which sometimes have empty values, to get child counts.

	execute v_sqlstr;
	
    --creating indexes rather than primary keys on temporary tables to speed up joining between them
    create index on finalCountsByConcept using btree (c_fullname);

    v_sqlstr := ' update ' || metadataTable || ' a set c_totalnum=b.num_patients '
             || ' from finalCountsByConcept b ' 
             || ' where a.c_fullname=b.c_fullname ';

    --display count and timing information to the user
    select count(*) into v_num from finalCountsByConcept where num_patients is not null and num_patients <> 0;
    raise info 'At %, updating c_totalnum in % %',clock_timestamp(), metadataTable, v_num;

    execute v_sqlstr;
    discard temp;
END; 
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;
  
