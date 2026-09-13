**# MFT Gear Matrix**

## Product North Star

MFT Gear Matrix is an **athlete-owned training record and
interoperability layer**.

It is not a workout-programming, coaching, community, leaderboard, or
program-delivery platform.

> **Your training data belongs to you, regardless of where your
> programming comes from.**

### Core Problem

Athletes accumulate valuable performance history inside siloed platforms
such as FITR/Misfit, SugarWOD/Mayhem, HWPO, Garmin, Concept2, and other
training systems.

When an athlete changes programs, gyms, coaches, devices, or platforms,
that history becomes fragmented. Benchmark identities change, result
formats differ, source platforms disappear, and longitudinal analysis
becomes difficult or impossible.

MFT Gear Matrix sits above those systems. It ingests their data,
normalizes it into a canonical athlete-owned record, preserves its
provenance, and maintains historical continuity across platforms.

### Core Product Value

The app should allow an athlete to:

- Import training data from multiple platforms and file formats.
- Normalize workouts, intervals, targets, benchmarks, and metrics.
- Preserve the original source and context of every record.
- Reconcile duplicate, conflicting, or renamed records.
- Retain a continuous training history when changing programming
  providers.
- Analyze performance across programs, platforms, devices, and years.
- Export the athlete's complete history in portable formats.

### Product Decision Filter

A proposed feature belongs in MFT Gear Matrix when it materially
improves one or more of the following:

- Data ingestion
- Data normalization
- Historical continuity
- Benchmark identity matching
- Source provenance and trust
- Interval and performance analysis
- Cross-platform comparison
- Athlete-controlled portability

Features centered on programming delivery, coaching, community,
leaderboards, or social engagement are outside the product's core scope.

### Questions the Product Must Answer

- How has my 2-kilometer row changed over several years?
- What was my last G5 run pace, regardless of programming provider?
- How have my Echo Bike benchmarks changed over time?
- What were my prescribed targets versus my actual results?
- What did Garmin actually record?
- What changed after I switched programs?
- What are my lifetime PRs and benchmark trends across every source?
- Where did a record come from, and why should I trust it?

### Strategic Moat

The defensible value of MFT Gear Matrix comes from:

- Source-specific importers and integrations
- Canonical data normalization
- Durable source provenance
- Cross-platform duplicate reconciliation
- Historical continuity
- Benchmark identity and alias resolution
- Interval-level performance analysis
- Athlete-controlled import and export portability

The moat is not possession of the athlete's data. The moat is the
ability to make fragmented data portable, trustworthy, and useful.

### Business Direction

The long-term business objective is to make MFT Gear Matrix strategically
valuable to a larger fitness or training platform, with a potential
acquisition target around **$1.5 million**.

That value should come from solving athlete-history interoperability and
portability—not from becoming another programming platform.

Strategic value will depend on:

- Reliable integrations
- A strong canonical data model
- High-confidence normalization
- Demonstrated athlete retention
- Routine cross-platform ingestion
- Trustworthy longitudinal analysis
- Clean intellectual property and privacy practices

### Phased Roadmap

1. **Own the data model**

   Establish the canonical record for workouts, intervals, targets,
   benchmarks, metrics, source metadata, external identities, and import
   history.

2. **Make migration and ingestion easy**

   Build source-specific imports and integrations, supported by reliable
   CSV and manual-entry fallbacks.

3. **Give answers, not merely storage**

   Provide trends, progression, benchmark history, target-versus-result
   analysis, program-switch effects, and lifetime performance insights.

4. **Create portability as the moat**

   Ensure athletes retain useful historical continuity when they change
   gyms, coaches, programs, devices, or platforms.

5. **Become strategically valuable**

   Become the athlete-history and interoperability capability that a
   larger training platform would rather acquire than rebuild.

### Suggested Integration Sequence

1. Garmin
2. FITR/Misfit
3. SugarWOD/Mayhem
4. HWPO and other major programming platforms
5. Concept2 and other machine-specific sources

### Phase 1 Status

Phase 1 is approximately **75% complete**. The current foundation
includes:

- A local SQLite canonical schema
- Workout, interval, metric, target-history, and benchmark models
- Source-workbook and program-day provenance
- Historical-import discovery, review, normalization, and validation
- Ten reconstructed programming phases
- 129 normalized Matrix workouts
- 66 categorized benchmark definitions
- 74 benchmark attempts
- Complete current Gear target coverage
- Benchmark descriptions, personal bests, previous results, and trends
- Proven Garmin workout construction and FIT post-processing
- Proven private-iPhone FITR to Garmin preview, conflict checking, and
  guarded workout scheduling
- Validated version-5 SQLite backup and restore with automatic rollback
- 210 Flutter tests
- 31 historical-import tests
- 15 Garmin integration tests

The primary remaining Phase 1 work is:

- Make current-day ingestion routine rather than project-based.
- Ingest completed Garmin and FITR results into the canonical record.
- Add durable external source identifiers and import-run provenance.
- Detect duplicates across different platforms and source types.
- Close remaining source and canonical-prescription gaps.
- Make record trust and reconciliation visible to the athlete.
- Improve the single-pane-of-glass history and analysis experience.
- Add in-app database export and record-level multi-device reconciliation.

### Phase 1 Exit Criterion

Phase 1 is complete when, for **30 consecutive days**, MFT Gear Matrix
is the primary place used to answer normal training-history and
performance questions without needing FITR, Garmin Connect, or old
spreadsheets.

**## Vision**

MFT Gear Matrix is a local-first, athlete-owned training record that
preserves performance history across programming providers, gyms,
devices, and platforms.

Its purpose is to make fragmented training data portable, trustworthy,
and useful over the athlete's entire training life.
**------------------------------------------------------------------------**

**# Project Philosophy**

