# Running totalnum Patient Counts

The totalnum scripts calculate patient counts for ontology nodes and write the
results to the metadata tables used by i2b2. They support a fast workflow for
normal operation and a classic workflow for compatibility and specialized
fact-table configurations.

This guide covers SQL Server, Oracle, and PostgreSQL.

## Choose a workflow

| Scenario | Recommended workflow | Platforms |
| --- | --- | --- |
| Standard i2b2 `observation_fact` | Fast, `i2b2` source mode | All |
| ACT-OMOP fact views | Fast, `omop` source mode | All |
| ACT demographics only | Fast default; named `act` on SQL Server | All |
| ACT plus demographics from other ontology tables | Fast, `all` demographics mode | SQL Server only |
| Custom or union fact table | Classic | All |
| SQL Server wildcard fact-column matching | Classic | SQL Server |
| Reproduce the previous totalnum algorithm | Classic | All |

The normal entry point is still named `RunTotalnum` on SQL Server and Oracle,
and `runtotalnum` on PostgreSQL. It now defaults to the fast workflow.

## What the scripts update

A successful run can update:

- `C_TOTALNUM` in active ontology tables listed in `TABLE_ACCESS`.
- `TABLE_ACCESS.C_TOTALNUM` for ontology roots.
- `TOTALNUM`, which retains count history.
- `TOTALNUM_REPORT`, which contains the latest obfuscated report counts.

Only active `TABLE_ACCESS` rows, identified by `C_VISUALATTRIBUTES` containing
`A`, are processed. Use `@` as the ontology-table argument to process all active
ontology tables.

The `\denominator\facts\` count comes from the prepared `OBSFACT_PAIRS` view, so
it follows the i2b2 or OMOP source selected during prep. Report generation is
optional; missing report objects do not discard successful ontology updates.

## Install or reload the procedures

Configure the database connection and platform in:

```text
edu.harvard.i2b2.data/Release_1-8/NewInstall/Metadata/db.properties
```

From the `NewInstall/Metadata` directory, load the procedures with:

```sh
ant -f data_build.xml create_metadata_procedures_release_1-8
```

The loader processes the platform's procedure directory in filename order. If
installing manually, run every top-level `.sql` file in the corresponding
directory in the same sorted order:

```text
scripts/procedures/sqlserver
scripts/procedures/oracle
scripts/procedures/postgresql
```

Review the install output carefully. The Ant procedure target continues after a
SQL error so that it can report additional installation problems.

The platform-specific Ant count targets remain available:

```sh
ant -f data_build.xml db_metadata_run_total_count_sqlserver
ant -f data_build.xml db_metadata_run_total_count_oracle
ant -f data_build.xml db_metadata_run_total_count_postgresql
```

These targets use the wrapper's defaults: fast counting, i2b2 source mode, and
ACT-only fast demographics. Run SQL directly for OMOP, classic, SQL Server
all-demographics mode, or a single ontology table.

The historical `FastTotalnumWrapper` files remain in the procedure directories
as commented reference implementations. Reloading procedures removes any
previously installed copies; use `RunTotalnum` or `runtotalnum` as the supported
entry point.

## Metadata requirements

Fast prep builds its source list from `TABLE_ACCESS`. For ACT visit and
demographic supplements, it finds the physical ontology table names using:

```text
C_TABLE_CD = ACT_VISIT
C_TABLE_CD = ACT_DEMO
```

The physical `C_TABLE_NAME` values are not hardcoded. If either mapping is
absent, prep prints a notice and skips that supplement rather than failing the
entire run.

Before running, confirm that:

- `TABLE_ACCESS.C_TABLE_NAME` points to each real ontology table.
- `ACT_VISIT` and `ACT_DEMO` identify the intended ACT tables when installed.
- The database user can read the data tables, ontology tables, and OMOP views
  used by the selected mode.
- The database user can update ontology tables, `TABLE_ACCESS`, `TOTALNUM`, and
  `TOTALNUM_REPORT`.

## SQL Server

### Standard fast count

This is the default and fastest ACT-oriented workflow:

```sql
EXEC dbo.RunTotalnum;
```

An explicit call is:

```sql
EXEC dbo.RunTotalnum
    @observationTable = 'observation_fact',
    @schemaname = 'dbo',
    @tablename = '@',
    @mode = 'fast',
    @demographics_mode = 'act';
```

`mode = 'i2b2'` is an alias for `mode = 'fast'`.

### ACT-OMOP fast count

```sql
EXEC dbo.RunTotalnum
    @schemaname = 'dbo',
    @mode = 'omop';
