#!/usr/bin/env python3
"""
Generate synthetic demo patient data for the i2b2 ACT project on Snowflake.

Produces snappy-compressed parquet files (one per CRC table) that are loaded
by load_demo_patients.sql via PUT + COPY INTO:

    PATIENT_DIMENSION.snappy.parquet
    PATIENT_MAPPING.snappy.parquet
    VISIT_DIMENSION.snappy.parquet
    ENCOUNTER_MAPPING.snappy.parquet
    PROVIDER_DIMENSION.snappy.parquet
    OBSERVATION_FACT.snappy.parquet

All facts use concept codes that exist in the ACT ontology CONCEPT_DIMENSION
(ICD10CM / RXNORM / CPT4 / LOINC / CVX / DEM| / VISIT|), so ontology-driven
queries in the i2b2 webclient return these patients.

The generator is deterministic for a given --seed, so re-running it produces
identical data.

Usage:
    python3 generate_act_demo_patients.py [--patients 500] [--seed 20251020]
                                          [--output-dir .]

Requires: pyarrow
"""

import argparse
import random
from datetime import date, datetime, timedelta

import pyarrow as pa
import pyarrow.parquet as pq

SOURCESYSTEM_CD = "ACT_DEMO"
PROJECT_ID = "ACT"
PATIENT_IDE_SOURCE = "ACT_DEMO"
ENCOUNTER_IDE_SOURCE = "ACT_DEMO"
UPLOAD_ID = 1
AS_OF = date(2025, 10, 1)          # reference date for ages / "today"
VISIT_RANGE = (date(2018, 1, 1), date(2025, 9, 30))

# ---------------------------------------------------------------------------
# Terminology (every code below exists in the ACT ontology CONCEPT_DIMENSION)
# ---------------------------------------------------------------------------

SEXES = [("F", "DEM|SEX:F", 0.51), ("M", "DEM|SEX:M", 0.49)]

RACES = [  # (patient_dimension.race_cd, fact concept_cd, weight)
    ("W", "DEM|RACE:W", 0.60),
    ("B", "DEM|RACE:B", 0.14),
    ("AS", "DEM|RACE:AS", 0.07),
    ("NA", "DEM|RACE:NA", 0.02),
    ("H", "DEM|RACE:H", 0.01),
    ("M", "DEM|RACE:M", 0.05),
    ("NI", "DEM|RACE:NI", 0.11),
]

HISPANIC = [
    ("Y", "DEM|HISP:Y", 0.17),
    ("N", "DEM|HISP:N", 0.77),
    ("NI", "DEM|HISP:NI", 0.06),
]

# chronic condition profiles: dx code -> (meds, labs); labs: (loinc, lo, hi, units)
CHRONIC_CONDITIONS = {
    "ICD10CM:E11.9": {  # type 2 diabetes
        "meds": ["RXNORM:6809"],                       # metformin
        "labs": [("LOINC:4548-4", 5.8, 10.5, "%"),     # HbA1c
                 ("LOINC:2345-7", 90, 260, "mg/dL")],  # glucose
    },
    "ICD10CM:I10": {    # hypertension
        "meds": ["RXNORM:29046", "RXNORM:17767", "RXNORM:6918"],  # lisinopril/amlodipine/metoprolol
        "labs": [],
    },
    "ICD10CM:E78.5": {  # hyperlipidemia
        "meds": ["RXNORM:83367", "RXNORM:36567"],      # atorvastatin/simvastatin
        "labs": [("LOINC:2093-3", 150, 280, "mg/dL")], # cholesterol
    },
    "ICD10CM:J45.909": {"meds": ["RXNORM:435"], "labs": []},                      # asthma / albuterol
    "ICD10CM:J44.9": {"meds": ["RXNORM:435", "RXNORM:8640"], "labs": []},         # COPD / albuterol+prednisone
    "ICD10CM:F32.9": {"meds": [], "labs": []},                                    # depression
    "ICD10CM:F41.1": {"meds": [], "labs": []},                                    # anxiety
    "ICD10CM:K21.9": {"meds": ["RXNORM:7646"], "labs": []},                       # GERD / omeprazole
    "ICD10CM:M54.5": {"meds": ["RXNORM:5640"], "labs": []},                       # low back pain / ibuprofen
    "ICD10CM:E03.9": {"meds": ["RXNORM:10582"], "labs": []},                      # hypothyroidism / levothyroxine
    "ICD10CM:I48.91": {"meds": ["RXNORM:1191"], "labs": []},                      # atrial fibrillation / aspirin
    "ICD10CM:I25.10": {"meds": ["RXNORM:1191", "RXNORM:32968"], "labs": []},      # CAD / aspirin+clopidogrel
    "ICD10CM:N18.3": {"meds": [], "labs": [("LOINC:2160-0", 1.4, 3.0, "mg/dL")]}, # CKD3 / creatinine
    "ICD10CM:G47.33": {"meds": [], "labs": []},                                   # obstructive sleep apnea
    "ICD10CM:M17.9": {"meds": ["RXNORM:161"], "labs": []},                        # knee OA / acetaminophen
    "ICD10CM:E66.9": {"meds": [], "labs": []},                                    # obesity
    "ICD10CM:D64.9": {"meds": [], "labs": [("LOINC:718-7", 8.0, 11.5, "g/dL")]},  # anemia / hemoglobin
}

