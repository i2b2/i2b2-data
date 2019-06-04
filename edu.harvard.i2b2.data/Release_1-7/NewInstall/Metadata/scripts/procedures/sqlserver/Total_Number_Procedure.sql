-- Instructions:
-- This script will update the c_totalnum column in your ontology to reflect the total count of each term you've mapped in your fact table.
-- This is useful when developing queries (the totalnum appears in the query builder) and will also be used by the SCILHS team for quality checks.
-- To use: 
--- 1) If your fact table is in a different database or schema, search and replace 'observation_fact' with your database name, e.g.,
--   i2b2_facts.dbo.observation_fact. 
--  2) Run this script, which will create the stored procedures and execute them on pcornet_lab.
--  3) EXEC RUN_ALL_COUNTS <mymetadata_table>[, <myobsfact_table>] GO , replacing <mymetadata_table> with whichever table you want to update the totalnums,
--      and optionally including <myobsfact_table>

-- Developed by Griffin Weber, Harvard Medical School
-- Modified by Lori Phillips, Partners HealthCare
-- Minor edits to support modifiers by Jeff Klann, Harvard Medical School
-- Additional changes to PAT_COUNT_BY_CONCEPT for multiple fact tables
-- May 2018
-- Bugfix: pat_count_in_equal got messed up somehow, reverted
-- Bugfix in modifiers counts 12/11/15
-- Support multiple fact tables 11/3/16- BUT NOW USES *GLOBAL TEMP TABLES* SO BE CAREFUL!
-- Speedup to not run irrelevant count procedures - 12/19/16


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PAT_COUNT_MODIFIERS]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PAT_COUNT_MODIFIERS]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PAT_COUNT_BY_CONCEPT]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PAT_COUNT_BY_CONCEPT]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PAT_COUNT_BY_PROVIDER]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PAT_COUNT_BY_PROVIDER]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PAT_COUNT_IN_EQUAL]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PAT_COUNT_IN_EQUAL]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PAT_VISIT_COUNTS]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PAT_VISIT_COUNTS]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[RUN_ALL_COUNTS]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[RUN_ALL_COUNTS]
GO

-- Modified from PAT_COUNT_BY_CONCEPT by Jeff Klann, PhD
-- Note: This is somewhat "quick and dirty" - it assumes modifier_cd is unique and does not check that modifier modifies a valid concept code
CREATE PROCEDURE [dbo].[PAT_COUNT_MODIFIERS]  @metadataTable varchar(50), @obsfact varchar(50) = 'observation_fact'

AS BEGIN
declare @sqlstr nvarchar(4000)

    if exists (select 1 from sysobjects where name='conceptCountOnt') drop table conceptCountOnt
    if exists (select 1 from sysobjects where name='finalCountsByConcept') drop table finalCountsByConcept


-- Modify this query to select a list of all your ontology paths and basecodes.

set @sqlstr = 'select c_fullname, c_basecode
	into conceptCountOnt
	from ' + @metadataTable + 
	' where c_facttablecolumn = ''modifier_cd''
		and c_tablename = ''modifier_dimension''
		and c_columnname = ''modifier_path''
		and c_synonym_cd = ''N''
		and c_columndatatype = ''T''
		and c_operator = ''LIKE''
		and m_applied_path != ''@'' '
		
execute sp_executesql @sqlstr;

if exists(select top 1 NULL from conceptCountOnt)
BEGIN

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

alter table #ConceptPath add primary key (c_basecode, path_num)

-- Create a list of distinct concept-patient pairs
SET @sqlstr = 'select distinct modifier_cd, patient_num
	into ##ConceptPatient
	from '+@obsfact+' f with (nolock)'
EXEC sp_executesql @sqlstr

-- Bugfix 12/10/15 - modifier_cd is nullable so primary key creation fails
--   Fastest solution is just to skip the primary key - making the column non-nullable takes a very long time.
--alter table #ConceptPatient add primary key (modifier_cd, patient_num)

