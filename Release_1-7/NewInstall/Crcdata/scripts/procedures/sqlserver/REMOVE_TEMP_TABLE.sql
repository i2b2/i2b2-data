CREATE PROCEDURE REMOVE_TEMP_TABLE(@tempTableName VARCHAR(500)) 
AS
BEGIN 
    declare @dropSql nvarchar(MAX);
	set @dropSql = 'drop table ' + @tempTableName + ' ';
	exec sp_executesql @dropSql;
END;
