/*
SQL Server validation script for RunTotalnum @demographics_mode.

Run this only in a test database or a disposable copy of metadata and data.
The enabled tests execute totalnum counting, update ontology tables and TABLE_ACCESS,
append rows to TOTALNUM, and rebuild TOTALNUM_REPORT when that procedure is available.

Manual preparation:
  1. Load all SQL Server procedure scripts after installing this change.
  2. Confirm TABLE_ACCESS correctly identifies ACT_DEMO in C_TABLE_CD.
  3. Confirm at least one other active ontology contains metadata rows whose
     C_TABLENAME is patient_dimension. Without one, act and all should match.
  4. Set the variables below for the test database.
  5. Keep this query window open for the entire test; temporary comparison tables
     are session-scoped.

Expected behavior:
  - act uses the existing optimized ACT demographic path.
  - all produces the same ACT_DEMO counts as act.
  - the all run reuses the structures prepared by the act run, exercising
    RunTotalnum @run_prep = 0.
  - all additionally produces PA rows and ontology counts for non-ACT
    patient_dimension metadata.
  - all also invokes the constrained-fact supplement. Validate those rows with
    test_totalnum_constrained_facts.sql.
  - the classic PAT_COUNT_VISITS interface still counts patient and visit metadata.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @SchemaName varchar(50) = 'dbo';
DECLARE @ObservationTable varchar(50) = 'observation_fact';
DECLARE @SourceMode varchar(20) = 'fast'; -- fast/i2b2, or omop
DECLARE @SingleOntologyTable varchar(255) = NULL; -- Optional focused test
DECLARE @RunClassicComparison bit = 0; -- Set to 1 only when the slower classic run is desired
DECLARE @RestoreAllAtEnd bit = 0; -- Set to 1 to leave metadata populated by fast/all
DECLARE @StartedAt datetime2;
DECLARE @Sql nvarchar(max);
DECLARE @MetadataTable varchar(255);
DECLARE @TableCd varchar(255);

IF OBJECT_ID('tempdb..#TestTiming') IS NOT NULL DROP TABLE #TestTiming;
IF OBJECT_ID('tempdb..#DimensionItems') IS NOT NULL DROP TABLE #DimensionItems;
IF OBJECT_ID('tempdb..#ActResults') IS NOT NULL DROP TABLE #ActResults;
IF OBJECT_ID('tempdb..#AllResults') IS NOT NULL DROP TABLE #AllResults;
IF OBJECT_ID('tempdb..#ClassicResults') IS NOT NULL DROP TABLE #ClassicResults;
IF OBJECT_ID('tempdb..#TableAccessMismatches') IS NOT NULL DROP TABLE #TableAccessMismatches;

CREATE TABLE #TestTiming (
    test_name varchar(30) NOT NULL,
    elapsed_seconds decimal(18,3) NOT NULL
);

CREATE TABLE #DimensionItems (
    c_table_cd varchar(255),
    metadata_table varchar(255),
    c_fullname varchar(1200),
    c_visualattributes varchar(50),
    dimension_table varchar(128),
    is_act_demo bit
);

CREATE TABLE #ActResults (
    metadata_table varchar(255),
    c_fullname varchar(1200),
    c_totalnum bigint NULL
);

CREATE TABLE #AllResults (
    metadata_table varchar(255),
    c_fullname varchar(1200),
    c_totalnum bigint NULL
);

CREATE TABLE #ClassicResults (
    metadata_table varchar(255),
    c_fullname varchar(1200),
    c_totalnum bigint NULL
);

CREATE TABLE #TableAccessMismatches (
    c_table_cd varchar(255),
    metadata_table varchar(255),
    table_access_count bigint NULL,
    ontology_count bigint NULL
);

/* Inventory the patient/visit metadata that is in scope. Review this first. */
DECLARE inventory_tables CURSOR LOCAL FAST_FORWARD FOR
    SELECT c_table_cd, c_table_name
    FROM table_access
    WHERE c_visualattributes LIKE '%A%';

