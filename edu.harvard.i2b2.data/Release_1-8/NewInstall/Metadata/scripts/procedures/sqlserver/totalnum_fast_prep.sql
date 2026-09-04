-----------------------------------------------------------------------------------------------------------------
-- This is all the preparatory work that must happen once when the ontology changes before running FastTotalnumRun.
-- create a view of distinct concept codes and patient nums (OBSFACT_PAIRS), a unified ontology (TNUM_ONTOLOGY) and a transitive closure table (CONCEPT_CLOSURE) 
-- by Darren Henderson (UKY) and Jeff Klann, PhD (MGB) 
-- Last updated: 02/2024
--
-- 1) Modify the obsfact_pairs view to include additional fact tables, if applicable.
-- 2) Make sure TABLE_ACCESS includes rows for ACT_VISIT and ACT_DEMO if you want the visit/demographics supplements.
-- 3) Run with: exec FastTotalnumPrep or exec FastTotalnumPrep 'dbo'
--       (Optionally you can specify the schemaname and source_mode: 'i2b2' or 'omop'.)
--
-- Visit and demographics ontology table names are resolved from TABLE_ACCESS using C_TABLE_CD = ACT_VISIT and ACT_DEMO.
-- Note that if you use more than one fact table, the obsfact_pairs view will need to be customized.
-----------------------------------------------------------------------------------------------------------------

IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'FastTotalnumPrep')
                    AND type IN ( N'P', N'PC' ) ) 
DROP PROCEDURE FastTotalnumPrep;
GO

CREATE PROCEDURE [dbo].[FastTotalnumPrep]  (@schemaname varchar(50) = 'dbo', @source_mode varchar(20) = 'i2b2') as --, @tablename varchar(50)='@') as

DECLARE @sqlstr NVARCHAR(4000);
DECLARE @sqltext NVARCHAR(4000);
DECLARE @sqlcurs NVARCHAR(4000);
DECLARE @startime datetime;
DECLARE @derived_facttablecolumn NVARCHAR(4000);
DECLARE @facttablecolumn_prefix NVARCHAR(4000);
DECLARE @source_mode_norm VARCHAR(20) = LOWER(ISNULL(NULLIF(@source_mode,''),'i2b2'));
DECLARE @VISIT_TABLE_REF VARCHAR(400) = '';
DECLARE @DEMO_TABLE_REF VARCHAR(400) = '';
DECLARE @VISIT_TABLE_SQL VARCHAR(500) = '';
DECLARE @DEMO_TABLE_SQL VARCHAR(500) = '';
DECLARE @TABLE_NAME VARCHAR(400) = '';
DECLARE @PATH VARCHAR(700) = '';
DECLARE @SQL VARCHAR(MAX) = '';

BEGIN

IF @source_mode_norm NOT IN ('i2b2','omop')
BEGIN
  RAISERROR('Invalid source_mode. Use i2b2 or omop.', 16, 1);
  RETURN;
END

SELECT @VISIT_TABLE_REF = ISNULL(MAX(C_TABLE_NAME),'')
FROM TABLE_ACCESS
WHERE UPPER(C_TABLE_CD) = 'ACT_VISIT';

SELECT @DEMO_TABLE_REF = ISNULL(MAX(C_TABLE_NAME),'')
FROM TABLE_ACCESS
WHERE UPPER(C_TABLE_CD) = 'ACT_DEMO';

IF NULLIF(@VISIT_TABLE_REF,'') IS NULL
  PRINT 'Skipping ACT_VISIT ontology supplement: TABLE_ACCESS has no row for C_TABLE_CD = ACT_VISIT.';
ELSE
  SET @VISIT_TABLE_SQL = CASE WHEN CHARINDEX('.', @VISIT_TABLE_REF) > 0 THEN @VISIT_TABLE_REF ELSE @schemaname + '.' + @VISIT_TABLE_REF END;

IF NULLIF(@DEMO_TABLE_REF,'') IS NULL
  PRINT 'Skipping ACT_DEMO ontology supplement: TABLE_ACCESS has no row for C_TABLE_CD = ACT_DEMO.';
ELSE
  SET @DEMO_TABLE_SQL = CASE WHEN CHARINDEX('.', @DEMO_TABLE_REF) > 0 THEN @DEMO_TABLE_REF ELSE @schemaname + '.' + @DEMO_TABLE_REF END;

/* 03-22: DWH - build concept patient table once here, rather than in each call to count */
/* 05-23: jgk - I use a view here which is obviously slow but doesn't overflow the temp table on big operations. */

