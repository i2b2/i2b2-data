-----------------------------------------------------------------------------------------------------------------
-- Function to run totalnum counts on all tables in table_access 
-- By Mike Mendis and Jeff Klann, PhD
-- Run with: exec RunTotalnum or exec RunTotalnum 'observation_fact','dbo','@' 
-- To use with multi-fact-table setups, run once with each fact table specified! 
--  e.g., to use on a fact table called derived_fact with just the act_covid ontology: exec RunTotalnum 'derived_fact','dbo','act_covid' 
-- Note that visit and patient dimension will only be counted in conjunction with the default (observation_fact) tablename!
--  Optionally you can specify the observation table name (for multi-fact-table setups), the schemaname, or
--    a single table name to run on a single ontology table.
-- The results are in: c_totalnum column of all ontology tables, the totalnum table (keeps a historical record), and the totalnum_report table (most recent run, obfuscated) 
-----------------------------------------------------------------------------------------------------------------

IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'RunTotalnum')
                    AND type IN ( N'P', N'PC' ) ) 
DROP PROCEDURE RunTotalnum;
GO

CREATE PROCEDURE [dbo].[RunTotalnum]  (@observationTable varchar(50) = 'observation_fact', @schemaname varchar(50) = 'dbo', @tablename varchar(50)='@') as  

DECLARE @sqlstr NVARCHAR(4000);
DECLARE @sqltext NVARCHAR(4000);
DECLARE @sqlcurs NVARCHAR(4000);
DECLARE @startime datetime;
DECLARE @derived_facttablecolumn NVARCHAR(4000);

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
        SET @derived_facttablecolumn = case when @observationTable='observation_fact' then 'concept_cd' else @observationTable+'.concept_cd' end
        exec PAT_COUNT_DIMENSIONS @sqltext , @schemaName, @observationTable ,  @derived_facttablecolumn, 'concept_dimension', 'concept_path';
        EXEC EndTime @startime,@sqltext,'PAT_COUNT_concept_dimension';
        set @startime = getdate(); 
        SET @derived_facttablecolumn = case when @observationTable='observation_fact' then 'provider_id' else @observationTable+'.provider_id' end
        exec PAT_COUNT_DIMENSIONS  @sqltext , @schemaName,  @observationTable ,  @derived_facttablecolumn, 'provider_dimension', 'provider_path';
        EXEC EndTime @startime,@sqltext,'PAT_COUNT_provider_dimension';
        set @startime = getdate(); 
        SET @derived_facttablecolumn = case when @observationTable='observation_fact' then 'modifier_cd' else @observationTable+'.modifier_cd' end
        exec PAT_COUNT_DIMENSIONS  @sqltext , @schemaName, @observationTable ,  @derived_facttablecolumn, 'modifier_dimension', 'modifier_path';
        EXEC EndTime @startime,@sqltext,'PAT_COUNT_modifier_dimension';
        set @startime = getdate(); 
        -- New 11/20 - update counts in top levels (table_access) at the end
        SET @sqlstr = 'update t set c_totalnum=x.c_totalnum from table_access t inner join '+@sqltext+' x on x.c_fullname=t.c_fullname'
        execute sp_executesql @sqlstr
    END
    
--	exec sp_executesql @sqltext
	FETCH NEXT FROM getsql INTO @sqltext;	
END

CLOSE getsql;
DEALLOCATE getsql;

    exec BuildTotalnumReport 10, 6.5
end;
GO
