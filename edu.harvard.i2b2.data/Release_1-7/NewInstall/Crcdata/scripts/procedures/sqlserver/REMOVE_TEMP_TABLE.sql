IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'REMOVE_TEMP_TABLE')
                    AND type IN ( N'P', N'PC' ) ) 
DROP PROCEDURE REMOVE_TEMP_TABLE
;


CREATE PROCEDURE REMOVE_TEMP_TABLE(@tempTableName VARCHAR(500)) 
AS
BEGIN 
    declare @dropSql nvarchar(MAX);
	set @dropSql = 'drop table ' + @tempTableName + ' ';
	exec sp_executesql @dropSql;
END;
