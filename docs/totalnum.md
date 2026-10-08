# Running totalnum Patient Counts

Totalnum calculates patient counts for ontology nodes and writes them to the
metadata tables used by i2b2. The `RunTotalnum` wrapper (`runtotalnum` in
PostgreSQL) defaults to the fast workflow. Classic counting remains available
for compatibility and specialized fact-table configurations.

## Modes and platform support

| Mode or option | SQL Server | Oracle | PostgreSQL |
| --- | --- | --- | --- |
| Fast i2b2 (`fast` or `i2b2`; default) | Yes | Yes | Yes |
| Fast ACT-OMOP (`omop`) | Yes | Yes | Yes |
| Fast ACT-only demographics (default) | `@demographics_mode = 'act'` | Built in | Built in |
| Fast all demographics, including non-ACT `patient_dimension` rows | `@demographics_mode = 'all'` | No | No |
| Numeric-value constrained facts in fast all mode | Yes, i2b2 source only | No | No |
| Fast count without rebuilding prep | `@run_prep = 0` | `run_prep => 0` | `run_prep => false` |
| Fast output for one ontology table | `@tablename` | `tableName` | Third argument |
| Classic counting (`classic`) for custom or union fact tables | Yes | Yes | Yes |
| Classic wildcard fact-column matching | `@wildcard_factcolumn = 'Y'` | No | No |

`demographics_mode` and `wildcard_factcolumn` are SQL Server-only wrapper
parameters. Oracle and PostgreSQL use the optimized ACT demographic path in
fast mode and have no fast `all` option.

## Install and prepare

Configure the connection and database platform in
`edu.harvard.i2b2.data/Release_1-8/NewInstall/Metadata/db.properties`. From
`NewInstall/Metadata`, load the procedures with:

```sh
ant -f data_build.xml create_metadata_procedures_release_1-8
```

The loader processes the top-level `.sql` files in
`scripts/procedures/sqlserver`, `scripts/procedures/oracle`, or
`scripts/procedures/postgresql` in filename order. If installing manually,
load all files in the selected directory in that order. Check the install
output: the Ant target continues after SQL errors. The historical
`FastTotalnumWrapper` files are retained as commented references; use
`RunTotalnum` or `runtotalnum` for new calls.

The platform-specific Ant count targets run the default fast i2b2 workflow
with prep enabled:

```sh
ant -f data_build.xml db_metadata_run_total_count_sqlserver
ant -f data_build.xml db_metadata_run_total_count_oracle
ant -f data_build.xml db_metadata_run_total_count_postgresql
```

Fast prep reads active ontology tables from `TABLE_ACCESS`. It resolves the
physical ACT visit and demographic tables from `C_TABLE_NAME` where
`C_TABLE_CD` is `ACT_VISIT` or `ACT_DEMO`. Missing mappings produce a notice
and skip the corresponding supplement. Check that the remaining
`TABLE_ACCESS.C_TABLE_NAME` values point to real ontology tables and that the
database user can read the selected fact source and update the metadata tables.
Investigate unexpected missing-ACT notices; they may indicate incorrect
`TABLE_ACCESS` configuration.

### Oracle privileges

Oracle's dynamic DDL requires privileges granted directly to the metadata
procedure owner, rather than through a role:

```sql
GRANT CREATE PROCEDURE TO <metadata_schema>;
GRANT CREATE VIEW TO <metadata_schema>;
GRANT CREATE TABLE TO <metadata_schema>;
GRANT CREATE SEQUENCE TO <metadata_schema>;

ALTER USER <metadata_schema>
    QUOTA UNLIMITED ON <tablespace_name>;
```

`CREATE SEQUENCE` supports the identity in `TNUM_ONTOLOGY`. For objects owned
by another schema, grant `SELECT` on source tables and views directly to the
procedure owner. Grant direct `UPDATE` and `INSERT` on output objects owned
by another schema.

### PostgreSQL search path

When metadata and data objects are in different schemas, make both visible to
the procedures. For example:

```sql
SET search_path TO i2b2metadata, public;
```

## Run fast counts

The normal sequence is: run once with prep enabled, then skip prep on later
counts while the prepared structures still match the ontology and source
mode. The default call runs `FastTotalnumPrep`, `FastTotalnumCount`, and
`FastTotalnumOutput`; disabling prep still runs count and output.

### SQL Server

```sql
-- First run, or after changing the ontology or source mode.
EXEC dbo.RunTotalnum;

-- Later runs using the same prepared structures.
EXEC dbo.RunTotalnum @run_prep = 0;
```

The default source is i2b2 `observation_fact`, with optimized ACT-only
demographics. `@mode = 'i2b2'` is an alias for the default `fast` mode.

### Oracle

```sql
BEGIN
  RunTotalnum(
    observationTable => 'observation_fact',
    schemaName        => 'I2B2DEMODATA'
  );
END;
/

BEGIN
  RunTotalnum(
    observationTable => 'observation_fact',
    schemaName        => 'I2B2DEMODATA',
    run_prep          => 0
  );
END;
/
```

