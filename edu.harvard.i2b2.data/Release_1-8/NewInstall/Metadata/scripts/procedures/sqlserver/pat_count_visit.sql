-- MSSQL version
-- Originally Developed by Griffin Weber, Harvard Medical School
-- Contributors: Mike Mendis, Jeff Klann, Lori Phillips
--
-- Compatibility wrapper. The shared implementation is in
-- pat_count_metadata_dimensions.sql.

IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'PAT_COUNT_VISITS')
                    AND type IN ( N'P', N'PC' ) ) 
DROP PROCEDURE PAT_COUNT_VISITS;
GO
 
CREATE PROCEDURE [dbo].[PAT_COUNT_VISITS] (
    @tabname varchar(50),
    @schemaName varchar(50)
)
AS
BEGIN
    EXEC PAT_COUNT_METADATA_DIMENSIONS
        @tabname = @tabname,
        @schemaName = @schemaName,
        @dimensionScope = 'all',
        @typeflagCd = 'PD';
END;
GO
