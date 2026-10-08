-----------------------------------------------------------------------------------------------------------------
-- Correct fast totalnum counts for ontology leaves that add a numeric fact-value
-- constraint through C_COLUMNNAME, for example:
--   C_FACTTABLECOLUMN = concept_cd
--   C_TABLENAME       = concept_dimension
--   C_COLUMNNAME      = nval_num = 1 AND concept_cd
--
-- Only this strict, numeric constraint form is recognized. Metadata expressions
-- are parsed as data and are never executed as SQL.
--
-- The procedure rebuilds fact-only hierarchy branches containing a supported
-- constraint. Ordinary descendants continue to use OBSFACT_PAIRS; constrained
-- descendants read OBSERVATION_FACT with the required NVAL_NUM. Mixed ancestors
-- containing patient/visit/provider dimensions retain their existing fast count.
-----------------------------------------------------------------------------------------------------------------

IF EXISTS ( SELECT *
            FROM sys.objects
            WHERE object_id = OBJECT_ID(N'FastTotalnumConstrainedFacts')
              AND type IN (N'P', N'PC') )
DROP PROCEDURE FastTotalnumConstrainedFacts;
GO

CREATE PROCEDURE [dbo].[FastTotalnumConstrainedFacts] (
    @schemaname varchar(50) = 'dbo',
    @tablename varchar(255) = '@',
    @source_mode varchar(20) = 'i2b2'
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @metadataTable varchar(255),
            @sqlstr nvarchar(max),
            @factObject nvarchar(300),
            @factObjectName nvarchar(300),
            @candidateCount int,
            @parsedCount int,
            @preparedCount int,
            @invalidCount int,
            @missingCount int,
            @errorMessage nvarchar(4000),
            @sourceModeNorm varchar(20) = LOWER(ISNULL(NULLIF(@source_mode, ''), 'i2b2'));

    IF @sourceModeNorm <> 'i2b2'
    BEGIN
        RAISERROR('Skipping constrained fact totals: only the i2b2 OBSERVATION_FACT source is currently supported.', 0, 1) WITH NOWAIT;
        RETURN;
    END;

    SET @factObjectName = @schemaname + '.observation_fact';
    SET @factObject = QUOTENAME(@schemaname) + '.' + QUOTENAME('observation_fact');
    IF OBJECT_ID(@factObjectName, 'U') IS NULL AND OBJECT_ID(@factObjectName, 'V') IS NULL
    BEGIN
        RAISERROR('Skipping constrained fact totals: %s is not visible.', 0, 1, @factObject) WITH NOWAIT;
        RETURN;
    END;

    IF OBJECT_ID('tempdb..#tnumConstraintCandidates') IS NOT NULL DROP TABLE #tnumConstraintCandidates;
    IF OBJECT_ID('tempdb..#tnumParsedConstraints') IS NOT NULL DROP TABLE #tnumParsedConstraints;
    IF OBJECT_ID('tempdb..#tnumPreparedConstraints') IS NOT NULL DROP TABLE #tnumPreparedConstraints;
    IF OBJECT_ID('tempdb..#tnumAffectedAncestors') IS NOT NULL DROP TABLE #tnumAffectedAncestors;
    IF OBJECT_ID('tempdb..#tnumAffectedDescendants') IS NOT NULL DROP TABLE #tnumAffectedDescendants;
    IF OBJECT_ID('tempdb..#tnumMatchedDescendants') IS NOT NULL DROP TABLE #tnumMatchedDescendants;

    CREATE TABLE #tnumConstraintCandidates (
        metadata_table varchar(255) NOT NULL,
        c_fullname varchar(1200) NOT NULL,
        c_basecode varchar(50) NOT NULL,
        constraint_expression varchar(128) NOT NULL,
        normalized_expression varchar(128) NULL,
        value_text varchar(80) NULL
    );

    DECLARE metadata_tables CURSOR LOCAL FAST_FORWARD FOR
        SELECT DISTINCT ta.c_table_name
        FROM table_access ta
        WHERE ta.c_visualattributes LIKE '%A%'
          AND (@tablename = '@' OR ta.c_table_name = @tablename)
          AND NOT EXISTS (
              SELECT 1
              FROM table_access act
              WHERE UPPER(act.c_table_cd) = 'ACT_DEMO'
                AND act.c_table_name = ta.c_table_name
          );

    OPEN metadata_tables;
    FETCH NEXT FROM metadata_tables INTO @metadataTable;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sqlstr =
            'INSERT INTO #tnumConstraintCandidates ' +
            '(metadata_table, c_fullname, c_basecode, constraint_expression) ' +
            'SELECT DISTINCT @metadataTable, c_fullname, c_basecode, c_columnname ' +
            'FROM ' + @metadataTable + ' ' +
            'WHERE m_applied_path = ''@'' ' +
            'AND c_visualattributes LIKE ''L%'' ' +
            'AND c_visualattributes LIKE ''%A%'' ' +
            'AND LOWER(c_facttablecolumn) = ''concept_cd'' ' +
            'AND LOWER(c_tablename) = ''concept_dimension'' ' +
            'AND LOWER(c_operator) = ''like'' ' +
            'AND NULLIF(c_basecode, '''') IS NOT NULL ' +
            'AND LOWER(c_columnname) LIKE ''%nval_num%'' ' +
            'AND LOWER(c_columnname) LIKE ''%concept_cd%''';

        BEGIN TRY
            EXEC sp_executesql @sqlstr, N'@metadataTable varchar(255)', @metadataTable;
        END TRY
        BEGIN CATCH
            SET @errorMessage = ERROR_MESSAGE();
            RAISERROR('Skipping constrained metadata table %s: %s', 0, 1, @metadataTable, @errorMessage) WITH NOWAIT;
        END CATCH;

        FETCH NEXT FROM metadata_tables INTO @metadataTable;
    END;

    CLOSE metadata_tables;
    DEALLOCATE metadata_tables;

    SELECT @candidateCount = COUNT(*) FROM #tnumConstraintCandidates;
    IF @candidateCount = 0
    BEGIN
        RAISERROR('No constrained fact ontology entries found.', 0, 1) WITH NOWAIT;
        RETURN;
    END;

    UPDATE #tnumConstraintCandidates
    SET normalized_expression = LOWER(LTRIM(RTRIM(
        REPLACE(REPLACE(REPLACE(constraint_expression, CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')
    )));

    WHILE EXISTS (SELECT 1 FROM #tnumConstraintCandidates WHERE normalized_expression LIKE '%  %')
        UPDATE #tnumConstraintCandidates
        SET normalized_expression = REPLACE(normalized_expression, '  ', ' ')
        WHERE normalized_expression LIKE '%  %';

    UPDATE #tnumConstraintCandidates
    SET value_text = LTRIM(RTRIM(SUBSTRING(
        normalized_expression,
        LEN('nval_num = ') + 1,
        LEN(normalized_expression) - LEN('nval_num = ') - LEN(' and concept_cd')
    )))
    WHERE LEFT(normalized_expression, LEN('nval_num = ')) = 'nval_num = '
      AND RIGHT(normalized_expression, LEN(' and concept_cd')) = ' and concept_cd'
      AND LEN(normalized_expression) > LEN('nval_num = ') + LEN(' and concept_cd');

    CREATE TABLE #tnumParsedConstraints (
        metadata_table varchar(255) NOT NULL,
        c_fullname varchar(1200) NOT NULL,
        concept_cd varchar(50) NOT NULL,
        required_nval decimal(38, 10) NOT NULL
    );

    INSERT INTO #tnumParsedConstraints(metadata_table, c_fullname, concept_cd, required_nval)
    SELECT DISTINCT metadata_table, c_fullname, c_basecode,
           TRY_CONVERT(decimal(38, 10), value_text)
    FROM #tnumConstraintCandidates
    WHERE TRY_CONVERT(decimal(38, 10), value_text) IS NOT NULL;

    SELECT @parsedCount = COUNT(*) FROM #tnumParsedConstraints;
    SET @invalidCount = @candidateCount - @parsedCount;
    IF @invalidCount > 0
        RAISERROR('Skipped %d constrained fact entries whose C_COLUMNNAME was not the supported nval_num = number AND concept_cd form.', 0, 1, @invalidCount) WITH NOWAIT;

    CREATE TABLE #tnumPreparedConstraints (
        path_num int NOT NULL,
        concept_cd varchar(50) NOT NULL,
        required_nval decimal(38, 10) NOT NULL,
        PRIMARY KEY (path_num, concept_cd, required_nval)
    );

    INSERT INTO #tnumPreparedConstraints(path_num, concept_cd, required_nval)
    SELECT DISTINCT o.path_num, p.concept_cd, p.required_nval
    FROM #tnumParsedConstraints p
    JOIN tnum_ontology o
      ON o.c_fullname = p.c_fullname
     AND o.c_basecode = p.concept_cd
     AND o.c_visualattributes LIKE 'L%';

    SELECT @preparedCount = COUNT(*) FROM #tnumPreparedConstraints;
    IF @preparedCount = 0
    BEGIN
        RAISERROR('Constrained fact entries are not present in TNUM_ONTOLOGY. Rerun FastTotalnumPrep after changing the ontology.', 0, 1) WITH NOWAIT;
        RETURN;
    END;

    IF @preparedCount < @parsedCount
    BEGIN
        SET @missingCount = @parsedCount - @preparedCount;
        RAISERROR('%d constrained fact entries were not found in TNUM_ONTOLOGY; rerun FastTotalnumPrep to include current ontology rows.', 0, 1, @missingCount) WITH NOWAIT;
    END

    CREATE TABLE #tnumAffectedAncestors (
        path_num int NOT NULL PRIMARY KEY
    );

    INSERT INTO #tnumAffectedAncestors(path_num)
    SELECT DISTINCT cc.ancestor
    FROM concept_closure cc
    JOIN #tnumPreparedConstraints r ON r.path_num = cc.descendant
    WHERE NOT EXISTS (
        SELECT 1
        FROM concept_closure branch
        JOIN tnum_ontology leaf ON leaf.path_num = branch.descendant
        WHERE branch.ancestor = cc.ancestor
          AND leaf.c_visualattributes LIKE 'L%'
          AND (
              LOWER(ISNULL(leaf.c_facttablecolumn, '')) <> 'concept_cd'
              OR LOWER(ISNULL(leaf.c_tablename, '')) <> 'concept_dimension'
          )
    )
      AND NOT EXISTS (
        SELECT 1
        FROM concept_closure branch
        JOIN tnum_ontology leaf ON leaf.path_num = branch.descendant
        JOIN #tnumConstraintCandidates candidate
          ON candidate.c_fullname = leaf.c_fullname
         AND candidate.c_basecode = leaf.c_basecode
        WHERE branch.ancestor = cc.ancestor
          AND NOT EXISTS (
              SELECT 1
              FROM #tnumPreparedConstraints supported
              WHERE supported.path_num = leaf.path_num
          )
    );

    IF NOT EXISTS (SELECT 1 FROM #tnumAffectedAncestors)
    BEGIN
        RAISERROR('No prepared constrained paths were found in CONCEPT_CLOSURE. Rerun FastTotalnumPrep after changing the ontology.', 0, 1) WITH NOWAIT;
        RETURN;
    END;

    CREATE TABLE #tnumAffectedDescendants (
        path_num int NOT NULL PRIMARY KEY
    );

    INSERT INTO #tnumAffectedDescendants(path_num)
    SELECT DISTINCT cc.descendant
    FROM concept_closure cc
    JOIN #tnumAffectedAncestors a ON a.path_num = cc.ancestor
    JOIN tnum_ontology o ON o.path_num = cc.descendant
    WHERE o.c_visualattributes LIKE 'L%'
      AND NULLIF(o.c_basecode, '') IS NOT NULL;

    CREATE TABLE #tnumMatchedDescendants (
        patient_num int NOT NULL,
        path_num int NOT NULL,
        PRIMARY KEY (patient_num, path_num)
    );

    -- Ordinary leaves in an affected branch retain the standard fast matching.
    INSERT INTO #tnumMatchedDescendants(patient_num, path_num)
    SELECT DISTINCT f.patient_num, o.path_num
    FROM obsfact_pairs f
    JOIN tnum_ontology o ON o.c_basecode = f.concept_cd
    JOIN #tnumAffectedDescendants d ON d.path_num = o.path_num
    WHERE NOT EXISTS (
        SELECT 1 FROM #tnumPreparedConstraints r WHERE r.path_num = o.path_num
    );

    -- Supported constrained leaves match their exact concept code and numeric value.
    SET @sqlstr =
        'INSERT INTO #tnumMatchedDescendants(patient_num, path_num) ' +
        'SELECT DISTINCT f.patient_num, r.path_num ' +
        'FROM ' + @factObject + ' f ' +
        'JOIN #tnumPreparedConstraints r ' +
        '  ON r.concept_cd = f.concept_cd ' +
        ' AND r.required_nval = f.nval_num ' +
        'WHERE f.patient_num IS NOT NULL ' +
        'AND NOT EXISTS (SELECT 1 FROM #tnumMatchedDescendants m ' +
        '                WHERE m.patient_num = f.patient_num AND m.path_num = r.path_num)';
    EXEC sp_executesql @sqlstr;

    -- PA rows are inserted after PF, so all-mode output uses these corrected branch counts.
    INSERT INTO totalnum(c_fullname, agg_count, agg_date, typeflag_cd)
    SELECT o.c_fullname, COUNT(DISTINCT m.patient_num), GETDATE(), 'PA'
    FROM #tnumAffectedAncestors a
    JOIN tnum_ontology o ON o.path_num = a.path_num
    LEFT JOIN concept_closure cc ON cc.ancestor = a.path_num
    LEFT JOIN #tnumMatchedDescendants m ON m.path_num = cc.descendant
    GROUP BY o.c_fullname;

    RAISERROR('Counted %d prepared constrained fact entries and rebuilt their eligible fact-only hierarchy branches.', 0, 1, @preparedCount) WITH NOWAIT;

    DROP TABLE #tnumMatchedDescendants;
    DROP TABLE #tnumAffectedDescendants;
    DROP TABLE #tnumAffectedAncestors;
    DROP TABLE #tnumPreparedConstraints;
    DROP TABLE #tnumParsedConstraints;
    DROP TABLE #tnumConstraintCandidates;
END;
GO
