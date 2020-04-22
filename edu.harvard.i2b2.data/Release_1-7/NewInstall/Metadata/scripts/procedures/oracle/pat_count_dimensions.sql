create or replace PROCEDURE              pat_count_dimensions  (metadataTable IN VARCHAR, schemaName IN VARCHAR, observationTable IN VARCHAR, 
 facttablecolumn in VARCHAR, tablename in VARCHAR, columnname in VARCHAR, 
   errorMsg OUT VARCHAR)
IS
    v_startime timestamp;
    v_duration varchar2(30);
BEGIN
-- EXECUTE IMMEDIATE 'drop table dimCountOnt';
-- EXECUTE IMMEDIATE 'drop table dimOntWithFolders';
-- EXECUTE IMMEDIATE 'drop table finalDimCounts';
--EXCEPTION
--  WHEN OTHERS THEN
--  NULL;

-- Modify this query to select a list of all your ontology paths and basecodes.

v_startime := CURRENT_TIMESTAMP;
 
execute immediate 'create table dimCountOnt as select c_fullname, c_basecode
	from '  || metadataTable  || ' where lower(c_facttablecolumn)= ''' || facttablecolumn || '''
		and lower(c_tablename) = ''' || tablename || '''
		and lower(c_columnname) = ''' || columnname || '''
		and lower(c_synonym_cd) = ''n''
		and lower(c_columndatatype) = ''t''
		and lower(c_operator) = ''like''
		and m_applied_path = ''@''
        and c_fullname is not null';

    --creating indexes rather than primary keys on temporary tables to speed up joining between them
execute immediate 'create index dim_fullname on dimCountOnt (c_fullname)';

    -- since 'folders' may exist such that a given concept code could be a child of another, query the result
    -- set against itself to generate a list of child codes that reflect themselves as members of the parent 
    -- group. This allows for patient counts to be reflected for each patient in both the child an parent record
    -- so that, for example, one patient who had his/her blood pressure taken on the upper arm to be reflected 
    -- in both the "blood pressure taken on the upper arm" as well as the more generic 
    -- "blood pressure taken." (i.e. location agnostic).  Performing this self join here, between just the 
    -- temporary table and itself, which is much smaller than observation_fact, is faster when done separately
    -- rather than being included in the join against the observation_fact table below.

execute immediate 'create table dimOntWithFolders  as 
	select distinct c1.c_fullname, c2.c_basecode
        from dimCountOnt c1 
        inner join dimCountOnt c2
        on c2.c_fullname like c1.c_fullname || ''%'''; -- expecting that no '&' exist in the data

execute immediate 'create index  dimFldBasecode on dimOntWithFolders (c_basecode)';
        
 v_duration := ((extract(minute from current_timestamp)-extract(minute from v_startime))*60+extract(second from current_timestamp)-extract(second from v_startime))*1000;
 DBMS_OUTPUT.PUT_LINE('(BENCH) '||metadataTable||',collected ontology,'||v_duration); 
 v_startime := CURRENT_TIMESTAMP;
 
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
execute immediate 'create  table finalDimCounts AS
        select c1.c_fullname, count(distinct patient_num) as num_patients
        from dimOntWithFolders c1 
        left join ' || schemaName || '.' || observationTable || ' o 
             on c1.c_basecode = o.' || facttablecolumn || '
             and c_basecode is not null 
        group by c1.c_fullname';               
        -- we dont want to match on empties themselves, but we did need to pull 
        -- the parent codes, which sometimes have empty values, to get child counts.

    --creating indexes rather than primary keys on temporary tables to speed up joining between them
execute immediate 'create index finalDimCounts_fullname on finalDimCounts  (c_fullname)';

 v_duration := ((extract(minute from current_timestamp)-extract(minute from v_startime))*60+extract(second from current_timestamp)-extract(second from v_startime))*1000;
 DBMS_OUTPUT.PUT_LINE('(BENCH) '||metadataTable||',counted facts,'||v_duration); 
 v_startime := CURRENT_TIMESTAMP;

execute immediate 'update ' || metadataTable || '  a  set c_totalnum=
        (select 
        b.num_patients 
            from finalDimCounts b  
            where a.c_fullname=b.c_fullname )
      where 
       lower(a.c_facttablecolumn)= ''' || facttablecolumn || '''
		and lower(a.c_tablename) = ''' || tablename || '''
		and lower(a.c_columnname) = ''' || columnname || '''
            ';

 EXECUTE IMMEDIATE 'drop table dimCountOnt';
 EXECUTE IMMEDIATE 'drop table finalDimCounts';
 EXECUTE IMMEDIATE 'drop table dimOntWithFolders';
 
  v_duration := ((extract(minute from current_timestamp)-extract(minute from v_startime))*60+extract(second from current_timestamp)-extract(second from v_startime))*1000;
 DBMS_OUTPUT.PUT_LINE('(BENCH) '||metadataTable||',cleanup,'||v_duration); 
 v_startime := CURRENT_TIMESTAMP;
 
END;
