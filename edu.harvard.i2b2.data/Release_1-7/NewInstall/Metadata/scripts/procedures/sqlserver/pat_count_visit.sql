-- Originally Developed by Griffin Weber, Harvard Medical School
-- Contributors: Mike Mendis, Jeff Klann, Lori Phillips
 
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
             numpats =  (select count(distinct(patient_num)) from ' + @schemaName + '.' + @tablename + 
               ' where ' + @facttablecolumn + ' in (select ' + @facttablecolumn + ' from ' +   @schemaName + '.' + @tablename + ' where '+ @columnname + ' ' + @operator +' ' + @dimcode +' ))
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