
-- Compatibility wrapper for totalnum counting.
-- Defaults to the fast i2b2 totalnum workflow while preserving
-- the legacy runtotalnum procedure name.
--
-- Use totalnum_mode => 'omop' for fast ACT-OMOP prep.
-- Use totalnum_mode => 'classic' for classic counting.
-- Use run_prep => 0 to reuse existing prepared structures.
-- The default run_prep => 1 rebuilds them.

CREATE OR REPLACE PROCEDURE runtotalnum (
    IN observationTable VARCHAR,
    IN schemaName VARCHAR,
    IN tableName VARCHAR DEFAULT '@',
    IN wildcard_factcolumn VARCHAR DEFAULT 'N',
    IN totalnum_mode VARCHAR DEFAULT 'fast',
    IN demographics_mode VARCHAR DEFAULT 'act',
    IN run_prep INTEGER DEFAULT 1
)
LANGUAGE plpgsql
AS $procedure$
DECLARE
    mode_norm VARCHAR(20);
    source_mode VARCHAR(20);
    demographics_mode_norm VARCHAR(20);
    prepared_object_count INTEGER;
BEGIN

    mode_norm := LOWER(
        COALESCE(NULLIF(totalnum_mode, ''), 'fast')
    );

    ------------------------------------------------------------------
    -- CLASSIC TOTALNUM
    ------------------------------------------------------------------

    IF mode_norm = 'classic' THEN

        CALL RunTotalnumClassic(
            observationTable,
            schemaName,
            tableName,
            wildcard_factcolumn
        );

        RETURN;
    END IF;

    ------------------------------------------------------------------
    -- COMPATIBILITY MODE
    -- Use classic counting for custom fact tables or wildcard flags.
    ------------------------------------------------------------------

    IF mode_norm IN ('fast', 'i2b2')
       AND (
           LOWER(observationTable) <> 'observation_fact'
           OR UPPER(COALESCE(wildcard_factcolumn, 'N')) = 'Y'
       )
    THEN

        RAISE NOTICE
            'runtotalnum compatibility mode: custom fact table or wildcard flag requested, using RunTotalnumClassic.';

        CALL RunTotalnumClassic(
            observationTable,
            schemaName,
            tableName,
            wildcard_factcolumn
        );

        RETURN;
    END IF;

    ------------------------------------------------------------------
    -- VALIDATE TOTALNUM MODE
    ------------------------------------------------------------------

    IF mode_norm NOT IN ('fast', 'i2b2', 'omop') THEN

        RAISE EXCEPTION
            'Invalid totalnum mode. Use fast, i2b2, omop, or classic.';

    END IF;

    ------------------------------------------------------------------
    -- DETERMINE SOURCE MODE
    ------------------------------------------------------------------

    source_mode := CASE
                       WHEN mode_norm = 'omop' THEN 'omop'
                       ELSE 'i2b2'
                   END;

    ------------------------------------------------------------------
    -- NORMALIZE DEMOGRAPHICS MODE
    -- Handle SQL NULL, empty strings, whitespace,
    -- and literal 'null'.
    ------------------------------------------------------------------

    demographics_mode_norm := LOWER(TRIM(demographics_mode));

    IF demographics_mode_norm IS NULL
       OR demographics_mode_norm = ''
       OR demographics_mode_norm = 'null'
    THEN

        demographics_mode_norm := 'act';

    END IF;

    IF demographics_mode_norm NOT IN ('act', 'all') THEN

        RAISE EXCEPTION
            'Invalid demographics_mode. Use act or all.';

    END IF;

    ------------------------------------------------------------------
    -- FAST TOTALNUM PREPARATION
    ------------------------------------------------------------------

    IF COALESCE(run_prep, 1) <> 0 THEN

        CALL FastTotalnumPrep(
            schemaName,
            source_mode
        );

    ELSE

        RAISE NOTICE
            'Skipping FastTotalnumPrep; using existing OBSFACT_PAIRS, TNUM_ONTOLOGY, and CONCEPT_CLOSURE. Rerun prep after ontology changes or when switching source mode.';

        ------------------------------------------------------------------
        -- VERIFY REQUIRED PREPARED OBJECTS
        --
        -- PostgreSQL equivalent of Oracle USER_OBJECTS.
        -- Checks the schema supplied in schemaName.
        ------------------------------------------------------------------

        SELECT COUNT(DISTINCT required.object_name)
        INTO prepared_object_count
        FROM (
            VALUES
                ('obsfact_pairs'),
                ('tnum_ontology'),
                ('concept_closure')
        ) AS required(object_name)
        WHERE
            (
                required.object_name = 'obsfact_pairs'
                AND EXISTS (
                    SELECT 1
                    FROM pg_catalog.pg_class c
                    JOIN pg_catalog.pg_namespace n
                      ON n.oid = c.relnamespace
                    WHERE n.nspname = schemaName
                      AND c.relname = required.object_name
                      AND c.relkind IN ('r', 'p', 'v', 'm')
                )
            )
            OR
            (
                required.object_name IN (
                    'tnum_ontology',
                    'concept_closure'
                )
                AND EXISTS (
                    SELECT 1
                    FROM pg_catalog.pg_class c
                    JOIN pg_catalog.pg_namespace n
                      ON n.oid = c.relnamespace
                    WHERE n.nspname = schemaName
                      AND c.relname = required.object_name
                      AND c.relkind IN ('r', 'p')
                )
            );

        IF prepared_object_count <> 3 THEN

            RAISE EXCEPTION
                'Cannot skip FastTotalnumPrep because one or more prepared objects are missing.';

        END IF;

    END IF;

    ------------------------------------------------------------------
    -- FAST TOTALNUM COUNT
    ------------------------------------------------------------------

    CALL FastTotalnumCount();

    ------------------------------------------------------------------
    -- ADDITIONAL DIMENSIONS AND CONSTRAINED FACTS
    -- Only when demographics_mode = 'all'
    ------------------------------------------------------------------

    IF demographics_mode_norm = 'all' THEN

        CALL FastTotalnumAdditionalDimensions(
            schemaName,
            tableName
        );

        CALL FastTotalnumConstrainedFacts(
            schemaName,
            tableName,
            source_mode
        );

    END IF;

    ------------------------------------------------------------------
    -- WRITE TOTALNUM COUNTS TO ONTOLOGY
    ------------------------------------------------------------------

    CALL FastTotalnumOutput(
        schemaName,
        tableName,
        demographics_mode_norm
    );

END;
$procedure$;
GO
