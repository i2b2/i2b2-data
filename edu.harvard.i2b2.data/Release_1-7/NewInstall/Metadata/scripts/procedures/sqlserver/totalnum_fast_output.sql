-----------------------------------------------------------------------------------------------------------------
-- Write most recent totalnum counts from totalnum table into ontology tables specified in table_access, and generate totalnum_report (obfuscated counts)
-- By Mike Mendis and Jeff Klann, PhD with performance optimization by Darren Henderson (UKY)
-- Modified for the fast totalnum approach by Darren Henderson
--
--
-- Run with: exec FastTotalnumOutput or exec FastTotalnumOutput 'dbo','@' 
--  Optionally you can specify the schemaname and a single table name to run on a single ontology table (or @ for all).
-- The results are in: c_totalnum column of all ontology tables, the totalnum table (keeps a historical record), and the totalnum_report table (most recent run, obfuscated) 
--
-- Prior to this, load the stored procedures, make sure you have run FastTotalnumPrep once, and run FastTotalnum to compute the counts.
-----------------------------------------------------------------------------------------------------------------




IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'FastTotalnumOutput')
                    AND type IN ( N'P', N'PC' ) ) 
DROP PROCEDURE FastTotalnumOutput;
GO

CREATE PROCEDURE [dbo].[FastTotalnumOutput]  (@schemaname varchar(50) = 'dbo', @tablename varchar(50)='@') as  

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
-- select distinct 'exec run_all_counts '+c_table_name+','+@schemaname+','+@obsfact   from TABLE_ACCESS where c_visualattributes like '%A%'

declare getsql cursor local for select distinct c_table_name from TABLE_ACCESS where c_visualattributes like '%A%' 

begin

-- Count all the totalnums, put results in totalnum table
--EXEC FastTotalnumCount;

-- Iterate through each table and put in top-level counts and other cleanup
OPEN getsql;
FETCH NEXT FROM getsql INTO @sqltext;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @derived_facttablecolumn ='';
    SET @facttablecolumn_prefix = '';
    IF @tablename='@' OR @tablename=@sqltext
    BEGIN
        EXEC EndTime @startime,@sqltext,'ready to go';
        set @startime = getdate(); 
        
        -- Null the counts in the ontology
		set @sqlstr='update '+@sqltext+'  set c_totalnum=null';
		PRINT @sqlstr;
		execute sp_executesql @sqlstr

		-- This updates counts in the ontology but will only work on the same day the counts are performed
		set @sqlstr='UPDATE o  set c_totalnum=agg_count from '+ @sqltext+
 			' o inner join (select row_number() over (partition by c_fullname order by agg_date desc) rn,c_fullname, agg_count,agg_date from totalnum where typeflag_cd like ''P%'') '+
 			' t on t.c_fullname=o.c_fullname  where t.c_fullname=o.c_fullname and rn=1';
 		execute sp_executesql @sqlstr
    
         -- New 11/20 - update counts in top level (table_access)
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
            select ''\denominator\facts\'',getdate(),count(distinct patient_num),''PX'' from ' + @schemaName + '.' + 'observation_fact'
        execute sp_executesql @sqlstr;
    END
        
    -- Build the report table
    exec BuildTotalnumReport 10, 6.5
end;
GO