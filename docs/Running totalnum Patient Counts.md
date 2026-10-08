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
| Fast count reusing existing prep | `@run_prep = 0` | `run_prep => 0` | `run_prep => false` |
| Fast output for one ontology table | `@tablename` | `tableName` | third argument |
| Classic counting (`classic`) | Yes | Yes | Yes |
| Fast ACT-only demographics | `@demographics_mode = 'act'` (default) | Built in | Built in |
| Fast all demographics (non-ACT `patient_dimension` rows) | `@demographics_mode = 'all'` | No | No |
| Numeric-value constrained facts (within fast `all`) | i2b2 source only | No | No |
| Classic wildcard fact-column matching | `@wildcard_factcolumn = 'Y'` | No | No |

`demographics_mode` and `wildcard_factcolumn` are SQL Server-only parameters. Oracle and PostgreSQL always use the optimized ACT demographic path in fast mode.

### Parameter names by platform

| Meaning | SQL Server | Oracle | PostgreSQL |
| --- | --- | --- | --- |
| Fact table | `@observationTable` | `observationTable` | 1st argument |
| Data schema | `@schemaname` | `schemaName` | 2nd argument |
| Ontology table (`@` = all active) | `@tablename` | `tableName` | 3rd argument |
| Mode | `@mode` | `mode` | `mode` |
| Reuse prep | `@run_prep` (0/1) | `run_prep` (0/1) | `run_prep` (false/true) |

`mode = 'i2b2'` is an alias for `mode = 'fast'`. Ontology table names are case-sensitive on Oracle and PostgreSQL.

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

The loader processes the platform's procedure directory in filename order. For a manual install, run every top-level `.sql` file in the matching directory in the same sorted order:

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

These targets use the wrapper's defaults: fast counting, i2b2 source, ACT-only demographics, prep enabled. For OMOP, classic, a single ontology table, prep reuse, or SQL Server all-demographics mode, run SQL directly.

## 4. Prerequisites

### Metadata

Fast prep builds its source list from `TABLE_ACCESS`. For the ACT visit and demographic supplements it locates the physical ontology tables through:

```text
C_TABLE_CD = ACT_VISIT
C_TABLE_CD = ACT_DEMO
```

The physical `C_TABLE_NAME` values are not hardcoded. If either mapping is absent, prep prints a notice and skips that supplement instead of failing the run. Before running, confirm that:

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

If metadata and data objects are in different schemas, make both visible:

```sql
SET search_path TO i2b2metadata, public;
```

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
SELECT runtotalnum('observation_fact', 'public');
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
SELECT runtotalnum('observation_fact', 'public', run_prep => false);
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
-- PostgreSQL (case-sensitive)
SELECT runtotalnum('observation_fact', 'public', 'my_ontology');
```

On SQL Server with `demographics_mode = 'all'`, the supplemental demographics are limited to that table as well.

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
    mode             => 'omop'
  );
END;
/
```

```sql
-- PostgreSQL
SELECT runtotalnum('observation_fact', 'public', mode => 'omop');
```

Re-run prep whenever you switch between i2b2 and OMOP.

### 5.5 SQL Server: all demographics

By default, fast mode counts only the ACT demographic tables. On SQL Server, `demographics_mode = 'all'` keeps that fast path and adds metadata-defined demographics from other ontology tables:

```sql
EXEC dbo.RunTotalnum
    @schemaname = 'dbo',
    @demographics_mode = 'all';
```

It works with OMOP source mode and with prep reuse:

```sql
EXEC dbo.RunTotalnum
    @schemaname = 'dbo',
    @mode = 'omop',
    @demographics_mode = 'all';

EXEC dbo.RunTotalnum
    @schemaname = 'dbo',
    @demographics_mode = 'all',
    @run_prep = 0;
```

In this mode:

- `ACT_DEMO` continues to use the fast fact-pair implementation.
- Other active ontology tables are inspected for rows backed by `patient_dimension`. Their `C_COLUMNNAME`, `C_OPERATOR`, and `C_DIMCODE` expressions are evaluated with the shared classic dimension-counting code.
- With the i2b2 source, metadata using the strict `nval_num = number AND concept_cd` constraint form is also counted. Affected fact-only hierarchy branches are rebuilt so constrained leaves and their shortcut folders agree; mixed higher roots keep the normal fast count. In OMOP mode this step is skipped with a message.
- Visit-dimension metadata outside ACT is not added.
- Supplemental patient counts are recorded in `TOTALNUM` with type `PA`.

This is slower than `act`, but much cheaper than running the full classic concept, provider, and modifier workflow.

**Validation scripts.** Run these only in a test database or disposable copy: they update counts and append `TOTALNUM` history.

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
    mode             => 'classic'
  );
END;
/
```

```sql
-- PostgreSQL
SELECT runtotalnum('observation_fact', 'public', mode => 'classic');
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

For all demographics, add two supplemental steps between count and output, and pass `'all'` to output:

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
CALL fasttotalnumcount();
CALL fasttotalnumoutput('public', '@');
```

The output procedures execute their updates directly. Do not re-run any printed update statements by hand.

## 6. Count types

`TOTALNUM` rows are tagged by how they were produced:

| Type | Meaning |
| --- | --- |
| `PF` | Fast patient counts (SQL Server) |
| `PA` | Supplemental all-demographics counts (SQL Server, `demographics_mode = 'all'`) |
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
| `RunTotalnum` / `runtotalnum` ran classic counting | The same name is a wrapper that defaults to fast (prep, count, output) | Add `mode = 'classic'` wherever classic behavior is required |
| Fast users called prep, count, and output separately | The wrapper does all three | Use the wrapper; skip prep only when its structures are still current |
| Repeated fast runs always rebuilt prep | The wrapper can reuse an existing prep | See section 5.2, Reusing prepared structures |
| Classic used the common procedure name | Classic is `RunTotalnumClassic` / `runtotalnumclassic`, in `totalnum_classic.sql` (formerly `run_all_counts.sql`) | Update direct classic calls; load all procedure files rather than naming one |
| Separate i2b2 and OMOP prep variants | One `FastTotalnumPrep` with `source_mode` | Pass `omop` instead of maintaining a separate copy |
| ACT table names could be hardcoded | Resolved through `ACT_VISIT` and `ACT_DEMO` rows in `TABLE_ACCESS` | Maintain correct mappings |
| Missing ACT tables could stop prep | Missing mappings are skipped with a notice | Review the notice |
| No fast all-demographics mode | SQL Server supports `demographics_mode = 'all'` | Keep `act` for maximum speed, or opt in to `all` |
| Some output SQL was diagnostic/manual | Output procedures run their updates directly | Do not re-run printed updates manually |

The switch is source-compatible but not behaviorally identical. Common two-argument calls (such as those in the Ant targets) still work, calls with custom fact tables are routed to classic where needed, and existing direct classic report calls remain valid because the new report parameters are optional. On SQL Server, the legacy `PAT_COUNT_VISITS` entry point remains and now delegates to a shared metadata-dimension evaluator.
