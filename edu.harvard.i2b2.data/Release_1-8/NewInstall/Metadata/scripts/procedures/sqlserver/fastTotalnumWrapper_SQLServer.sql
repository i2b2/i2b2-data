/* SET TARGET DATABASE */
--USE I2B2ACT
--GO
--DROP PROCEDURE IF EXISTS FastTotalnumWrapper;
--GO

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
    EXEC FastTotalnumCount @schemaname,@source_mode;


    -----------------------------------------------------------------------
    -- Step 3: Generate fast totalnum output
    -----------------------------------------------------------------------
	RAISERROR('Step 3: Generate fast totalnum output...', 0, 1) WITH NOWAIT;
    EXEC FastTotalnumOutput @schemaname,@tablename,@source_mode;
RAISERROR('Finished', 0, 1) WITH NOWAIT;
END;

/*
EXEC dbo.FastTotalnumWrapper 'dbo', '@', 'i2b2';

EXEC dbo.FastTotalnumWrapper 'dbo', '@', 'omop';
*/