OPEN inventory_tables;
FETCH NEXT FROM inventory_tables INTO @TableCd, @MetadataTable;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @Sql =
        'INSERT INTO #DimensionItems ' +
        '(c_table_cd, metadata_table, c_fullname, c_visualattributes, dimension_table, is_act_demo) ' +
        'SELECT @TableCd, @MetadataTable, c_fullname, c_visualattributes, LOWER(c_tablename), ' +
        'CASE WHEN UPPER(@TableCd) = ''ACT_DEMO'' THEN 1 ELSE 0 END ' +
        'FROM ' + @MetadataTable + ' ' +
        'WHERE m_applied_path = ''@'' ' +
        'AND LOWER(c_tablename) IN (''patient_dimension'', ''visit_dimension'')';

    BEGIN TRY
        EXEC sp_executesql @Sql,
            N'@TableCd varchar(255), @MetadataTable varchar(255)',
            @TableCd, @MetadataTable;
    END TRY
    BEGIN CATCH
        PRINT 'Inventory skipped ' + @MetadataTable + ': ' + ERROR_MESSAGE();
    END CATCH;

    FETCH NEXT FROM inventory_tables INTO @TableCd, @MetadataTable;
END;

CLOSE inventory_tables;
DEALLOCATE inventory_tables;

SELECT is_act_demo, dimension_table, COUNT(*) AS metadata_item_count
FROM #DimensionItems
GROUP BY is_act_demo, dimension_table
ORDER BY is_act_demo DESC, dimension_table;

SELECT DISTINCT c_table_cd, metadata_table
FROM #DimensionItems
ORDER BY c_table_cd, metadata_table;

/* Test 1: run and time the default optimized ACT path. */
SET @StartedAt = SYSDATETIME();
EXEC RunTotalnum
    @observationTable = @ObservationTable,
    @schemaname = @SchemaName,
    @tablename = '@',
    @mode = @SourceMode,
    @demographics_mode = 'act';
INSERT INTO #TestTiming
VALUES ('fast-act', DATEDIFF_BIG(millisecond, @StartedAt, SYSDATETIME()) / 1000.0);

DECLARE capture_act CURSOR LOCAL FAST_FORWARD FOR
    SELECT DISTINCT c_table_name
    FROM table_access
    WHERE c_visualattributes LIKE '%A%';

OPEN capture_act;
FETCH NEXT FROM capture_act INTO @MetadataTable;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @Sql =
        'INSERT INTO #ActResults(metadata_table, c_fullname, c_totalnum) ' +
        'SELECT @MetadataTable, c_fullname, c_totalnum FROM ' + @MetadataTable;
    EXEC sp_executesql @Sql, N'@MetadataTable varchar(255)', @MetadataTable;
    FETCH NEXT FROM capture_act INTO @MetadataTable;
END;
CLOSE capture_act;
DEALLOCATE capture_act;

/*
Test 2: run and time fast counting with all additional demographics.
This deliberately skips prep and reuses the structures built by Test 1. Before
using this shortcut in normal operation, rerun prep after ontology, TABLE_ACCESS,
source-view, or source-mode changes.
*/
SET @StartedAt = SYSDATETIME();
EXEC RunTotalnum
    @observationTable = @ObservationTable,
    @schemaname = @SchemaName,
    @tablename = '@',
    @mode = @SourceMode,
    @demographics_mode = 'all',
    @run_prep = 0;
INSERT INTO #TestTiming
VALUES ('fast-all', DATEDIFF_BIG(millisecond, @StartedAt, SYSDATETIME()) / 1000.0);

DECLARE capture_all CURSOR LOCAL FAST_FORWARD FOR
    SELECT DISTINCT c_table_name
    FROM table_access
    WHERE c_visualattributes LIKE '%A%';

OPEN capture_all;
FETCH NEXT FROM capture_all INTO @MetadataTable;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @Sql =
        'INSERT INTO #AllResults(metadata_table, c_fullname, c_totalnum) ' +
        'SELECT @MetadataTable, c_fullname, c_totalnum FROM ' + @MetadataTable;
    EXEC sp_executesql @Sql, N'@MetadataTable varchar(255)', @MetadataTable;
    FETCH NEXT FROM capture_all INTO @MetadataTable;
END;
CLOSE capture_all;
DEALLOCATE capture_all;

/* ACT rows should have no differences. Any returned row needs investigation. */
SELECT DISTINCT d.metadata_table, d.c_fullname,
       a.c_totalnum AS act_mode_count,
       x.c_totalnum AS all_mode_count