```

OMOP mode builds `OBSFACT_PAIRS` from the installed ACT-OMOP views rather than
from `observation_fact`.

### All demographics

SQL Server can retain the optimized ACT demographic path and supplement it with
metadata-defined demographics from other ontology tables:

```sql
EXEC dbo.RunTotalnum
    @schemaname = 'dbo',
    @demographics_mode = 'all';
```

In this mode:

- `ACT_DEMO` continues to use the existing fast fact-pair implementation.
- Other active ontology tables are inspected for rows backed by
  `patient_dimension`.
- Their `C_COLUMNNAME`, `C_OPERATOR`, and `C_DIMCODE` expressions are evaluated
  using the shared classic dimension-counting implementation.
- SQL Server i2b2 fact metadata using the strict
  `nval_num = number AND concept_cd` constraint form is also counted. Affected
  fact-only hierarchy branches are rebuilt so constrained leaves and their
  shortcut folders agree. Mixed higher roots retain the normal fast count.
- Visit-dimension metadata outside ACT is not added by this option.
- Supplemental patient counts are recorded in `TOTALNUM` with type `PA`.

This option is expected to be slower than `act`, but it avoids the much larger
cost of running the entire classic concept, provider, and modifier workflow.

It can be combined with OMOP source mode:

```sql
EXEC dbo.RunTotalnum
    @schemaname = 'dbo',
    @mode = 'omop',
    @demographics_mode = 'all';
```

The additional `patient_dimension` pass works in both source modes. Constrained
fact metadata currently requires the i2b2 `observation_fact` source and is
skipped with a message in OMOP mode.

The SQL Server validation script is
[test_totalnum_demographics_mode.sql](../edu.harvard.i2b2.data/Release_1-8/NewInstall/Metadata/scripts/procedures/sqlserver/tests/test_totalnum_demographics_mode.sql).

Constrained fact leaves can be checked against a direct `observation_fact`
count with
[test_totalnum_constrained_facts.sql](../edu.harvard.i2b2.data/Release_1-8/NewInstall/Metadata/scripts/procedures/sqlserver/tests/test_totalnum_constrained_facts.sql).

Run the validation scripts only in a test database or disposable copy. They
update counts and append `TOTALNUM` history while checking the selected modes
and constrained leaves.

### Reuse prepared structures

By default, `RunTotalnum` rebuilds the fast prep structures before counting.
After one successful prepared run, later counts can skip that work:

```sql
EXEC dbo.RunTotalnum
    @schemaname = 'dbo',
    @demographics_mode = 'all',
    @run_prep = 0;
```

The wrapper checks that `OBSFACT_PAIRS`, `TNUM_ONTOLOGY`, and
`CONCEPT_CLOSURE` exist before continuing. It cannot tell whether their content
is stale. Run with `@run_prep = 1` (the default) after ontology or
`TABLE_ACCESS` changes, after relevant source views change, or before switching
between i2b2 and OMOP source modes. The option applies only to the fast path;
classic routing ignores it.

### Single ontology table

```sql
EXEC dbo.RunTotalnum
    @tablename = 'MY_ONTOLOGY_TABLE';
```

Prep and counting still build the shared fast structures, but output is limited
to the selected ontology table. With `demographics_mode = 'all'`, supplemental
demographics are also limited to that table.

### Classic count

Use the wrapper:

```sql
EXEC dbo.RunTotalnum
    @observationTable = 'observation_fact',
    @schemaname = 'dbo',
    @mode = 'classic';
```

Or call the classic implementation directly:

```sql
EXEC dbo.RunTotalnumClassic
    @observationTable = 'observation_fact',
    @schemaname = 'dbo',
    @tablename = '@',
    @wildcard_factcolumn = 'N';
```

A custom fact table or `@wildcard_factcolumn = 'Y'` automatically routes a
normal fast/i2b2 wrapper call to `RunTotalnumClassic`.

For a union fact view whose ontology fact-column prefixes should be ignored:

```sql
EXEC dbo.RunTotalnumClassic
    @observationTable = 'observation_fact_view',
    @schemaname = 'dbo',
    @tablename = '@',
    @wildcard_factcolumn = 'Y';
```

### Manual fast steps

The wrapper runs all steps by default. Use `@run_prep = 0` as shown above to
reuse prepared structures through the wrapper, or run the steps separately for
more control.

Standard i2b2 and ACT-only demographics:

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

All demographics adds two supplemental steps between counting and output:

```sql
EXEC dbo.FastTotalnumPrep
    @schemaname = 'dbo',
    @source_mode = 'i2b2';

EXEC dbo.FastTotalnumCount;

EXEC dbo.FastTotalnumAdditionalDimensions
    @schemaname = 'dbo',
    @tablename = '@';