-- Create a list of distinct path-patient pairs

select distinct c.path_num, f.patient_num
	into #PathPatient
	from ##ConceptPatient f
		inner join #ConceptPath c
			on f.modifier_cd = c.c_basecode

alter table #PathPatient add primary key (path_num, patient_num)

-- Determine the number of patients per path

select path_num, count(*) num_patients
	into #PathCounts
	from #PathPatient
	group by path_num

alter table #PathCounts add primary key (path_num)

-- This is the final counts per ont path

select o.*, isnull(c.num_patients,0) num_patients into finalCountsByConcept
	from conceptCountOnt o
		left outer join #Path2Num p
			on o.c_fullname = p.c_fullname
		left outer join #PathCounts c
			on p.path_num = c.path_num
	order by o.c_fullname

	set @sqlstr='update a set c_totalnum=b.num_patients from '+@metadataTable+' a, finalCountsByConcept b '+
	'where a.c_fullname=b.c_fullname '
--	print @sqlstr
	execute sp_executesql @sqlstr

    DROP TABLE ##ConceptPatient

    END

END;
GO

-- Run PAT_COUNT_BY_CONCEPT on all multifact tables referenced in a given metadata table. Also works if only concept_cd is specified, but it will NOT work if using a single fact table but not using
-- concept_cd for your fact column!
-- Jeff Klann, PhD 05-2018
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'PAT_COUNT_BY_CONCEPT_ALLMULTIFACT') AND type in (N'P', N'PC'))
DROP PROCEDURE PAT_COUNT_BY_CONCEPT_ALLMULTIFACT
GO

create procedure dbo.PAT_COUNT_BY_CONCEPT_ALLMULTIFACT(@metadataTable varchar(50)) as 

DECLARE @sqlcurs NVARCHAR(4000);
Declare @sqldyn nvarchar(4000);

set @sqldyn='
DECLARE @sqltext NVARCHAR(4000);
declare getsql cursor static local for select distinct ''exec PAT_COUNT_BY_CONCEPT '+@metadatatable+',''+substring(replace(c_facttablecolumn,''concept_cd'',''''''''''''),1,charindex(''.'',c_facttablecolumn+''.'')-1) from '+@metadatatable+'


begin
OPEN getsql;
FETCH NEXT FROM getsql INTO @sqltext;
WHILE @@FETCH_STATUS = 0
BEGIN
	print @sqltext
	exec sp_executesql @sqltext
	FETCH NEXT FROM getsql INTO @sqltext;	
END

CLOSE getsql;
DEALLOCATE getsql;
end'
begin
exec sp_executesql @sqldyn
end
GO

-- Count by concept
-- Multifact support by Jeff Klann, PhD 05-18
CREATE PROCEDURE [dbo].[PAT_COUNT_BY_CONCEPT]  (@metadataTable varchar(50), @multifact varchar(50) ='')

AS BEGIN
declare @sqlstr nvarchar(4000)
declare @obsfact varchar(50)='observation_fact'
declare @definedfact varchar(50)=''
if @multifact!='' set @obsfact=@multifact
if @multifact!='' set @definedfact=@multifact+'.'

    if exists (select 1 from sysobjects where name='conceptCountOnt') drop table conceptCountOnt
    if exists (select 1 from sysobjects where name='finalCountsByConcept') drop table finalCountsByConcept


-- Modify this query to select a list of all your ontology paths and basecodes.

set @sqlstr = 'select c_fullname, c_basecode
	into conceptCountOnt
	from ' + @metadataTable + 
	' where c_facttablecolumn= '''+@definedfact+'concept_cd''
		and c_tablename = ''concept_dimension''
		and c_columnname = ''concept_path''
		and c_synonym_cd = ''N''
		and c_columndatatype = ''T''
		and c_operator = ''LIKE''
		and m_applied_path = ''@'' '
		