FROM #DimensionItems d
JOIN #ActResults a
  ON a.metadata_table = d.metadata_table AND a.c_fullname = d.c_fullname
JOIN #AllResults x
  ON x.metadata_table = d.metadata_table AND x.c_fullname = d.c_fullname
WHERE d.is_act_demo = 1
  AND ISNULL(a.c_totalnum, -1) <> ISNULL(x.c_totalnum, -1)
ORDER BY d.metadata_table, d.c_fullname;

/* These are the non-ACT patient_dimension rows added or changed by all mode. */
SELECT DISTINCT d.c_table_cd, d.metadata_table, d.c_fullname,
       a.c_totalnum AS act_mode_count,
       x.c_totalnum AS all_mode_count
FROM #DimensionItems d
LEFT JOIN #ActResults a
  ON a.metadata_table = d.metadata_table AND a.c_fullname = d.c_fullname
LEFT JOIN #AllResults x
  ON x.metadata_table = d.metadata_table AND x.c_fullname = d.c_fullname
WHERE d.is_act_demo = 0
  AND d.dimension_table = 'patient_dimension'
  AND ISNULL(a.c_totalnum, -1) <> ISNULL(x.c_totalnum, -1)
ORDER BY d.c_table_cd, d.metadata_table, d.c_fullname;

/*
Verify count provenance. ACT_DEMO paths should normally have PF as their newest
row; additional non-ACT patient_dimension paths should have PA. A path shared by
multiple ontology tables appears once because TOTALNUM is keyed historically by
C_FULLNAME rather than by ontology table.
*/
;WITH relevant_paths AS (
    SELECT c_fullname, MAX(CAST(is_act_demo AS int)) AS is_act_demo
    FROM #DimensionItems
    WHERE dimension_table = 'patient_dimension'
    GROUP BY c_fullname
), latest AS (
    SELECT t.c_fullname, t.agg_count, t.agg_date, t.typeflag_cd,
           ROW_NUMBER() OVER (PARTITION BY t.c_fullname ORDER BY t.agg_date DESC) AS rn
    FROM totalnum t
    JOIN relevant_paths p ON p.c_fullname = t.c_fullname
    WHERE t.typeflag_cd LIKE 'P%'
)
SELECT p.is_act_demo, l.typeflag_cd, COUNT(*) AS path_count
FROM relevant_paths p
JOIN latest l ON l.c_fullname = p.c_fullname AND l.rn = 1
GROUP BY p.is_act_demo, l.typeflag_cd
ORDER BY p.is_act_demo DESC, l.typeflag_cd;

/* Confirm TABLE_ACCESS agrees with each corresponding ontology root. */
DECLARE access_tables CURSOR LOCAL FAST_FORWARD FOR
    SELECT c_table_cd, c_table_name
    FROM table_access
    WHERE c_visualattributes LIKE '%A%';

OPEN access_tables;
FETCH NEXT FROM access_tables INTO @TableCd, @MetadataTable;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @Sql =
        'INSERT INTO #TableAccessMismatches(c_table_cd, metadata_table, table_access_count, ontology_count) ' +
        'SELECT @TableCd, @MetadataTable, ta.c_totalnum, o.c_totalnum ' +
        'FROM table_access ta JOIN ' + @MetadataTable + ' o ON o.c_fullname = ta.c_fullname ' +
        'WHERE ta.c_table_cd = @TableCd ' +
        'AND ISNULL(ta.c_totalnum, -1) <> ISNULL(o.c_totalnum, -1)';
    EXEC sp_executesql @Sql,
        N'@TableCd varchar(255), @MetadataTable varchar(255)',
        @TableCd, @MetadataTable;
    FETCH NEXT FROM access_tables INTO @TableCd, @MetadataTable;
END;
CLOSE access_tables;
DEALLOCATE access_tables;

SELECT *
FROM #TableAccessMismatches
ORDER BY c_table_cd, metadata_table;

/* Optional focused-table test. Other ontology tables should not be rewritten. */
IF @SingleOntologyTable IS NOT NULL
BEGIN
    EXEC RunTotalnum
        @observationTable = @ObservationTable,
        @schemaname = @SchemaName,
        @tablename = @SingleOntologyTable,
        @mode = @SourceMode,
        @demographics_mode = 'all';

    PRINT 'Focused table test completed for ' + @SingleOntologyTable +
          '. Manually verify another ontology table was not changed.';
