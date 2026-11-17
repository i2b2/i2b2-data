# Running totalnum Patient Counts

The totalnum scripts calculate patient counts for ontology nodes and write them to the metadata tables used by i2b2. Two workflows are available:

- **Fast** (default): prepares shared structures once, then counts and writes output. Intended for normal operation.
- **Classic**: the original algorithm, kept for custom or union fact tables and other specialized configurations.

SQL Server, Oracle, and PostgreSQL are supported. The entry point is `RunTotalnum` on SQL Server and Oracle, and `runtotalnum` on PostgreSQL.

> **Upgrade note:** `RunTotalnum` used to run the classic algorithm. It now defaults to fast, and so do the Ant total-count targets. Sites that need the previous behavior must request classic explicitly. See section 8, Upgrading from the previous behavior.

## Contents

1. Feature support
2. What a run updates
3. Installation
4. Prerequisites
5. Running counts
6. Count types
7. Operational notes
8. Upgrading from the previous behavior

## 1. Feature support

| Feature | SQL Server | Oracle | PostgreSQL |
| --- | --- | --- | --- |
| Fast i2b2 (`fast` or `i2b2`; default) | Yes | Yes | Yes |
| Fast ACT-OMOP (`omop`) | Yes | Yes | Yes |
| Fast count reusing existing prep | `@run_prep = 0` | `run_prep => 0` | `run_prep => 0` |
| Fast output for one ontology table | `@tablename` | `tableName` | `tablename` |
| Classic counting (`classic`) | Yes | Yes | Yes |
| Fast ACT-only demographics (default) | `@demographics_mode = 'act'` | `demographics_mode => 'act'` | `demographics_mode => 'act'` |
| Fast with supplemental demographics (non-ACT `patient_dimension` rows) | `@demographics_mode = 'other'` | `demographics_mode => 'other'` | `demographics_mode => 'other'` |
| Numeric-value constrained facts (within fast `other`) | i2b2 only | i2b2; OMOP requires a compatible fact view | i2b2; OMOP requires a compatible fact view |
| Classic wildcard fact-column matching | `@wildcard_factcolumn = 'Y'` | Flag exists; not reliable | Flag exists; not reliable |

All platforms retain the optimized ACT demographic path in fast mode. Use wildcard matching only on SQL Server; the Oracle and PostgreSQL wrappers expose the flag, but their wildcard counting paths have known limitations.

### Parameter names by platform

| Meaning | SQL Server | Oracle | PostgreSQL |
| --- | --- | --- | --- |
| Fact table | `@observationTable` | `observationTable` | `observationtable` |
| Data schema | `@schemaname` | `schemaName` | `schemaname` |
| Ontology table (`@` = all active) | `@tablename` | `tableName` | `tablename` |
| Wildcard fact-column matching | `@wildcard_factcolumn` | Leave `wildcard_factcolumn` at `N` | Leave `wildcard_factcolumn` at `N` |
| Mode | `@mode` | `totalnum_mode` | `totalnum_mode` |
| Demographics mode | `@demographics_mode` | `demographics_mode` | `demographics_mode` |
| Prep flag (0 = reuse, 1 = rebuild) | `@run_prep` | `run_prep` | `run_prep` |

`i2b2` is an alias for `fast`. Use the table name as listed in `TABLE_ACCESS`.

## 2. What a run updates

A successful run can update:

- `C_TOTALNUM` in each active ontology table listed in `TABLE_ACCESS`.
- `TABLE_ACCESS.C_TOTALNUM` for ontology roots.
- `TOTALNUM`, which retains count history.
- `TOTALNUM_REPORT`, which holds the latest obfuscated report counts.

Only active `TABLE_ACCESS` rows (`C_VISUALATTRIBUTES` containing `A`) are processed. Use `@` as the ontology-table argument to process all of them.

