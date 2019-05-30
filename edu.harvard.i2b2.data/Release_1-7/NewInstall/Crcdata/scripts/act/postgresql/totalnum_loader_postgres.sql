-- Instructions:
-- This script will update the c_totalnum column in your ontology to reflect the total count of each term you've mapped in your fact table.
-- This is useful when developing queries (the totalnum appears in the query builder) and will also be used by the SCILHS team for quality checks.
-- To use: 
--- 1) If your fact table is in a different database or schema, search and replace 'observation_fact' with your database name, e.g.,
--   i2b2_facts.dbo.observation_fact. 
--  2) Run this script, which will create the stored procedures and execute them on pcornet_ tables.
--  3) MSSQL: EXEC RUN_ALL_COUNTS <mymetadata_table> GO , replacing <mymetadata_table> with whichever table you want to update the totalnums.
--  3a) PostgreSQL: select run_all_counts('schema.table_name');

-- Developed by Griffin Weber, Harvard Medical School
-- Modified by Lori Phillips, Partners HealthCare
-- Minor edits to support modifiers by Jeff Klann, Harvard Medical School
-- Aug 2015
-- Bugfix in modifiers counts 12/11/15
----------------------------------------------------------------------------------------------------------------------------------------
-- 6/8/2016 
-- Modified for PostgreSQL by Dan Vianello, Center for Biomedical Informatics, Washington University in St. Louis
-- If you have questions or issues with the script, please contact i2b2admin@bmi.wustl.edu 
-- Team at WashU: Snehil Gupta, Connie Zabarovskaya, Brian Romine, Dan Vianello

-- DISCLAIMER for PostgreSQL: the code assumes that pcornet_ tables are in i2b2metadata schema, while observation_fact 
-- and dimension tables are in i2b2demodata schema. If your schema structure is different, 
-- please adjust the code accordingly.
----------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------
-- pat_count_by_concept(metadatatable)
---------------------------------------------------------------
CREATE OR REPLACE FUNCTION pat_count_by_concept(metadatatable character varying)
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
    create temp table finalCountsByConcept AS
        select c1.c_fullname, count(distinct patient_num) as num_patients
        from conceptCountOntWithFolders c1 
        left join public.observation_fact o 
             on c1.c_basecode = o.concept_cd
             and coalesce(c_basecode, '') <> '' -- we don't want to match on empties themselves, but we did need to pull 
        group by c1.c_fullname;                 -- the parent codes, which sometimes have empty values, to get child counts.

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
  
  
---------------------------------------------------------------
-- pat_count_modifiers(metadatatable)
---------------------------------------------------------------
CREATE OR REPLACE FUNCTION pat_count_modifiers(metadatatable text)
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

    create temp table finalCountsByConcept AS
        select c1.c_fullname, count(distinct patient_num) as num_patients
        from conceptCountOntWithFolders c1
        left join public.observation_fact o 
            on c1.c_basecode = o.modifier_cd -- modifier code
            and coalesce(c1.c_basecode, '') <> ''
        group by c1.c_fullname;

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

---------------------------------------------------------------
-- pat_count_by_provider(metadatatable)
---------------------------------------------------------------
CREATE OR REPLACE FUNCTION pat_count_by_provider(metadatatable character varying)
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

    create temp table finalProviderCounts AS
        select p1.c_fullname, count(distinct patient_num) as num_patients
        from providerOntWithFolders p1
        left join public.observation_fact o 
            on p1.c_basecode = o.provider_id --provider id
            and coalesce(p1.c_basecode, '') <> ''
        group by p1.c_fullname;

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

-----------------------------------------------------------------------------------------
-- pat_visit_counts(tabname)
-- DISCLAIMER: assumes that the default value for missing sex_cd is lower('not recorded')
-- adjust the function if a different value is used
-----------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pat_visit_counts(tabname character varying)
  RETURNS void AS
$BODY$
declare 
    v_sqlstr text;
    -- using cursor defined withing FOR RECORD IN QUERY loop below.
    curRecord RECORD;
    v_num integer;
