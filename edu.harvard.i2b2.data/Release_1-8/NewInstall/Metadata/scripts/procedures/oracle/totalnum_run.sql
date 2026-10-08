-- Compatibility wrapper for totalnum counting.
-- Defaults to the fast i2b2 totalnum workflow while preserving the legacy runtotalnum procedure name.
-- Use mode => 'omop' for fast ACT-OMOP prep or mode => 'classic' to force the legacy/classic implementation.
-- Use run_prep => 0 to reuse existing prepared structures; the default of 1 rebuilds them.

create or replace PROCEDURE runtotalnum (
  observationTable IN VARCHAR,
  schemaName IN VARCHAR,
  tableName IN VARCHAR DEFAULT '@',
  mode IN VARCHAR DEFAULT 'fast',
  run_prep IN NUMBER DEFAULT 1
)
AUTHID CURRENT_USER
IS
  mode_norm VARCHAR2(20);
  source_mode VARCHAR2(20);
  prepared_object_count NUMBER;
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

  IF NVL(run_prep, 1) <> 0 THEN
    FastTotalnumPrep(schemaName, source_mode);
  ELSE
    DBMS_OUTPUT.PUT_LINE('Skipping FastTotalnumPrep; using existing OBSFACT_PAIRS, TNUM_ONTOLOGY, and CONCEPT_CLOSURE. Rerun prep after ontology changes or when switching source mode.');

    SELECT COUNT(DISTINCT object_name)
      INTO prepared_object_count
      FROM user_objects
     WHERE object_name IN ('OBSFACT_PAIRS', 'TNUM_ONTOLOGY', 'CONCEPT_CLOSURE')
       AND status = 'VALID'
       AND ((object_name = 'OBSFACT_PAIRS' AND object_type IN ('VIEW', 'TABLE'))
         OR (object_name IN ('TNUM_ONTOLOGY', 'CONCEPT_CLOSURE') AND object_type = 'TABLE'));

    IF prepared_object_count <> 3 THEN
      RAISE_APPLICATION_ERROR(-20005, 'Cannot skip FastTotalnumPrep because one or more prepared objects are missing or invalid.');
    END IF;
  END IF;

  FastTotalnumCount;
  FastTotalnumOutput(schemaName, tableName);
END;
