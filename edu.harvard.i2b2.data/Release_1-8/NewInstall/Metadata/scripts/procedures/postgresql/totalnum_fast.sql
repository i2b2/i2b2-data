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

Acknowledgement:
  This Postgres conversion by Jeff Klann, assisted by ChatGPT.
--------------------------------------------------------------------------------

*/
CREATE OR REPLACE PROCEDURE fasttotalnumcount(
    IN schemaname varchar DEFAULT 'public',
    IN source_mode varchar DEFAULT 'i2b2'
)
LANGUAGE plpgsql
AS $procedure$
DECLARE
    source_mode_norm text;
    start_time timestamptz;
BEGIN
    start_time := clock_timestamp();
    source_mode_norm := lower(coalesce(nullif(source_mode, ''), 'i2b2'));
    IF source_mode_norm NOT IN ('i2b2', 'omop') THEN
        RAISE EXCEPTION 'Invalid source_mode. Use i2b2 or omop.';
    END IF;

    -- PostgreSQL temp tables are per-session, not persistent Oracle-style GTT definitions.
    -- The temp table shadows any permanent relation of the same name in search_path.
    CREATE TEMP TABLE IF NOT EXISTS pv_fact_pairs (
        patient_num bigint,
        concept_cd varchar(50),
        CONSTRAINT pk_pv_fact_pairs PRIMARY KEY (patient_num, concept_cd)
    ) ON COMMIT PRESERVE ROWS;
    TRUNCATE TABLE pg_temp.pv_fact_pairs;

    WITH patient_visit_prelim AS (
        SELECT
            p.patient_num,
            floor((CURRENT_DATE - p.birth_date::date)::numeric / 365.25) AS age_today_num,
            'DEM|AGE:' || CASE
                WHEN floor((CURRENT_DATE - p.birth_date::date)::numeric / 365.25) >= 3
                THEN floor((CURRENT_DATE - p.birth_date::date)::numeric / 365.25)::bigint::text
                ELSE extract(year FROM age(CURRENT_DATE, p.birth_date::date))::int::text
                     || '.' || extract(month FROM age(CURRENT_DATE, p.birth_date::date))::int::text
            END AS age_today_char,
            floor((v.start_date::date - p.birth_date::date)::numeric / 365.25) AS age_visit_num,
            'VIS|AGE:' || CASE
                WHEN floor((v.start_date::date - p.birth_date::date)::numeric / 365.25) >= 3
                THEN floor((v.start_date::date - p.birth_date::date)::numeric / 365.25)::bigint::text
                ELSE extract(year FROM age(v.start_date::date, p.birth_date::date))::int::text
                     || '.' || extract(month FROM age(v.start_date::date, p.birth_date::date))::int::text
            END AS age_visit_char,
            'visit_dimension|length_of_stay:' || (v.end_date::date - v.start_date::date)::text AS length_of_stay,
            CASE WHEN (v.end_date::date - v.start_date::date) >= 10
                 THEN 'visit_dimension|length_of_stay:>10' END AS length_of_stay_gte10,
            'visit_dimension|inout_cd:' || v.inout_cd AS inout_cd,
            'DEM|RACE:' || p.race_cd AS race_cd,
            'DEM|SEX:' || p.sex_cd AS sex_cd
        FROM patient_dimension p
        JOIN visit_dimension v ON p.patient_num = v.patient_num
    ),
    derived AS (
        SELECT
            patient_num,
            age_today_char::varchar(50) AS age_today,
            age_visit_char::varchar(50) AS age_visit,
            (CASE WHEN age_today_num < 18 THEN 'DEM|AGE:<18' END)::varchar(50) AS age_today_lt18,
            (CASE WHEN age_today_num >= 18 THEN 'DEM|AGE:>=18' END)::varchar(50) AS age_today_gte18,
            (CASE WHEN age_today_num >= 65 THEN 'DEM|AGE:>=65' END)::varchar(50) AS age_today_gte65,
            (CASE WHEN age_today_num >= 85 THEN 'DEM|AGE:>=85' END)::varchar(50) AS age_today_gte85,
            (CASE WHEN age_today_num >= 90 THEN 'DEM|AGE:>=90' END)::varchar(50) AS age_today_gte90,
            (CASE WHEN age_visit_num >= 65 THEN 'VIS|AGE:>=65' END)::varchar(50) AS age_visit_gte65,
            (CASE WHEN age_visit_num >= 85 THEN 'VIS|AGE:>=85' END)::varchar(50) AS age_visit_gte85,
            (CASE WHEN age_visit_num >= 90 THEN 'VIS|AGE:>=90' END)::varchar(50) AS age_visit_gte90,
            length_of_stay::varchar(50) AS length_of_stay,
            length_of_stay_gte10::varchar(50) AS length_of_stay_gte10,
            inout_cd::varchar(50) AS inout_cd,
            race_cd::varchar(50) AS race_cd,
            sex_cd::varchar(50) AS sex_cd
        FROM patient_visit_prelim
    )
    INSERT INTO pg_temp.pv_fact_pairs (patient_num, concept_cd)
    SELECT DISTINCT d.patient_num, vals.val
    FROM derived d
    CROSS JOIN LATERAL (VALUES
        (d.age_today), (d.age_visit), (d.age_today_lt18),
        (d.age_today_gte18), (d.age_today_gte65), (d.age_today_gte85),
        (d.age_today_gte90), (d.age_visit_gte65), (d.age_visit_gte85),
        (d.age_visit_gte90), (d.length_of_stay), (d.length_of_stay_gte10),
        (d.inout_cd), (d.race_cd), (d.sex_cd)
    ) AS vals(val)
    WHERE vals.val IS NOT NULL AND d.patient_num IS NOT NULL;

    INSERT INTO totalnum (c_fullname, agg_count, agg_date, typeflag_cd)
    WITH cte_fact_pairs AS (
        SELECT patient_num, concept_cd FROM pg_temp.pv_fact_pairs
        UNION ALL
        SELECT patient_num, concept_cd FROM obsfact_pairs
    )
    SELECT DISTINCT oanc.c_fullname, counts.agg_count, CURRENT_TIMESTAMP, 'PF'
    FROM (
        SELECT cc.ancestor, count(DISTINCT f.patient_num) AS agg_count
        FROM concept_closure cc
        JOIN tnum_ontology o ON cc.descendant = o.path_num
        JOIN cte_fact_pairs f ON o.c_basecode = f.concept_cd
        GROUP BY cc.ancestor
    ) counts
    JOIN tnum_ontology oanc ON counts.ancestor = oanc.path_num;

    -- Optional timing helper (if installed as a PostgreSQL procedure):
    -- CALL endtime(start_time, 'all ontologies', 'counting');
    RAISE NOTICE 'FastTotalnumCount completed in %', clock_timestamp() - start_time;
    -- No COMMIT or ROLLBACK: caller manages transaction.
END;
$procedure$;
GO

-- Example:
-- CALL public.fasttotalnumcount('public', 'i2b2');