execute sp_executesql @sqlstr;

if exists(select top 1 NULL from conceptCountOnt)
BEGIN

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

alter table #ConceptPath add primary key (c_basecode, path_num)

-- Create a list of distinct concept-patient pairs

SET @sqlstr = 'select distinct concept_cd, patient_num
	into ##ConceptPatient
	from '+@obsfact+' f with (nolock)'
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

-- This is the final counts per ont path

select o.*, isnull(c.num_patients,0) num_patients into finalCountsByConcept
	from conceptCountOnt o
		left outer join #Path2Num p
			on o.c_fullname = p.c_fullname
		left outer join #PathCounts c
			on p.path_num = c.path_num
	order by o.c_fullname

	set @sqlstr='update a set c_totalnum=b.num_patients from '+@metadataTable+' a, finalCountsByConcept b '+
	'where a.c_fullname=b.c_fullname '
--	print @sqlstr
	execute sp_executesql @sqlstr

    DROP TABLE ##CONCEPTPATIENT


    END

END;
GO

-- Based on similar script created by Griffin Weber, Harvard Medical School
-- Modified by Lori Phillips, Partners HealthCare
-- Feb 2015
-- Skips if not relevant, Dec 2016, Jeff Klann, PhD


CREATE PROCEDURE [dbo].[PAT_COUNT_BY_PROVIDER]  (@metadataTable varchar(50), @obsfact varchar(50) = 'observation_fact')

AS BEGIN
declare @sqlstr nvarchar(4000)

    if exists (select 1 from sysobjects where name='provider_ont') drop table provider_ont

    if exists (select 1 from sysobjects where name='finalProviderCounts') drop table finalProviderCounts

-- Modify this query to select a list of all your ontology paths and basecodes.

set @sqlstr = 'select c_fullname, c_basecode
	into provider_ont
	from ' + @metadataTable + 
	' where c_facttablecolumn = ''provider_id''
		and c_tablename = ''provider_dimension''
		and c_columnname = ''provider_path''
		and c_synonym_cd = ''N''
		and c_columndatatype = ''T''
		and c_operator = ''LIKE''
		and m_applied_path = ''@'' '
		
execute sp_executesql @sqlstr;

if exists(select top 1 NULL from provider_ont)

BEGIN

-- Convert the ontology paths to integers to save space

select c_fullname, isnull(row_number() over (order by c_fullname),-1) path_num
	into #ProvPath2Num
	from (
		select distinct isnull(c_fullname,'') c_fullname
		from provider_ont
		where isnull(c_fullname,'')<>''
	) t

alter table #ProvPath2Num add primary key (c_fullname)

-- Create a list of all the c_basecode values under each ontology path

select distinct isnull(c_fullname,'') c_fullname, isnull(c_basecode,'') c_basecode
	into #PathProvider
	from provider_ont
	where isnull(c_fullname,'')<>'' and isnull(c_basecode,'')<>''

alter table #PathProvider add primary key (c_fullname, c_basecode)

select distinct c_basecode, path_num
	into #ProviderPath
	from #ProvPath2Num a
		inner join #PathProvider b
			on b.c_fullname like a.c_fullname+'%'

alter table #ProviderPath add primary key (c_basecode, path_num)

-- Create a list of distinct provider-patient pairs

SET @sqlstr = 'select distinct provider_id, patient_num
	into #ProviderPatient
	from '+@obsfact+' f with (nolock)'
EXEC sp_executesql  @sqlstr

alter table #ProviderPatient add primary key (provider_id, patient_num)

-- Create a list of distinct path-patient pairs

select distinct c.path_num, f.patient_num
	into #ProvPathPatient
	from #ProviderPatient f
		inner join #ProviderPath c
			on f.provider_id = c.c_basecode

alter table #ProvPathPatient add primary key (path_num, patient_num)

-- Determine the number of patients per path