In fast runs, the `\denominator\facts\` count comes from the prepared `OBSFACT_PAIRS` view, so it follows whichever source (i2b2 or OMOP) was chosen during prep. Report generation is optional in fast output: missing report objects do not discard successful ontology updates.

## 3. Installation

Configure the database connection and platform in:

```text
edu.harvard.i2b2.data/Release_1-8/NewInstall/Metadata/db.properties
```

Then, from the `NewInstall/Metadata` directory, load or reload the procedures:

```sh
ant -f data_build.xml create_metadata_procedures_release_1-8
```

The loader processes the platform's procedure directory in filename order. Prefer Ant. If installing manually, use the same order and adapt the Ant `GO` delimiters to your client: SQL*Plus and SQL Developer Run Script need `/` after each executable PL/SQL block, and `psql` does not accept `GO` lines.

```text
scripts/procedures/sqlserver
scripts/procedures/oracle
scripts/procedures/postgresql
```

Review the output carefully: the Ant target continues after a SQL error so it can report further problems.

Reloading removes any previously installed `FastTotalnumWrapper` copies. Those files remain in the procedure directories only as commented reference implementations; use `RunTotalnum` / `runtotalnum` as the supported entry point.

### Scheduled runs with Ant

```sh
ant -f data_build.xml db_metadata_run_total_count_sqlserver
ant -f data_build.xml db_metadata_run_total_count_oracle
ant -f data_build.xml db_metadata_run_total_count_postgresql
```

These targets use the wrapper's defaults: fast counting, i2b2 source, ACT-only demographics, prep enabled. For OMOP, classic, a single ontology table, prep reuse, or supplemental demographics, run SQL directly.

## 4. Prerequisites

### Metadata

Fast prep builds its source list from `TABLE_ACCESS`. For the ACT visit and demographic supplements it locates the physical ontology tables through:

```text
C_TABLE_CD = ACT_VISIT
C_TABLE_CD = ACT_DEMO
```

The physical `C_TABLE_NAME` values are not hardcoded. If a mapping is absent, prep prints a notice. SQL Server handles the two supplements independently, while the combined Oracle and PostgreSQL ACT load requires both. Before running, confirm that:

- `TABLE_ACCESS.C_TABLE_NAME` points to each real ontology table.
- `ACT_VISIT` and `ACT_DEMO` identify the intended ACT tables, when installed.
- The database user can read the data tables, ontology tables, and any OMOP views the chosen mode uses.
- The database user can update ontology tables, `TABLE_ACCESS`, `TOTALNUM`, and `TOTALNUM_REPORT`.

### Oracle privileges

Oracle stored procedures do not use privileges inherited only through roles for dynamic DDL. Grant these directly to the metadata procedure owner:

```sql
GRANT CREATE PROCEDURE TO <metadata_schema>;
GRANT CREATE VIEW TO <metadata_schema>;
GRANT CREATE TABLE TO <metadata_schema>;
GRANT CREATE SEQUENCE TO <metadata_schema>;

ALTER USER <metadata_schema>
    QUOTA UNLIMITED ON <tablespace_name>;
```

`CREATE SEQUENCE` is needed for the identity used in `TNUM_ONTOLOGY`. If fact tables, ontology tables, or ACT-OMOP views live in another schema, grant `SELECT` on them directly to the procedure owner. Output objects owned by another schema also need direct `UPDATE` and `INSERT` grants.

### PostgreSQL search path

Put the metadata schema first on `search_path` and pass the data schema as the second argument. For example, when the data is in `public`:

```sql
SET search_path TO i2b2metadata, public;
CALL runtotalnum('observation_fact', 'public');
```

The wrapper is a procedure; older `SELECT runtotalnum(...)` calls must use `CALL`. For Ant, set `db.type=postgresql`, make the metadata schema first on the connection's search path, and set `db.schemaname` to the data schema. See the [PostgreSQL setup notes](totalnum.md#postgresql-search-path) for the core-server limitation on split schemas.

## 5. Running counts

### 5.1 Standard fast count

The default workflow runs prep, count, and output in one call, using the i2b2 source and ACT-only demographics.

**SQL Server**

```sql
EXEC dbo.RunTotalnum;
```

Equivalent explicit call:

```sql
EXEC dbo.RunTotalnum
    @observationTable = 'observation_fact',
    @schemaname = 'dbo',
    @tablename = '@',
    @mode = 'fast',
    @demographics_mode = 'act';
