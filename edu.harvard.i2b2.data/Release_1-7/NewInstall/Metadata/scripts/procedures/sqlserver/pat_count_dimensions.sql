-- Originally Developed by Griffin Weber, Harvard Medical School
-- Contributors: Mike Mendis, Jeff Klann, Lori Phillips, Jeff Green

-- Count by concept
-- Multifact support by Jeff Klann, PhD 05-18
-- Performance improvements by Jeff Green and Jeff Klann, PhD 03-20

CREATE PROCEDURE [dbo].[PAT_COUNT_DIMENSIONS]  (@metadataTable varchar(50), @schemaName varchar(50),
@observationTable varchar(50), 
 @facttablecolumn varchar(50), @tablename varchar(50), @columnname varchar(50)

 )

AS BEGIN
declare @sqlstr nvarchar(4000)
declare @startime datetime


    if exists (select 1 from sysobjects where name='conceptCountOnt') drop table conceptCountOnt
    if exists (select 1 from sysobjects where name='finalCountsByConcept') drop table finalCountsByConcept


-- Modify this query to select a list of all your ontology paths and basecodes.

set @sqlstr = 'select c_fullname, c_basecode, c_hlevel
	into conceptCountOnt
	from ' + @metadataTable + 
' where lower(c_facttablecolumn)= ''' + @facttablecolumn + '''
		and lower(c_tablename) = ''' + @tablename + '''
		and lower(c_columnname) = ''' + @columnname + '''
		and lower(c_synonym_cd) = ''n''
		and lower(c_columndatatype) = ''t''
		and lower(c_operator) = ''like''
		and m_applied_path = ''@''
        and c_fullname is not null
        and (c_visualattributes not like ''L%'' or  c_basecode in (select distinct concept_cd from observation_fact))'
        -- ^ NEW: Sparsify the working ontology by eliminating leaves with no data. HUGE win in ACT meds ontology.
        -- From 1.47M entries to 100k entries!
		
execute sp_executesql @sqlstr;

print @sqlstr

if exists(select top 1 NULL from conceptCountOnt)
BEGIN
    set @startime = getdate(); 
    
-- Convert the ontology paths to integers to save space

select c_fullname, isnull(row_number() over (order by c_fullname),-1) path_num
	into #Path2Num
	from (
		select distinct isnull(c_fullname,'') c_fullname
		from conceptCountOnt
		where isnull(c_fullname,'')<>''
	) t

alter table #Path2Num add primary key (c_fullname)

-- Create a list of all the c_basecode values under each ontology path

-- Based on Jeff Green's optimized code
;with concepts (c_fullname, c_hlevel, c_basecode) as
	(
	select c_fullname, c_hlevel, c_basecode
	from conceptCountOnt
	where isnull(c_fullname,'') <> '' and isnull(c_basecode,'') <> ''
	union all
	select 
			left(c_fullname, len(c_fullname)-charindex('\', right(reverse(c_fullname), len(c_fullname)-1)))
		   	 c_fullname,
	c_hlevel-1 c_hlevel, c_basecode
	from concepts
	where concepts.c_hlevel>0
	)
select distinct path_num, isnull(c_basecode,'') c_basecode into #ConceptPath
from concepts
inner join #path2num
 on concepts.c_fullname=#path2num.c_fullname

/*
THIS VERSION IS DEPRECATED BECAUSE IT IS VERY SLOW ON DEEP ONTOLOGIES
select distinct isnull(c_fullname,'') c_fullname, isnull(c_basecode,'') c_basecode
	into #PathConcept
	from conceptCountOnt
	where isnull(c_fullname,'')<>'' and isnull(c_basecode,'')<>''

alter table #PathConcept add primary key (c_fullname, c_basecode)

select distinct c_basecode, path_num
	into #ConceptPath
	from #Path2Num a
		inner join #PathConcept b
			on b.c_fullname like a.c_fullname+'%'
*/
alter table #ConceptPath add primary key (c_basecode, path_num)


    EXEC EndTime @startime,'dimension','ontology';
    set @startime = getdate(); 

-- Create a list of distinct concept-patient pairs

SET @sqlstr = 'select distinct concept_cd, patient_num
	into ##ConceptPatient
	from '+@schemaName + '.' + @observationTable+' f with (nolock)'
EXEC sp_executesql @sqlstr

ALTER TABLE ##ConceptPatient  ALTER COLUMN [PATIENT_NUM] int NOT NULL
ALTER TABLE ##ConceptPatient  ALTER COLUMN [concept_cd] varchar(50) NOT NULL

alter table ##ConceptPatient add primary key (concept_cd, patient_num)

-- Create a list of distinct path-patient pairs

select distinct c.path_num, f.patient_num
	into #PathPatient
	from ##ConceptPatient f
		inner join #ConceptPath c
			on f.concept_cd = c.c_basecode


ALTER TABLE #PathPatient  ALTER COLUMN [PATIENT_NUM] int NOT NULL
alter table #PathPatient add primary key (path_num, patient_num)


-- Determine the number of patients per path

select path_num, count(*) num_patients
	into #PathCounts
	from #PathPatient
	group by path_num

alter table #PathCounts add primary key (path_num)

    EXEC EndTime @startime,'dimension','patients';
    set @startime = getdate(); 

-- This is the final counts per ont path

select o.*, isnull(c.num_patients,0) num_patients into finalCountsByConcept
	from conceptCountOnt o
		left outer join #Path2Num p
			on o.c_fullname = p.c_fullname
		left outer join #PathCounts c
			on p.path_num = c.path_num
	order by o.c_fullname

	set @sqlstr='update a set c_totalnum=b.num_patients from '+@metadataTable+' a, finalCountsByConcept b '+
	'where a.c_fullname=b.c_fullname ' +
 ' and lower(a.c_facttablecolumn)= ''' + @facttablecolumn + ''' ' +
	' and lower(a.c_tablename) = ''' + @tablename + ''' ' +
	' and lower(a.c_columnname) = ''' + @columnname + ''' '

--	print @sqlstr
	execute sp_executesql @sqlstr
	
	-- New 4/2020 - Update the totalnum reporting table as well
	insert into totalnum(c_fullname, agg_date, agg_count, typeflag_cd)
	select c_fullname, CONVERT (date, GETDATE()), num_patients, 'PF' from finalCountsByConcept where num_patients>0

    DROP TABLE ##CONCEPTPATIENT
    
    EXEC EndTime @startime,'dimension','cleanup';
    set @startime = getdate(); 

    END

END;