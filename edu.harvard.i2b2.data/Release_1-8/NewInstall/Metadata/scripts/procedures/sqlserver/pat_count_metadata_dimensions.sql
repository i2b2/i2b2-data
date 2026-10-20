-- MSSQL version
-- Shared metadata-driven patient/visit dimension counter.
-- PAT_COUNT_VISITS retains the legacy public interface and delegates to this procedure.
-- FastTotalnumAdditionalDimensions uses the patient scope for non-ACT demographics.

IF EXISTS ( SELECT *
            FROM sys.objects
            WHERE object_id = OBJECT_ID(N'PAT_COUNT_METADATA_DIMENSIONS')
              AND type IN (N'P', N'PC') )
DROP PROCEDURE PAT_COUNT_METADATA_DIMENSIONS;
GO

CREATE PROCEDURE [dbo].[PAT_COUNT_METADATA_DIMENSIONS] (
    @tabname varchar(255),
    @schemaName varchar(50),
    @dimensionScope varchar(20) = 'all',
    @typeflagCd varchar(3) = 'PD'
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sqlstr nvarchar(max),
            @concept varchar(1200),
            @facttablecolumn varchar(128),
            @dimensionTable varchar(128),
            @columnname varchar(128),
            @operator varchar(10),
            @dimcode varchar(1200),
            @predicate nvarchar(2600),
            @errorMessage nvarchar(4000),
            @scope varchar(20) = LOWER(ISNULL(NULLIF(@dimensionScope, ''), 'all')),
            @typeflag varchar(3) = UPPER(ISNULL(NULLIF(@typeflagCd, ''), 'PD'));

    IF @scope NOT IN ('all', 'patient', 'visit')
    BEGIN
        RAISERROR('Invalid dimension scope. Use all, patient, or visit.', 16, 1);
        RETURN;
    END;

    IF LEN(@typeflag) <> 2 OR LEFT(@typeflag, 1) <> 'P'
    BEGIN
        RAISERROR('Invalid typeflag code. Use a two-character patient count code beginning with P.', 16, 1);
        RETURN;
    END;

    IF OBJECT_ID('tempdb..#tnum_ontPatVisitDims') IS NOT NULL
        DROP TABLE #tnum_ontPatVisitDims;

    CREATE TABLE #tnum_ontPatVisitDims (
        c_fullname varchar(1200),
        c_basecode varchar(1200),
        c_facttablecolumn varchar(128),
        c_tablename varchar(128),
        c_columnname varchar(128),
        c_operator varchar(10),
        c_dimcode varchar(1200),
        numpats int NULL
    );

    SET @predicate = CASE @scope
        WHEN 'patient' THEN 'LOWER(c_tablename) = ''patient_dimension'''
        WHEN 'visit' THEN 'LOWER(c_tablename) = ''visit_dimension'''
        ELSE 'LOWER(c_tablename) IN (''patient_dimension'', ''visit_dimension'')'
    END;

    SET @sqlstr =
        'INSERT INTO #tnum_ontPatVisitDims ' +
        '(c_fullname, c_basecode, c_facttablecolumn, c_tablename, c_columnname, c_operator, c_dimcode) ' +
        'SELECT DISTINCT c_fullname, c_basecode, c_facttablecolumn, c_tablename, ' +
        'c_columnname, c_operator, c_dimcode FROM ' + @tabname +
        ' WHERE m_applied_path = ''@'' AND ' + @predicate;

    RAISERROR('dimension query: %s', 0, 1, @sqlstr) WITH NOWAIT;
    EXEC sp_executesql @sqlstr;

    IF EXISTS (SELECT 1 FROM #tnum_ontPatVisitDims)
    BEGIN
        DECLARE dimension_items CURSOR LOCAL FAST_FORWARD FOR
            SELECT c_fullname, c_facttablecolumn, c_tablename, c_columnname,
                   c_operator, c_dimcode
            FROM #tnum_ontPatVisitDims;

        OPEN dimension_items;
        FETCH NEXT FROM dimension_items
            INTO @concept, @facttablecolumn, @dimensionTable, @columnname,
                 @operator, @dimcode;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @predicate = NULL;

            IF LOWER(@operator) = 'like'
                SET @predicate = @operator + ' ''' + REPLACE(ISNULL(@dimcode, ''), '''', '''''') + '%''';
            ELSE IF LOWER(@operator) = 'in'
                SET @predicate = @operator + ' ' +
                    CASE WHEN LEFT(LTRIM(ISNULL(@dimcode, '')), 1) = '('
                         THEN @dimcode ELSE '(' + ISNULL(@dimcode, '') + ')' END;
            ELSE IF LOWER(@operator) = '='
                SET @predicate = @operator + ' ''' + REPLACE(ISNULL(@dimcode, ''), '''', '''''') + '''';
            ELSE
                SET @predicate = @operator +
                    CASE WHEN @dimcode IS NULL THEN ' NULL' ELSE ' ' + @dimcode END;

            SET @sqlstr =
                'UPDATE #tnum_ontPatVisitDims SET numpats = (' +
                'SELECT COUNT(DISTINCT patient_num) FROM ' +
                QUOTENAME(@schemaName) + '.' + QUOTENAME(@dimensionTable) +
                ' WHERE ' + QUOTENAME(@facttablecolumn) + ' IN (' +
                'SELECT ' + QUOTENAME(@facttablecolumn) + ' FROM ' +
                QUOTENAME(@schemaName) + '.' + QUOTENAME(@dimensionTable) +
                ' WHERE ' + QUOTENAME(@columnname) + ' ' + @predicate + ')) ' +
                'WHERE c_fullname = ''' + REPLACE(@concept, '''', '''''') +
                ''' AND numpats IS NULL';

            BEGIN TRY
                EXEC sp_executesql @sqlstr;
            END TRY
            BEGIN CATCH
                SET @errorMessage = ERROR_MESSAGE();
                RAISERROR('Skipping dimension item %s: %s', 0, 1, @concept, @errorMessage) WITH NOWAIT;
            END CATCH;

            FETCH NEXT FROM dimension_items
                INTO @concept, @facttablecolumn, @dimensionTable, @columnname,
                     @operator, @dimcode;
        END;

        CLOSE dimension_items;
        DEALLOCATE dimension_items;

        -- Preserve the legacy direct metadata update. Fast output subsequently
        -- refreshes these values from TOTALNUM, including explicit zero counts.
        SET @sqlstr =
            'UPDATE a SET c_totalnum = b.numpats FROM ' + @tabname +
            ' a INNER JOIN #tnum_ontPatVisitDims b ON a.c_fullname = b.c_fullname ' +
            'WHERE b.numpats > 0';
        EXEC sp_executesql @sqlstr;

        -- Use a full timestamp so supplemental rows inserted after PF rows
        -- deterministically take precedence during FastTotalnumOutput.
        INSERT INTO totalnum(c_fullname, agg_date, agg_count, typeflag_cd)
        SELECT c_fullname, GETDATE(), numpats, @typeflag
        FROM #tnum_ontPatVisitDims
        WHERE numpats IS NOT NULL;
    END;

    DROP TABLE #tnum_ontPatVisitDims;
END;
GO