ACUTE_CONDITIONS = ["ICD10CM:J06.9", "ICD10CM:N39.0", "ICD10CM:R07.9", "ICD10CM:U07.1"]

# routine labs available at any visit: (loinc, lo, hi, units)
ROUTINE_LABS = [
    ("LOINC:2345-7", 70, 125, "mg/dL"),    # glucose
    ("LOINC:2160-0", 0.6, 1.3, "mg/dL"),   # creatinine
    ("LOINC:718-7", 11.5, 17.0, "g/dL"),   # hemoglobin
    ("LOINC:6690-2", 4.0, 11.0, "10*3/uL"),# WBC
    ("LOINC:777-3", 150, 400, "10*3/uL"),  # platelets
    ("LOINC:2951-2", 135, 145, "mmol/L"),  # sodium
    ("LOINC:2823-3", 3.5, 5.2, "mmol/L"),  # potassium
]

# visit types: (visit_dimension.inout_cd, fact concept_cd, weight)
VISIT_TYPES = [
    ("O", "VISIT|TYPE:O", 0.55),    # ambulatory
    ("E", "VISIT|TYPE:E", 0.10),    # emergency
    ("EI", "VISIT|TYPE:EI", 0.05),  # ED admit to inpatient
    ("I", "VISIT|TYPE:I", 0.10),    # inpatient
    ("T", "VISIT|TYPE:T", 0.12),    # tele-health
    ("X", "VISIT|TYPE:X", 0.08),    # other ambulatory
]
INPATIENT_TYPES = {"I", "EI"}

OUTPATIENT_EM = ["CPT4:99213", "CPT4:99213", "CPT4:99214", "CPT4:99203"]
EXTRA_PROCEDURES = ["CPT4:93000", "CPT4:71046", "CPT4:80053", "CPT4:85025", "CPT4:36415", "CPT4:70450"]
FLU_VAX = ["CVX:140", "CVX:141"]
COVID_VAX = "CVX:208"

PROVIDER_SPECIALTIES = [
    "Internal Medicine", "Family Medicine", "Cardiology", "Endocrinology",
    "Pulmonology", "Emergency Medicine", "Psychiatry", "Orthopedics",
]
PROVIDER_LAST_NAMES = [
    "Smith", "Johnson", "Chen", "Patel", "Garcia", "Mueller", "Okafor",
    "Nguyen", "Rossi", "Kowalski", "Haddad", "Silva", "Novak", "Dubois",
    "Yamamoto", "Andersson", "Petrov", "OBrien", "Khan", "Lopez",
]

ZIPS = [  # (zip, state, city)
    ("02115", "Massachusetts", "Boston"),
    ("10016", "New York", "New York"),
    ("19104", "Pennsylvania", "Philadelphia"),
    ("60612", "Illinois", "Chicago"),
    ("77030", "Texas", "Houston"),
    ("94143", "California", "San Francisco"),
    ("98195", "Washington", "Seattle"),
    ("30322", "Georgia", "Atlanta"),
    ("48109", "Michigan", "Ann Arbor"),
    ("37232", "Tennessee", "Nashville"),
]

LANGUAGES = [("english", 0.78), ("spanish", 0.12), ("other", 0.10)]
MARITAL = [("M", 0.45), ("S", 0.35), ("D", 0.10), ("W", 0.07), ("U", 0.03)]


def weighted(rng, items):
    """items: list of tuples whose last element is the weight."""
    total = sum(it[-1] for it in items)
    x = rng.uniform(0, total)
    for it in items:
        x -= it[-1]
        if x <= 0:
            return it
    return items[-1]


