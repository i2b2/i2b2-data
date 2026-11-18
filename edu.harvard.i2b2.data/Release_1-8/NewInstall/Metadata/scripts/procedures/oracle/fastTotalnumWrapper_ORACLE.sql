
-- ============================================================
-- FastTotalnumWrapper - Oracle - DEPRECATED
-- ============================================================
-- Retained for future reference.
-- RunTotalnum is now the supported wrapper.
--
-- The original procedure is fully commented out.
-- Only the DROP block at the end will execute.
--
-- ANT delimiter: GO
-- ============================================================


-- ============================================================
-- ORIGINAL FastTotalnumWrapper - DISABLED
-- ============================================================
--
-- Executes:
--   1. FastTotalnumPrep
--   2. FastTotalnumCount
--   3. FastTotalnumOutput
--
-- Supports:
--   source_mode = 'i2b2'
--   source_mode = 'omop'
-- ============================================================

-- CREATE OR REPLACE PROCEDURE FastTotalnumWrapper
-- (
--     p_schemaname  IN VARCHAR2 DEFAULT 'DBO',
--     p_tablename   IN VARCHAR2 DEFAULT '@',
--     p_source_mode IN VARCHAR2 DEFAULT 'i2b2'
-- )
-- AS
-- BEGIN
--
--     -------------------------------------------------------
--     -- Step 1: Prepare fast totalnum
--     -------------------------------------------------------
--     DBMS_OUTPUT.PUT_LINE('Step 1: Prepare fast totalnum...');
--
--     FastTotalnumPrep(
--         p_schemaname,
--         p_source_mode
--     );
--
--     DBMS_OUTPUT.PUT_LINE('Step 1 completed.');
--
--
--     -------------------------------------------------------
--     -- Step 2: Calculate fast totalnum
--     -------------------------------------------------------
--     DBMS_OUTPUT.PUT_LINE('Step 2: Calculate fast totalnum...');
--
--     FastTotalnumCount;
--
--     DBMS_OUTPUT.PUT_LINE('Step 2 completed.');
--
--
--     -------------------------------------------------------
--     -- Step 3: Generate fast totalnum output
--     -------------------------------------------------------
--     DBMS_OUTPUT.PUT_LINE('Step 3: Generate fast totalnum output...');
--
--     FastTotalnumOutput(
--         p_schemaname,
--         p_tablename
--     );
--
--     DBMS_OUTPUT.PUT_LINE('Step 3 completed.');
--
--
--     -------------------------------------------------------
--     -- Finished
--     -------------------------------------------------------
--     DBMS_OUTPUT.PUT_LINE('Finished.');
--
-- EXCEPTION
--     WHEN OTHERS THEN
--         DBMS_OUTPUT.PUT_LINE(
--             'ERROR: ' || SQLCODE || ' - ' || SQLERRM
--         );
--         RAISE;
--
-- END FastTotalnumWrapper;


-- ============================================================
-- ORIGINAL EXECUTION EXAMPLES - DISABLED
-- ============================================================

-- BEGIN
--     FastTotalnumWrapper('I2B2', '@', 'i2b2');
-- END;

-- BEGIN
--     FastTotalnumWrapper('I2B2', '@', 'omop');
-- END;


-- ============================================================
-- ACTIVE DEPLOYMENT - DROP DEPRECATED PROCEDURE
-- ============================================================
-- Remove FastTotalnumWrapper if it exists.
-- Ignore ORA-04043 if the procedure does not exist.
-- ============================================================

BEGIN
    EXECUTE IMMEDIATE 'DROP PROCEDURE FastTotalnumWrapper';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -4043 THEN
            RAISE;
        END IF;
END;
GO