```

**Oracle**

```sql
BEGIN
  RunTotalnum(
    observationTable => 'observation_fact',
    schemaName       => 'I2B2DEMODATA'
  );
END;
/
```

**PostgreSQL**

```sql
CALL runtotalnum('observation_fact', 'public');
```

### 5.2 Reusing prepared structures

By default the wrapper rebuilds the fast prep structures (`OBSFACT_PAIRS`, `TNUM_ONTOLOGY`, `CONCEPT_CLOSURE`) on every run. After one successful prepared run, later runs can skip that step. Count and output still run.

**SQL Server**

```sql
EXEC dbo.RunTotalnum
    @schemaname = 'dbo',
    @run_prep = 0;
```

**Oracle**

```sql
BEGIN
  RunTotalnum(
    observationTable => 'observation_fact',
    schemaName       => 'I2B2DEMODATA',
    run_prep         => 0
  );
END;
/
```

**PostgreSQL**

```sql
CALL runtotalnum('observation_fact', 'public', run_prep => 0);
```

The wrapper checks only that the three prep objects exist (on Oracle, that they are also valid, in the executing metadata schema; on PostgreSQL, that they are visible on the current search path). **It cannot tell whether their content is stale.**

Run with prep enabled (the default) when:

- the ontology or `TABLE_ACCESS` mappings have changed,
- relevant source views have changed, or
- you are switching between i2b2 and OMOP source modes.

Run count and output again (prep can stay off) after patient data changes. `run_prep` applies only to the fast path; classic ignores it.

### 5.3 A single ontology table

Pass the ontology table name instead of `@`. Prep and counting still build the shared fast structures, but output is limited to the selected table.

```sql
-- SQL Server
EXEC dbo.RunTotalnum @tablename = 'MY_ONTOLOGY_TABLE';
```

```sql
-- Oracle (case-sensitive)
BEGIN
  RunTotalnum(
    observationTable => 'observation_fact',
    schemaName       => 'I2B2DEMODATA',
    tableName        => 'I2B2'
  );
END;
/
```

```sql
-- PostgreSQL
CALL runtotalnum('observation_fact', 'public', 'my_ontology');
```

With `demographics_mode = 'other'`, the supplemental searches are limited to that table as well. Reporting and all `TABLE_ACCESS` updates are not necessarily table-local.

### 5.4 ACT-OMOP

OMOP mode builds `OBSFACT_PAIRS` from the installed ACT-OMOP views instead of from `observation_fact`.

```sql
-- SQL Server
EXEC dbo.RunTotalnum @schemaname = 'dbo', @mode = 'omop';
```

```sql
-- Oracle
BEGIN
  RunTotalnum(
    observationTable => 'observation_fact',
    schemaName       => 'OMOPDEMO',
    totalnum_mode    => 'omop'
  );
END;
/
```

```sql
-- PostgreSQL
CALL runtotalnum('observation_fact', 'public', totalnum_mode => 'omop');
```

Re-run prep whenever you switch between i2b2 and OMOP.

### 5.5 Supplemental demographics

By default, fast mode counts only ACT demographics. On all three platforms, `demographics_mode = 'other'` keeps that fast path and adds metadata-defined demographics from other ontology tables:

```sql
EXEC dbo.RunTotalnum
    @schemaname = 'dbo',
    @demographics_mode = 'other';
```

```sql
-- Oracle
BEGIN
  RunTotalnum('observation_fact', 'I2B2DEMODATA', demographics_mode => 'other');
END;
/

-- PostgreSQL
CALL runtotalnum('observation_fact', 'public', demographics_mode => 'other');
```

It works with prep reuse. If using OMOP, check the source prerequisites below.
SQL Server examples:

```sql
EXEC dbo.RunTotalnum
    @schemaname = 'dbo',
    @mode = 'omop',
    @demographics_mode = 'other';

EXEC dbo.RunTotalnum
    @schemaname = 'dbo',
    @demographics_mode = 'other',
    @run_prep = 0;
