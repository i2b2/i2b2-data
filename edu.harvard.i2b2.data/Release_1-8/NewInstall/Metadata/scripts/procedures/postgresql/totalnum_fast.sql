/*
--------------------------------------------------------------------------------
Postgres Version: FastTotalnumCount Procedure
--------------------------------------------------------------------------------
Fast version by Darren Henderson (DARREN.HENDERSON@UKY.EDU) and Jeff Klann, PhD.
Based on code by Griffin Weber, Jeff Klann, Mike Mendis, Lori Phillips, Jeff Green, 
and Darren Henderson.

Description:
  This procedure refactors patient counting for speed and ACT-OMOP support.
  It builds fact tuples from patient and visit dimensions, “unpivots” these attributes
  into a single set of fact rows (inserted into the temporary table pv_fact_pairs),
  and then aggregates distinct patient counts per ontology element via the concept_closure
  and tnum_ontology tables. The aggregated counts are inserted into the totalnum table.
  
Usage Example:
  CALL fasttotalnumcount();

Acknowledgement:
  This Postgres conversion by Jeff Klann, assisted by ChatGPT.
--------------------------------------------------------------------------------
*/
CREATE OR REPLACE PROCEDURE fasttotalnumcount()
LANGUAGE plpgsql
AS $sql$
DECLARE
    start_time timestamp;
BEGIN
    start_time := now();
    
    --------------------------------------------------------------------------
    -- 
    --------------------------------------------------------------------------
    CREATE TEMPORARY TABLE IF NOT EXISTS PV_FACT_PAIRS (
    	PATIENT_NUM INT,
    	CONCEPT_CD VARCHAR(50),
    	PRIMARY KEY (PATIENT_NUM, CONCEPT_CD)
    ) ON COMMIT PRESERVE ROWS;
    TRUNCATE TABLE pv_fact_pairs;
    
    --------------------------------------------------------------------------
    -- Build PATIENT/VISIT FEATURES AS FACT TUPLES
    --------------------------------------------------------------------------
    WITH patient_visit_prelim AS (
      SELECT 
        p.patient_num,
        EXTRACT(YEAR FROM age(current_date, p.birth_date::date))::int AS age_today_num,
        'DEM|AGE:' ||
          CASE 
            WHEN EXTRACT(YEAR FROM age(current_date, p.birth_date::date))::int >= 3 THEN
              EXTRACT(YEAR FROM age(current_date, p.birth_date::date))::text
            ELSE
              (EXTRACT(YEAR FROM age(current_date, p.birth_date::date))::int)::text || '.' ||
              (EXTRACT(MONTH FROM age(current_date, p.birth_date::date))::int % 12)::text
          END AS age_today_char,
        EXTRACT(YEAR FROM age(v.start_date::date, p.birth_date::date))::int AS age_visit_num,
        'VIS|AGE:' ||
          CASE 
            WHEN EXTRACT(YEAR FROM age(v.start_date::date, p.birth_date::date))::int >= 3 THEN
              (EXTRACT(YEAR FROM age(v.start_date::date, p.birth_date::date))::int)::text
            ELSE
              (EXTRACT(YEAR FROM age(v.start_date::date, p.birth_date::date))::int)::text || '.' ||
              ((EXTRACT(MONTH FROM age(v.start_date::date, p.birth_date::date))::int % 12))::text
          END AS age_visit_char,
        'visit_dimension|length_of_stay:' || ((v.end_date::date - v.start_date::date))::text AS length_of_stay,
        CASE WHEN (v.end_date::date - v.start_date::date) >= 10 THEN 'visit_dimension|length_of_stay:>10' END AS length_of_stay_gte10,
        'visit_dimension|inout_cd:' || v.inout_cd AS inout_cd,
        p.race_cd::text AS race_cd,
        p.sex_cd::text AS sex_cd
      FROM patient_dimension p
      JOIN visit_dimension v ON p.patient_num = v.patient_num
    ),
    derived AS (
      SELECT
        patient_num,
        age_today_char AS age_today,
        age_visit_char AS age_visit,
        CASE WHEN age_today_num < 18 THEN 'DEM|AGE:<18' ELSE NULL END AS age_today_lt18,
        CASE WHEN age_today_num >= 18 THEN 'DEM|AGE:>=18' ELSE NULL END AS age_today_gte18,
        CASE WHEN age_today_num >= 65 THEN 'DEM|AGE:>=65' ELSE NULL END AS age_today_gte65,
        CASE WHEN age_today_num >= 85 THEN 'DEM|AGE:>=85' ELSE NULL END AS age_today_gte85,
        CASE WHEN age_today_num >= 90 THEN 'DEM|AGE:>=90' ELSE NULL END AS age_today_gte90,
        CASE WHEN age_visit_num >= 65 THEN 'VIS|AGE:>=65' ELSE NULL END AS age_visit_gte65,
        CASE WHEN age_visit_num >= 85 THEN 'VIS|AGE:>=85' ELSE NULL END AS age_visit_gte85,
        CASE WHEN age_visit_num >= 90 THEN 'VIS|AGE:>=90' ELSE NULL END AS age_visit_gte90,
        length_of_stay,
        length_of_stay_gte10,
        inout_cd,
        race_cd,
        sex_cd
      FROM patient_visit_prelim
    ),
    unpivoted AS (
      SELECT patient_num, col AS concept_cd
      FROM derived,
      LATERAL (
         VALUES
         (age_today::text),
         (age_visit::text),
         (age_today_lt18::text),
         (age_today_gte18::text),
         (age_today_gte65::text),
         (age_today_gte85::text),
         (age_today_gte90::text),
         (age_visit_gte65::text),
         (age_visit_gte85::text),
         (age_visit_gte90::text),
         (length_of_stay::text),
         (length_of_stay_gte10::text),
         (inout_cd::text),
         (race_cd::text),
         (sex_cd::text)
      ) AS unpvt(col)
      WHERE col IS NOT NULL
    )
    INSERT INTO pv_fact_pairs (patient_num, concept_cd)
    SELECT DISTINCT patient_num, concept_cd
    FROM unpivoted;
    
    --------------------------------------------------------------------------
    -- Calculate TOTALNUMS: aggregate distinct patient counts per ontology element.
    --------------------------------------------------------------------------
    WITH cte_fact_pairs AS (
      SELECT patient_num, concept_cd FROM pv_fact_pairs
      UNION ALL
      SELECT patient_num, concept_cd FROM obsfact_pairs
    ),
    agg AS (
      SELECT cc.ancestor, COUNT(DISTINCT patient_num) AS agg_count
      FROM concept_closure cc
      JOIN tnum_ontology o ON cc.descendant = o.path_num
      JOIN cte_fact_pairs f ON o.c_basecode = f.concept_cd
      GROUP BY cc.ancestor
    )
    INSERT INTO totalnum (c_fullname, agg_count, agg_date, typeflag_cd)
    SELECT DISTINCT oanc.c_fullname, agg.agg_count, now(), 'PF'
    FROM agg
    JOIN tnum_ontology oanc ON agg.ancestor = oanc.path_num;
    
    PERFORM endtime(start_time, 'all ontologies', 'counting');
    start_time := now();
    
    --COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$sql$;
