-----------------------------------------------------------------------------------------------------------------
-- Compatibility wrapper for totalnum counting.
-- Defaults to the fast i2b2 totalnum workflow while preserving the legacy runtotalnum function name.
-- Use mode => 'omop' for fast ACT-OMOP prep or mode => 'classic' to force the legacy/classic implementation.
-----------------------------------------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS runtotalnum(text, text, text);

CREATE OR REPLACE FUNCTION runtotalnum(
    observationTable text,
    schemaName text,
    tableName text default '@',
    mode text default 'fast'
)
  RETURNS void AS
$BODY$
DECLARE
    mode_norm text;
    source_mode text;
BEGIN
    mode_norm := lower(coalesce(nullif(mode, ''), 'fast'));

    IF mode_norm = 'classic' THEN
        PERFORM runtotalnumclassic(observationTable, schemaName, tableName);
        RETURN;
    END IF;

    IF mode_norm IN ('fast','i2b2') AND lower(observationTable) <> 'observation_fact' THEN
        RAISE NOTICE 'runtotalnum compatibility mode: custom fact table requested, using runtotalnumclassic.';
        PERFORM runtotalnumclassic(observationTable, schemaName, tableName);
        RETURN;
    END IF;

    IF mode_norm NOT IN ('fast','i2b2','omop') THEN
        RAISE EXCEPTION 'Invalid totalnum mode. Use fast, i2b2, omop, or classic.';
    END IF;

    source_mode := CASE WHEN mode_norm = 'omop' THEN 'omop' ELSE 'i2b2' END;
    PERFORM fasttotalnumprep(schemaName, source_mode);
    CALL fasttotalnumcount();
    CALL fasttotalnumoutput(schemaName, tableName);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;