def midnight(d):
    return datetime(d.year, d.month, d.day)


def generate(num_patients, seed):
    rng = random.Random(seed)
    now = midnight(AS_OF)

    providers = [{
        "PROVIDER_ID": "@",
        "PROVIDER_PATH": "\\ACT\\Providers\\@\\",
        "NAME_CHAR": "No Information",
    }]
    for i, last in enumerate(PROVIDER_LAST_NAMES, start=1):
        spec = PROVIDER_SPECIALTIES[(i - 1) % len(PROVIDER_SPECIALTIES)]
        pid = "ACT_DEMO_PRV_%03d" % i
        providers.append({
            "PROVIDER_ID": pid,
            "PROVIDER_PATH": "\\ACT\\Providers\\%s\\%s\\" % (spec, pid),
            "NAME_CHAR": "Dr. %s (%s)" % (last, spec),
        })
    provider_ids = [p["PROVIDER_ID"] for p in providers[1:]]

    patients, patient_maps, visits, encounter_maps, facts = [], [], [], [], []
    fact_keys = set()

    def add_fact(enc, pat, concept, provider, start, valtype=None, tval=None,
                 nval=None, units=None, end=None, modifier="@", instance=1):
        key = (pat, concept, modifier, start, enc, instance, provider)
        if key in fact_keys:
            return
        fact_keys.add(key)
        facts.append({
            "ENCOUNTER_NUM": enc, "PATIENT_NUM": pat, "CONCEPT_CD": concept,
            "PROVIDER_ID": provider, "START_DATE": start, "MODIFIER_CD": modifier,
            "INSTANCE_NUM": instance, "VALTYPE_CD": valtype, "TVAL_CHAR": tval,
            "NVAL_NUM": nval, "VALUEFLAG_CD": None, "QUANTITY_NUM": None,
            "UNITS_CD": units, "END_DATE": end, "LOCATION_CD": "ACT_DEMO",
            "OBSERVATION_BLOB": None, "CONFIDENCE_NUM": None,
            "UPDATE_DATE": now, "DOWNLOAD_DATE": now, "IMPORT_DATE": now,
            "SOURCESYSTEM_CD": SOURCESYSTEM_CD, "UPLOAD_ID": UPLOAD_ID,
        })

    encounter_num = 0
    for patient_num in range(1, num_patients + 1):
        age = min(int(rng.gammavariate(3.0, 17.0)), 95)
        birth = midnight(AS_OF) - timedelta(days=age * 365 + rng.randint(0, 364))
        sex_cd, sex_concept, _ = weighted(rng, SEXES)
        race_cd, race_concept, _ = weighted(rng, RACES)
        hisp_cd, hisp_concept, _ = weighted(rng, HISPANIC)
        zip_cd, state, city = ZIPS[rng.randrange(len(ZIPS))]
        language = weighted(rng, LANGUAGES)[0]
        marital = weighted(rng, MARITAL)[0]

        # chronic problem list grows with age
        n_chronic = min(rng.randint(0, 2) + (age // 30), 5)
        chronic = rng.sample(sorted(CHRONIC_CONDITIONS), n_chronic)

        n_visits = rng.randint(1, 3) + min(n_chronic * 2, 5)
        first_visit = VISIT_RANGE[0] + timedelta(
            days=rng.randint(0, (VISIT_RANGE[1] - VISIT_RANGE[0]).days // 2))
        visit_dates = sorted(
            first_visit + timedelta(days=rng.randint(0, (VISIT_RANGE[1] - first_visit).days))
            for _ in range(n_visits))

        deceased = age >= 60 and rng.random() < 0.06
        death_date = midnight(visit_dates[-1]) + timedelta(days=rng.randint(1, 180)) if deceased else None
        if death_date is not None and death_date > now:
            death_date = now

        patients.append({
            "PATIENT_NUM": patient_num,
            "VITAL_STATUS_CD": "Y" if deceased else "N",
            "BIRTH_DATE": birth,
            "DEATH_DATE": death_date,
            "SEX_CD": sex_cd,
            "AGE_IN_YEARS_NUM": age,
            "LANGUAGE_CD": language,
            "RACE_CD": race_cd,
            "MARITAL_STATUS_CD": marital,
            "RELIGION_CD": None,
            "ZIP_CD": zip_cd,
            "STATECITYZIP_PATH": "Zip codes\\%s\\%s\\%s\\" % (state, city, zip_cd),
            "INCOME_CD": None,
            "PATIENT_BLOB": None,
            "UPDATE_DATE": now, "DOWNLOAD_DATE": now, "IMPORT_DATE": now,
            "SOURCESYSTEM_CD": SOURCESYSTEM_CD, "UPLOAD_ID": UPLOAD_ID,
        })
        for ide, src in ((str(patient_num), "HIVE"),
                         ("ACT_DEMO_P%06d" % patient_num, PATIENT_IDE_SOURCE)):
            patient_maps.append({
                "PATIENT_IDE": ide, "PATIENT_IDE_SOURCE": src,
                "PATIENT_NUM": patient_num, "PATIENT_IDE_STATUS": "A",
                "PROJECT_ID": PROJECT_ID,
                "UPLOAD_DATE": now, "UPDATE_DATE": now, "DOWNLOAD_DATE": now,
                "IMPORT_DATE": now, "SOURCESYSTEM_CD": SOURCESYSTEM_CD,
                "UPLOAD_ID": UPLOAD_ID,
            })

        first_enc = None
        for vd in visit_dates:
            encounter_num += 1
            if first_enc is None:
                first_enc = encounter_num
            inout_cd, visit_concept, _ = weighted(rng, VISIT_TYPES)
            provider = provider_ids[rng.randrange(len(provider_ids))]
            start = midnight(vd) + timedelta(hours=rng.randint(7, 19))
            los = rng.randint(1, 10) if inout_cd in INPATIENT_TYPES else 0
            end = start + (timedelta(days=los) if los else timedelta(hours=rng.randint(1, 4)))

            visits.append({
                "ENCOUNTER_NUM": encounter_num, "PATIENT_NUM": patient_num,
                "ACTIVE_STATUS_CD": "F", "START_DATE": start, "END_DATE": end,
                "INOUT_CD": inout_cd, "LOCATION_CD": "ACT_DEMO",
                "LOCATION_PATH": "\\ACT\\Facility\\ACT Demo Hospital\\",
                "LENGTH_OF_STAY": los if los else None, "VISIT_BLOB": None,
                "UPDATE_DATE": now, "DOWNLOAD_DATE": now, "IMPORT_DATE": now,
                "SOURCESYSTEM_CD": SOURCESYSTEM_CD, "UPLOAD_ID": UPLOAD_ID,
            })
            encounter_maps.append({
                "ENCOUNTER_IDE": "ACT_DEMO_E%08d" % encounter_num,
                "ENCOUNTER_IDE_SOURCE": ENCOUNTER_IDE_SOURCE,
                "PROJECT_ID": PROJECT_ID, "ENCOUNTER_NUM": encounter_num,
                "PATIENT_IDE": "ACT_DEMO_P%06d" % patient_num,
                "PATIENT_IDE_SOURCE": PATIENT_IDE_SOURCE,
                "ENCOUNTER_IDE_STATUS": "A", "UPLOAD_DATE": now.date(),
                "UPDATE_DATE": now, "DOWNLOAD_DATE": now, "IMPORT_DATE": now,
                "SOURCESYSTEM_CD": SOURCESYSTEM_CD, "UPLOAD_ID": UPLOAD_ID,
            })

            # visit-detail facts
            add_fact(encounter_num, patient_num, visit_concept, provider, start, end=end)
            if los:
                add_fact(encounter_num, patient_num, "VISIT|LENGTH:%d" % min(los, 10),
                         provider, start, end=end)

            # diagnoses: chronic conditions recur across visits; acute now and then
            dx_today = rng.sample(chronic, rng.randint(1, len(chronic))) if chronic else []
            if inout_cd in ("E", "EI") or rng.random() < 0.25:
                dx_today.append(ACUTE_CONDITIONS[rng.randrange(len(ACUTE_CONDITIONS))])
            for dx in dx_today:
                add_fact(encounter_num, patient_num, dx, provider, start, end=end)
                if dx == "ICD10CM:U07.1":  # COVID dx comes with a positive PCR
                    add_fact(encounter_num, patient_num, "LOINC:94500-6", provider,
                             start, valtype="T", tval="Positive", end=end)

            # medications tied to today's chronic diagnoses
            for dx in dx_today:
                meds = CHRONIC_CONDITIONS.get(dx, {}).get("meds", [])
                if meds and rng.random() < 0.8:
                    add_fact(encounter_num, patient_num,
                             meds[rng.randrange(len(meds))], provider, start, end=end)

            # procedures
            if inout_cd in ("O", "T", "X"):
                add_fact(encounter_num, patient_num,
                         OUTPATIENT_EM[rng.randrange(len(OUTPATIENT_EM))],
                         provider, start, end=end)
            elif inout_cd == "E":
                add_fact(encounter_num, patient_num, "CPT4:99285", provider, start, end=end)
            else:
                add_fact(encounter_num, patient_num, "CPT4:99232", provider, start, end=end)
            if rng.random() < 0.35:
                add_fact(encounter_num, patient_num,
                         EXTRA_PROCEDURES[rng.randrange(len(EXTRA_PROCEDURES))],
                         provider, start, end=end)
            if age >= 45 and rng.random() < 0.04:
                add_fact(encounter_num, patient_num, "CPT4:45378", provider, start, end=end)

            # immunizations at some ambulatory visits
            if inout_cd in ("O", "X") and rng.random() < 0.15:
                vax = COVID_VAX if rng.random() < 0.4 else FLU_VAX[rng.randrange(2)]
                add_fact(encounter_num, patient_num, "ICD10CM:Z23", provider, start, end=end)
                add_fact(encounter_num, patient_num, vax, provider, start, end=end)
                add_fact(encounter_num, patient_num, "CPT4:90471", provider, start, end=end)

            # labs: condition-specific plus an occasional routine panel
            lab_pool = [lab for dx in dx_today
                        for lab in CHRONIC_CONDITIONS.get(dx, {}).get("labs", [])]
            if rng.random() < 0.40:
                lab_pool += rng.sample(ROUTINE_LABS, rng.randint(1, 3))
            for loinc, lo, hi, units in lab_pool:
                add_fact(encounter_num, patient_num, loinc, provider, start,
                         valtype="N", tval="E", nval=round(rng.uniform(lo, hi), 2),
                         units=units, end=end)

        # demographics facts attached to the first encounter
        first_start = midnight(visit_dates[0])
        for concept in (sex_concept, race_concept, hisp_concept):
            add_fact(first_enc, patient_num, concept, "@", first_start)

    for p in providers:
        p.update({"PROVIDER_BLOB": None, "UPDATE_DATE": now, "DOWNLOAD_DATE": now,
                  "IMPORT_DATE": now, "SOURCESYSTEM_CD": SOURCESYSTEM_CD,
                  "UPLOAD_ID": UPLOAD_ID})

    return patients, patient_maps, visits, encounter_maps, providers, facts


# ---------------------------------------------------------------------------
# Parquet output (column names match the Snowflake DDL; COPY INTO uses
# MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE)
# ---------------------------------------------------------------------------

TS = pa.timestamp("ms")

SCHEMAS = {
    "PATIENT_DIMENSION": pa.schema([
        ("PATIENT_NUM", pa.int64()), ("VITAL_STATUS_CD", pa.string()),
        ("BIRTH_DATE", TS), ("DEATH_DATE", TS), ("SEX_CD", pa.string()),
        ("AGE_IN_YEARS_NUM", pa.int64()), ("LANGUAGE_CD", pa.string()),
        ("RACE_CD", pa.string()), ("MARITAL_STATUS_CD", pa.string()),
        ("RELIGION_CD", pa.string()), ("ZIP_CD", pa.string()),
        ("STATECITYZIP_PATH", pa.string()), ("INCOME_CD", pa.string()),
        ("PATIENT_BLOB", pa.string()), ("UPDATE_DATE", TS),
        ("DOWNLOAD_DATE", TS), ("IMPORT_DATE", TS),
        ("SOURCESYSTEM_CD", pa.string()), ("UPLOAD_ID", pa.int64()),
    ]),
    "PATIENT_MAPPING": pa.schema([
        ("PATIENT_IDE", pa.string()), ("PATIENT_IDE_SOURCE", pa.string()),
        ("PATIENT_NUM", pa.int64()), ("PATIENT_IDE_STATUS", pa.string()),
        ("PROJECT_ID", pa.string()), ("UPLOAD_DATE", TS), ("UPDATE_DATE", TS),
        ("DOWNLOAD_DATE", TS), ("IMPORT_DATE", TS),
        ("SOURCESYSTEM_CD", pa.string()), ("UPLOAD_ID", pa.int64()),
    ]),
    "VISIT_DIMENSION": pa.schema([
        ("ENCOUNTER_NUM", pa.int64()), ("PATIENT_NUM", pa.int64()),
        ("ACTIVE_STATUS_CD", pa.string()), ("START_DATE", TS), ("END_DATE", TS),
        ("INOUT_CD", pa.string()), ("LOCATION_CD", pa.string()),
        ("LOCATION_PATH", pa.string()), ("LENGTH_OF_STAY", pa.int64()),
        ("VISIT_BLOB", pa.string()), ("UPDATE_DATE", TS), ("DOWNLOAD_DATE", TS),
        ("IMPORT_DATE", TS), ("SOURCESYSTEM_CD", pa.string()),
        ("UPLOAD_ID", pa.int64()),
    ]),
    "ENCOUNTER_MAPPING": pa.schema([
        ("ENCOUNTER_IDE", pa.string()), ("ENCOUNTER_IDE_SOURCE", pa.string()),
        ("PROJECT_ID", pa.string()), ("ENCOUNTER_NUM", pa.int64()),
        ("PATIENT_IDE", pa.string()), ("PATIENT_IDE_SOURCE", pa.string()),
        ("ENCOUNTER_IDE_STATUS", pa.string()), ("UPLOAD_DATE", pa.date32()),
        ("UPDATE_DATE", TS), ("DOWNLOAD_DATE", TS), ("IMPORT_DATE", TS),
        ("SOURCESYSTEM_CD", pa.string()), ("UPLOAD_ID", pa.int64()),
    ]),
    "PROVIDER_DIMENSION": pa.schema([
        ("PROVIDER_ID", pa.string()), ("PROVIDER_PATH", pa.string()),
        ("NAME_CHAR", pa.string()), ("PROVIDER_BLOB", pa.string()),
        ("UPDATE_DATE", TS), ("DOWNLOAD_DATE", TS), ("IMPORT_DATE", TS),
        ("SOURCESYSTEM_CD", pa.string()), ("UPLOAD_ID", pa.int64()),
    ]),
    "OBSERVATION_FACT": pa.schema([
        ("ENCOUNTER_NUM", pa.int64()), ("PATIENT_NUM", pa.int64()),
        ("CONCEPT_CD", pa.string()), ("PROVIDER_ID", pa.string()),
        ("START_DATE", TS), ("MODIFIER_CD", pa.string()),
        ("INSTANCE_NUM", pa.int64()), ("VALTYPE_CD", pa.string()),
        ("TVAL_CHAR", pa.string()), ("NVAL_NUM", pa.float64()),
        ("VALUEFLAG_CD", pa.string()), ("QUANTITY_NUM", pa.float64()),
        ("UNITS_CD", pa.string()), ("END_DATE", TS),
        ("LOCATION_CD", pa.string()), ("OBSERVATION_BLOB", pa.string()),
        ("CONFIDENCE_NUM", pa.float64()), ("UPDATE_DATE", TS),
        ("DOWNLOAD_DATE", TS), ("IMPORT_DATE", TS),
        ("SOURCESYSTEM_CD", pa.string()), ("UPLOAD_ID", pa.int64()),
    ]),
}


def write_table(rows, name, out_dir):
    schema = SCHEMAS[name]
    columns = {f.name: [r[f.name] for r in rows] for f in schema}
    table = pa.Table.from_pydict(columns, schema=schema)
    path = "%s/%s.snappy.parquet" % (out_dir, name)
    pq.write_table(table, path, compression="snappy")
    print("  %-42s %7d rows" % (path, len(rows)))


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    ap.add_argument("--patients", type=int, default=500)
    ap.add_argument("--seed", type=int, default=20251020)
    ap.add_argument("--output-dir", default=".")
    args = ap.parse_args()

    patients, patient_maps, visits, encounter_maps, providers, facts = generate(
        args.patients, args.seed)

    print("Writing parquet files to %s" % args.output_dir)
    write_table(patients, "PATIENT_DIMENSION", args.output_dir)
    write_table(patient_maps, "PATIENT_MAPPING", args.output_dir)
    write_table(visits, "VISIT_DIMENSION", args.output_dir)
    write_table(encounter_maps, "ENCOUNTER_MAPPING", args.output_dir)
    write_table(providers, "PROVIDER_DIMENSION", args.output_dir)
    write_table(facts, "OBSERVATION_FACT", args.output_dir)


if __name__ == "__main__":
    main()
