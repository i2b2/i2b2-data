-----------------------------------------------------------------------------------------------------------------
-- Compatibility wrapper for totalnum counting.
-- Defaults to the fast i2b2 totalnum workflow while preserving the legacy RunTotalnum procedure name.
-- Use @mode = 'omop' for fast ACT-OMOP prep or @mode = 'classic' to force the legacy/classic implementation.
-- Examples:
--   exec RunTotalnum
--   exec RunTotalnum 'observation_fact','dbo','@','N','omop'
--   exec RunTotalnum 'observation_fact','dbo','@','N','classic'
-----------------------------------------------------------------------------------------------------------------

IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'RunTotalnum')
                    AND type IN ( N'P', N'PC' ) )
DROP PROCEDURE RunTotalnum;
GO

CREATE PROCEDURE [dbo].[RunTotalnum] (
    @observationTable varchar(50) = 'observation_fact',
    @schemaname varchar(50) = 'dbo',
    @tablename varchar(50) = '@',
    @wildcard_factcolumn varchar(1) = 'N',
    @mode varchar(20) = 'fast'
) AS
BEGIN
    DECLARE @mode_norm varchar(20) = LOWER(ISNULL(NULLIF(@mode,''),'fast'));
    DECLARE @source_mode varchar(20) = CASE WHEN @mode_norm = 'omop' THEN 'omop' ELSE 'i2b2' END;

    IF @mode_norm = 'classic'
    BEGIN
        EXEC RunTotalnumClassic @observationTable, @schemaname, @tablename, @wildcard_factcolumn;
        RETURN;
    END

    IF @mode_norm IN ('fast','i2b2')
       AND (LOWER(@observationTable) <> 'observation_fact' OR UPPER(ISNULL(@wildcard_factcolumn,'N')) = 'Y')
    BEGIN
        PRINT 'RunTotalnum compatibility mode: custom fact table or wildcard flag requested, using RunTotalnumClassic.';
        EXEC RunTotalnumClassic @observationTable, @schemaname, @tablename, @wildcard_factcolumn;
        RETURN;
    END

    IF @mode_norm NOT IN ('fast','i2b2','omop')
    BEGIN
        RAISERROR('Invalid totalnum mode. Use fast, i2b2, omop, or classic.', 16, 1);
        RETURN;
    END

    EXEC FastTotalnumPrep @schemaname = @schemaname, @source_mode = @source_mode;
    EXEC FastTotalnumCount;
    EXEC FastTotalnumOutput @schemaname = @schemaname, @tablename = @tablename;
END;
GO
