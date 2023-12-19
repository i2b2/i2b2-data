-- MSSQL version
-- Originally Developed by Griffin Weber, Harvard Medical School
-- Contributors: Mike Mendis, Jeff Klann, Lori Phillips

IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'PAT_COUNT_VISITS')
                    AND type IN ( N'P', N'PC' ) ) 
DROP PROCEDURE PAT_COUNT_VISITS;
GO
 
CREATE PROCEDURE [dbo].[PAT_COUNT_VISITS] (@tabname varchar(50), @schemaName varchar(50))
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

    SET NOCOUNT ON

    if exists (select 1 from sysobjects where name='tnum_ontPatVisitDims') drop table tnum_ontPatVisitDims

-- pat_dim , visit_dim queries

	set @sqlstr='select c_fullname, c_basecode, c_facttablecolumn, c_tablename, c_columnname, c_operator, c_dimcode into tnum_ontPatVisitDims from ' + @tabname
        + ' where  m_applied_path = ''@'' and c_tablename in (''patient_dimension'', ''visit_dimension'') '
    execute sp_executesql @sqlstr
    
    RAISERROR('visit query: %s',0,1,@sqlstr) WITH NOWAIT;

	alter table tnum_ontPatVisitDims add numpats int

	alter table tnum_ontPatVisitDims alter column c_fullname varchar(900) NOT NULL
	
	alter table tnum_ontPatVisitDims add primary key (c_fullname)

    if exists(select top 1 NULL from tnum_ontPatVisitDims)
    BEGIN

--------------  start of cursor e -------------------------------
	Declare e CURSOR
		Local Fast_Forward
		For
			select c_fullname, c_facttablecolumn, c_tablename, c_columnname, c_operator, c_dimcode from tnum_ontPatVisitDims
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
				-- Parentheses are optional in dimcode with IN queries
				if left(@dimcode,1) != '('
					BEGIN
					set @dimcode = '(' + @dimcode + ')'
					END
			end
			if lower(@operator) = '='
			begin
				set @dimcode = '''' +  replace(@dimcode,'''','''''') + ''''
			end
			set @sqlstr='update tnum_ontPatVisitDims set 
             numpats =  (select count(distinct(patient_num)) from ' + @schemaName + '.' + @tablename + 
               ' where ' + @facttablecolumn + ' in (select ' + @facttablecolumn + ' from ' +   @schemaName + '.' + @tablename + ' where '+ @columnname + ' ' + @operator +' ' + @dimcode +' ))
            where c_fullname = ' + ''''+ @concept + ''''+ ' and numpats is null'


			BEGIN TRY
    			execute sp_executesql @sqlstr
			END TRY
			BEGIN CATCH
				print 'Error executing:' + @sqlstr
                --  RAISERROR('visit query: %s',0,1,@sqlstr) WITH NOWAIT;
			END CATCH

		end

		fetch next from e into @concept, @facttablecolumn, @tablename, @columnname, @operator, @dimcode

	End
	close e
	deallocate e

--------------  end of cursor e -------------------------------
 

	set @sqlstr='update a set c_totalnum=b.numpats from '+@tabname+' a, tnum_ontPatVisitDims b '+
	'where a.c_fullname=b.c_fullname and b.numpats>0'
--	print @sqlstr
	execute sp_executesql @sqlstr
	
	-- New 4/2020 - Update the totalnum reporting table as well
	insert into totalnum(c_fullname, agg_date, agg_count, typeflag_cd)
	select c_fullname, CONVERT (date, GETDATE()), numpats, 'PD' from tnum_ontPatVisitDims
	
	if exists (select 1 from sysobjects where name='tnum_ontPatVisitDims') drop table tnum_ontPatVisitDims

END

END;
GO
