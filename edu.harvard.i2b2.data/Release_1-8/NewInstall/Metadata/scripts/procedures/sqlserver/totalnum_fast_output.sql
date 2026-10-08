-----------------------------------------------------------------------------------------------------------------
-- Write most recent totalnum counts from totalnum table into ontology tables specified in table_access, and generate totalnum_report (obfuscated counts)
-- By Mike Mendis and Jeff Klann, PhD with performance optimization by Darren Henderson (UKY)
-- Modified for the fast totalnum approach by Darren Henderson
--
--
-- Run with: exec FastTotalnumOutput or exec FastTotalnumOutput 'dbo','@','all'
--  Optionally you can specify the schemaname, a single table name to run on a single ontology table (or @ for all),
--  and demographics_mode ('act' for PF fast counts only, or 'all' for supplemental non-ACT PA counts).
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

CREATE PROCEDURE [dbo].[FastTotalnumOutput]  (
    @schemaname varchar(50) = 'dbo',
    @tablename varchar(50) = '@',
    @demographics_mode varchar(20) = 'act'
) as

DECLARE @sqlstr NVARCHAR(4000);
DECLARE @sqltext NVARCHAR(4000);
DECLARE @sqlcurs NVARCHAR(4000);
DECLARE @startime datetime;
DECLARE @derived_facttablecolumn NVARCHAR(4000);
DECLARE @facttablecolumn_prefix NVARCHAR(4000);
DECLARE @demographics_mode_norm varchar(20) = LOWER(ISNULL(NULLIF(@demographics_mode,''),'act'));
DECLARE @is_act_demo bit;
DECLARE @typeflag_predicate varchar(40);
DECLARE @report_typeflag_pattern varchar(10) = CASE WHEN @demographics_mode_norm = 'all' THEN 'P[FA]' ELSE 'PF' END;

--IF COL_LENGTH('table_access','c_obsfact') is NOT NULL 
--declare getsql cursor local for
--select 'exec RunTotalnumClassic '+c_table_name+','+c_obsfact from TABLE_ACCESS where c_visualattributes like '%A%'
--ELSE
-- select distinct 'exec RunTotalnumClassic '+c_table_name+','+@schemaname+','+@obsfact   from TABLE_ACCESS where c_visualattributes like '%A%'

IF @demographics_mode_norm NOT IN ('act','all')
BEGIN
    RAISERROR('Invalid demographics_mode. Use act or all.', 16, 1);
    RETURN;
END

declare getsql cursor local for
    select c_table_name,
           max(case when upper(c_table_cd) = 'ACT_DEMO' then 1 else 0 end) as is_act_demo
    from TABLE_ACCESS
    where c_visualattributes like '%A%'
    group by c_table_name

begin

-- Count all the totalnums, put results in totalnum table
--EXEC FastTotalnumCount;

-- Iterate through each table and put in top-level counts and other cleanup
OPEN getsql;
FETCH NEXT FROM getsql INTO @sqltext, @is_act_demo;
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
		
		-- Zero the counts in the ontology
		set @sqlstr='update '+@sqltext+'  set c_totalnum=0 where c_operator=''LIKE'' and c_visualattributes LIKE ''%A%''';
		PRINT @sqlstr;
		execute sp_executesql @sqlstr

			-- Update counts from the latest applicable TOTALNUM rows.
			-- ACT ontologies always use the optimized PF rows. In all mode, other ontologies may
			-- also use supplemental PA rows produced by the metadata-driven counters.
			set @typeflag_predicate = case
			    when @demographics_mode_norm = 'all' and @is_act_demo = 0 then 'like ''P[FA]'''
			    else '= ''PF'''
			end;
			set @sqlstr='UPDATE o  set c_totalnum=agg_count from '+ @sqltext+
				' o inner join (select row_number() over (partition by c_fullname order by agg_date desc, case when typeflag_cd = ''PA'' then 1 else 0 end desc) rn,c_fullname, agg_count,agg_date from totalnum where typeflag_cd '+@typeflag_predicate+') '+
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
		FETCH NEXT FROM getsql INTO @sqltext, @is_act_demo;
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
            select ''\denominator\facts\'',getdate(),count(distinct patient_num),''PX'' from OBSFACT_PAIRS'
        execute sp_executesql @sqlstr;
    END
        
    -- Build the report table when the optional report procedure is installed.
    IF OBJECT_ID(N'dbo.BuildTotalnumReport', N'P') IS NULL
        PRINT 'Skipping totalnum report build: dbo.BuildTotalnumReport is not installed.';
    ELSE
    BEGIN
        BEGIN TRY
            EXEC dbo.BuildTotalnumReport 10, 6.5, @report_typeflag_pattern;
        END TRY
        BEGIN CATCH
            PRINT 'Skipping totalnum report build: ' + ERROR_MESSAGE();
        END CATCH
    END
end;
GO
