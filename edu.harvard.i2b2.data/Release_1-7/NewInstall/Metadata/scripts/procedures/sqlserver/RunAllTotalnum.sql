-----------------------------------------------------------------------------------------------------------------
-- Procedure to run totalnum counts on all tables in table_access that have a key like PCORI_
-- Depends on the TOTALNUM script at http://github.com/SCILHS-utils/totalnum , which must be run first
-- 11/3/16 - now supports optional table access column, c_obsfact, which defines a custom obsfact table for totalnum counting
-----------------------------------------------------------------------------------------------------------------

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'RunTotalnum') AND type in (N'P', N'PC'))
DROP PROCEDURE RunTotalnum
;

create procedure dbo.RunTotalnum as 

DECLARE @sqltext NVARCHAR(4000);
DECLARE @sqlcurs NVARCHAR(4000);

--IF COL_LENGTH('table_access','c_obsfact') is NOT NULL 
--declare getsql cursor local for
--select 'exec run_all_counts '+c_table_name+','+c_obsfact from TABLE_ACCESS where c_visualattributes like '%A%' 
--ELSE 
declare getsql cursor local for select 'exec run_all_counts '+c_table_name  from TABLE_ACCESS where c_visualattributes like '%A%'


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
end
;

-----------------------------------------------------------------------------------------------------------------
-- Procedure to CLEAR totalnum counts on all tables in table_access that have a key like PCORI_
-- Not needed to run before setting but helpful to verify job completed ok
-----------------------------------------------------------------------------------------------------------------

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'ClearTotalnum') AND type in (N'P', N'PC'))
DROP PROCEDURE ClearTotalnum
;

create procedure dbo.ClearTotalnum as 

DECLARE @sqltext NVARCHAR(4000);
DECLARE @sqlcurs NVARCHAR(4000);

declare getsql cursor local for select 'update '+c_table_name+' set c_totalnum=NULL' from TABLE_ACCESS where c_visualattributes like '%A%'


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
end
;