select path_num, count(*) num_patients
	into #ProvPathCounts
	from #ProvPathPatient
	group by path_num

alter table #ProvPathCounts add primary key (path_num)

-- This is the final counts per ontology path

select o.*, isnull(c.num_patients,0) num_patients into finalProviderCounts
	from provider_ont o
		left outer join #ProvPath2Num p
			on o.c_fullname = p.c_fullname
		left outer join #ProvPathCounts c
			on p.path_num = c.path_num
	order by o.c_fullname


	set @sqlstr='update a set c_totalnum=b.num_patients from '+@metadataTable+' a, finalProviderCounts b '+
	'where a.c_fullname=b.c_fullname '
--	print @sqlstr
	execute sp_executesql @sqlstr


    DROP TABLE #PROVIDERPATIENT

END

END;
GO

-- Modified by Lori Phillips, Partners HealthCare
-- Feb 2015

CREATE PROCEDURE [dbo].[PAT_COUNT_IN_EQUAL] (@tabname varchar(50), @obsfact varchar(50) = 'observation_fact')
AS BEGIN

declare @sqlstr nvarchar(4000),
		@folder varchar(1200),
        @concept varchar(1200),
		@facttablecolumn varchar(50),
		 @tablename varchar(50),
		 @columnname varchar(50),
		 @columndatatype varchar(50), 
		 @operator varchar(10),
		 @dimcode varchar(1200)
		


    if exists (select 1 from sysobjects where name='ontInOperator') drop table ontInOperator

-- IN / = operator queries on concept or provider dimension

    set @sqlstr='select c_fullname, c_basecode, c_facttablecolumn, c_tablename, c_columnname, c_operator, c_dimcode into ontInOperator from ' + @tabname
        + ' where  m_applied_path = ''@'' and lower(c_operator) in (''in'', ''='') and lower(c_tablename) in (''concept_dimension'', ''provider_dimension'') '
    execute sp_executesql @sqlstr

	alter table ontInOperator add numpats int
	

  if exists(select top 1 NULL from ontInOperator)
  BEGIN
--------------  start of cursor e -------------------------------
	Declare e CURSOR
		Local Fast_Forward
		For
			select c_fullname, c_facttablecolumn, c_tablename, c_columnname, c_operator, c_dimcode from ontInOperator
	Open e
		fetch next from e into @concept, @facttablecolumn, @tablename, @columnname, @operator, @dimcode
	WHILE @@FETCH_STATUS = 0
	Begin
		begin
			if lower(@operator) = 'in'
			begin
				set @dimcode = '(' + @dimcode + ')'
			end
			if lower(@operator) = '='
			begin
				set @dimcode = '''' +  replace(@dimcode,'''','''''') + ''''
			end
			set @sqlstr='update ontInOperator set 
             numpats =  (select count(distinct(patient_num)) from '+@obsfact+'   
                where ' + @facttablecolumn + ' in (select ' + @facttablecolumn + ' from ' + @tablename + ' where '+ @columnname + ' ' + @operator +' ' + @dimcode +' ))
            where c_fullname = ' + ''''+ @concept + ''''+ ' and numpats is null'

		--	print @sqlstr
			execute sp_executesql @sqlstr
		end

		fetch next from e into @concept, @facttablecolumn, @tablename, @columnname, @operator, @dimcode

	End
	close e
	deallocate e

--------------  end of cursor e -------------------------------

	set @sqlstr='update a set c_totalnum=b.numpats from '+@tabname+' a, ontInOperator b '+
	'where a.c_fullname=b.c_fullname '
--	print @sqlstr
	execute sp_executesql @sqlstr

  END

END;
GO

-- Modified by Lori Phillips, Partners HealthCare
-- Feb 2015


CREATE PROCEDURE [dbo].[PAT_VISIT_COUNTS] (@tabname varchar(50), @obsfact varchar(50) = 'observation_fact')
AS BEGIN

