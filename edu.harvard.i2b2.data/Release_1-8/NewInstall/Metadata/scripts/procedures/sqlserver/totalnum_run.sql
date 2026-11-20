-----------------------------------------------------------------------------------------------------------------
-- Compatibility wrapper for totalnum counting.
-- Defaults to the fast i2b2 totalnum workflow while preserving the legacy RunTotalnum procedure name.
-- Use @mode = 'omop' for fast ACT-OMOP prep or @mode = 'classic' to force the legacy/classic implementation.
-- @demographics_mode = 'act' keeps the optimized ACT-only path (default).
-- @demographics_mode = 'all' adds metadata-driven patient_dimension counts and supported constrained fact counts.
-- @run_prep = 0 reuses existing prepared structures; the default of 1 rebuilds them.
-- Examples:
--   exec RunTotalnum
--   exec RunTotalnum 'observation_fact','dbo','@','N','omop'
--   exec RunTotalnum 'observation_fact','dbo','@','N','classic'
--   exec RunTotalnum @demographics_mode = 'all'
--   exec RunTotalnum @run_prep = 0
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
    @mode varchar(20) = 'fast',
    @demographics_mode varchar(20) = 'act',
    @run_prep bit = 1
) AS
BEGIN
    DECLARE @mode_norm varchar(20) = LOWER(ISNULL(NULLIF(@mode,''),'fast'));
    DECLARE @demographics_mode_norm varchar(20) = LOWER(ISNULL(NULLIF(@demographics_mode,''),'act'));
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

    IF @demographics_mode_norm NOT IN ('act','all')
    BEGIN
        RAISERROR('Invalid demographics_mode. Use act or all.', 16, 1);
        RETURN;
    END

    IF ISNULL(@run_prep, 1) = 1
    BEGIN
        EXEC FastTotalnumPrep @schemaname = @schemaname, @source_mode = @source_mode;
    END
    ELSE
    BEGIN
        RAISERROR('Skipping FastTotalnumPrep; using existing OBSFACT_PAIRS, TNUM_ONTOLOGY, and CONCEPT_CLOSURE. Rerun prep after ontology changes or when switching source mode.', 0, 1) WITH NOWAIT;

        IF (OBJECT_ID(N'OBSFACT_PAIRS', N'V') IS NULL
            AND OBJECT_ID(N'OBSFACT_PAIRS', N'U') IS NULL)
           OR OBJECT_ID(N'TNUM_ONTOLOGY', N'U') IS NULL
           OR OBJECT_ID(N'CONCEPT_CLOSURE', N'U') IS NULL
        BEGIN
            RAISERROR('Cannot skip FastTotalnumPrep because one or more prepared objects are missing.', 16, 1);
            RETURN;
        END
    END

    EXEC FastTotalnumCount;

    IF @demographics_mode_norm = 'all'
    BEGIN
        EXEC FastTotalnumAdditionalDimensions @schemaname = @schemaname, @tablename = @tablename;
        EXEC FastTotalnumConstrainedFacts
            @schemaname = @schemaname,
            @tablename = @tablename,
            @source_mode = @source_mode;
    END

    EXEC FastTotalnumOutput
        @schemaname = @schemaname,
        @tablename = @tablename,
        @demographics_mode = @demographics_mode_norm;
END;
GO
