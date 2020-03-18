-- By Mike Mendis, Partners Healthcare
-- Performance improvements by Jeff Green, Prognosis Data Corp; Jeff Klann, PhD; and Griffin Weber, MD, PhD
-- Based on code from Dan Vianello, Center for Biomedical Informatics, Washington University in St. Louis

-- Usage example:
--     select PAT_COUNT_DIMENSIONS( 'I2B2' ,'public' , 'observation_fact' ,  'concept_cd', 'concept_dimension', 'concept_path'  )
--   (replace 'public' by the schema name for the fact table)

CREATE OR REPLACE FUNCTION pat_count_dimensions(metadataTable character varying, schemaName character varying, observationTable character varying, facttablecolumn character varying,tablename character varying,columnname character varying )
  RETURNS void AS
$BODY$
declare 
        -- select PAT_COUNT_DIMENSIONS( 'I2B2' ,'public' , 'observation_fact' ,  'concept_cd', 'concept_dimension', 'concept_path'  )
    v_sqlstr text;
    v_num integer;
    curRecord RECORD;
    v_startime timestamp;
    v_duration text = '';
BEGIN
    raise info 'At %, running PAT_COUNT_DIMENSIONS(''%'')',clock_timestamp(), metadataTable;
    v_startime := clock_timestamp();

    DISCARD TEMP;
    -- Modify this query to select a list of all your ontology paths and basecodes.

    v_sqlstr := 'create temp table dimCountOnt AS '
             || ' select c_fullname, c_basecode, c_hlevel '
             || ' from ' || metadataTable  
             || ' where lower(c_facttablecolumn) = '''||facttablecolumn||''' '
             || ' and lower(c_tablename) = '''|| tablename || ''' '
             || ' and lower(c_columnname) = '''|| columnname || ''' '
             || ' and lower(c_synonym_cd) = ''n'' '
             || ' and lower(c_columndatatype) = ''t'' '
             || ' and lower(c_operator) = ''like'' '
             || ' and m_applied_path = ''@'' '
		     || ' and coalesce(c_fullname, '''') <> '''' '
		     || ' and (c_visualattributes not like ''L%'' or  c_basecode in (select distinct concept_cd from observation_fact)) ';
		-- NEW: Sparsify the working ontology by eliminating leaves with no data. HUGE win in ACT meds ontology (10x speedup).
        -- From 1.47M entries to 300k entries!
           
    raise info 'SQL: %',v_sqlstr;
    execute v_sqlstr;

    create index dimCountOntA on dimCountOnt using spgist (c_fullname);
    CREATE INDEX dimCountOntB ON dimCountOnt(c_fullname text_pattern_ops);

    create temp table dimOntWithFolders AS
        select distinct p1.c_fullname, p1.c_basecode
        from dimCountOnt p1
        where 1=0;
        
    CREATE INDEX dimOntWithFoldersIndex ON dimOntWithFolders using btree(c_basecode);


For curRecord IN 
		select c_fullname,c_table_name from table_access 
    LOOP 
if metadataTable = curRecord.c_table_name then
--v_sqlstr := 'insert into dimOntWithFolders select distinct  c_fullname , c_basecode  from  provider_ont where c_fullname like ''' || replace(curRecord.c_fullname,'\','\\') || '%'' ';

--v_sqlstr := 'insert into dimOntWithFolders '
--       || '   select distinct p1.c_fullname, p2.c_basecode '
--       || '   from dimCountOnt p1 '
--       || '   inner join dimCountOnt p2 '
--       || '     on p2.c_fullname like p1.c_fullname || ''%''  '
--       || '     where p2.c_fullname like  ''' || replace(curRecord.c_fullname,'\','\\') || '%'' '
--       || '       and p1.c_fullname like  ''' || replace(curRecord.c_fullname,'\','\\') || '%'' ';


-- Jeff Green's version
v_sqlstr := 'with recursive concepts (c_fullname, c_hlevel, c_basecode) as ('
	|| ' select c_fullname, c_hlevel, c_basecode '
	|| '  from dimCountOnt '
	|| '  where c_fullname like ''' || replace(curRecord.c_fullname,'\','\\') || '%'' '
	|| ' union all ' 
	|| ' select cast( '
	|| '  	left(c_fullname, length(c_fullname)-position(''\'' in right(reverse(c_fullname), length(c_fullname)-1))) '
	|| '	   	as varchar(700) '
	|| '	) c_fullname, ' 
	|| ' c_hlevel-1 c_hlevel, c_basecode '
	|| ' from concepts '
	|| ' where concepts.c_hlevel>0 '
	|| ' ) '
|| ' insert into dimOntWithFolders '
|| ' select distinct c_fullname, c_basecode '
|| '  from concepts '
|| '  where c_fullname like ''' || replace(curRecord.c_fullname,'\','\\') || '%'' '
|| '  order by c_fullname, c_basecode ';

    raise info 'SQL_dimOntWithFolders: %',v_sqlstr;
	execute v_sqlstr;
	

 end if;

    END LOOP;

	--raise notice 'At %, collected concepts for % %',clock_timestamp(),curRecord.c_table_name,curRecord.c_fullname;
	v_duration := clock_timestamp()-v_startime;
	raise info '(BENCH) %,collected_concepts,%',curRecord,v_duration;
	v_startime := clock_timestamp();

    -- Too slow version
    --v_sqlstr := ' create temp table finalDimCounts AS '
    --    || ' select p1.c_fullname, count(distinct patient_num) as num_patients '
    --    || ' from dimOntWithFolders p1 '
    --    || ' left join ' || schemaName ||'.'|| observationtable ||  '  o '
    --    || '     on p1.c_basecode = o.' || facttablecolumn  --provider id
    --    || '     and coalesce(p1.c_basecode, '''') <> '''' '
    --    || ' group by p1.c_fullname';
    
    -- 10-20x faster version (based on MSSQL optimizations) 
    
    -- Assign a number to each path and use this for the join to the fact table!
    create temp table Path2Num as
    select c_fullname, row_number() over (order by c_fullname) path_num
        from (
            select distinct c_fullname c_fullname
            from dimOntWithFolders
            where c_fullname is not null and c_fullname<>''
        ) t;
    
    alter table Path2Num add primary key (c_fullname);
    
    create temp table ConceptPath as
    select path_num,c_basecode from Path2Num n inner join dimontwithfolders o on o.c_fullname=n.c_fullname
    where o.c_fullname is not null and c_basecode is not null;
    
    alter table ConceptPath add primary key (c_basecode, path_num);
    
    create temp table PathCounts as
    select p1.path_num, count(distinct patient_num) as num_patients  from ConceptPath p1  left join public.observation_fact  o      on p1.c_basecode = o.concept_cd     and coalesce(p1.c_basecode, '') <> ''  group by p1.path_num;
    
    alter table PathCounts add primary key (path_num);
    
    create temp table finalCountsbyConcept as
    select p.c_fullname, c.num_patients num_patients 
        from PathCounts c
          inner join Path2Num p
           on p.path_num=c.path_num
        order by p.c_fullname;


    --raise notice 'At %, done counting.',clock_timestamp();
	v_duration := clock_timestamp()-v_startime;
	raise info '(BENCH) %,counted_concepts,%',curRecord,v_duration;
	v_startime := clock_timestamp();

    create index on finalCountsbyConcept using btree (c_fullname);

    v_sqlstr := ' update ' || metadataTable || ' a set c_totalnum=b.num_patients '
             || ' from finalCountsbyConcept b '
             || ' where a.c_fullname=b.c_fullname '
            || ' and lower(a.c_facttablecolumn)= ''' || facttablecolumn || ''' '
		    || ' and lower(a.c_tablename) = ''' || tablename || ''' '
		    || ' and lower(a.c_columnname) = ''' || columnname || ''' ';
    select count(*) into v_num from finalCountsByConcept where num_patients is not null and num_patients <> 0;
    raise info 'At %, updating c_totalnum in % %',clock_timestamp(), metadataTable, v_num;
    
	execute v_sqlstr;

    discard temp;
END; 
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;
