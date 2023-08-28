-----------------------------------------------------------------------------------------------------------------
/*********************************************************
*         SNOWFLAKE IMPLEMENATION FOR RUNNING pat_count_dimensions FUNCTION
*         Based on implementation from Postgresql
*         MD SABER HOSSAIN	7/14/2023
/*        University of Missouri-Columbia			
**********************************************************/

CREATE OR REPLACE PROCEDURE pat_count_dimensions(
    metadataTable VARCHAR
    , schemaName VARCHAR
    , observationTable VARCHAR
    , facttablecolumn VARCHAR
    , tablename VARCHAR
    , columnname VARCHAR
)
RETURNS INT 
LANGUAGE SQL
AS
DECLARE
    v_sqlstr TEXT;
    v_num INTEGER;
    cur CURSOR FOR select c_fullname,c_table_name from table_access;
    v_startime TIMESTAMP;
    v_duration TEXT;
BEGIN
   -- raise info 'At %, running PAT_COUNT_DIMENSIONS(''%'')',clock_timestamp(), metadataTable;
    --v_startime := CURRENT_TIMESTAMP();

    --DISCARD TEMP;
    drop table if exists dimCountOnt;
    drop table if exists dimOntWithFolders;
    drop table if exists Path2Num; 
    drop table if exists ConceptPath; 
    drop table if exists PathCounts; 
    drop table if exists finalDimCounts;
    drop table if exists finalCountsbyConcept;
    
    -- Modify this query to select a list of all your ontology paths and basecodes.
    v_sqlstr := 'create temp table dimCountOnt AS '
             || ' select c_fullname, c_basecode, c_hlevel '
             || ' from ' || metadataTable  
             || ' where lower(c_facttablecolumn) like ''%'||facttablecolumn||''' '
             || ' and lower(c_tablename) = '''|| tablename || ''' '
             || ' and lower(c_columnname) = '''|| columnname || ''' '
             || ' and lower(c_synonym_cd) = ''n'' '
             || ' and lower(c_columndatatype) = ''t'' '
             || ' and lower(c_operator) = ''like'' '
             || ' and m_applied_path = ''@'' '
		     || ' and coalesce(c_fullname, '''') <> '''' '
		     || ' and (c_visualattributes not like ''L%'' or  c_basecode in (select distinct concept_cd from ' || lower(schemaName) || '.'|| observationTable || ')) ';
		-- NEW: Sparsify the working ontology by eliminating leaves with no data. HUGE win in ACT meds ontology (10x speedup).
        -- From 1.47M entries to 300k entries!
           
    -- raise info 'SQL: %',v_sqlstr;
    EXECUTE IMMEDIATE :v_sqlstr;
    
    create temp table dimOntWithFolders AS
        select distinct p1.c_fullname, p1.c_basecode
        from dimCountOnt p1
        where 1=0;
        
    FOR curRecord IN cur DO
        if (metadataTable = curRecord.c_table_name) then
            -- Jeff Green's version
            v_sqlstr := 'insert into dimOntWithFolders '
            || 'with recursive concepts as ('
	        || ' select c_fullname, c_hlevel, c_basecode '
	        || '  from dimCountOnt '
	        || '  where c_fullname like ''' || replace(curRecord.c_fullname,'\\','\\\\') || '%'' '
	        || ' union all ' 
	        || ' select cast( '
	        || '  	left(c_fullname, length(c_fullname)-position(''\\\\'' in right(reverse(c_fullname), length(c_fullname)-1))) '
	        || '	   	as varchar(700) '
	        || '	) c_fullname, ' 
	        || ' c_hlevel-1 c_hlevel, c_basecode '
	        || ' from concepts '
	        || ' where concepts.c_hlevel>0 '
	        || ' ) '
            || ' select distinct c_fullname, c_basecode '
            || '  from concepts '
            || '  where c_fullname like ''' || replace(curRecord.c_fullname,'\\','\\\\') || '%'' '
            || '  order by c_fullname, c_basecode ';

            --raise info 'SQL_dimOntWithFolders: %',v_sqlstr;
	        execute IMMEDIATE :v_sqlstr;
	        --raise notice 'At %, collected concepts for % %',clock_timestamp(),curRecord.c_table_name,curRecord.c_fullname;
	       -- v_duration := CURRENT_TIMESTAMP() - v_startime;
	        --raise info '(BENCH) %,collected_concepts,%',curRecord,v_duration;
	       -- v_startime := CURRENT_TIMESTAMP();
        end if;
    END FOR;

    -- Assign a number to each path and use this for the join to the fact table!
    create temp table Path2Num as
    select c_fullname, row_number() over (order by c_fullname) path_num
        from (
            select distinct c_fullname c_fullname
            from dimOntWithFolders
            where c_fullname is not null and c_fullname<>''
        ) t;
    
    --alter table Path2Num add primary key (c_fullname);
    
    create temp table ConceptPath as
    select path_num,c_basecode from Path2Num n inner join dimontwithfolders o on o.c_fullname=n.c_fullname
    where o.c_fullname is not null and c_basecode is not null;
    
    --alter table ConceptPath add primary key (c_basecode, path_num);
    
  --  create temp table PathCounts as

    v_sqlstr := 'create temp table PathCounts as select p1.path_num, count(distinct patient_num) as num_patients  from ConceptPath p1  left join ' || lower(schemaName) || '.'|| observationTable || '  o      on p1.c_basecode = o.concept_cd     and coalesce(p1.c_basecode, '''') <> ''''  group by p1.path_num';
    

	execute IMMEDIATE :v_sqlstr;

    -- alter table PathCounts add primary key (path_num);
    
    create temp table finalCountsbyConcept as
    select p.c_fullname, c.num_patients num_patients 
        from PathCounts c
          inner join Path2Num p
           on p.path_num=c.path_num
        order by p.c_fullname;
        
    --raise notice 'At %, done counting.',clock_timestamp();
	
    --v_duration := CURRENT_TIMESTAMP() - v_startime;
	--raise info '(BENCH) %,counted_concepts,%',curRecord,v_duration;
	--v_startime := CURRENT_TIMESTAMP();
    --create index on finalCountsbyConcept using btree (c_fullname);
    v_sqlstr := ' update ' || metadataTable || ' a set c_totalnum=b.num_patients '
             || ' from finalCountsbyConcept b '
             || ' where a.c_fullname=b.c_fullname '
            || ' and lower(a.c_facttablecolumn) like ''%' || facttablecolumn || ''' '
		    || ' and lower(a.c_tablename) = ''' || tablename || ''' '
		    || ' and lower(a.c_columnname) = ''' || columnname || ''' ';
    select count(*) into :v_num from finalCountsByConcept where num_patients is not null and num_patients <> 0;
    --raise info 'At %, updating c_totalnum in % %',clock_timestamp(), metadataTable, v_num;
    
	execute IMMEDIATE :v_sqlstr;
	
	-- New 4/2020 - Update the totalnum reporting table as well
	insert into totalnum(c_fullname, agg_date, agg_count, typeflag_cd)
	select c_fullname, current_date, num_patients, 'PF' from finalCountsByConcept where num_patients>0;
    
    -- discard temp;
    drop table if exists dimCountOnt;
    drop table if exists dimOntWithFolders;
    drop table if exists Path2Num; 
    drop table if exists ConceptPath; 
    drop table if exists PathCounts; 
    drop table if exists finalDimCounts;
    drop table if exists finalCountsbyConcept;
END; 
