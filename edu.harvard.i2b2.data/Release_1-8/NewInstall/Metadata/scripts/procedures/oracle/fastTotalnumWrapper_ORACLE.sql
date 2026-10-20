-- Retained for reference, but disabled because RunTotalnum is the supported wrapper.
-- Remove any previously installed copy, then keep the implementation commented below.
BEGIN
  EXECUTE IMMEDIATE 'DROP PROCEDURE FastTotalnumWrapper';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -4043 THEN
      RAISE;
    END IF;
END;
GO

/*
CREATE OR REPLACE PROCEDURE FastTotalnumWrapper
(
    p_schemaname  IN VARCHAR2 DEFAULT 'DBO',
    p_tablename   IN VARCHAR2 DEFAULT '@',
    p_source_mode IN VARCHAR2 DEFAULT 'i2b2'
)
AS
BEGIN

    -----------------------------------------------------------------------
    -- Step 1: Prepare
    -----------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('Step 1: Prepare fast totalnum...');

    FastTotalnumPrep(
        p_schemaname,
        p_source_mode
    );

    DBMS_OUTPUT.PUT_LINE('Step 1 completed.');


    -----------------------------------------------------------------------
    -- Step 2: Calculate
    -----------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('Step 2: Calculate fast totalnum...');

    FastTotalnumCount;

    DBMS_OUTPUT.PUT_LINE('Step 2 completed.');


    -----------------------------------------------------------------------
    -- Step 3: Output
    -----------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('Step 3: Generate fast totalnum output...');

    FastTotalnumOutput(
        p_schemaname,
        p_tablename
    );

    DBMS_OUTPUT.PUT_LINE('Step 3 completed.');

    -----------------------------------------------------------------------
    -- Finished
    -----------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('Finished.');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            'ERROR: ' || SQLCODE || ' - ' || SQLERRM
        );
        RAISE;

END FastTotalnumWrapper;
/
-- Examples:
-- BEGIN
--     FastTotalnumWrapper('I2B2', '@', 'i2b2');
-- END;
--
-- BEGIN
--     FastTotalnumWrapper('I2B2', '@', 'omop');
-- END;
*/
