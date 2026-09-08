-- Compatibility wrapper for totalnum counting.
-- Defaults to the fast i2b2 totalnum workflow while preserving the legacy runtotalnum procedure name.
-- Use mode => 'omop' for fast ACT-OMOP prep or mode => 'classic' to force the legacy/classic implementation.

create or replace PROCEDURE runtotalnum (
  observationTable IN VARCHAR,
  schemaName IN VARCHAR,
  tableName IN VARCHAR DEFAULT '@',
  mode IN VARCHAR DEFAULT 'fast'
)
AUTHID CURRENT_USER
IS
  mode_norm VARCHAR2(20);
  source_mode VARCHAR2(20);
BEGIN
  mode_norm := LOWER(NVL(NULLIF(mode, ''), 'fast'));

  IF mode_norm = 'classic' THEN
    RunTotalnumClassic(observationTable, schemaName, tableName);
    RETURN;
  END IF;

  IF mode_norm IN ('fast','i2b2') AND LOWER(observationTable) <> 'observation_fact' THEN
    DBMS_OUTPUT.PUT_LINE('runtotalnum compatibility mode: custom fact table requested, using RunTotalnumClassic.');
    RunTotalnumClassic(observationTable, schemaName, tableName);
    RETURN;
  END IF;

  IF mode_norm NOT IN ('fast','i2b2','omop') THEN
    RAISE_APPLICATION_ERROR(-20004, 'Invalid totalnum mode. Use fast, i2b2, omop, or classic.');
  END IF;

  source_mode := CASE WHEN mode_norm = 'omop' THEN 'omop' ELSE 'i2b2' END;
  FastTotalnumPrep(schemaName, source_mode);
  FastTotalnumCount;
  FastTotalnumOutput(schemaName, tableName);
END;