\- Local-first \- No accounts \- No cloud required \- No
subscriptions \- Fast \- Simple \- Athlete owns their data \-
Preserve history instead of replacing it

Cloud synchronization may be added in the future, but it is
**\*\*not\*\*** part of the MVP.

**------------------------------------------------------------------------**

**# Team Roles**

**## Chris**

**\*\*Product Owner\*\***

Responsibilities

\- Defines workflow \- Makes product decisions \- Determines
priorities \- Tests every feature \- Approves architecture

No Flutter knowledge is assumed.

Implementation should always be delivered in small, testable steps.

**------------------------------------------------------------------------**

**## ChatGPT**

**\*\*Technical Lead\*\***

Responsibilities

\- Software architecture \- Flutter implementation \- Data model
design \- Code review \- Sprint planning \- Maintain PROJECT.md

Implementation should always be incremental.

Wait for testing before moving to the next step.

**------------------------------------------------------------------------**

**# Current Architecture**

\`\`\` text Home ├── Matrix │ └── Modality │ └── Prescription │
├── Zone │ ├── Gear │ └── Power │ │ ├── Log Workout │ ├── Workout
Summary │ ├── Workout History │ ├── Workout Detail │ ├── Target Manager
(Gear only) │ └── Target History (Gear only) │ └── History \`\`\`

**------------------------------------------------------------------------**

**# Core Architecture Decisions**

\- One Living Matrix \- One Prescription engine \- Gears are one
prescription type \- Zones are continuous-duration prescriptions \-
Power prescriptions support modality-specific protocols \- Only Gear
prescriptions support targets \- Zone and Power prescriptions retain
workout history and future analytics without targets

**------------------------------------------------------------------------**

**# Supported Modalities**

\- Run \- Echo Bike \- C2 BikeErg \- C2 Rower \- C2 SkiErg

**------------------------------------------------------------------------**

**# Current Features**

**## Completed**

**### Navigation**

\- Home Screen \- Matrix \- Modality selection \- Prescription
groups (Gear / Power / Aerobic) \- Unified prescription detail screen
\- History navigation

**### Targets**

\- Gear-only target architecture \- Independent Gear target per
modality \- Target Manager \- Target History \- Persistent targets
\- Automatic migration of saved targets \- Automatic initial target
creation from first completed Gear workout \- Target controls hidden
for Zone and Power prescriptions

**### Workout Logging**

\- Dynamic workout entry \- Modality-specific workout screens \-
Dynamic metric engine \- Workout validation \- Target warning dialog
for Gear workouts \- Workout Summary \- Workout Detail \- Workout
History \- Zone workout logging \- Power workout logging \-
Modality-specific Power protocols \- Dynamic Power interval counts \-
Power scoring metric selection (Calories / Distance for Row, Ski,
BikeErg) \- Fixed Power scoring for Run (Distance) and Echo (Calories)
\- Workout Detail uses the modality default metric when no Gear target
exists

**### Persistence**

\- SQLite database on native platforms \- SharedPreferences
persistence for web \- Native workout reads and writes use SQLite \-
Native target-history reads and writes use SQLite \- Relational
workout, interval, metric, and target-history storage \- JSON
serialization retained for web compatibility \- Automatic
target-history migration from SharedPreferences to SQLite \- AppState
as application state manager

**------------------------------------------------------------------------**

**# Technology**

\- Flutter \- SQLite \- sqflite \- SharedPreferences for web and
temporary target migration \- JSON serialization \- Git \- GitHub

**------------------------------------------------------------------------**

**# Data Model**

**## Prescription**

\- id \- name \- TrainingStimulus \- work/rest/intervals (Gear) \-
durationRange (Zone) \- modality protocols (Power) \- targets (Gear
only) \- supportsTargets capability

**## PrescriptionProtocol**

\- every \- rounds \- AMRAP

**## Gear**

\- number \- work \- rest \- intervals \- targets

**## GearTarget**

\- modality \- metric \- history

**## TargetHistory**

\- lowTarget \- highTarget \- effectiveDate

**## LogEntry**

\- modality \- prescription \- workout date \- duration (continuous
workouts) \- interval results \- notes

**## IntervalResult**

\- interval number \- dynamic workout metric values

**## WorkoutMetric**

Dynamic workout metrics used by each modality.

Examples include:

\- Distance \- Primary Metric \- Watts \- Calories \- Calories /
Hour \- RPM \- Stroke Rate \- Heart Rate \- RPE

Each modality defines which workout metrics are recorded.

**------------------------------------------------------------------------**

**# Completed Sprints**

**## Sprint 1**

\- Project setup \- Navigation \- Initial models

**## Sprint 2**

\- Workout logging \- Validation \- Workout summary

**## Sprint 3**

\- Workout history \- Gear history \- Workout detail

**## Sprint 4**

\- SharedPreferences \- JSON serialization \- Persistent history \-
Global Home navigation

**## Sprint 5**

\- Target Manager \- Living Matrix architecture \- GearTarget model
\- TargetHistory model \- Persistent targets \- Target History screen
\- Default matrix architecture

**## Sprint 6**

Completed

\- Five-modality Living Matrix \- Modality-aware targets \- Generic
Gear architecture \- Generic History architecture \- Generic Detail
screens \- Generic Summary screens \- Generic Target Manager \-
Removed remaining run-specific assumptions

**## Sprint 7**

Completed

\- Dynamic WorkoutMetric engine \- Dynamic interval data model \-
Dynamic workout logging \- Dynamic workout summaries \- Dynamic
workout detail \- Dynamic workout history \- Automatic first-workout
target creation \- Dynamic primary metric support \- Migration-safe
persistence

**## Sprint 8**

Completed

**### Architecture**

\- Introduced generic Prescription model \- Added TrainingStimulus
architecture \- Added PrescriptionProtocol model \- Added Zone
prescriptions (Z1--Z2) \- Added Power prescriptions (P1--P3) \-
Unified AppState around Prescription architecture \- Preserved backward
compatibility with existing Gear workflow

**### UI**

\- Matrix now groups prescriptions into: \- Gears \- Power \-
Aerobic \- Unified prescription detail screen \- Unified target
management \- Unified target history \- Unified workout entry
navigation \- Unified workout history navigation

**### Power Prescriptions**

\- Display Continuous Machines protocol \- Display Ski / Row protocol
\- Improved prescription formatting \- Recovery wording updated to:
\- "Recover in remaining time"

**### Continuous Workouts**

\- Added duration support for continuous (Z1--Z2) workouts \- Duration
stored in LogEntry \- Duration displayed on Workout Summary \-
Duration displayed on Workout Detail \- Continuous workouts display
"Workout" instead of "Interval 1"

**## Sprint 9**

Completed

**### Dynamic Workout Logging**

\- Completed Zone workout logger \- Completed Power workout logger \-
Dynamic logging by prescription type \- Modality-specific Power
protocols \- Dynamic interval counts from PrescriptionProtocol.rounds
\- Power scoring metric selection \- Power history and summaries

**## Sprint 10**

Completed

**### Prescription Architecture**

\- Added prescription-level target eligibility through
\`supportsTargets\` \- Restricted target management to Gear
prescriptions \- Removed target display and target controls from Zone
and Power prescriptions \- Renamed \`GearDetailScreen\` to
\`PrescriptionDetailScreen\` \- Updated workout entry to support
prescriptions without targets \- Verified target warnings and
initial-target creation run only for Gear prescriptions

**### History and Summary**

\- Unified Gear, Zone, and Power workout-history behavior \- Changed
workout history to open Workout Summary before Workout Detail \-
Retained interval-by-interval Workout Detail access from Workout Summary
\- Split Workout Summary into Workout Totals and Interval Averages \-
Added derived total duration, distance, and calories \- Added derived
interval averages for recorded metrics, including calories and watts \-
Retained workout notes and navigation to History and Home

**### Validation and Regression**

\- Fixed duration entry for continuous workouts longer than 99:59 \-
Completed navigation, logging, summary, detail, history, target, and
persistence regression testing \- Verified Gear, Zone, and Power
prescription workflows

**------------------------------------------------------------------------**

**# Current Status**

The application now supports three prescription families through a
common architecture:

\- Gear (G1--G8) \- Power (P1--P3) \- Aerobic (Z1--Z2)

Current capabilities include:

\- Five modalities \- Unified prescription engine \- Gear-only target
management \- Independent Gear target histories by modality \- Dynamic
workout logging for Gear, Aerobic, and Power \- Power protocol support
with modality-specific interval counts and scoring \- Persistent
workout history \- Persistent Gear target history \- Migration-safe
persistence \- Workout History → Workout Summary → Workout Detail
navigation \- Derived workout totals and interval averages \-
Continuous-workout durations longer than 99:59

**------------------------------------------------------------------------**

**# Analytics Philosophy**

**## Store Facts**

The application permanently stores only athlete-entered data and
prescription definitions.

Examples:

\- Workout date \- Modality \- Prescription \- Interval results \-
Duration \- Notes \- Targets

Stored data should never depend on a calculation that could change in
the future.

**## Derive Insights**

All analytics are calculated from stored facts.

Examples include:

\- Workout totals \- Interval averages \- Personal Records \-
Execution scores \- Interval fade \- Consistency \- Historical trends
\- Future coaching recommendations

Derived values are never permanently stored.

**## Workout Evaluation**

Every completed workout is evaluated in two independent ways.

**### Performance**

Measures the outcome of the workout.

Performance is used for:

\- Personal Records \- Historical comparison \- Trend analysis

Performance is specific to the prescription family.

Examples:

\- Gear → Primary performance metric \- Power → Workout score defined
by the prescription \- Aerobic → Trend metrics only (no Personal
Records)

**### Execution**

Measures how well the prescription was executed.

Execution evaluates consistency rather than absolute performance.

Potential metrics include:

\- Interval fade \- Fastest vs slowest interval \- Standard deviation
\- Coefficient of variation

Execution is never considered a Personal Record.

**------------------------------------------------------------------------**

**# Current Sprint**

**## Sprint 11**

In Progress

**### Primary Objective**

Replace native SharedPreferences persistence with a relational SQLite
database while preserving existing workout and target history.

**### Completed**

\- Added SQLite and sqflite \- Created relational database schema \-
Added workouts table \- Added workout intervals table \- Added
interval metrics table \- Added target history table \- Enabled
foreign-key enforcement \- Added cascade deletion for workout child
records \- Added SQLite workout insertion \- Added SQLite workout
reconstruction and reading \- Added SQLite workout deletion \-
Migrated native workout reads to SQLite \- Migrated native workout
writes to SQLite \- Retained SharedPreferences workout fallback for web
\- Verified workout logging and restart persistence \- Added SQLite
target-history insertion \- Added SQLite target-history reading \-
Dual-write new native target changes to SQLite and SharedPreferences \-
Verified target updates and target history after restart

**### Historical Import**

\- Created reusable historical workout import pipeline \- Added
workbook reader supporting multiple Misfit worksheet formats \- Added
automatic workout candidate detection \- Added explicit and inferred
date extraction \- Added parser support for: \- Gear workouts (G1--G8)
\- Power workouts (P1--P3) \- Aerobic workouts (Z1--Z2) \- Added
modality detection for: \- Run \- Row \- SkiErg \- C2 BikeErg \-
Echo Bike \- Added automatic review classification: \- READY \-
REVIEW \- SKIP \- TBD\_LATER \- Added review CSV generation
workflow \- Added parser regression test suite \- Added unified
run\_all\_tests.py regression runner \- Added normalization
pipeline and normalized workout models \- Added review CSV reader and
SQLite importer scaffold \- Added interval, structured interval, and
metric parsers for historical workout normalization \- Introduced
Execution Plan architecture separating Prescription, Execution Plan, and
Execution Result \- Added Execution Plan parser supporting both
count-first (\`8×1:45\`) and duration-first (\`1:45 x 8\`)
formats \- Added interval distance parser for Garmin interval-distance
results \- Execution Plan now populates from programming text with
canonical Gear fallback \- Normalizer now supports interval paces,
structured metrics, interval distances, and workout averages \-
Validated OffSZN 1 historical import at 18 of 18 READY workouts - Added
historical workout provenance (source workbook and program day) -
Extended SQLite schema with source_workbook and program_day - Added
provenance validation before SQLite import - Historical workout detail
and summary screens now display provenance - Historical history cards
derive Performance and Execution from imported interval data - Added
decimal-pace support (e.g. 1:50.4) throughout historical analytics -
Verified end-to-end historical import, analytics, and UI integration \-
Validated parser against: \- OffSZN 1 \- OffSZN 2 \- Summit Games \-
Phase 1 \- Completed Summit Games historical import validation
including interval-time results and calorie-based execution plans \-
Deferred mixed Gear, mixed Power, mixed Modality, and Benchmark import
until future implementation - Benchmark workouts are a separate future
workout family and must not be forced into Gear, Power, or Aerobic
classifications - When Benchmark support is implemented, re-scan all
historical workbooks for benchmark workouts, including workouts
previously misclassified because benchmark programming text contains
Gear, Power, or Zone terminology - M.A.T.T. Row Test identified during
Phase 1 review as the first confirmed deferred Benchmark case

**### Remaining**

\- Migrate existing saved target histories into SQLite \- Build Gear
target collections from SQLite records \- Switch native target reads to
SQLite \- Remove native target writes from SharedPreferences \- Remove
obsolete legacy target persistence code \- Complete persistence
regression testing

**------------------------------------------------------------------------**

**------------------------------------------------------------------------

# Current Sprint

## Sprint 12

In Progress

### Primary Objective

Complete historical migration by importing and validating the remaining
historical workbooks (OffSZN 2, Summit Games, Phase 1, and later
workbooks) while extending the importer to support deferred edge cases
such as mixed prescriptions and benchmark workouts.

### Sprint 12 Historical Import Checkpoint

- OffSZN 2 historical migration is complete. A dry run against
  `offszn2_review_v3.csv` found 20 normalized workouts and all 20 were
  already present in SQLite.
- Phase 1 review v8 contains 7 normalized Matrix workouts. The missing
  2025-09-22 Row workout was initially imported before being identified
  as a benchmark.
- Benchmark persistence and historical import are implemented. Eight
  Phase 1 benchmark attempts are stored in SQLite.
- The two Phase 1 workouts previously misclassified under Matrix
  prescriptions were reclassified on 2026-09-02:
  - 2025-09-22 Z2 Row → M.A.T.T. Row, scored at 183 average watts.
  - 2025-10-07 G6 Echo → Echo Bike Cube Test, scored at 316 total
    calories from rounds of 72, 80, 81, and 83.
- Reclassification removed only the duplicate Matrix workout rows and
  their cascading interval data after verifying the corresponding
  benchmark attempts existed. A timestamped database backup was created
  before the transaction.
- Added an idempotent `benchmark_reclassifier.py` migration utility.
- Historical-import regression testing now automatically discovers every
  `test_*.py` file, works from any current directory, reports failure
  details, and passes 19/19 tests.
- Added direct coverage for benchmark importing, benchmark
  reclassification, SQLite importing, metric parsing, and the
  historical-import CLI. The previously omitted pace-distance parser
  test is now included automatically.
- Added a maintained Benchmark registry covering the known benchmark
  names and aliases, including punctuation and spacing variants such as
  MATT, M.A.T.T., and M. A. T. T.
- Added a CSV-aware Benchmark reader that preserves the existing
  programming-row and Notes/Results column alignment.
- Benchmark names are required in programming text. References to another
  benchmark in result notes do not create false candidate attempts.
- Re-scanned OffSZN 1, OffSZN 2, Summit Games, and Phase 1 with the full
  registry. The first three contained no benchmark candidates; Phase 1
  produced exactly the eight attempts already stored in SQLite.
- The W9D1 M.A.T.T. programming date infers to 2025-10-27, while the
  authoritative stored attempt date remains 2025-10-28.
- Resolved three non-mixed historical exceptions:
  - OffSZN 2 W8D5 was marked SKIP because the programmed mixed-Gear
    workout was not performed.
  - Phase 1 W8D4 was marked SKIP because Zone 1 yard work has no
    supported app modality.
  - Phase 1 W8D5 was imported as a partial G3 Row workout with five
    prescribed intervals and three completed intervals (97/92/91).
- Phase 1 dry-run verification now reports zero workouts ready and six
  existing workouts skipped.
- Fourteen completed historical workouts remain deferred. Eleven use
  multiple prescriptions within one workout, and three use multiple
  modalities. These require a Mixed Workout data model before import.

### In-App Misfit CSV Import Checkpoint

- Added the first read-only in-app historical import workflow for Misfit
  coaching spreadsheets.
- Added local macOS CSV selection using `file_picker` and CSV decoding
  using the `csv` package. User-selected read-only file access was added
  to both macOS entitlement files.
- Added an `Import Misfit History` home-screen entry with Google Sheets
  CSV-export instructions.
- Ported Matrix workout discovery and classification from Python to
  Dart for Gear, Power, and Zone workouts.
- Validated the Dart scanner against the previously unprocessed Phase II
  2025–2026 workbook. Dart and Python produced exact parity: 53 Matrix
  candidates, including 20 READY, 32 SKIP, and 1 TBD_LATER.
- Added a filterable, read-only review screen showing source location,
  prescription, modality, programming, recorded result, and status.
- Ported execution-plan parsing to Dart. Supported formats include
  count-first, duration-first, multiplication-symbol, calorie-round,
  and Power interval prescriptions.
- The import workflow remains preview-only and makes no SQLite changes.
- Flutter tests pass 32/32 and the Python historical-import suite passes
  19/19.
- Next steps are calendar-date resolution, result normalization,
  duplicate detection, explicit approval, SQLite import, and in-app
  benchmark discovery.

### In-App Result Normalization Checkpoint

- The in-app Misfit CSV workflow now matches the Python candidate scan
  for the Phase II 2025–2026 worksheet: 53 candidates, including 20
  READY, 32 SKIP, and 1 TBD_LATER.
- Added Dart parsers for execution plans, average metrics, interval
  paces, interval times, structured interval values, distances, and
  pace-distance pairs.
- Added Phase II result-format support in both the Dart and Python
  parsers, including fractional-mile distances, numbered meter results,
  distance/pace pairs, and duration-only Zone results.
- Result normalization succeeds for 17 of the 20 READY Phase II
  candidates. The G4 Run at W3D2 and the note-only Z2 Echo workouts at
  W4D1 and W6D1 remain excluded.
- The review screen displays captured execution and interval data,
  identifies parse failures, and provides per-workout Include/Skip
  controls. Successfully parsed workouts are included by default;
  failures are disabled and excluded.
- The import workflow remains preview-only and makes no SQLite changes.
- Flutter tests pass 76/76 and the Python historical-import suite passes
  22/22.
- Next steps are calendar-date resolution, duplicate detection,
  explicit final approval, and transactional SQLite import.

### In-App Historical Import Completion Checkpoint

- Added calendar-date resolution for Misfit worksheet headers, including
  ordinal dates, numeric dates, inferred program days, and calendar-year
  rollover. Users confirm the calendar year containing W1D1 before
  review.
- Phase II date resolution mapped all 53 candidates, from W1D1 on
  2025-11-03 through the January 2026 program days.
- Added read-only SQLite duplicate detection using the same workout
  identity as the Python importer: prescription, modality, date, work
  duration, interval count, source workbook, and program day.
- Successfully normalized candidates are selected by default. Parse
  failures and existing database records are excluded and cannot be
  accidentally selected.
- Added normalized-preview conversion into typed `LogEntry`,
  `IntervalResult`, `Modality`, and `WorkoutMetric` values while
  preserving the original recorded result as workout notes.
- Added an explicit final confirmation dialog and an atomic SQLite batch
  import. Duplicate identity is rechecked inside the transaction before
  any workout is inserted.
- Imported 17 Phase II Matrix workouts through the app. The G4 Run at
  W3D2 and the note-only Z2 Echo workouts at W4D1 and W6D1 were
  intentionally excluded.
- The database now contains 80 Matrix workouts: 76 historical imports
  and 4 manual/app workouts. Eight benchmark attempts remain stored
  separately.
- A post-import duplicate scan found all 17 Phase II workouts already
  present, and the G2 Row W4D6 workout was verified in History with its
  date, execution plan, two interval distances, paces, and original
  notes.
- Flutter tests pass 89/89 and the Python historical-import suite passes
  22/22.
- Next steps are in-app benchmark discovery/import and additional import
  workflow polish.

### Phase II Benchmark Import Checkpoint

- Phase II benchmark discovery now scans every result row between a
  programming row and the next workout header instead of assuming that
  the result is exactly one row below the programming.
- Retests select the result row whose `WEEK N` label matches the
  programming week. Exact carried-forward results can be discarded as a
  fallback, while unresolved ambiguity is flagged for review rather than
  guessed.
- The Phase II worksheet contains eight benchmark occurrences: six
  recorded attempts and two Power Output Bike Test occurrences with no
  recorded result.
- Added definitions for M.A.T.T. Echo Bike Test, Cube Steaked, Row Mount
  Doom, and Power Output Bike Test.
- Imported the six recorded Phase II benchmark attempts:
  - M.A.T.T. Echo Bike: 288 watts on 2025-11-03 and 302 watts on
    2025-12-29.
  - Cube Steaked: 145 reps on 2025-11-04 and 185 reps on 2025-12-30.
  - Row Mount Doom: 543 calories on 2025-11-08 and 588 calories on
    2026-01-03.
- The benchmark importer remains dry-run-first, duplicate-safe,
  backup-protected, and transactional. The database now contains 14
  benchmark attempts.
- The Benchmarks screen now displays the attempt count for every
  benchmark definition, including zero-attempt benchmarks.
- Flutter tests pass 90/90 and the Python historical-import suite passes
  25/25.
- Next steps are bringing reusable benchmark discovery, normalization,
  review, and import into the same in-app CSV workflow used for Matrix
  workouts, followed by rescanning the remaining historical workbooks.

### Phase III Historical Import Checkpoint

- Phase III date resolution maps all 41 Matrix candidates from W1D1 on
  2026-01-05 through W6D3 on 2026-02-11. A one-day spreadsheet date
  conflict in W2 is corrected from the authoritative program calendar.
- Safe mixed-Gear workouts can now be expanded into separate candidates
  when the programmed interval groups and recorded result rows match
  exactly. The W6D3 Row workout was split into three G7 intervals and
  three G8 intervals with their respective work durations.
- Ambiguous Row/C2 Bike Zone workouts can be resolved from internally
  consistent duration, pace, and distance results. The W5D4 Z2 workout
  was correctly identified as C2 Bike.
- Partial workouts remain excluded by default but can be manually
  included after review. The W5D3 G7 Echo workout imported its three
  completed intervals out of five prescribed intervals.
- Echo Bike RPM is retained as a supporting metric rather than treated
  as the scoring metric. Echo workouts now explicitly select calories,
  distance, or watts as appropriate; the partial G7 Echo workout is
  scored by distance.
- Added structured parsing for Echo RPM/calories/watts/kilometer tables,
  Row distance/watts/calories/pace tables, and hyphen-separated
  distance/pace interval results.
- The Phase III worksheet produces 41 Matrix candidates: 17 READY,
  1 REVIEW, 0 deferred, and 23 skipped. Two READY candidates remain
  intentionally excluded because their recorded results do not
  represent supported completed workouts.
- Imported 16 Phase III Matrix workouts through the app. A post-import
  duplicate scan reports 0 new and 16 already imported, with the import
  action disabled.
- Imported three Phase III benchmark attempts separately: M.A.T.T. C2
  Bike at 230 watts, Row Cube Test at 330 calories, and Spiders on Mars
  at 6 calories.
- Added all maintained benchmark-registry entries to the Benchmarks UI,
  including definitions with zero attempts. Unconfirmed descriptions
  and scoring rules remain intentionally blank until the Phase 0/1
  workbook review.
- Added all four confirmed Power Output benchmark definitions: Echo
  Bike, C2 Bike, Ski, and Row, each programmed as 50/40 calories for
  time.
- The database now contains 96 Matrix workouts and 17 benchmark
  attempts.
- Flutter tests pass 105/105 and the Python historical-import suite
  passes 31/31. Static analysis retains eight previously known issues.

### Benchmark Architecture Findings

- Benchmarks should not be inferred from the literal word "benchmark".
  Historical discovery should use a maintained list of known benchmark
  names and aliases.
- Benchmark definitions and benchmark attempts should be separate
  concepts. A definition describes the named test, prescription and
  scoring method; attempts store dated historical performances.
- Added `BenchmarkScoreType` with initial score types: time,
  roundsReps, calories, averageWatts, load, reps, and distance.
- M.A.T.T. tests and Kill-O tests are different benchmark families:
  M.A.T.T. is a 40-minute maximum-threshold test; Kill-O tests use six
  intervals and are scored by the lowest round.
- Cube Tests are repeated machine intervals. The observed Echo Bike Cube
  Test is 4 x 4:00 with 4:00 rest and is scored by total calories.
- Mount Doom is an escalating every-2:00-until-failure test and is scored
  by total accumulated work, including work completed in the failed
  round. Example: Bike Mount Doom starting at 20 calories, completing
  every round through 40 and then 40 of 41 = 670 total calories.
- Known benchmark names/aliases collected for the future historical
  rescan include M.A.T.T. machine tests, Ski/C2 Bike/Row/Run/Echo Cube
  Tests, Cube Steaked, Cleo, Runner/Ski/Row/C2 Bike/Echo Bike Mount Doom,
  Kill-O-Meter/Kill-O-Watt tests, Spiders on Mars, Tour de Misfit,
  Riverside Time Trial, Enzo Gorlomi, Cupcake Lungs, Might Not, Rule 8,
  Bumper Cables, Pennies, Speed Not Volume, 75 Continental Drive,
  King Larry I, Chuckles 1&2, Hurt and Injured, and Fairy Dust.

### Qtrs Prep 2026 Historical Import Checkpoint

- Added support for worksheets that store the calendar date in column A
  and the program-day identifier in column B. Qtrs Prep resolves all 35
  Matrix candidate dates from W1D1 on 2026-02-16 through W8D4 on
  2026-04-09.

- Date arithmetic now uses calendar-day construction rather than elapsed
  durations, preventing daylight-saving transitions from shifting inferred
  dates by one day. Date-conflict errors now display both the expected
  calendar date and the date contained in the worksheet header.

- The Qtrs Prep worksheet produces 35 Matrix candidates: 10 READY,
  0 REVIEW, 1 deferred mixed-modality workout, and 24 skipped workouts.
  All 10 READY workouts normalize successfully.

- Added explicit parsing for calorie-scored Echo Bike results recorded as
  bare labeled rounds. The W3D1 G6 Echo workout imported four calorie
  intervals: 68, 69, 71, and 70.

- Results indicating that illness prevented the workout are classified as
  skipped. Run-for-meters workouts explicitly completed on a treadmill
  without recorded distance are also skipped.

- Ported all 34 maintained benchmark registry entries and aliases into
  Dart. The in-app CSV preview now reports benchmark discovery counts
  alongside Matrix candidates. Qtrs Prep contains no registered benchmark
  occurrences, confirmed independently by scanning every CSV cell.

- Imported all 10 supported Qtrs Prep Matrix workouts through the app.
  The database now contains 106 Matrix workouts. The intentionally
  deferred mixed-modality workout was not imported.

- Flutter tests pass 117/117 and the Python historical-import suite passes
  31/31. The eight existing analyzer findings remain unchanged.

### Phase 0 2026 Historical Import Checkpoint

- Corrected the Phase 0 W1D7 source date to 2026-08-02 and resolved all
  relevant Matrix and benchmark dates from W1D1 on 2026-07-27 through
  W5D6 on 2026-08-29.

- Narrowed Matrix discovery so repeated active-rest instructions that
  merely mention a Zone 2 Bike are not treated as workout prescriptions.
  Phase 0 produces 14 genuine Matrix candidates: 2 READY and 12 skipped
  because no result was recorded.

- Added complete in-app benchmark normalization for the Phase 0 result
  formats. The worksheet contains 21 registered benchmark occurrences:
  15 selected results, 0 review items, 3 intentionally excluded results,
  and 3 occurrences with no result.

- Confirmed special scoring rules for Phase 0: Kill-O-Watt uses the
  lowest interval watts, Kill-O-Meter uses the slowest interval time,
  M.A.T.T. uses average watts for the detected machine, and rounds-plus-
  reps results retain their canonical score formats.

- Added a combined Matrix and Benchmarks review screen with independent
  filters, parsing summaries, detailed source/result inspection,
  selection controls, and duplicate reporting for both record types.

- Added benchmark duplicate detection and a shared SQLite transaction
  that rechecks and imports selected Matrix workouts and benchmark
  attempts atomically. Download suffixes such as `(1)` are removed from
  the canonical source-workbook name.

- Imported 2 Matrix workouts and 15 benchmark attempts from Phase 0
  through the app. The database now contains 108 Matrix workouts and
  32 benchmark attempts. Verification found no records stored with the
  downloaded `(1)` filename suffix.

- Historical workbook import is now current through Phase 0 2026.

### Garmin Calendar and Verified Data Rebuild Checkpoint

- Added an in-app `FITR → Garmin Calendar` workflow for macOS. The app
  retrieves a requested FITR week, previews recognized workouts, allows
  individual selection, and creates and schedules only approved workouts
  in Garmin.

- The Garmin bridge supports Zone 2, single-Gear, Power, and reviewed
  mixed-machine Gear workouts. It assigns appropriate Garmin sport types,
  avoids duplicate creation and scheduling, and passes current in-app Gear
  targets to Garmin. Run, Row, and C2 Bike use native interval targets;
  Ski and Echo targets appear in workout descriptions without triggering
  target alerts.

- FITR credentials and the Garmin login session remain outside the
  repository. The macOS sandbox is currently disabled so the development
  app can launch the local Python bridge and use its external credentials
  and Garmin session.

- Added Python coverage for FITR classification, mixed-machine workouts,
  Garmin workout construction, sport types, scheduling idempotence, and
  Run pace targets.

- Added `tool/audit_historical_inputs.dart` to audit every current CSV
  export through the same Dart discovery and normalization services used
  by the app without writing to SQLite.

- Re-audited and imported ten fresh Google Sheets exports. Added safe
  normalization for constant treadmill pace, numbered kilometer/pace
  intervals, Zone duration derived from distance and average pace, Rule 8,
  and Bike Mount Doom. Instruction-only, target-only, uncompleted, and
  intentionally non-importable result text is excluded.

- The active database was rebuilt from empty and verified with 129 Matrix
  workouts and 32 benchmark attempts. This consists of 127 READY Matrix
  workouts plus two deliberately approved partial workouts. Every
  per-workbook count matches the audit, SQLite integrity is `ok`, and
  there are no blank/test sources or duplicate workout or benchmark keys.

- Restored only three independently verified target-history rows: G5
  BikeErg at 1:47-1:49 effective 2026-06-27, G6 BikeErg at 1:44-1:46
  effective 2026-07-11, and G3 Run at 8:30-8:45 effective 2026-09-06.

- Default prescriptions no longer fabricate target-history rows with
  `DateTime.now()`, and the obsolete native SharedPreferences-to-SQLite
  target migration has been removed. Native target history now comes
  exclusively from SQLite.

- Current verification passes 142 Flutter tests, 12 Garmin bridge Python
  tests, and 31 historical-import Python tests.

### Mobile FITR to Garmin and Database Portability Checkpoint

- Established a privately signed iPhone release build and confirmed that
  the app launches independently after disconnecting from Flutter tooling.

- Added phone-native FITR week retrieval and Dart classification for Zone 2,
  Gear, mixed Gear, Power, and M.A.T.T. candidates.

- FITR credentials and Garmin OAuth session data are stored in the iOS
  Keychain. Garmin access-token refresh and read-only account validation
  work without storing the Garmin password.

- Added human-readable Garmin payload previews, athlete-age-based Zone 2
  heart-rate targets, and structured Gear targets for Run, Row, and C2 Bike.
  Ski and Echo targets remain visible in Garmin step descriptions.

- Added live Garmin calendar conflict checks, exact-duplicate detection, a
  guarded import review, explicit acknowledgement, and a second confirmation
  before any workout is written.

- Added phone-native Garmin workout upload and scheduling. The transaction
  rechecks the calendar immediately before writing and removes a newly
  uploaded workout definition if scheduling fails.

- Completed the first real end-to-end phone import by creating and scheduling
  a G1 C2 Bike workout for 2026-09-16. This proved the complete FITR to Garmin
  write path and exposed that a fresh phone database lacked athlete targets.

- Added a version-5 SQLite restore engine that validates integrity, schema,
  and required tables before replacement. It backs up the existing phone
  database, reopens and validates the restored copy, and automatically rolls
  back if reopening fails.

- Added a guarded iPhone Restore Database screen with a validated record-count
  preview, acknowledgement checkbox, and final replacement confirmation.

- Restored the canonical Mac database to the iPhone and verified 129 workouts,
  65 target-history records, 66 benchmark definitions, and 74 benchmark
  attempts. Workout history, Matrix targets, and the resulting Garmin payload
  targets were verified on the phone.

- Gear payload construction now fails visibly when an athlete target is
  missing instead of silently creating an untargeted Garmin workout. Run may
  use an explicit FITR pace range; all other Gear work requires a saved target.

- The Flutter suite now passes 210 tests. Focused analysis for the database
  restore and Garmin target-safety changes reports no issues.

# Next Priorities

## Mobile Portability and FITR to Garmin

- Add actionable missing-target recovery directly to the payload screen:
  Restore Database, Set Target, and a complete list of missing targets.

- Add an in-app database export workflow so an athlete can create a validated
  portable backup without using command-line SQLite.

- Define durable record identifiers, source identifiers, modification
  timestamps, and conflict rules before implementing multi-device merge or
  synchronization.

- Evaluate athlete-controlled iCloud or CloudKit synchronization after backup
  and restore are proven. Whole-database replacement remains a private-spike
  portability mechanism, not the final multi-device architecture.

- Continue real-device FITR to Garmin validation with one reviewed workout at
  a time before enabling routine multi-workout scheduling.

## Historical Import

- Use the combined in-app workflow for future coaching sheets as they
  become available.

- Maintain the benchmark registry and add new aliases, descriptions,
  scoring rules, and result formats when new benchmarks appear.

- Extend safe candidate expansion to additional mixed-Gear,
  mixed-Power, and mixed-modality result formats as they are reviewed.

- Keep all historical-import components covered by the automatically
  discovered regression suites.

### 2026 Focus-Sheet and Benchmark Checkpoint

- Reconciled the 2025 and 2026 `Gears + Benchmarks` sheets with the
  freshly rebuilt database and original workout worksheets.

- Preserved historical Gear targets for progression analysis while
  updating all 40 current Gear × modality combinations to match the
  current matrix. SQLite contains 65 target-history rows.

- Benchmark definitions are divided into five explicit categories:
  Power Output, Machine Benchmarks, Weightlifting 1RM, Named Metcons,
  and Skill Chippers.

- Expanded the catalog from 37 to 66 definitions. The catalog uses the
  current 2026 Skill Chippers, retains M.A.T.T., Mount Doom, Rule 8,
  and other definitions unique to the 2025 sheet, and adds separate
  Ski, Row, C2 Bike, and Echo Bike Kill-O-Watt definitions.

- Added all 14 weightlifting 1RM definitions and imported all 32 dated
  weightlifting results from the focus sheet.

- Added the six direct completed 2026 Skill Chipper results. The scaled
  10 Legless Rope Climbs result retains its modification details.
  The 100 GHD Sit Ups entry remains unconfigured because the located
  programming explicitly marked it as not for time.

- Added the missing Power Output Echo Bike, Run Cube Test, Yaptain, and
  Enzo Gorlomi attempts. Enzo is stored as a modified completion on
  2026-08-25/W5D2. The Enzo substitutions are not counted as a
  100 GHD Sit Ups result.

- Corrected Chuckles 1 & 2 from 20:51 to the authoritative focus-sheet
  result of 10:51 while retaining an audit note. Preserved the original
  source-workbook dates and results for Cleo, Mount Doom, and other
  conflicts where the program calendar or source result was authoritative.

- Added score-aware benchmark analysis. Benchmark history now identifies
  the latest result, previous result, personal best, and directional
  trend. Time-based scores treat lower as better; weights, watts,
  calories, reps, and distances treat higher as better; rounds-plus-reps
  compare rounds before reps.

- Added source-backed descriptions for every benchmark. Entries whose
  canonical prescriptions could not be located are labeled honestly
  rather than receiving invented programming. Full prescriptions remain
  unresolved for `"The" Cube Test`, Tour de Misfit, Riverside Time Trial,
  Runner Mount Doom, and King Larry I. Exact interval/recovery details
  also remain pending for the Kill-O-Watt family.

- Added SQLite schema version 5 with an explicit benchmark category
  column. The migration preserves all definitions and attempts, and
  startup upserts keep names, descriptions, score types, and categories
  synchronized with the catalog.

- The active database is verified with 129 Matrix workouts,
  66 benchmark definitions, 74 benchmark attempts, no orphaned attempts,
  and successful foreign-key and integrity checks.

- Current verification passes 151 Flutter tests. The eight existing
  analyzer findings remain unchanged and are unrelated to this work.

Remaining focus-sheet work:

- Build a reproducible target and benchmark focus-sheet import/restore
  workflow so future database rebuilds do not require manual SQL.

- Locate and add the remaining canonical benchmark prescriptions and
  complete the exact Kill-O-Watt protocols when authoritative source
  programming becomes available.

## Garmin Calendar

- Replace the development machine's external Python environment with a
  packaged or explicitly configured runtime before distributing the app.

- Add an in-app credential and session setup flow rather than relying on
  an external FITR credentials file and an existing Garmin session.

- Revisit macOS sandboxing and entitlements before production distribution.

- Extend classification only when new FITR workout formats are encountered,
  keeping preview, explicit approval, and idempotent scheduling intact.

## History Improvements

\- Better workout history dashboard \- Workout counts \- Latest
workout summary \- Trend indicators

## Training Analytics

\- Interval fade detection \- Consistency analysis \- Target
recommendations for Gear prescriptions \- Historical performance trends

## Quality of Life

\- Better summary insights \- Personal best indicators \- Workout
search \- Filters

**------------------------------------------------------------------------**

# Future Roadmap

\- Training analytics \- Trend graphs \- Performance dashboards \-
Benchmark tracking \- Weightlifting PRs \- Search \- Export \-
Backup \- Optional cloud sync \- Coach Mode \- AI coaching insights

**------------------------------------------------------------------------**

## Future Cleanup

\- Revisit the Gear History **Execution** score. It currently
measures interval consistency using coefficient of variation, not
percentage of prescribed target achieved. Decide whether to rename it
(for example, **Consistency**) or change the calculation/meaning
during analytics/UI polish.
**------------------------------------------------------------------------**

# Development Notes

The project remains in a development/testing environment.

The active local macOS database now contains verified historical data
reconstructed from the current coaching-sheet exports. Application
databases, credentials, Garmin sessions, current CSV inputs, and archived
CSV inputs remain outside version control.

Synthetic and placeholder records should be confined to automated tests.
Future historical records should be imported through the audited in-app
workflow with preview, explicit approval, duplicate checking, and
post-import database validation.
