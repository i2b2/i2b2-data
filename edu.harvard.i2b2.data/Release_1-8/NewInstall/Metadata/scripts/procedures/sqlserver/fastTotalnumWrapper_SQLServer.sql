-- Retained for reference, but disabled because RunTotalnum is the supported wrapper.
-- Remove any previously installed copy, then keep the implementation commented below.
IF OBJECT_ID(N'dbo.FastTotalnumWrapper', N'P') IS NOT NULL
    DROP PROCEDURE dbo.FastTotalnumWrapper;
GO

/*
-- SET TARGET DATABASE
--USE I2B2ACT
--GO
--DROP PROCEDURE IF EXISTS FastTotalnumWrapper;
--GO
--supports both i2b2 and OMOP data models

IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'FastTotalnumWrapper')
                    AND type IN ( N'P', N'PC' ) ) 
DROP PROCEDURE FastTotalnumWrapper;
GO
CREATE PROCEDURE [dbo].[FastTotalnumWrapper]
(
    @schemaname varchar(50) = 'dbo',
    @tablename varchar(50) = '@',
    @source_mode varchar(20) = 'i2b2'
)
AS
BEGIN

    -----------------------------------------------------------------------
    -- Step 1: Prepare fast totalnum
    -----------------------------------------------------------------------
	RAISERROR('Step 1: Prepare fast totalnum...', 0, 1) WITH NOWAIT;
    EXEC Fasttotalnumprep @schemaname,@source_mode;


    -----------------------------------------------------------------------
    -- Step 2: Calculate fast totalnum
    -----------------------------------------------------------------------
	RAISERROR('Step 2: Calculate fast totalnum...', 0, 1) WITH NOWAIT;
    EXEC FastTotalnumCount;


    -----------------------------------------------------------------------
    -- Step 3: Generate fast totalnum output
    -----------------------------------------------------------------------
	RAISERROR('Step 3: Generate fast totalnum output...', 0, 1) WITH NOWAIT;
    EXEC FastTotalnumOutput @schemaname,@tablename;
RAISERROR('Finished', 0, 1) WITH NOWAIT;
END;

-- Examples:
-- EXEC dbo.FastTotalnumWrapper 'dbo', '@', 'i2b2';
-- EXEC dbo.FastTotalnumWrapper 'dbo', '@', 'omop';
*/
