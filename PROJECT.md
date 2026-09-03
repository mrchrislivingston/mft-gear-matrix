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

# Next Priorities**

**## Historical Import**

- Re-scan every historical workbook using the maintained benchmark names
  and aliases.
- Add any newly discovered benchmark definitions and attempts through the
  Benchmark import path rather than Matrix prescriptions.
- Extend benchmark discovery beyond the currently configured Phase 1
  attempts into reusable parsing and normalization.
- Implement the remaining deferred mixed-Gear, mixed-Power, and
  mixed-modality workout cases.
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
