-----------------------------------------------------------------------------------------------------------------
-- Function to run totalnum counts on all tables in table_access 
-- By Mike Mendis and Jeff Klann, PhD
-----------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[RunTotalnum]  (@observationTable varchar(50) = 'observation_fact', @schemaname varchar(50) = 'dbo') as  

DECLARE @sqlstr NVARCHAR(4000);
DECLARE @sqltext NVARCHAR(4000);
DECLARE @sqlcurs NVARCHAR(4000);

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
	print @sqltext
    SET @sqlstr = 'update '+ @sqltext +' set c_totalnum=null';
    EXEC sp_executesql @sqlstr;
    exec PAT_COUNT_VISITS @sqltext , @schemaName   
    exec PAT_COUNT_DIMENSIONS @sqltext , @schemaName, @observationTable ,  'concept_cd', 'concept_dimension', 'concept_path'  
    exec PAT_COUNT_DIMENSIONS  @sqltext , @schemaName,  @observationTable ,  'provider_id', 'provider_dimension', 'provider_path'  
    exec PAT_COUNT_DIMENSIONS  @sqltext , @schemaName, @observationTable ,  'modifier_cd', 'modifier_dimension', 'modifier_path'  

--	exec sp_executesql @sqltext
	FETCH NEXT FROM getsql INTO @sqltext;	
END

CLOSE getsql;
DEALLOCATE getsql;
end