declare @sqlstr nvarchar(4000),
		@folder varchar(1200),
        @concept varchar(1200),
		@facttablecolumn varchar(50),
		 @tablename varchar(50),
		 @columnname varchar(50),
		 @columndatatype varchar(50), 
		 @operator varchar(10),
		 @dimcode varchar(1200)


    if exists (select 1 from sysobjects where name='ontPatVisitDims') drop table ontPatVisitDims

-- pat_dim , visit_dim queries

	set @sqlstr='select c_fullname, c_basecode, c_facttablecolumn, c_tablename, c_columnname, c_operator, c_dimcode into ontPatVisitDims from ' + @tabname
        + ' where  m_applied_path = ''@'' and c_tablename in (''patient_dimension'', ''visit_dimension'') '
    execute sp_executesql @sqlstr

	alter table ontPatVisitDims add numpats int

    if exists(select top 1 NULL from ontPatVisitDims)
    BEGIN

--------------  start of cursor e -------------------------------
	Declare e CURSOR
		Local Fast_Forward
		For
			select c_fullname, c_facttablecolumn, c_tablename, c_columnname, c_operator, c_dimcode from ontPatVisitDims
	Open e
		fetch next from e into @concept, @facttablecolumn, @tablename, @columnname, @operator, @dimcode
	WHILE @@FETCH_STATUS = 0
	Begin
		begin
			if lower(@operator) = 'like'
			begin
				set @dimcode =  '''' + replace(@dimcode,'''','''''') + '%''' 
			end
			if lower(@operator) = 'in'
			begin
				set @dimcode = '(' + @dimcode + ')'
			end
			if lower(@operator) = '='
			begin
				set @dimcode = '''' +  replace(@dimcode,'''','''''') + ''''
			end
			set @sqlstr='update ontPatVisitDims set 
             numpats =  (select count(distinct(patient_num)) from ' + @tablename + 
               ' where ' + @facttablecolumn + ' in (select ' + @facttablecolumn + ' from ' + @tablename + ' where '+ @columnname + ' ' + @operator +' ' + @dimcode +' ))
            where c_fullname = ' + ''''+ @concept + ''''+ ' and numpats is null'

		--	print @sqlstr
			execute sp_executesql @sqlstr
		end

		fetch next from e into @concept, @facttablecolumn, @tablename, @columnname, @operator, @dimcode

	End
	close e
	deallocate e

--------------  end of cursor e -------------------------------
 

	set @sqlstr='update a set c_totalnum=b.numpats from '+@tabname+' a, ontPatVisitDims b '+
	'where a.c_fullname=b.c_fullname '
--	print @sqlstr
	execute sp_executesql @sqlstr


END

END;
GO

-- Created by Lori Phillips, Partners HealthCare
-- Modified by Jeff Klann, PhD
-- August 2015
-- Bugfix jklann 6/18 - I had changed this to pass fact table names for multifact counting. This is not the way to invoke multifact counting. Run the new multifact proc instead.

CREATE PROCEDURE [dbo].[RUN_ALL_COUNTS] (@tablename varchar(50))
AS BEGIN

    declare @sqlstr nvarchar(4000)
          
	set @sqlstr='update ' + @tablename + ' set c_totalnum=null'
--	print @sqlstr
	execute sp_executesql @sqlstr


exec dbo.PAT_VISIT_COUNTS @tablename
exec dbo.PAT_COUNT_BY_CONCEPT @tablename
exec dbo.PAT_COUNT_BY_PROVIDER @tablename
exec dbo.PAT_COUNT_IN_EQUAL @tablename
exec dbo.PAT_COUNT_MODIFIERS @tablename

	set @sqlstr='update ' + @tablename + ' set c_totalnum=null where c_visualattributes = ''CA'' and c_totalnum = 0'
--	print @sqlstr
	execute sp_executesql @sqlstr



END;
GO