EXEC dbo.FastTotalnumConstrainedFacts
    @schemaname = 'dbo',
    @tablename = '@',
    @source_mode = 'i2b2';

EXEC dbo.FastTotalnumOutput
    @schemaname = 'dbo',
    @tablename = '@',
    @demographics_mode = 'all';
```

For OMOP, change the prep call to `@source_mode = 'omop'`. The legacy
`FastTotalnumPrepOMOP` procedure remains as a compatibility wrapper, but new
automation should use `FastTotalnumPrep` with `source_mode`.

## Oracle

### Required direct privileges

Oracle stored procedures do not use privileges inherited only through roles for
dynamic DDL. Grant the required privileges directly to the metadata procedure
owner:

```sql
GRANT CREATE PROCEDURE TO <metadata_schema>;
GRANT CREATE VIEW TO <metadata_schema>;
GRANT CREATE TABLE TO <metadata_schema>;
GRANT CREATE SEQUENCE TO <metadata_schema>;

ALTER USER <metadata_schema>
    QUOTA UNLIMITED ON <tablespace_name>;
```

`CREATE SEQUENCE` is required by the identity used in `TNUM_ONTOLOGY`. If fact
tables, ontology tables, or ACT-OMOP views are owned by another schema, grant
`SELECT` on those objects directly to the metadata procedure owner. Direct
`UPDATE` and `INSERT` grants are also required for output objects owned by
another schema.

### Standard fast count

```sql
BEGIN
  RunTotalnum(
    observationTable => 'observation_fact',
    schemaName        => 'I2B2DEMODATA'
  );
END;
/
```

### ACT-OMOP fast count

```sql
BEGIN
  RunTotalnum(
    observationTable => 'observation_fact',
    schemaName        => 'OMOPDEMO',
    mode              => 'omop'
  );
END;
/
```

### Single ontology table

The table name is case-sensitive:

```sql
BEGIN
  RunTotalnum(
    observationTable => 'observation_fact',
    schemaName        => 'I2B2DEMODATA',
    tableName         => 'I2B2'
  );
END;
/
```

### Classic count

```sql
BEGIN
  RunTotalnum(
    observationTable => 'observation_fact',
    schemaName        => 'I2B2DEMODATA',
    mode              => 'classic'
  );
END;
/
```

The direct classic call is:

```sql
BEGIN
  RunTotalnumClassic(
    observationTable => 'observation_fact',
    schemaName        => 'I2B2DEMODATA',
    tableName         => '@'
  );
END;
/
```

A custom observation table passed with fast/i2b2 mode automatically routes to
classic. Oracle does not yet provide SQL Server's `demographics_mode = 'all'`.

### Manual fast steps

```sql
BEGIN
  FastTotalnumPrep('I2B2DEMODATA', 'i2b2');
  FastTotalnumCount;
  FastTotalnumOutput('I2B2DEMODATA', '@');
