-----------------------------------------------------------------------------------------------------------------
-- Count metadata-defined demographics that are not part of the optimized ACT_DEMO fast path.
-- This procedure is called only when RunTotalnum uses @demographics_mode = 'all'.
-- ACT_DEMO is identified through TABLE_ACCESS.C_TABLE_CD; its physical table name is never hardcoded.
-- For a manual fast run, call this after FastTotalnumCount and then call
-- FastTotalnumOutput with @demographics_mode = 'all'.
-----------------------------------------------------------------------------------------------------------------

IF EXISTS ( SELECT *
            FROM sys.objects
            WHERE object_id = OBJECT_ID(N'FastTotalnumAdditionalDimensions')
              AND type IN (N'P', N'PC') )
DROP PROCEDURE FastTotalnumAdditionalDimensions;
GO

CREATE PROCEDURE [dbo].[FastTotalnumAdditionalDimensions] (
    @schemaname varchar(50) = 'dbo',
    @tablename varchar(255) = '@'
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @metadataTable varchar(255);

    DECLARE additional_dimension_tables CURSOR LOCAL FAST_FORWARD FOR
        SELECT DISTINCT ta.c_table_name
        FROM table_access ta
        WHERE ta.c_visualattributes LIKE '%A%'
          AND (@tablename = '@' OR ta.c_table_name = @tablename)
          AND NOT EXISTS (
              SELECT 1
              FROM table_access act
              WHERE UPPER(act.c_table_cd) = 'ACT_DEMO'
                AND act.c_table_name = ta.c_table_name
          );

    OPEN additional_dimension_tables;
    FETCH NEXT FROM additional_dimension_tables INTO @metadataTable;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        RAISERROR('Counting additional patient_dimension demographics in %s.', 0, 1, @metadataTable) WITH NOWAIT;

        EXEC PAT_COUNT_METADATA_DIMENSIONS
            @tabname = @metadataTable,
            @schemaName = @schemaname,
            @dimensionScope = 'patient',
            @typeflagCd = 'PA';

        FETCH NEXT FROM additional_dimension_tables INTO @metadataTable;
    END;

    CLOSE additional_dimension_tables;
    DEALLOCATE additional_dimension_tables;
END;
GO
