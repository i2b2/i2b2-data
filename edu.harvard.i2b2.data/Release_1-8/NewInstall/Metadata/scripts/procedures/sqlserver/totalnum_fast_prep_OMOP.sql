-----------------------------------------------------------------------------------------------------------------
-- Compatibility wrapper for ACT-OMOP fast totalnum prep.
--
-- Load totalnum_fast_prep.sql first. The shared FastTotalnumPrep procedure owns the implementation;
-- this wrapper exists so older install/run instructions that call FastTotalnumPrepOMOP continue to work.
-----------------------------------------------------------------------------------------------------------------

IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'FastTotalnumPrepOMOP')
                    AND type IN ( N'P', N'PC' ) )
DROP PROCEDURE FastTotalnumPrepOMOP;
GO

CREATE PROCEDURE [dbo].[FastTotalnumPrepOMOP] (@schemaname varchar(50) = 'dbo') AS
BEGIN
  EXEC FastTotalnumPrep @schemaname = @schemaname, @source_mode = 'omop';
END;
GO