END;
/
```

Use `'omop'` instead of `'i2b2'` in `FastTotalnumPrep` for ACT-OMOP views.

## PostgreSQL

If metadata and data objects are in different schemas, set a search path that
makes the metadata procedures and tables visible. For example:

```sql
SET search_path TO i2b2metadata, public;
```

### Standard fast count

```sql
SELECT runtotalnum('observation_fact', 'public');
```

### ACT-OMOP fast count

```sql
SELECT runtotalnum(
    'observation_fact',
    'public',
    mode => 'omop'
);
```

### Single ontology table

The table name is case-sensitive:

```sql
SELECT runtotalnum(
    'observation_fact',
    'public',
    'my_ontology'
);
```

### Classic count

```sql
SELECT runtotalnum(
    'observation_fact',
    'public',
    mode => 'classic'
);
```

The direct classic call is:

```sql
SELECT runtotalnumclassic(
    'observation_fact',
    'public',
    '@'
);
```

A custom observation table passed with fast/i2b2 mode automatically routes to
classic. PostgreSQL does not yet provide SQL Server's
`demographics_mode = 'all'`.

### Manual fast steps

```sql
SELECT fasttotalnumprep('public', 'i2b2');
CALL fasttotalnumcount();
CALL fasttotalnumoutput('public', '@');
```

For ACT-OMOP views:

```sql
SELECT fasttotalnumprep('public', 'omop');
CALL fasttotalnumcount();
CALL fasttotalnumoutput('public', '@');
```

## Multi-fact-table configurations

The fast i2b2 workflow reads `observation_fact`. OMOP mode reads the configured
ACT-OMOP views. Use classic mode when a different fact table or a union fact view
must drive counting.

A typical union view is:

```sql
CREATE VIEW observation_fact_view AS
SELECT * FROM condition_view
UNION ALL
SELECT * FROM drug_view;
```

Then pass `observation_fact_view` to the classic procedure. This approach assumes
that concept codes do not conflict across the combined fact sources. SQL Server
also supports its classic wildcard option for ontology fact-column references.

## What changed

| Before | Now | Migration action |
| --- | --- | --- |
| `RunTotalnum`/`runtotalnum` ran classic counting | The same name is a wrapper that defaults to fast | Add `mode = 'classic'` where classic behavior is required |
| Fast users called prep, count, and output separately | The wrapper runs all three steps | Use the wrapper unless prep is deliberately scheduled separately |
| Classic implementation used the common procedure name | Classic is explicitly named `RunTotalnumClassic`/`runtotalnumclassic` | Update direct classic calls; old common calls now mean fast |
| Classic implementation was presented as `run_all_counts.sql` | It is stored in `totalnum_classic.sql` | Load all procedure files rather than referring to the old filename |
| i2b2 and OMOP prep could require separate script variants | One prep procedure uses `source_mode` | Pass `omop` instead of maintaining a separate prep copy |
| ACT ontology table names could be hardcoded | Names are resolved through `TABLE_ACCESS` | Maintain correct `ACT_VISIT` and `ACT_DEMO` rows |
| Missing ACT special tables could stop prep | Missing mappings are skipped with a notice | Review the notice and decide whether the mapping is intentionally absent |
| No supplemental all-demographics fast mode | SQL Server supports `demographics_mode = 'all'` | Keep `act` for maximum speed or opt into `all` |
| Some output SQL was used as diagnostic/manual SQL | Output procedures execute their updates directly | Do not rerun printed update statements manually |

The Ant total-count targets call the common wrapper, so they now run fast rather
than classic. This is the most important scheduling change for existing
installations.

### `RunTotalnum` now defaults to fast

Previously, `RunTotalnum` or `runtotalnum` directly invoked the classic counting
algorithm. The same common call now runs the complete fast workflow:

```text
FastTotalnumPrep -> FastTotalnumCount -> FastTotalnumOutput
```

This is intentionally source-compatible, but it is not behaviorally identical.
Sites that require the previous algorithm must request `mode = 'classic'` or call
the explicit classic procedure.

### Classic has an explicit name

The classic implementations now live in `totalnum_classic.sql` and are named:

```text
SQL Server: RunTotalnumClassic
Oracle:     RunTotalnumClassic
PostgreSQL: runtotalnumclassic
```

`totalnum_run.sql` contains the compatibility wrapper and mode selection. On SQL
Server, the legacy `PAT_COUNT_VISITS` entry point also remains available and now
delegates to a shared metadata-dimension evaluator.

The classic counting algorithm itself remains available; the change is how it is
named and selected. Existing custom fact-table behavior is preserved through
explicit classic calls and automatic compatibility routing where documented
above.

### i2b2 and OMOP share fast prep

Fast prep now accepts `source_mode = 'i2b2'` or `source_mode = 'omop'`. This keeps
one prep implementation per database instead of maintaining separate i2b2 and
OMOP copies. i2b2 remains the default.

### ACT physical table names are discovered

The scripts no longer depend on hardcoded ACT visit and demographic table names.
They resolve `C_TABLE_NAME` through the `ACT_VISIT` and `ACT_DEMO` rows in
`TABLE_ACCESS`. Missing mappings produce a notice and skip the relevant special
section.

### SQL Server can add non-ACT demographics

SQL Server adds `demographics_mode = 'all'`. It preserves the fast ACT path and
uses the shared classic metadata-expression evaluator only for non-ACT
`patient_dimension` rows. The default remains `act`, so existing fast runs do not
pay this additional cost.

Fast SQL Server rows use `PF`, supplemental all-demographics rows use `PA`, and
classic patient/visit rows continue to use `PD`. Output and report generation
select the appropriate count types for the requested mode.

### Existing special calls remain compatible

The common two-argument calls used by the Ant targets still work. Calls that
specify custom fact tables are routed to classic where required. Existing direct
classic report calls also remain valid because new report parameters are
optional.

## Operational notes

- Run prep again after ontology structure or `TABLE_ACCESS` mappings change.
- Run count and output again after patient data changes.
- The one-command wrapper always runs prep, count, and output.
- Fast prep recreates shared objects including `OBSFACT_PAIRS`, `TNUM_ONTOLOGY`,
  and `CONCEPT_CLOSURE`; do not run overlapping prep jobs in the same metadata
  schema.
- Review informational skip messages. Missing ACT mappings are allowed, but they
  may indicate an unintended `TABLE_ACCESS` configuration.
- Test classic versus fast results before changing production scheduling,
  especially for custom ontologies, site-specific demographic expressions, or
  multi-fact configurations.
