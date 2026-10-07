---------------------------------------------------------------------------
-- FastTotalnumWrapper - PostgreSQL
--
-- Executes:
--   1. fasttotalnumprep
--   2. fasttotalnumcount
--   3. fasttotalnumoutput
--
-- Supports:
--   source_mode = 'i2b2'
--   source_mode = 'omop'
---------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE fasttotalnumwrapper
(
    p_schemaname  text DEFAULT 'public',
    p_tablename   text DEFAULT '@',
    p_source_mode text DEFAULT 'i2b2'
)
LANGUAGE plpgsql
AS $$
BEGIN

    -----------------------------------------------------------------------
    -- Step 1: Prepare fast totalnum
    -----------------------------------------------------------------------
    RAISE NOTICE 'Step 1: Prepare fast totalnum...';

    CALL fasttotalnumprep(
        p_schemaname,
        p_source_mode
    );

    RAISE NOTICE 'Step 1 completed.';


    -----------------------------------------------------------------------
    -- Step 2: Calculate fast totalnum
    -----------------------------------------------------------------------
    RAISE NOTICE 'Step 2: Calculate fast totalnum...';

    CALL fasttotalnumcount(
        p_schemaname,
        p_source_mode
    );

    RAISE NOTICE 'Step 2 completed.';


    -----------------------------------------------------------------------
    -- Step 3: Generate fast totalnum output
    -----------------------------------------------------------------------
    RAISE NOTICE 'Step 3: Generate fast totalnum output...';

    CALL fasttotalnumoutput(
        p_schemaname,
        p_tablename,
        p_source_mode
    );

    RAISE NOTICE 'Step 3 completed.';

    -----------------------------------------------------------------------
    -- Finished
    -----------------------------------------------------------------------
    RAISE NOTICE 'Finished.';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: %', SQLERRM;
        RAISE;

END;
$$;