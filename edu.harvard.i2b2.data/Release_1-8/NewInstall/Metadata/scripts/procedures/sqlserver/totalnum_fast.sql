-----------------------------------------------------------------------------------------------------------------
-- Totalnum patient counting script refactored - speed improvement, support for ACT-OMOP. 
--   This version by Darren Henderson (DARREN.HENDERSON@UKY.EDU) and Jeff Klann, PhD.
--   Based on code by Griffin Weber, Jeff Klann, Mike Mendis, Lori Phillips, Jeff Green, and Darren Henderson.

--   NOTE: ONTOLOGY TABLE NAMES CORRESPONDING TO PATIENT/VISIT DIMENSION ARE HARDCODED. */   
-- Last updated: July 2023
-----------------------------------------------------------------------------------------------------------------
/* SET TARGET DATABASE */
--USE I2B2ACT
--GO


/****************************************************************/
/* BASED ON ACT V4 ONTOLOGY                                     */
/* PATHS FROM TABLE_ACCESS FOR MANAGING MULTITABLE ONTOLOGY     */
/* SITE MAY CUSTOMIZE THIS STEP TO FULLY CAPTURE THEIR ONTOLOGY */
/****************************************************************/

--DROP PROCEDURE IF EXISTS PAT_COUNT_FAST;
--GO

IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'FastTotalnumCount')
                    AND type IN ( N'P', N'PC' ) ) 
DROP PROCEDURE FastTotalnumCount;
GO

CREATE PROCEDURE [dbo].[FastTotalnumCount]  

AS BEGIN
declare @sqlstr nvarchar(4000)
declare @startime datetime

set @startime = getdate(); 

/* CLEAR OUT TEMP OBJECTS FROM PREVIOUS RUN */
--DROP TABLE IF EXISTS #ONTOLOGY;
--DROP TABLE IF EXISTS #CONCEPT_CLOSURE;
--DROP TABLE IF EXISTS #PV_FACT_PAIRS;

/********************************************/


/* BUILD PAT/VIS DIM FEATURES AS FACT TUPLES */

CREATE TABLE #PV_FACT_PAIRS (PATIENT_NUM INT, CONCEPT_CD VARCHAR(50), PRIMARY KEY (PATIENT_NUM, CONCEPT_CD));