```

In this mode:

- `ACT_DEMO` continues to use the fast fact-pair implementation.
- Other active ontology tables are inspected for rows backed by `patient_dimension`. The supplement evaluates their `C_COLUMNNAME`, `C_OPERATOR`, and `C_DIMCODE` expressions.
- The wrapper also checks for numeric fact constraints. SQL Server skips that step in OMOP mode. Oracle and PostgreSQL run it in both modes and require a visible `schemaName.observation_fact` table or view; in OMOP it must expose the same facts as the prep views, including `NVAL_NUM`. See [numeric-value constrained facts](totalnum.md#numeric-value-constrained-facts).
- Visit-dimension metadata outside ACT is not added.
- Supplemental patient counts are recorded in `TOTALNUM` with type `PA`.

This is slower than `act`, but much cheaper than running the full classic concept, provider, and modifier workflow.

**SQL Server validation scripts.** Run these only in a test database or disposable copy: they update counts and append `TOTALNUM` history. The [main guide](totalnum.md#include-supplemental-demographics) also links the Oracle and PostgreSQL tests.

- test\_totalnum\_demographics\_mode.sql checks the selected demographics modes.
- test\_totalnum\_constrained\_facts.sql compares constrained fact leaves against a direct `observation_fact` count.

### 5.6 Classic counting and multi-fact-table configurations

The fast i2b2 workflow reads `observation_fact`, and OMOP mode reads the ACT-OMOP views. Use classic when a different fact table or a union fact view must drive counting.

Select classic through the wrapper:

```sql
-- SQL Server
EXEC dbo.RunTotalnum
    @observationTable = 'observation_fact',
    @schemaname = 'dbo',
    @mode = 'classic';
```

```sql
-- Oracle
BEGIN
  RunTotalnum(
    observationTable => 'observation_fact',
    schemaName       => 'I2B2DEMODATA',
    totalnum_mode    => 'classic'
  );
END;
/
```

```sql
-- PostgreSQL
CALL runtotalnum('observation_fact', 'public', totalnum_mode => 'classic');
```

Or call the classic implementation directly:

```sql
-- SQL Server
EXEC dbo.RunTotalnumClassic
    @observationTable = 'observation_fact',
    @schemaname = 'dbo',
    @tablename = '@',
    @wildcard_factcolumn = 'N';
```

```sql
-- Oracle
BEGIN
  RunTotalnumClassic(
    observationTable => 'observation_fact',
    schemaName       => 'I2B2DEMODATA',
    tableName        => '@'
  );
END;
/
```

```sql
-- PostgreSQL
SELECT runtotalnumclassic('observation_fact', 'public', '@');
```

**Automatic routing.** A custom observation table passed to a fast/i2b2 wrapper call routes to classic automatically. On SQL Server, `@wildcard_factcolumn = 'Y'` does too.

**Union fact views.** A typical union view:

```sql
CREATE VIEW observation_fact_view AS
SELECT * FROM condition_view
UNION ALL
SELECT * FROM drug_view;
```

Pass the view to the classic procedure. This assumes concept codes do not conflict across the combined sources. On SQL Server, `@wildcard_factcolumn = 'Y'` additionally makes classic ignore ontology fact-column prefixes:

```sql
EXEC dbo.RunTotalnumClassic
    @observationTable = 'observation_fact_view',
    @schemaname = 'dbo',
    @tablename = '@',
    @wildcard_factcolumn = 'Y';
```

### 5.7 Running the fast steps manually

The wrapper runs prep, count, and output in sequence. Run the steps yourself for more control. Use `'omop'` instead of `'i2b2'` for ACT-OMOP views. (The legacy `FastTotalnumPrepOMOP` remains as a compatibility wrapper; new automation should use `FastTotalnumPrep` with `source_mode`.)

**SQL Server**

```sql
EXEC dbo.FastTotalnumPrep
    @schemaname = 'dbo',
    @source_mode = 'i2b2';

EXEC dbo.FastTotalnumCount;

EXEC dbo.FastTotalnumOutput
    @schemaname = 'dbo',
    @tablename = '@',
    @demographics_mode = 'act';
