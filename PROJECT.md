**# MFT Gear Matrix**

**## Vision**

MFT Gear Matrix is a local-first training application built to replace a
living spreadsheet used for endurance pacing and workout tracking.

The goal is not simply to log workouts.

The goal is to preserve the evolution of an athlete over years of
training.

Every workout, every target, every improvement, and every change should
become permanent history instead of being overwritten.

The application should eventually provide meaningful coaching insights
that are impossible to see in a spreadsheet while remaining fast,
simple, and entirely owned by the athlete.

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

- Benchmark discovery is now available in the app preview. Benchmark
  normalization, detailed review, duplicate detection, and atomic import
  still need to be connected to the shared final-approval workflow before
  processing a sheet that contains benchmark attempts.

# Next Priorities**

**## Historical Import**

- Add reusable benchmark discovery, normalization, review, duplicate
  detection, and import to the existing in-app CSV workflow.
- Process the Phase 0/1 2026 workbooks using the maintained benchmark
  names and aliases, adding confirmed benchmark descriptions and
  scoring criteria as they are discovered.
- Add newly discovered benchmark definitions and attempts through the
  Benchmark import path rather than Matrix prescriptions.
- Extend safe candidate expansion to additional mixed-Gear,
  mixed-Power, and mixed-modality result formats as they are reviewed.
- Keep all historical-import components covered by the automatically
  discovered regression suite.

**## History Improvements**

\- Better workout history dashboard \- Workout counts \- Latest
workout summary \- Trend indicators

**## Training Analytics**

\- Interval fade detection \- Consistency analysis \- Target
recommendations for Gear prescriptions \- Historical performance trends

**## Quality of Life**

\- Better summary insights \- Personal best indicators \- Workout
search \- Filters

**------------------------------------------------------------------------**

**# Future Roadmap**

\- Training analytics \- Trend graphs \- Performance dashboards \-
Benchmark tracking \- Weightlifting PRs \- Search \- Export \-
Backup \- Optional cloud sync \- Coach Mode \- AI coaching insights

**------------------------------------------------------------------------**

**## Future Cleanup**

\- Remove the temporary SharedPreferences → SQLite target migration
after the first production release. At that point, all existing native
users will have migrated and the migration code can be safely deleted,
simplifying AppState.

\- Revisit the Gear History **Execution** score. It currently
measures interval consistency using coefficient of variation, not
percentage of prescribed target achieved. Decide whether to rename it
(for example, **Consistency**) or change the calculation/meaning
during analytics/UI polish.
**------------------------------------------------------------------------**

**# Development Notes**

The project intentionally remains in a \*\*development/testing
environment\*\*.

Development should continue using placeholder/test workout data until
the application is considered feature complete.

Historical spreadsheet data and historical gear progression will be
imported as a dedicated migration step after MVP completion.
