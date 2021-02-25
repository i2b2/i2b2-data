-----------------------------------------------------------------------------------------------------------------
-- Function to run totalnum counts on all tables in table_access 
-- By Mike Mendis and Jeff Klann, PhD
-- Run with: exec RunTotalnum or exec RunTotalnum 'observation_fact','dbo','@' 
--  Optionally you can specify the observation table name (for multi-fact-table setups), the schemaname, 
--    a single table name to run on a single ontology table, and a wildcard flag that will ignore multifact references in the ontology if 'Y'.
-- The results are in: c_totalnum column of all ontology tables, the totalnum table (keeps a historical record), and the totalnum_report table (most recent run, obfuscated) 
--
-- Note that visit and patient dimension will only be counted in conjunction with the default (observation_fact) tablename!
--
--
-- To use with multi-fact-table setups: 
--   Option 1) If you have at most one fact table per ontology, run this once with each fact table specified! 
--        e.g., to use on a fact table called derived_fact with just the act_covid ontology: exec RunTotalnum 'derived_fact','dbo','act_covid' 
--   Option 2) Create a fact table view as the union of all your fact tables. (This is essentially going back to a single fact table,  but it is only used
--     for totalnum counting. This is needed to correctly count patients that mention multiple fact tables within a hierarchy.)
--    e.g., 
--       create view observation_fact_view as
--       select * from CONDITION_VIEW 
--       union all
--       select * from drug_view
--    And then run the totalnum counter with the wildcard flag, to ignore multifact references in the ontology
--      e.g., exec RunTotalnum 'observation_fact_view','dbo','@','Y'
--    Note this approach does not work if you have conflicting concept_cds across fact tables.
-----------------------------------------------------------------------------------------------------------------

IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'RunTotalnum')
                    AND type IN ( N'P', N'PC' ) ) 
DROP PROCEDURE RunTotalnum;
GO

CREATE PROCEDURE [dbo].[RunTotalnum]  (@observationTable varchar(50) = 'observation_fact', @schemaname varchar(50) = 'dbo', @tablename varchar(50)='@', @wildcard_factcolumn varchar(1)='N') as  

DECLARE @sqlstr NVARCHAR(4000);
DECLARE @sqltext NVARCHAR(4000);
DECLARE @sqlcurs NVARCHAR(4000);
DECLARE @startime datetime;
DECLARE @derived_facttablecolumn NVARCHAR(4000);
DECLARE @facttablecolumn_prefix NVARCHAR(4000);

--IF COL_LENGTH('table_access','c_obsfact') is NOT NULL 
--declare getsql cursor local for
--select 'exec run_all_counts '+c_table_name+','+c_obsfact from TABLE_ACCESS where c_visualattributes like '%A%' 
--ELSE 
declare getsql cursor local for select distinct c_table_name from TABLE_ACCESS where c_visualattributes like '%A%'


-- select distinct 'exec run_all_counts '+c_table_name+','+@schemaname+','+@obsfact   from TABLE_ACCESS where c_visualattributes like '%A%'


begin

OPEN getsql;
FETCH NEXT FROM getsql INTO @sqltext;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @derived_facttablecolumn = case when @observationTable='observation_fact' then '' else @observationTable+'.' end
    SET @facttablecolumn_prefix = case when @wildcard_factcolumn='Y' then '%.' else
        case when @observationTable='observation_fact' then '' else @observationTable+'.' end end
    IF @tablename='@' OR @tablename=@sqltext
    BEGIN
        print @sqltext
        SET @sqlstr = 'update '+ @sqltext +' set c_totalnum=null';
        EXEC sp_executesql @sqlstr;
        IF @derived_facttablecolumn='' 
            BEGIN
            set @startime = getdate();
            exec PAT_COUNT_VISITS @sqltext , @schemaName;
            EXEC EndTime @startime,@sqltext,'PAT_COUNT_VISITS';
        END
        set @startime = getdate();    
        SET @derived_facttablecolumn = @facttablecolumn_prefix+'concept_cd' 
        exec PAT_COUNT_DIMENSIONS @sqltext , @schemaName, @observationTable ,  @derived_facttablecolumn, 'concept_dimension', 'concept_path';
        EXEC EndTime @startime,@sqltext,'PAT_COUNT_concept_dimension';
        set @startime = getdate(); 
        SET @derived_facttablecolumn = @facttablecolumn_prefix+'provider_id' 
        exec PAT_COUNT_DIMENSIONS  @sqltext , @schemaName,  @observationTable ,  @derived_facttablecolumn, 'provider_dimension', 'provider_path';
        EXEC EndTime @startime,@sqltext,'PAT_COUNT_provider_dimension';
        set @startime = getdate(); 
        SET @derived_facttablecolumn = @facttablecolumn_prefix+'modifier_cd' 
        exec PAT_COUNT_DIMENSIONS  @sqltext , @schemaName, @observationTable ,  @derived_facttablecolumn, 'modifier_dimension', 'modifier_path';
        EXEC EndTime @startime,@sqltext,'PAT_COUNT_modifier_dimension';
        set @startime = getdate(); 
        -- New 11/20 - update counts in top levels (table_access) at the end
        SET @sqlstr = 'update t set c_totalnum=x.c_totalnum from table_access t inner join '+@sqltext+' x on x.c_fullname=t.c_fullname'
        execute sp_executesql @sqlstr
        -- Null out cases that are actually 0 [1/21]
        SET @sqlstr = 'update t set c_totalnum=null from '+@sqltext+' t where c_totalnum=0 and c_visualattributes like ''C%'''
        execute sp_executesql @sqlstr
    END
                  
--	exec sp_executesql @sqltext
	FETCH NEXT FROM getsql INTO @sqltext;	
END

CLOSE getsql;
DEALLOCATE getsql;

    -- Cleanup (1/21)
    update table_access set c_totalnum=null where c_totalnum=0
    -- Denominator (1/21)
    IF (SELECT count(*) from totalnum where c_fullname='\denominator\facts\' and cast(agg_date as date)=cast(getdate() as date)) = 0
    BEGIN
        set @sqlstr = '
        insert into totalnum(c_fullname,agg_date,agg_count,typeflag_cd)
            select ''\denominator\facts\'',getdate(),count(distinct patient_num),''PX'' from ' + @schemaName + '.' + @observationTable
        execute sp_executesql @sqlstr;
    END
        
    exec BuildTotalnumReport 10, 6.5
end;
GO