```

For supplemental demographics, add two supplemental steps between count and output, and pass `'other'` to output:

```sql
EXEC dbo.FastTotalnumAdditionalDimensions
    @schemaname = 'dbo',
    @tablename = '@';

EXEC dbo.FastTotalnumConstrainedFacts
    @schemaname = 'dbo',
    @tablename = '@',
    @source_mode = 'i2b2';
```

**Oracle**

```sql
BEGIN
  FastTotalnumPrep('I2B2DEMODATA', 'i2b2');
  FastTotalnumCount;
  FastTotalnumOutput('I2B2DEMODATA', '@');
END;
/
```

**PostgreSQL**

```sql
SELECT fasttotalnumprep('public', 'i2b2');
CALL fasttotalnumcount('public');
CALL fasttotalnumoutput('public', '@');
```

For Oracle and PostgreSQL `other` runs, see the [manual supplemental calls](totalnum.md#run-the-fast-steps-manually). The output procedures execute their updates directly. Do not re-run any printed update statements by hand.

## 6. Count types

`TOTALNUM` rows are tagged by how they were produced:

| Type | Meaning |
| --- | --- |
| `PF` | Ordinary fast patient counts |
| `PA` | Supplemental counts in `demographics_mode = 'other'` |
| `PD` | Classic patient and visit counts |

Output and report generation select the appropriate types for the requested mode.

## 7. Operational notes

- Do not run overlapping prep jobs in the same metadata schema: prep recreates the shared `OBSFACT_PAIRS`, `TNUM_ONTOLOGY`, and `CONCEPT_CLOSURE` objects.
- Review informational skip messages. A missing `ACT_VISIT` or `ACT_DEMO` mapping is allowed, but may indicate an unintended `TABLE_ACCESS` configuration.
- Compare classic and fast results before changing production scheduling, especially for custom ontologies, site-specific demographic expressions, or multi-fact configurations.

## 8. Upgrading from the previous behavior

**The most important change:** the Ant total-count targets call the common wrapper, so scheduled jobs now run fast instead of classic.

| Before | Now | Migration action |
| --- | --- | --- |
| `RunTotalnum` / `runtotalnum` ran classic counting | The same name is a wrapper that defaults to fast (prep, count, output) | Set `@mode = 'classic'` on SQL Server or `totalnum_mode => 'classic'` on Oracle and PostgreSQL |
| Fast users called prep, count, and output separately | The wrapper does all three | Use the wrapper; skip prep only when its structures are still current |
| Repeated fast runs always rebuilt prep | The wrapper can reuse an existing prep | See section 5.2, Reusing prepared structures |
| Classic used the common procedure name | Classic is `RunTotalnumClassic` / `runtotalnumclassic`, in `totalnum_classic.sql` (formerly `run_all_counts.sql`) | Update direct classic calls; load all procedure files rather than naming one |
| Separate i2b2 and OMOP prep variants | One `FastTotalnumPrep` with `source_mode` | Pass `omop` instead of maintaining a separate copy |
| ACT table names could be hardcoded | Resolved through `ACT_VISIT` and `ACT_DEMO` rows in `TABLE_ACCESS` | Maintain correct mappings |
| Missing ACT tables could stop prep | Missing mappings are skipped with a notice | Review the notice |
| Supplemental demographics was unavailable or called `all` | All platforms support `demographics_mode = 'other'` | Keep `act` or opt in to `other`; replace existing `all` arguments |
| Earlier PostgreSQL jobs used a function, `mode`, or boolean prep values | The wrapper is a procedure with `totalnum_mode` and integer `run_prep` | Use `CALL runtotalnum(...)` and `0`/`1`; direct `SELECT fasttotalnumprep(...)` is unchanged |
| Some output SQL was diagnostic/manual | Output procedures run their updates directly | Do not re-run printed updates manually |

The common two-argument form still works with the current invocation syntax. Calls with custom fact tables are routed to classic in fast i2b2 mode, and direct classic report calls remain valid. On SQL Server, the legacy `PAT_COUNT_VISITS` entry point remains and delegates to a shared metadata-dimension evaluator.