### PostgreSQL

```sql
SELECT runtotalnum('observation_fact', 'public');
SELECT runtotalnum('observation_fact', 'public', run_prep => false);
```

On all three platforms, prep creates `OBSFACT_PAIRS`, `TNUM_ONTOLOGY`, and
`CONCEPT_CLOSURE`. The wrappers check that these objects exist before skipping
prep (Oracle also checks validity), but cannot detect stale content. Re-enable
prep after ontology or `TABLE_ACCESS` changes, after relevant source-view
changes, or when switching between i2b2 and OMOP. Prep is enabled by default:
`@run_prep = 1` on SQL Server, `run_prep => 1` on Oracle, and
`run_prep => true` on PostgreSQL. Classic mode ignores this option.

After patient data changes, count and output need to run again, even when prep
can be reused. Avoid overlapping prep jobs in one metadata schema because
prep recreates shared objects.

## Choose an ACT-OMOP source

Use `omop` mode to build `OBSFACT_PAIRS` from the installed ACT-OMOP views.
The first call must run prep for that source; later calls can reuse it:

```sql
-- SQL Server
EXEC dbo.RunTotalnum @schemaname = 'dbo', @mode = 'omop';
EXEC dbo.RunTotalnum @schemaname = 'dbo', @mode = 'omop', @run_prep = 0;
```

```sql
-- Oracle
BEGIN
  RunTotalnum('observation_fact', 'OMOPDEMO', mode => 'omop');
  RunTotalnum('observation_fact', 'OMOPDEMO', mode => 'omop', run_prep => 0);
END;
/
```

```sql
-- PostgreSQL
SELECT runtotalnum('observation_fact', 'public', mode => 'omop');
SELECT runtotalnum('observation_fact', 'public', mode => 'omop', run_prep => false);
```

Fast prep uses one procedure per platform with `source_mode = 'i2b2'` or
`source_mode = 'omop'`. SQL Server also retains `FastTotalnumPrepOMOP` as a
compatibility alias; new automation should use `FastTotalnumPrep` with
`@source_mode = 'omop'`.

## Include all demographics (SQL Server only)

`@demographics_mode = 'all'` keeps the optimized ACT demographic path and adds
metadata-defined non-ACT `patient_dimension` counts. It evaluates
`C_COLUMNNAME`, `C_OPERATOR`, and `C_DIMCODE` through the shared classic
dimension counter. The default `act` mode skips this extra work.

```sql
-- First run with prep, then reuse it.
EXEC dbo.RunTotalnum @demographics_mode = 'all';
EXEC dbo.RunTotalnum @demographics_mode = 'all', @run_prep = 0;
```

The patient-dimension supplement works with i2b2 and OMOP sources. In i2b2
mode, `all` also counts fact metadata using the strict
`nval_num = number AND concept_cd` form. It rebuilds affected fact-only
hierarchy branches so constrained leaves and shortcut folders agree; mixed
higher roots retain the ordinary fast count. This constrained-fact supplement
is skipped with a message in OMOP mode. Non-ACT `visit_dimension` metadata is
not added by `all`.

Supplemental patient counts use `TOTALNUM.TYPEFLAG_CD = 'PA'`; fast ACT counts
use `PF`. Output chooses the appropriate rows for the mode. This option is
slower than ACT-only counting, but avoids the full classic concept, provider,
and modifier workflow.

SQL Server validation scripts:
[all demographics](../edu.harvard.i2b2.data/Release_1-8/NewInstall/Metadata/scripts/procedures/sqlserver/tests/test_totalnum_demographics_mode.sql)
and [constrained facts](../edu.harvard.i2b2.data/Release_1-8/NewInstall/Metadata/scripts/procedures/sqlserver/tests/test_totalnum_constrained_facts.sql).
Run them only in a test database or disposable copy; they update counts and
append `TOTALNUM` history.

## Limit output to one ontology table

Use the table's physical name from `TABLE_ACCESS.C_TABLE_NAME`. The fast prep
and count steps still build shared structures; only output is limited to the
selected table. In SQL Server `all` mode, the supplemental steps are also
limited to that table. Oracle and PostgreSQL table names are case-sensitive.

```sql
-- SQL Server
EXEC dbo.RunTotalnum @tablename = 'MY_ONTOLOGY_TABLE';
```

```sql
-- Oracle
BEGIN
  RunTotalnum('observation_fact', 'I2B2DEMODATA', tableName => 'I2B2');
END;
/
```

```sql
-- PostgreSQL
SELECT runtotalnum('observation_fact', 'public', 'my_ontology');
```

Use `@` to process all active ontology tables.

## Run classic counting

Classic reproduces the previous totalnum algorithm and supports a custom or
union fact table. Request `classic` through the wrapper:

```sql
-- SQL Server
EXEC dbo.RunTotalnum @mode = 'classic';
```

```sql
-- Oracle
BEGIN
  RunTotalnum('observation_fact', 'I2B2DEMODATA', mode => 'classic');
END;
/
```