if object_id(N'OBSFACT_PAIRS') is not null exec('drop view OBSFACT_PAIRS');

--RAISERROR(N'Building OBSFACT_PAIRS', 1, 1) with nowait;

-- Modify this view as needed to include additional fact tables. e.g.,
--   CREATE VIEW OBSFACT_PAIRS AS SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM observation_fact
--     UNION ALL SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM Derived_fact
IF @source_mode_norm = 'omop'
BEGIN
  EXEC('CREATE VIEW OBSFACT_PAIRS AS
    (SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM CONDITION_NS_VIEW) UNION ALL
    (SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM CONDITION_VIEW) UNION ALL
    (SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM DRUG_NS_VIEW) UNION ALL
    (SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM DEVICE_VIEW) UNION ALL
    (SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM DEVICE_NS_VIEW) UNION ALL
    (SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM DRUG_VIEW) UNION ALL
    (SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM MEASUREMENT_NS_VIEW) UNION ALL
    (SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM MEASUREMENT_VIEW) UNION ALL
    (SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM OBSERVATION_NS_VIEW) UNION ALL
    (SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM OBSERVATION_VIEW) UNION ALL
    (SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM PROCEDURE_NS_VIEW) UNION ALL
    (SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM PROCEDURE_VIEW) UNION ALL
    (SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM VISIT_NS_VIEW);')
END
ELSE
BEGIN
  EXEC('CREATE VIEW OBSFACT_PAIRS AS SELECT DISTINCT PATIENT_NUM, CONCEPT_CD FROM observation_fact;')
END


-- This version creates pairs as a table, which causes overflow of temp tables
/* CREATE TABLE WITH CONSTRAINTS AND INSERT INTO WITH(TABLOCK) = PARALLEL - MUCH FAST */
/*CREATE TABLE OBSFACT_PAIRS (
PATIENT_NUM INT NOT NULL, 
CONCEPT_CD VARCHAR(50) NOT NULL,
CONSTRAINT PKCONPAT PRIMARY KEY (CONCEPT_CD, PATIENT_NUM)
)

SET @sqlstr = 'insert into OBSFACT_PAIRS with(tablock) (concept_cd, patient_num)
  select distinct concept_cd, patient_num
	from '+@schemaName + '.observation_fact f with (nolock)'
EXEC sp_executesql @sqlstr

CREATE INDEX IDX_OFP_CONCEPT ON OBSFACT_PAIRS (CONCEPT_CD);*/

EXEC EndTime @startime,'observation_fact','pairs';
    set @startime = getdate();

/************************************************/
/* CREATE MASTER ONTOLOGY TABLE FROM METADATA   */
/* SITES CAN CUSTOMIZE THIS BLOCK OF CODE TO    */ 
/* INCLUDE ANY SITE CUSTOM ONTOLOGY ITEMS       */
/************************************************/ 

if object_id(N'TNUM_ONTOLOGY') is not null exec('drop table TNUM_ONTOLOGY');

CREATE TABLE TNUM_ONTOLOGY (
  [PATH_NUM] [int] IDENTITY(1,1) PRIMARY KEY,
	[C_HLEVEL] [int] NOT NULL,
	[C_FULLNAME] [varchar](700) NOT NULL,
  [C_SYNONYM_CD] [char](1) NOT NULL,
	[C_VISUALATTRIBUTES] [char](3) NOT NULL,
	[C_BASECODE] [varchar](50) NULL,
	[C_FACTTABLECOLUMN] [varchar](50) NOT NULL,
	[C_TABLENAME] [varchar](50) NOT NULL,
	[C_COLUMNNAME] [varchar](50) NOT NULL,
	[C_COLUMNDATATYPE] [varchar](50) NOT NULL,
	[C_OPERATOR] [varchar](10) NOT NULL,
	[C_DIMCODE] [varchar](700) NOT NULL,
	[M_APPLIED_PATH] [varchar](900) NOT NULL
) ON [PRIMARY];

/* LOAD TNUM_ONTOLOGY*/

DECLARE CUR CURSOR FOR
  SELECT C_TABLE_NAME, CONCAT(C_FULLNAME,'%') AS [PATH]
  FROM TABLE_ACCESS
  --WHERE C_TABLE_NAME=@metadataTable -- DO JUST 1 ONTOLOBY
  -- (FOR TESTING) where c_table_name='ACT_ICD10CM_DX_V4'
  WHERE C_TABLE_CD NOT IN ('ACT_DEMO','ACT_VISIT') /* THESE ARE HANDLED BY CONVERTING DEMOGRAPHICS AND VISIT DETAILS INTO FACTS IN A LATER STEP */
   AND C_VISUALATTRIBUTES LIKE '%A%'
   
OPEN CUR
FETCH NEXT FROM CUR
  INTO @TABLE_NAME, @PATH

WHILE @@FETCH_STATUS=0
BEGIN
  SET @SQL = CONCAT('INSERT INTO TNUM_ONTOLOGY (C_HLEVEL, C_FULLNAME, C_SYNONYM_CD, C_VISUALATTRIBUTES, C_BASECODE, C_FACTTABLECOLUMN, C_TABLENAME, C_COLUMNNAME, C_COLUMNDATATYPE, C_OPERATOR, C_DIMCODE, M_APPLIED_PATH)
              SELECT DISTINCT C_HLEVEL, C_FULLNAME, C_SYNONYM_CD, C_VISUALATTRIBUTES, C_BASECODE, C_FACTTABLECOLUMN, C_TABLENAME, C_COLUMNNAME, C_COLUMNDATATYPE, C_OPERATOR, C_DIMCODE, M_APPLIED_PATH
              FROM '
              ,@TABLE_NAME
              ,' WHERE C_FULLNAME LIKE '''
              ,@PATH
              ,'''')
  PRINT @SQL
  EXEC(@SQL)

  FETCH NEXT FROM CUR
    INTO @TABLE_NAME, @PATH

END

CLOSE CUR
DEALLOCATE CUR

/* 20250620 - DWH: SPECIAL CASE TO ENSURE VISIT TYPE ONTOLOGY IS INCLUDED FROM ACT_VISIT */
/* In FastTotalnumCount the INOUT_CD field from visit dimension is pulled as a fact keypair with an override concept_cd prefix of visit_dimension|inout_cd: */
IF NULLIF(@VISIT_TABLE_REF,'') IS NOT NULL
BEGIN
SET @SQL = CONCAT('INSERT INTO TNUM_ONTOLOGY (C_HLEVEL, C_FULLNAME, C_SYNONYM_CD, C_VISUALATTRIBUTES, C_BASECODE, C_FACTTABLECOLUMN, C_TABLENAME, C_COLUMNNAME, C_COLUMNDATATYPE, C_OPERATOR, C_DIMCODE, M_APPLIED_PATH)
SELECT DISTINCT C_HLEVEL, C_FULLNAME, C_SYNONYM_CD, C_VISUALATTRIBUTES, CONCAT(''visit_dimension|inout_cd:'',C_BASECODE), C_FACTTABLECOLUMN, C_TABLENAME, C_COLUMNNAME, C_COLUMNDATATYPE, C_OPERATOR, C_DIMCODE, M_APPLIED_PATH
FROM ', @VISIT_TABLE_SQL, '
WHERE C_FULLNAME LIKE ''\ACT\Visit Details\Visit type\%''
UNION

/* 20250620 - DWH: SPECIAL CASE TO ENSURE VISIT LENGTH OF STAY ONTOLOGY IS INCLUDED FROM ACT_VISIT */
/* In FastTotalnumCount the LENGTH_OF_STAY field from visit dimension is pulled as a fact keypair with an override concept_cd prefix of visit_dimension|length_of_stay: */

SELECT DISTINCT C_HLEVEL, C_FULLNAME, C_SYNONYM_CD, C_VISUALATTRIBUTES, CONCAT(''visit_dimension|length_of_stay:'',C_BASECODE), C_FACTTABLECOLUMN, C_TABLENAME, C_COLUMNNAME, C_COLUMNDATATYPE, C_OPERATOR, C_DIMCODE, M_APPLIED_PATH
FROM ', @VISIT_TABLE_SQL, '
WHERE C_FULLNAME LIKE ''\ACT\Visit Details\Length of Stay\%''')
PRINT @SQL
EXEC(@SQL)

/* 20250620 - DWH */
/* Ensure root node for Visit Details exists for closure */
SET @SQL = CONCAT('INSERT INTO TNUM_ONTOLOGY (C_HLEVEL, C_FULLNAME, C_SYNONYM_CD, C_VISUALATTRIBUTES, C_BASECODE, C_FACTTABLECOLUMN, C_TABLENAME, C_COLUMNNAME, C_COLUMNDATATYPE, C_OPERATOR, C_DIMCODE, M_APPLIED_PATH)
SELECT DISTINCT C_HLEVEL, C_FULLNAME, C_SYNONYM_CD, C_VISUALATTRIBUTES, CONCAT(''visit_dimension|inout_cd:'',C_BASECODE) AS C_BASECODE, C_FACTTABLECOLUMN, C_TABLENAME, C_COLUMNNAME, C_COLUMNDATATYPE, C_OPERATOR, C_DIMCODE, M_APPLIED_PATH
FROM ', @VISIT_TABLE_SQL, '
WHERE C_FULLNAME = ''\ACT\Visit Details\''')
PRINT @SQL
EXEC(@SQL)
END

/* THIS ONTOLOGY WILL BE USED TO CONVERT PATIENT DATA IN THE PATIENT_DIMENSION TABLE INTO FACTS THAT CAN BE AGGREGATED IN THE SAME FASHION AS THE FACT(S) TABLES */
IF NULLIF(@VISIT_TABLE_REF,'') IS NOT NULL OR NULLIF(@DEMO_TABLE_REF,'') IS NOT NULL
BEGIN
SET @SQL = ';WITH CTE_BASECODE_OVERRIDE AS (
SELECT ''\ACT\Visit Details\Length of stay\ > 10 days\'' AS c_fullname, ''visit_dimension|length_of_stay:>10'' c_basecode union all
SELECT ''\ACT\Visit Details\Length of stay\'' AS c_fullname, ''visit_dimension|length_of_stay:>0'' c_basecode union all
SELECT ''\ACT\Visit Details\Length of stay\'' AS c_fullname, ''visit_dimension|length_of_stay:>0'' c_basecode union all
SELECT ''\ACT\Visit Details\Age at visit\>= 65 years old\'' AS c_fullname, ''VIS|AGE:>=65'' AS c_basecode union all
SELECT ''\ACT\Visit Details\Age at visit\>= 85 years old\'' AS c_fullname, ''VIS|AGE:>=85'' AS c_basecode union all
SELECT ''\ACT\Visit Details\Age at visit\>= 90 years old\'' AS c_fullname, ''VIS|AGE:>=90'' AS c_basecode union all
SELECT ''\ACT\Demographics\Age\>= 90 years old\'' AS c_fullname, ''DEM|AGE:>=90'' AS c_basecode union all
SELECT ''\ACT\Demographics\Age\>= 85 years old\'' AS c_fullname, ''DEM|AGE:>=85'' AS c_basecode union all
SELECT ''\ACT\Demographics\Age\>= 65 years old\'' AS c_fullname, ''DEM|AGE:>=65'' AS c_basecode union all
SELECT ''\ACT\Demographics\Age\>= 18 years old\'' AS c_fullname, ''DEM|AGE:>=18'' AS c_basecode union all
SELECT ''\ACT\Demographics\Age\< 18 years old\''  AS c_fullname, ''DEM|AGE:<18''  AS c_basecode
)
INSERT INTO TNUM_ONTOLOGY (C_HLEVEL, M.C_FULLNAME, C_SYNONYM_CD, C_VISUALATTRIBUTES, C_BASECODE, C_FACTTABLECOLUMN, C_TABLENAME, C_COLUMNNAME, C_COLUMNDATATYPE, C_OPERATOR, C_DIMCODE, M_APPLIED_PATH)
SELECT DISTINCT c_hlevel, M.c_fullname, c_synonym_cd, c_visualattributes, COALESCE(BO.c_basecode, M.c_basecode) AS c_basecode, c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, c_operator, c_dimcode, m_applied_path
FROM ('

IF NULLIF(@VISIT_TABLE_REF,'') IS NOT NULL
  SET @SQL = CONCAT(@SQL, '
SELECT c_hlevel, c_fullname, c_synonym_cd, c_visualattributes, case when charindex('':'',c_basecode)=0 and nullif(c_basecode,'''') is not null
        then concat(c_tablename,''|'',c_columnname,'':'',c_basecode)
        /* override ACT age at visit FACT based c_basecode so the query can pull AGE TODAY simultaneously below in the next step
            since its c_basecode is also DEM|AGE prefixed */
        when c_fullname like ''\ACT\Visit Details\Age at visit\%'' then replace(c_basecode,''DEM|'',''VIS|'')
        else c_basecode
        end as c_basecode, c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, c_operator, c_dimcode, m_applied_path
FROM ', @VISIT_TABLE_SQL)

IF NULLIF(@VISIT_TABLE_REF,'') IS NOT NULL AND NULLIF(@DEMO_TABLE_REF,'') IS NOT NULL
  SET @SQL = CONCAT(@SQL, '
UNION')

IF NULLIF(@DEMO_TABLE_REF,'') IS NOT NULL
  SET @SQL = CONCAT(@SQL, '
SELECT c_hlevel, c_fullname, c_synonym_cd, c_visualattributes, case when charindex('':'',c_basecode)=0 and nullif(c_basecode,'''') is not null
                        then concat(c_tablename,''|'',c_columnname,'':'',c_basecode)
                        else c_basecode
                        end as c_basecode, c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, c_operator, c_dimcode, m_applied_path
FROM ', @DEMO_TABLE_SQL)

SET @SQL = CONCAT(@SQL, '
)M LEFT JOIN CTE_BASECODE_OVERRIDE BO
  ON M.c_fullname = BO.c_fullname
where C_FACTTABLECOLUMN != ''concept_cd'';')
PRINT @SQL
EXEC(@SQL)
END
/* SITE SPECIFIC ONTOLOGY ITEMS CAN BE ADDED HERE -- REQUIRED FOR usp [FastTotalNumCount] TO AGGREGATE SITE CUSTOM CONCEPTS
EX: 
UNION
SELECT c_hlevel, c_fullname, c_synonym_cd, c_visualattributes, case when charindex(':',c_basecode)=0 and nullif(c_basecode,'') is not null 
                        then concat(c_tablename,'|',c_columnname,':',c_basecode) 
                        else c_basecode 
                        end as c_basecode, c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, c_operator, c_dimcode, m_applied_path
FROM DBO.<SITE_ONTOLOGY_TABLE>
*/

/* END TNUM_ONTOLOGY LOAD */

CREATE INDEX IDX_ONT_ITEMS ON TNUM_ONTOLOGY (C_FULLNAME) INCLUDE (C_HLEVEL, C_BASECODE);

EXEC EndTime @startime,'ontology','ontology';
    set @startime = getdate(); 

/* BUILD CLOSURE TABLE */

if object_id(N'CONCEPT_CLOSURE') is not null drop table CONCEPT_CLOSURE

CREATE TABLE CONCEPT_CLOSURE (
  ANCESTOR INT,
  DESCENDANT INT,
  C_BASECODE VARCHAR(50),
  PRIMARY KEY CLUSTERED (ANCESTOR,DESCENDANT)
) 

/* RECURSIVE CTE TO CONVERT PATHS TO ANCESTOR/DESCENDANT KEY PAIRS FOR CLOSURE TABLE */
;WITH CONCEPTS (C_FULLNAME, C_HLEVEL, C_BASECODE, DESCENDANT) AS (
SELECT C_FULLNAME, CAST(C_HLEVEL AS INT) C_HLEVEL, C_BASECODE, PATH_NUM AS DESCENDANT
FROM TNUM_ONTOLOGY
WHERE ISNULL(C_FULLNAME,'') <> '' 
  AND ((C_VISUALATTRIBUTES='LA' AND ISNULL(C_BASECODE,'') <> '')  -- 20250620 - DWH: fixes ontology skip issues in concept_closure
        OR C_VISUALATTRIBUTES = 'FA')
UNION ALL
SELECT LEFT(C_FULLNAME, LEN(C_FULLNAME)-CHARINDEX('\', RIGHT(REVERSE(C_FULLNAME), LEN(C_FULLNAME)-1))) AS C_FULLNAME
  , CAST(C_HLEVEL-1 AS INT) C_HLEVEL, C_BASECODE, DESCENDANT
FROM CONCEPTS
WHERE CONCEPTS.C_HLEVEL>0
)
INSERT INTO CONCEPT_CLOSURE(ANCESTOR,DESCENDANT,C_BASECODE)
SELECT DISTINCT O.PATH_NUM AS ANCESTOR, C.DESCENDANT, ISNULL(C.C_BASECODE,'') C_BASECODE
FROM CONCEPTS C
  INNER JOIN TNUM_ONTOLOGY O
    ON C.C_FULLNAME=O.C_FULLNAME
OPTION(MAXRECURSION 0);

CREATE INDEX IDX_DESCN ON CONCEPT_CLOSURE (DESCENDANT);

EXEC EndTime @startime,'ontology','closure';
    set @startime = getdate();

END;