BEGIN
    --display count and timing information to the user
    raise info 'At %, running PAT_VISIT_COUNTS(''%'')',clock_timestamp(), tabname;

    --using all temporary tables instead of creating and dropping tables
    DISCARD TEMP;
    --checking each text fields for forced lowercase values since DB defaults to case sensitive 
	v_sqlstr = 'create temp table ontPatVisitDims as '
          ||    ' select c_fullname'
          ||          ', c_basecode'
          ||          ', c_facttablecolumn'
          ||          ', c_tablename'
          ||          ', c_columnname'
          ||          ', c_operator'
          ||          ', c_dimcode'
          ||          ', null::integer as numpats'
          ||      ' from ' || tabname
          ||      ' where  m_applied_path = ''@'''
          ||        ' and lower(c_tablename) in (''patient_dimension'', ''visit_dimension'') '
          ||        ' and lower(c_dimcode) <> ''\pcori\encounter\version\''  ' ;  -- added because pcori version number is stored in the pcornet_enc table with a c_columnname = 'LOCATION_ZIP'
    /*
     * THE ORIGINAL WUSM implementation did not have the column "visit_dimension.location_zip" in 
     *     ||        ' and lower(c_columnname) not in (''location_zip'') '; --ignoring this often occuring column that we know is not in WUSM schema
     */

    execute v_sqlstr;

    -- rather than creating cursor and fetching rows into local variables, instead using record variable type to 
    -- access each element of the current row of the cursor
	For curRecord IN 
		select c_fullname, c_facttablecolumn, c_tablename, c_columnname, c_operator, c_dimcode from ontPatVisitDims
    LOOP 
        -- check first to determine if current columns of current table actually exist in the schema
        if exists(select 1 from information_schema.columns 
                  where table_catalog = current_catalog 
                    and table_schema = 'i2b2demodata'
                    and table_name = lower(curRecord.c_tablename)
                    and column_name = lower(curRecord.c_columnname)
                 ) then 

            -- simplified query to directly query distinct patient_num instead of querying list of patien_num to feed into outer query for the same
            -- result.  New style runs in approximately half the time as tested with all patients with a particular sex_cd value.  Since all rows 
            -- Since c_facttablecolumn is ALWAYS populated with 'patient_num' for all rows accessed by this function the change to the function is 
            -- worthwhile.  Only in rare cases if changes to the ontology tables are made would the original query be needed, but only where 
            -- c_facttablecolumn would not be 'patient_num AND the values saved in that column in the dimension table are shared between patients that 
            -- don't otherwise have the same ontology would the original method return different results.  It is believed that those results would be 
            -- inaccurate since they would reflect the number of patients who have XXX like patients with this ontology rather than the number of patients
            -- with that ontology. 
            v_sqlstr := 'update ontPatVisitDims '
                     || ' set numpats =  ( '                     
                     ||     ' select count(distinct(patient_num)) '
                     ||     ' from i2b2demodata.' || curRecord.c_tablename 
                     --||     ' where ' || curRecord.c_facttablecolumn
                     --||     ' in ( '
                     --||         ' select ' || curRecord.c_facttablecolumn 
                     --||         ' from i2b2demodata.' || curRecord.c_tablename 
                     ||         ' where '|| curRecord.c_columnname || ' '  ;

            CASE 
            WHEN lower(curRecord.c_columnname) = 'birth_date' 
                 and lower(curRecord.c_tablename) = 'patient_dimension'
                 and lower(curRecord.c_dimcode) like '%not recorded%' then 
                    -- adding specific change of " WHERE patient_dimension.birth_date in ('not_recorded') " to " WHERE patient_dimension.birth_date IS NULL " 
                    -- since IS NULL syntax is not supported in the ontology tables, but the birth_date column is a timestamp datatype and can be null, but cannot be
                    -- the character string 'not recorded'
                    v_sqlstr := v_sqlstr || ' is null';
            WHEN lower(curRecord.c_operator) = 'like' then 
                -- escaping escape characters and double quotes.  The additon of '\' to '\\' is needed in Postgres. Alternatively, a custom escape character
                -- could be listed in the query if it is known for certain that that character will never be found in any c_dimcode value accessed by this 
                -- function
                v_sqlstr := v_sqlstr || curRecord.c_operator  || ' ' || '''' || replace(replace(curRecord.c_dimcode,'\','\\'),'''','''''') || '%''' ;
            WHEN lower(curRecord.c_operator) = 'in' then 
                v_sqlstr := v_sqlstr || curRecord.c_operator  || ' ' ||  '(' || curRecord.c_dimcode || ')';
            WHEN lower(curRecord.c_operator) = '=' then 
                v_sqlstr := v_sqlstr || curRecord.c_operator  || ' ' ||  replace(curRecord.c_dimcode,'''','''''') ;
            ELSE 
                -- A mistake in WUSM data existed, requiring special handling in this function.  
                -- The original note is listed next for reference purposes only and the IF THEN 
                -- ELSE block that was needed has been commented out since the original mistake 
                -- in the ontology tables has been corrected.

                /* ORIGINAL NOTE AND CODE
                 *   -- a mistake in WUSM data has this c_dimcode incorrectly listed.  It is being handled in this function until other testing and approvals
                 *   -- are conducted to allow for the correction of this value in the ontology table.
                 *   if curRecord.c_dimcode = 'current_date - interval ''85 year''85 year''' then 
                 *       v_sqlstr := v_sqlstr || curRecord.c_operator  || ' ' || 'current_date - interval ''85 year''';
                 *   else
                 */
                        v_sqlstr := v_sqlstr || curRecord.c_operator  || ' ' || curRecord.c_dimcode;
                /* 
                 *   end if;
                 */
            END CASE;
            
            v_sqlstr := v_sqlstr -- || ' ) ' -- in
                     || ' ) ' -- set
                     || ' where c_fullname = ' || '''' || curRecord.c_fullname || '''' 
                     || ' and numpats is null';

            execute v_sqlstr;
		else
            -- do nothing since we do not have the column in our schema
        end if;
    END LOOP;

	v_sqlstr := 'update ' || tabname || ' a set c_totalnum=b.numpats '
             || ' from ontPatVisitDims b '
             || ' where a.c_fullname=b.c_fullname ';

    --display count and timing information to the user
    select count(*) into v_num from ontPatVisitDims where numpats is not null and numpats <> 0;
    raise info 'At %, updating c_totalnum in % for % records',clock_timestamp(), tabname, v_num;
             
	execute v_sqlstr;
    discard temp;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;
  
  
---------------------------------------------------------------
-- pat_count_in_equal(tabname)
---------------------------------------------------------------  
CREATE OR REPLACE FUNCTION pat_count_in_equal(tabname character varying)
  RETURNS void AS
$BODY$
declare 
    -- see also the notes listed in pat_visit_counts().  The methodolgy of the code here is the same unless noted
    v_sqlstr text;
    curRecord RECORD;
    v_num integer;
BEGIN
    raise info 'At %, running PAT_COUNT_IN_EQUAL(''%'')',clock_timestamp(), tabname;

    DISCARD TEMP;
    -- IN / = operator queries on concept or provider dimension

	v_sqlstr := 'create temp table ontInOperator AS '
             || ' select c_fullname '
             || ', c_basecode '
             || ', c_facttablecolumn '
             || ', c_tablename '
             || ', c_columnname '
             || ', c_operator '
             || ', c_dimcode '
             || ', null::integer as numpats '
             || ' from ' || tabname
             || ' where  m_applied_path = ''@'' '
             || ' and lower(c_operator) in (''in'', ''='') '
             || ' and lower(c_tablename) in (''concept_dimension'', ''provider_dimension'') ';
            
    execute v_sqlstr;

    FOR curRecord IN 
        select c_fullname, c_facttablecolumn, c_tablename, c_columnname, c_operator, c_dimcode from ontInOperator
    LOOP 
        if exists(select 1 from information_schema.columns 
                  where table_catalog = current_catalog 
                    and table_schema = 'i2b2demodata'
                    and table_name = lower(curRecord.c_tablename)
                    and column_name = lower(curRecord.c_columnname)
                 ) then 

            -- unlike the pat_visit_counts(), see long note there, this function dynamic query queries
            -- against obersvation_fact rather than the one of the dimension tables.  The original version used 
            -- syntax of WHERE IN (SUBQUERY), which has been converted here to an inner join which Postgres processes
            -- much more quickly than IN ().
            v_sqlstr := 'UPDATE ontInOperator '
                     || ' SET numpats = ( '
                     ||         ' select count(distinct patient_num) '
                     ||         ' from public.observation_fact o'
                     ||         ' inner join i2b2demodata.' || curRecord.c_tablename || ' t'
                     ||         ' on o.' || curRecord.c_facttablecolumn || ' = t.' || curRecord.c_facttablecolumn
                     --||         ' where ' || curRecord.c_facttablecolumn || ' in ( '
                     --||             ' select ' || curRecord.c_facttablecolumn 
                     --||             ' from i2b2demodata.' || curRecord.c_tablename 
                     ||             ' where t.' || curRecord.c_columnname || ' ' || curRecord.c_operator || ' ';
                     
            CASE lower(curRecord.c_operator)
                WHEN 'like' then --this won't be used because of the query above only looking for "IN" and "="
                    v_sqlstr := v_sqlstr || '''' || replace(replace(curRecord.c_dimcode,'\','\\'),'''','''''') || '%''' ;
                WHEN 'in' THEN 
                    v_sqlstr := v_sqlstr || '(' || curRecord.c_dimcode || ')';
                WHEN '=' THEN 
                    v_sqlstr := v_sqlstr || replace(curRecord.c_dimcode,'''','''''') ; -- replace ' with '' in value from table
                ELSE
                v_sqlstr := v_sqlstr || curRecord.c_dimcode;
            END CASE;
            
            v_sqlstr := v_sqlstr --|| ') ' --in
                     ||        ' ) '
                     || ' where c_fullname = ''' || curRecord.c_fullname ||  ''' and numpats is null';

            if lower(curRecord.c_operator) <> 'in' then 
                raise info 'sql: %',v_sqlstr;
            end if;
            execute v_sqlstr;
        else
            -- do nothing since the column does not exist in our schema.
        end if;
    END LOOP;
	
	v_sqlstr := ' update ' || tabname || ' a set c_totalnum=b.numpats '
             || ' from ontInOperator b '
             || ' where a.c_fullname=b.c_fullname ';

    select count(*) into v_num from ontInOperator where numpats is not null and numpats <> 0;
    raise info 'At %, updating c_totalnum in % for % records',clock_timestamp(), tabname, v_num;
    
	execute v_sqlstr;
    discard temp;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;
  
-----------------------------------------------------------------------------------------
-- run_all_counts(tablename)
-- DEPENDS: on functsions -PAT_VISIT_COUNTS, PAT_COUNT_BY_CONCEPT,PAT_COUNT_BY_PROVIDER,
-- PAT_COUNT_IN_EQUAL, PAT_COUNT_MODIFIERS
-----------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION run_all_counts(tablename text)
  RETURNS void AS
$BODY$
declare 
    sqlstr text;
    v_numpats integer;
BEGIN      
    --display count and timing information to the user
    raise info 'At %, running run_all_counts(''%'')',clock_timestamp(), tablename;
	sqlstr := 'update ' || tablename || ' set c_totalnum=null';
	execute sqlstr;

    perform PAT_VISIT_COUNTS(tablename);
    perform PAT_COUNT_BY_CONCEPT(tablename);
    perform PAT_COUNT_BY_PROVIDER(tablename);
    perform PAT_COUNT_IN_EQUAL(tablename);
    perform PAT_COUNT_MODIFIERS(tablename);

	sqlstr := 'update ' || tablename || ' set c_totalnum=null where c_visualattributes = ''CA'' and c_totalnum = 0';
	execute sqlstr;

    --display count and timing information to the user
	execute 'select count(*) from '||tablename||' where c_totalnum is not null and c_totalnum <> 0' into v_numpats ;
    raise info 'At %, finished running run_all_counts(''%''); populated % recods.',clock_timestamp(), tablename, v_numpats;
END; 
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;