END;

/*
Optional slow comparison with classic totalnum. This leaves classic counts in the
ontology unless @RestoreAllAtEnd is set. Compare only non-ACT patient_dimension
paths: fast/all deliberately keeps ACT_DEMO on the optimized implementation.
*/
IF @RunClassicComparison = 1
BEGIN
    SET @StartedAt = SYSDATETIME();
    EXEC RunTotalnum
        @observationTable = @ObservationTable,
        @schemaname = @SchemaName,
        @tablename = '@',
        @mode = 'classic';
    INSERT INTO #TestTiming
    VALUES ('classic', DATEDIFF_BIG(millisecond, @StartedAt, SYSDATETIME()) / 1000.0);

    DECLARE capture_classic CURSOR LOCAL FAST_FORWARD FOR
        SELECT DISTINCT c_table_name
        FROM table_access
        WHERE c_visualattributes LIKE '%A%';

    OPEN capture_classic;
    FETCH NEXT FROM capture_classic INTO @MetadataTable;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Sql =
            'INSERT INTO #ClassicResults(metadata_table, c_fullname, c_totalnum) ' +
            'SELECT @MetadataTable, c_fullname, c_totalnum FROM ' + @MetadataTable;
        EXEC sp_executesql @Sql, N'@MetadataTable varchar(255)', @MetadataTable;
        FETCH NEXT FROM capture_classic INTO @MetadataTable;
    END;
    CLOSE capture_classic;
    DEALLOCATE capture_classic;

    SELECT DISTINCT d.c_table_cd, d.metadata_table, d.c_fullname,
           x.c_totalnum AS fast_all_count,
           c.c_totalnum AS classic_count
    FROM #DimensionItems d
    LEFT JOIN #AllResults x
      ON x.metadata_table = d.metadata_table AND x.c_fullname = d.c_fullname
    LEFT JOIN #ClassicResults c
      ON c.metadata_table = d.metadata_table AND c.c_fullname = d.c_fullname
    WHERE d.is_act_demo = 0
      AND d.dimension_table = 'patient_dimension'
      AND ISNULL(x.c_totalnum, -1) <> ISNULL(c.c_totalnum, -1)
    ORDER BY d.c_table_cd, d.metadata_table, d.c_fullname;
END;

IF @RestoreAllAtEnd = 1
BEGIN
    EXEC RunTotalnum
        @observationTable = @ObservationTable,
        @schemaname = @SchemaName,
        @tablename = '@',
        @mode = @SourceMode,
        @demographics_mode = 'all';
END;

SELECT test_name, elapsed_seconds
FROM #TestTiming
ORDER BY elapsed_seconds;

/*
Additional manual edge cases (perform only in a disposable database):

Missing ACT_DEMO
  - Begin a transaction.
  - Delete the ACT_DEMO row from TABLE_ACCESS.
  - Run act mode: it should print a skip message and complete.
  - Run all mode: non-ACT patient_dimension entries should still be counted.
  - Roll back the transaction.

Zero and NULL demographics
  - Find a non-ACT patient_dimension ontology leaf matching no patients and one
    matching a NULL/not-recorded value.
  - Run all mode and compare its C_TOTALNUM with a direct COUNT(DISTINCT patient_num)
    using that row's C_COLUMNNAME, C_OPERATOR, and C_DIMCODE.
  - Re-run after changing a previously populated test value so that it matches no
    patients; verify an old nonzero count does not survive.

Invalid metadata column
  - Begin a transaction and change C_COLUMNNAME for one non-ACT patient_dimension
    row to a nonexistent column.
  - Run FastTotalnumAdditionalDimensions directly.
  - It should print a "Skipping dimension item" message and continue counting the
    remaining rows.
  - Roll back the transaction.

Classic compatibility against a pre-change baseline
  - Before installing these procedures in a test copy, export C_FULLNAME and
    C_TOTALNUM after RunTotalnumClassic.
  - Install the change, run classic again, and compare the export. Counts should
    match; timing and TOTALNUM timestamps will naturally differ.
*/
