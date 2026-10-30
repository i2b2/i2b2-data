# Totalnum future work and known issues

This page tracks follow-up work for the fast totalnum workflow. See
[Running totalnum Patient Counts](totalnum.md) for current usage and platform
support. The items below describe current limitations and proposals, not
features that are already available.

## Make fast-run output deterministic

**Status:** Open. Relevant to Oracle and PostgreSQL now, and worth addressing
on SQL Server for consistency. This is especially important now that fast
`demographics_mode = 'all'` is available on Oracle and PostgreSQL.

`TOTALNUM` is an append-only count history. Fast ACT counts have type `PF`;
supplemental non-ACT patient-dimension counts have type `PA`;
classic patient/visit counts have type `PD`. Fast output and report now filter
to `PF` or `PF`/`PA` according to mode, but still choose one row per ontology
path mainly by `AGG_DATE`. That selection does not distinguish the current
run from older fast runs or fully resolve ties.
PostgreSQL stores `AGG_DATE` as a `date`, so every run on the same day ties.
Oracle stores it as a `DATE` with second precision, so closely spaced writes
can tie too. SQL Server has finer timestamp precision, but its report still
ranks mainly by date.

Consequences include picking the wrong historical `PF`/`PA` row and
resurrecting an old count when the current aggregate inserts no row for a
path. Merely changing PostgreSQL `AGG_DATE` to a timestamp, or adding a
secondary `ORDER BY`, would make some ties less common or repeatable, but
would not identify which rows belong to this run. An `AGG_DATE` cutoff has
the same weakness, especially for retries and concurrent jobs.

### Proposed solution

Add a nullable `RUN_ID` to `TOTALNUM` and create one ID at the start of each
fast count run. Pass that ID through fast count, any supplemental counters,
output, and report generation. The wrapper should orchestrate this; manual
step-by-step calls should accept an explicit ID so all steps select the same
run. Keep `AGG_DATE` for display and historical queries, not as the current
run's identity. Existing rows can retain `NULL` IDs; no backfill is needed to
make new fast runs deterministic.

For a given run, output should query only rows with its `RUN_ID`. In ACT-only
mode, select `PF`. In all-demographics mode, select `PF` for the ACT
ontology and prefer `PA` over `PF` where the non-ACT supplement owns a path.
Use the same rules in report generation; do not let a report silently choose
counts from an older run. Define the ownership/priority explicitly rather
than relying on insert order or timestamp order. If a path has no count in
the current run, decide whether its output is zero or null and update it
accordingly; filtering to the run alone must not leave an old `C_TOTALNUM`
untouched. Make the denominator and `TABLE_ACCESS` updates follow the same
current-run policy.

Implementation needs a schema migration for existing installations, updates
to the three platforms' `TOTALNUM` definitions, and parameter plumbing through
the fast procedures and wrappers. Preserve existing wrapper calls with
defaults, and define how standalone count/output calls obtain or pass the
same ID. Consider an index beginning with `RUN_ID` if current-run lookups are
large. Classic counting can keep its existing behavior initially; its rows
must not leak into fast output or fast reports. Review transaction boundaries
and concurrency because prep recreates shared objects and two simultaneous
runs in one metadata schema are not currently isolated.

### Validation

- Run fast twice on the same day with different source counts; output and
  report must use only the second run.
- Interleave `PF`, `PA`, and historical `PD` rows for the same path; verify
  ACT and non-ACT selection independently.
- Remove all facts for a previously counted path; verify that its old
  `C_TOTALNUM` does not survive the new run.
- Repeat with `run_prep` disabled, with a single-table output target, and with
  a report procedure absent or failing.
- Test upgrades where old `TOTALNUM` rows have `RUN_ID IS NULL`.

## Complete all-demographics parity

**Status:** The non-ACT `patient_dimension` supplement is implemented on all
three platforms. SQL Server alone also handles supported constrained numeric
facts in `all` mode.

The Oracle and PostgreSQL implementations keep the ACT fast path and add a
patient-only counter that writes `PA` in `all` mode. The wrappers default to
`act`. The full classic patient/visit counter remains separate because it also
handles visits, writes `PD`, and has different side effects. If constrained
numeric-fact parity is needed, implement and test it separately on Oracle and
PostgreSQL.

The run-identity work above remains open. Adding `PA` makes existing date ties
more likely to produce incorrect or inconsistent demographics counts.
