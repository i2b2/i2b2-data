
/****** Object:  StoredProcedure [dbo].[insert_Concept_FROMTableAccess]    Script Date: 3/18/2022 12:04:21 PM ******/
SET ANSI_NULLS ON


SET QUOTED_IDENTIFIER ON

IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'insert_Concept_FROMTableAccess')
                    AND type IN ( N'P', N'PC' ) ) 
DROP PROCEDURE insert_Concept_FROMTableAccess
;

CREATE PROCEDURE [dbo].[insert_Concept_FROMTableAccess]
	
AS
BEGIN
	SET NOCOUNT ON;
DECLARE @sqltext NVARCHAR(4000);
declare getsql cursor local for
select 'insert into concept_dimension select c_dimcode AS concept_path, c_basecode AS concept_cd, c_name AS name_char, null AS concept_blob, update_date AS update_date, download_date as download_date, import_date as import_date, sourcesystem_cd as sourcesystem_cd, 1 as upload_id from '
+c_table_name+' where m_applied_path=''@'' and c_tablename=''CONCEPT_DIMENSION'' and c_columnname=''concept_path'' and c_visualattributes not like ''%I%'' and (c_columndatatype=''T'' or c_columndatatype=''N'') and c_synonym_cd = ''N'' and (m_exclusion_cd is null or m_exclusion_cd='''') and c_basecode is not null and c_basecode!='''''
from TABLE_ACCESS

begin
delete from concept_dimension;
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
END
