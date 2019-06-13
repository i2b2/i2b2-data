create or replace PROCEDURE pat_count_dimensions  (metadataTable IN VARCHAR, observationTable IN VARCHAR, 
 facttablecolumn in VARCHAR, tablename in VARCHAR, columnname in VARCHAR, 
   errorMsg OUT VARCHAR)
IS
BEGIN

execute immediate 'create table dimCountOnt as select c_fullname, c_basecode
	from '  || metadataTable  || ' where lower(c_facttablecolumn)= ''' || facttablecolumn || '''
		and lower(c_tablename) = ''' || tablename || '''
		and lower(c_columnname) = ''' || columnname || '''
		and lower(c_synonym_cd) = ''n''
		and lower(c_columndatatype) = ''t''
		and lower(c_operator) = ''like''
		and m_applied_path = ''@''
        and c_fullname is not null';

execute immediate 'create index dim_fullname on dimCountOnt (c_fullname)';


execute immediate 'create table dimOntWithFolders  as 
	select distinct c1.c_fullname, c2.c_basecode
        from dimCountOnt c1 
        inner join dimCountOnt c2
        on c2.c_fullname like c1.c_fullname || ''%'''; -- expecting that no '&' exist in the data

execute immediate 'create index  dimFldBasecode on dimOntWithFolders (c_basecode)';
        
execute immediate 'create  table finalDimCounts AS
        select c1.c_fullname, count(distinct patient_num) as num_patients
        from dimOntWithFolders c1 
        left join ' || observationTable || ' o 
             on c1.c_basecode = o.' || facttablecolumn || '
             and c_basecode is not null 
        group by c1.c_fullname';               

execute immediate 'create index finalDimCounts_fullname on finalDimCounts  (c_fullname)';

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
END;
