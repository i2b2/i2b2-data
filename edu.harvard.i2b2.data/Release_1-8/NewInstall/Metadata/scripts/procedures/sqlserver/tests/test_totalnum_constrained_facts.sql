/*
SQL Server validation script for FastTotalnumConstrainedFacts.

This script uses one existing constrained ontology leaf and compares the
supplemental TOTALNUM result with a direct OBSERVATION_FACT count.

Manual preparation:
  1. Load all SQL Server procedure scripts.
  2. Run FastTotalnumPrep after loading the constrained ontology rows.
  3. Set the variables below to an existing constrained leaf.
  4. Set @RunTest = 1 and execute in a test database.

The test appends TOTALNUM history but does not run FastTotalnumOutput.
*/

SET NOCOUNT ON;

DECLARE @RunTest bit = 0;
DECLARE @SchemaName sysname = 'dbo';
DECLARE @MetadataTable sysname = 'emergecdpgira2_metadata';
DECLARE @Fullname varchar(1200) = '\Shortcuts\Condition Self-Report\Asthma\';
DECLARE @ConceptCd varchar(50) = 'E4:basl_ad_asth_1';
DECLARE @RequiredNval decimal(38, 10) = 1;

IF @RunTest = 0
BEGIN
    PRINT 'Set the metadata variables and @RunTest = 1 to execute this validation.';
    RETURN;
END;

DECLARE @sql nvarchar(max),
        @expected int,
        @actual int,
        @startedAt datetime = GETDATE();

-- Confirm the selected ontology row has the supported metadata shape.
SET @sql =
    'SELECT c_fullname, c_basecode, c_facttablecolumn, c_tablename, ' +
    '       c_columnname, c_operator, c_dimcode ' +
    'FROM ' + QUOTENAME(@MetadataTable) + ' ' +
    'WHERE c_fullname = @Fullname';
EXEC sp_executesql @sql, N'@Fullname varchar(1200)', @Fullname;

-- Establish the expected leaf count directly from the source facts.
SET @sql =
    'SELECT @ExpectedOut = COUNT(DISTINCT patient_num) ' +
    'FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME('observation_fact') + ' ' +
    'WHERE concept_cd = @ConceptCd AND nval_num = @RequiredNval';
EXEC sp_executesql @sql,
    N'@ConceptCd varchar(50), @RequiredNval decimal(38, 10), @ExpectedOut int OUTPUT',
    @ConceptCd, @RequiredNval, @expected OUTPUT;

EXEC dbo.FastTotalnumConstrainedFacts
    @schemaname = @SchemaName,
    @tablename = @MetadataTable,
    @source_mode = 'i2b2';

SELECT TOP (1) @actual = agg_count
FROM totalnum
WHERE c_fullname = @Fullname
  AND typeflag_cd = 'PA'
  AND agg_date >= @startedAt
ORDER BY agg_date DESC;

SELECT @Fullname AS c_fullname,
       @ConceptCd AS concept_cd,
       @RequiredNval AS required_nval,
       @expected AS expected_count,
       @actual AS supplemental_count,
       CASE WHEN @actual = @expected THEN 'PASS' ELSE 'FAIL' END AS test_result;

IF @actual IS NULL OR @actual <> @expected
    RAISERROR('Constrained fact totalnum validation failed.', 16, 1);

/*
Manual hierarchy check:
  - Run RunTotalnum with @demographics_mode = 'all'.
  - Inspect the selected leaf and its fact-only shortcut folders.
  - Eligible folder counts should be distinct-patient unions across ordinary
    and constrained descendants, not sums of child counts.
  - Mixed higher roots containing dimension-backed leaves intentionally retain
    their normal fast count.

Unsupported-shape check:
  - In a transaction, alter C_COLUMNNAME to a nonnumeric or additional SQL
    expression, rerun the constrained procedure, and confirm it reports that
    the row was skipped without executing the expression. Roll back afterward.
*/