```sql
-- PostgreSQL
SELECT runtotalnum('observation_fact', 'public', mode => 'classic');
```

The direct classic entry points are `dbo.RunTotalnumClassic` on SQL Server,
`RunTotalnumClassic` on Oracle, and `runtotalnumclassic` on PostgreSQL. A custom
observation table passed with fast/i2b2 mode automatically routes to classic.
For a union fact view, ensure concept codes do not conflict across its source
tables. For example:

```sql
CREATE VIEW observation_fact_view AS
SELECT * FROM condition_view
UNION ALL
SELECT * FROM drug_view;
```

Compare classic and fast results before changing production scheduling for
custom ontologies, site-specific demographics, or multiple fact sources.

### Wildcard fact-column matching (SQL Server only)

For a union fact view whose ontology fact-column prefixes should be ignored,
use the classic wildcard flag:

```sql
EXEC dbo.RunTotalnumClassic
    @observationTable = 'observation_fact_view',
    @schemaname = 'dbo',
    @tablename = '@',
    @wildcard_factcolumn = 'Y';
```

Passing `@wildcard_factcolumn = 'Y'` to the SQL Server wrapper also routes
fast/i2b2 calls to classic. Oracle and PostgreSQL do not have this flag.

## Run the fast steps manually

Call the individual routines when a job scheduler needs separate prep,
count, and output stages. For i2b2 with ACT-only demographics:

```sql
-- SQL Server
EXEC dbo.FastTotalnumPrep @schemaname = 'dbo', @source_mode = 'i2b2';
EXEC dbo.FastTotalnumCount;
EXEC dbo.FastTotalnumOutput @schemaname = 'dbo', @tablename = '@',
    @demographics_mode = 'act';
```

```sql
-- Oracle
BEGIN
  FastTotalnumPrep('I2B2DEMODATA', 'i2b2');
  FastTotalnumCount;
  FastTotalnumOutput('I2B2DEMODATA', '@');
END;
/
```

```sql
-- PostgreSQL
SELECT fasttotalnumprep('public', 'i2b2');
CALL fasttotalnumcount();
CALL fasttotalnumoutput('public', '@');
```

For OMOP, use `omop` as the prep source. In SQL Server `all` mode, replace the
ACT-only output call above with these steps after `FastTotalnumCount`:

```sql
-- SQL Server only; run after FastTotalnumCount.
EXEC dbo.FastTotalnumAdditionalDimensions @schemaname = 'dbo', @tablename = '@';
EXEC dbo.FastTotalnumConstrainedFacts @schemaname = 'dbo', @tablename = '@',
    @source_mode = 'i2b2';
EXEC dbo.FastTotalnumOutput @schemaname = 'dbo', @tablename = '@',
    @demographics_mode = 'all';
```

With OMOP, pass `@source_mode = 'omop'` to the constrained-fact procedure; it
will report that it is skipping that supplement.

## What the scripts update

A successful run can update `C_TOTALNUM` in active ontology tables,
`TABLE_ACCESS.C_TOTALNUM` for ontology roots, `TOTALNUM` count history, and the
obfuscated `TOTALNUM_REPORT`. Active tables have `C_VISUALATTRIBUTES`
containing `A` in `TABLE_ACCESS`. Fast output treats report generation as
optional; missing report objects do not discard successful ontology updates.

For fast runs, the `\denominator\facts\` count comes from the prepared
`OBSFACT_PAIRS` view, following the i2b2 or OMOP source selected during prep.

## Changes from earlier versions

| Before | Now | Action |
| --- | --- | --- |
| `RunTotalnum`/`runtotalnum` ran classic counting | The same name defaults to fast | Request `classic` where the old algorithm is required |
| Fast runs required separate prep, count, and output calls | The wrapper runs all three by default | Use the wrapper; disable prep when its structures are current |
| Classic used the common procedure name or `run_all_counts.sql` | The implementation is `RunTotalnumClassic`/`runtotalnumclassic` in `totalnum_classic.sql` | Update direct classic calls |
| i2b2 and OMOP prep could require separate script variants | One prep accepts `source_mode` | Pass `omop` for ACT-OMOP views |
| ACT table names could be hardcoded | Prep resolves `ACT_VISIT` and `ACT_DEMO` via `TABLE_ACCESS` | Keep those mappings current; missing entries are skipped with a notice |
| Fast counts covered ACT demographics only | SQL Server can opt into `demographics_mode = 'all'` | Choose `all` only on SQL Server when non-ACT demographics are needed |
| Some output SQL had to be run manually | Output procedures execute the updates | Do not rerun printed updates |

The Ant count targets call the common wrapper, so they now run fast. The
common two-argument calls still work, but sites that require classic behavior
must request it explicitly. SQL Server's legacy `PAT_COUNT_VISITS` remains
available and delegates to a shared metadata-dimension evaluator. Classic
patient/visit counts use `TOTALNUM.TYPEFLAG_CD = 'PD'`.