;WITH PATIENT_VISIT_PRELIM AS (
SELECT P.PATIENT_NUM
  , FLOOR(DATEDIFF(DD,P.BIRTH_DATE,GETDATE())/365.25) AS AGE_TODAY_NUM
  , CONCAT('DEM|AGE:'
      , CASE WHEN FLOOR(DATEDIFF(DD,P.BIRTH_DATE,GETDATE())/365.25)>=3 /* AFTER 3YO AGE IS INT */
             THEN CAST(FLOOR(DATEDIFF(DD,P.BIRTH_DATE,GETDATE())/365.25) AS VARCHAR(5)) 
             /* UNDER 3 AGE IS YR + NUM MON = DATEDIFF MO/12 || DATEDIFF MO%12 */
             ELSE CONCAT(CAST(DATEDIFF(MM,P.BIRTH_DATE,GETDATE())/12 AS VARCHAR(5)),'.',CAST(DATEDIFF(MM,P.BIRTH_DATE,GETDATE())%12 AS VARCHAR(5)))
             END) AS AGE_TODAY_CHAR
  , FLOOR(DATEDIFF(DD,P.BIRTH_DATE,V.START_DATE)/365.25) AS AGE_VISIT_NUM
  , CONCAT('VIS|AGE:'
      , CASE WHEN FLOOR(DATEDIFF(DD,P.BIRTH_DATE,V.START_DATE)/365.25) >=3 /* AFTER 3YO AGE IS INT */
             THEN CAST(FLOOR(DATEDIFF(DD,P.BIRTH_DATE,V.START_DATE)/365.25) AS VARCHAR(5))
            /* UNDER 3 AGE IS YR + NUM MON = DATEDIFF MO/12 || DATEDIFF MO%12 */
             ELSE CONCAT(CAST(DATEDIFF(MM,P.BIRTH_DATE,V.START_DATE)/12 AS VARCHAR(5)),'.',CAST(DATEDIFF(MM,P.BIRTH_DATE,V.START_DATE)%12 AS VARCHAR(5)))
             END) AS AGE_VISIT_CHAR
  , CONCAT('visit_dimension|length_of_stay:',CAST(DATEDIFF(DD,V.START_DATE,V.END_DATE) AS VARCHAR(5))) AS LENGTH_OF_STAY
  , CASE WHEN DATEDIFF(DD,V.START_DATE,V.END_DATE)>=10 THEN 'visit_dimension|length_of_stay:>10' END AS LENGTH_OF_STAY_GTE10
  , CONCAT('visit_dimension|inout_cd:',V.INOUT_CD) AS inout_cd
  , P.RACE_CD
FROM DBO.PATIENT_DIMENSION P
  JOIN DBO.VISIT_DIMENSION V
    ON P.PATIENT_NUM = V.PATIENT_NUM
)
INSERT INTO #PV_FACT_PAIRS(PATIENT_NUM, CONCEPT_CD)
SELECT DISTINCT PATIENT_NUM, VAL AS CONCEPT_CD
FROM (
SELECT PATIENT_NUM
  , CAST(AGE_TODAY_CHAR AS VARCHAR(50)) AS AGE_TODAY
  , CAST(AGE_VISIT_CHAR AS VARCHAR(50)) AS AGE_VISIT
  , CAST(CASE WHEN AGE_TODAY_NUM < 18 THEN  'DEM|AGE:<18'  ELSE NULL END AS VARCHAR(50)) AS AGE_TODAY_LT18
  , CAST(CASE WHEN AGE_TODAY_NUM >= 18 THEN 'DEM|AGE:>=18' ELSE NULL END AS VARCHAR(50)) AS AGE_TODAY_GTE18
  , CAST(CASE WHEN AGE_TODAY_NUM >= 65 THEN 'DEM|AGE:>=65' ELSE NULL END AS VARCHAR(50)) AS AGE_TODAY_GTE65
  , CAST(CASE WHEN AGE_TODAY_NUM >= 85 THEN 'DEM|AGE:>=85' ELSE NULL END AS VARCHAR(50)) AS AGE_TODAY_GTE85
  , CAST(CASE WHEN AGE_TODAY_NUM >= 90 THEN 'DEM|AGE:>=90' ELSE NULL END AS VARCHAR(50)) AS AGE_TODAY_GTE90
  , CAST(CASE WHEN AGE_VISIT_NUM >= 65 THEN 'VIS|AGE:>=65' ELSE NULL END AS VARCHAR(50)) AS AGE_VISIT_GTE65
  , CAST(CASE WHEN AGE_VISIT_NUM >= 85 THEN 'VIS|AGE:>=85' ELSE NULL END AS VARCHAR(50)) AS AGE_VISIT_GTE85
  , CAST(CASE WHEN AGE_VISIT_NUM >= 90 THEN 'VIS|AGE:>=90' ELSE NULL END AS VARCHAR(50)) AS AGE_VISIT_GTE90
  , CAST(LENGTH_OF_STAY       AS VARCHAR(50)) AS LENGTH_OF_STAY
  , CAST(LENGTH_OF_STAY_GTE10 AS VARCHAR(50)) AS LENGTH_OF_STAY_GTE10
  , CAST(INOUT_CD             AS VARCHAR(50)) AS INOUT_CD
FROM PATIENT_VISIT_PRELIM
)O
UNPIVOT
(VAL FOR FACT IN ([AGE_TODAY],[AGE_VISIT], [AGE_TODAY_LT18]
  , AGE_TODAY_GTE18, AGE_TODAY_GTE65, AGE_TODAY_GTE85, AGE_TODAY_GTE90
  , AGE_VISIT_GTE65, AGE_VISIT_GTE85, AGE_VISIT_GTE90
  , LENGTH_OF_STAY, LENGTH_OF_STAY_GTE10, INOUT_CD))P
;

/* CALCULATE TOTALNUMS */

;WITH CTE_FACT_PAIRS AS (
SELECT PATIENT_NUM, CONCEPT_CD FROM #PV_FACT_PAIRS
UNION ALL
SELECT PATIENT_NUM, CONCEPT_CD FROM OBSFACT_PAIRS
)
INSERT INTO TOTALNUM WITH(TABLOCK) (C_FULLNAME, AGG_COUNT, AGG_DATE, TYPEFLAG_CD)
SELECT DISTINCT OANC.C_FULLNAME, C.AGG_COUNT, CONVERT(DATE, GETDATE()),'PF'
FROM (
SELECT CC_ANCESTOR.ANCESTOR, COUNT(DISTINCT PATIENT_NUM) AGG_COUNT
FROM CONCEPT_CLOSURE CC_ANCESTOR
  JOIN TNUM_ONTOLOGY O
    ON CC_ANCESTOR.DESCENDANT = O.PATH_NUM
  JOIN CTE_FACT_PAIRS F
    ON O.C_BASECODE = F.CONCEPT_CD
GROUP BY CC_ANCESTOR.ANCESTOR
)C
  JOIN TNUM_ONTOLOGY OANC
    ON C.ANCESTOR = OANC.PATH_NUM;

	EXEC EndTime @startime,'all ontologies','counting';
    set @startime = getdate();
	

END;
GO