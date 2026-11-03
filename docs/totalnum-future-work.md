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

## Align PF/PA selection across fast outputs

**Status:** Open. These are narrower consistency issues than run identity;
fixing them would not by itself prevent stale rows from older runs.

All three fast output procedures use only `PF` in `act` mode. In `all` mode,
they use `PF` for the `ACT_DEMO` ontology and allow `PF` or `PA` for other
ontology tables. Where both flags qualify for a path, output sorts by
`AGG_DATE` first and prefers `PA` only on a tie. PostgreSQL's date-only
`AGG_DATE` makes same-day ties routine; Oracle has second precision, while
SQL Server has finer timestamp precision.

Two platform differences can make the published counts disagree:

- SQL Server passes `PF` or `P[FA]` to its fast report, but the report ranks
  rows only by `AGG_DATE`. On a tie, ontology output can select `PA` while
  `TOTALNUM_REPORT` selects `PF`. Add the same explicit tie-break to the
  report, and test the report against ontology output for a tied path.
- Oracle and PostgreSQL copy counts from each ontology into `TABLE_ACCESS`,
  then do another, global refresh from `TOTALNUM`. That refresh accepts
  `PF`/`PA` in `all` mode without checking whether a `TABLE_ACCESS` row
  belongs to the ACT ontology. A path shared by ACT and a non-ACT table can
  therefore leave `TABLE_ACCESS` inconsistent with the ACT table's `PF`-only
  output. Make the final refresh use each row's ontology ownership and the
  same flag rule as per-table output, or remove it after verifying that the
  per-table copy covers every intended root.

Fast reports on all three platforms also rank globally by `C_FULLNAME`, not
by ontology ownership. Define the desired behavior for a path shared by ACT
and non-ACT ontologies before aligning report selection: a report with one
row per path cannot represent two different counts for that same path. Keep
the direct, legacy two-argument report calls compatible; their `P%` default
is separate from the fast wrapper's mode-specific filtering.

Validation should cover a same-day `PF`/`PA` tie, a `PA` row newer than a
`PF` row, and the same path present in ACT and non-ACT ontologies. Compare
the ontology `C_TOTALNUM`, matching `TABLE_ACCESS.C_TOTALNUM`, and
`TOTALNUM_REPORT` after both `act` and `all` runs. The run-ID work above is
still needed to make those comparisons reliably about the current run.

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
