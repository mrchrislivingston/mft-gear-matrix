# MFT Gear Matrix

## Vision

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

------------------------------------------------------------------------

# Project Philosophy

-   Local-first
-   No accounts
-   No cloud required
-   No subscriptions
-   Fast
-   Simple
-   Athlete owns their data
-   Preserve history instead of replacing it

Cloud synchronization may be added in the future, but it is **not** part
of the MVP.

------------------------------------------------------------------------

# Team Roles

## Chris

**Product Owner**

Responsibilities

-   Defines workflow
-   Makes product decisions
-   Determines priorities
-   Tests every feature
-   Approves architecture

No Flutter knowledge is assumed.

Implementation should always be delivered in small, testable steps.

------------------------------------------------------------------------

## ChatGPT

**Technical Lead**

Responsibilities

-   Software architecture
-   Flutter implementation
-   Data model design
-   Code review
-   Sprint planning
-   Maintain PROJECT.md

Implementation should always be incremental.

Wait for testing before moving to the next step.

------------------------------------------------------------------------

# Current Architecture

``` text
Home
├── Matrix
│   └── Modality
│       └── Prescription
│           ├── Zone
│           ├── Gear
│           └── Power
│
│           ├── Log Workout
│           ├── Workout Summary
│           ├── Workout History
│           ├── Workout Detail
│           ├── Target Manager (Gear only)
│           └── Target History (Gear only)
│
└── History
```

------------------------------------------------------------------------

# Core Architecture Decisions

-   One Living Matrix
-   One Prescription engine
-   Gears are one prescription type
-   Zones are continuous-duration prescriptions
-   Power prescriptions support modality-specific protocols
-   Only Gear prescriptions support targets
-   Zone and Power prescriptions retain workout history and future
    analytics without targets

------------------------------------------------------------------------

# Supported Modalities

-   Run
-   Echo Bike
-   C2 BikeErg
-   C2 Rower
-   C2 SkiErg

------------------------------------------------------------------------

# Current Features

## Completed

### Navigation

-   Home Screen
-   Matrix
-   Modality selection
-   Prescription groups (Gear / Power / Aerobic)
-   Unified prescription detail screen
-   History navigation

### Targets

-   Gear-only target architecture
-   Independent Gear target per modality
-   Target Manager
-   Target History
-   Persistent targets
-   Automatic migration of saved targets
-   Automatic initial target creation from first completed Gear workout
-   Target controls hidden for Zone and Power prescriptions

### Workout Logging

-   Dynamic workout entry
-   Modality-specific workout screens
-   Dynamic metric engine
-   Workout validation
-   Target warning dialog for Gear workouts
-   Workout Summary
-   Workout Detail
-   Workout History
-   Zone workout logging
-   Power workout logging
-   Modality-specific Power protocols
-   Dynamic Power interval counts
-   Power scoring metric selection (Calories / Distance for Row, Ski,
    BikeErg)
-   Fixed Power scoring for Run (Distance) and Echo (Calories)
-   Workout Detail uses the modality default metric when no Gear target
    exists

### Persistence

-   SharedPreferences
-   JSON serialization
-   Workout persistence
-   Target persistence
-   Automatic save migration
-   AppState as single source of truth

------------------------------------------------------------------------

# Technology

-   Flutter
-   SharedPreferences
-   JSON serialization
-   Git
-   GitHub

------------------------------------------------------------------------

# Data Model

## Prescription

-   id
-   name
-   TrainingStimulus
-   work/rest/intervals (Gear)
-   durationRange (Zone)
-   modality protocols (Power)
-   targets (Gear only)
-   supportsTargets capability

## PrescriptionProtocol

-   every
-   rounds
-   AMRAP

## Gear

-   number
-   work
-   rest
-   intervals
-   targets

## GearTarget

-   modality
-   metric
-   history

## TargetHistory

-   lowTarget
-   highTarget
-   effectiveDate

## LogEntry

-   modality
-   prescription
-   workout date
-   duration (continuous workouts)
-   interval results
-   notes

## IntervalResult

-   interval number
-   dynamic workout metric values

## WorkoutMetric

Dynamic workout metrics used by each modality.

Examples include:

-   Distance
-   Primary Metric
-   Watts
-   Calories
-   Calories / Hour
-   RPM
-   Stroke Rate
-   Heart Rate
-   RPE

Each modality defines which workout metrics are recorded.

------------------------------------------------------------------------

# Completed Sprints

## Sprint 1

-   Project setup
-   Navigation
-   Initial models

## Sprint 2

-   Workout logging
-   Validation
-   Workout summary

## Sprint 3

-   Workout history
-   Gear history
-   Workout detail

## Sprint 4

-   SharedPreferences
-   JSON serialization
-   Persistent history
-   Global Home navigation

## Sprint 5

-   Target Manager
-   Living Matrix architecture
-   GearTarget model
-   TargetHistory model
-   Persistent targets
-   Target History screen
-   Default matrix architecture

## Sprint 6

Completed

-   Five-modality Living Matrix
-   Modality-aware targets
-   Generic Gear architecture
-   Generic History architecture
-   Generic Detail screens
-   Generic Summary screens
-   Generic Target Manager
-   Removed remaining run-specific assumptions

## Sprint 7

Completed

-   Dynamic WorkoutMetric engine
-   Dynamic interval data model
-   Dynamic workout logging
-   Dynamic workout summaries
-   Dynamic workout detail
-   Dynamic workout history
-   Automatic first-workout target creation
-   Dynamic primary metric support
-   Migration-safe persistence

## Sprint 8

Completed

### Architecture

-   Introduced generic Prescription model
-   Added TrainingStimulus architecture
-   Added PrescriptionProtocol model
-   Added Zone prescriptions (Z1--Z2)
-   Added Power prescriptions (P1--P3)
-   Unified AppState around Prescription architecture
-   Preserved backward compatibility with existing Gear workflow

### UI

-   Matrix now groups prescriptions into:
    -   Gears
    -   Power
    -   Aerobic
-   Unified prescription detail screen
-   Unified target management
-   Unified target history
-   Unified workout entry navigation
-   Unified workout history navigation

### Power Prescriptions

-   Display Continuous Machines protocol
-   Display Ski / Row protocol
-   Improved prescription formatting
-   Recovery wording updated to:
    -   "Recover in remaining time"

### Continuous Workouts

-   Added duration support for continuous (Z1--Z2) workouts
-   Duration stored in LogEntry
-   Duration displayed on Workout Summary
-   Duration displayed on Workout Detail
-   Continuous workouts display "Workout" instead of "Interval 1"

## Sprint 9

Completed

### Dynamic Workout Logging

-   Completed Zone workout logger
-   Completed Power workout logger
-   Dynamic logging by prescription type
-   Modality-specific Power protocols
-   Dynamic interval counts from PrescriptionProtocol.rounds
-   Power scoring metric selection
-   Power history and summaries

## Sprint 10

Completed

### Prescription Architecture

-   Added prescription-level target eligibility through
    `supportsTargets`
-   Restricted target management to Gear prescriptions
-   Removed target display and target controls from Zone and Power
    prescriptions
-   Renamed `GearDetailScreen` to `PrescriptionDetailScreen`
-   Updated workout entry to support prescriptions without targets
-   Verified target warnings and initial-target creation run only for
    Gear prescriptions

### History and Summary

-   Unified Gear, Zone, and Power workout-history behavior
-   Changed workout history to open Workout Summary before Workout
    Detail
-   Retained interval-by-interval Workout Detail access from Workout
    Summary
-   Split Workout Summary into Workout Totals and Interval Averages
-   Added derived total duration, distance, and calories
-   Added derived interval averages for recorded metrics, including
    calories and watts
-   Retained workout notes and navigation to History and Home

### Validation and Regression

-   Fixed duration entry for continuous workouts longer than 99:59
-   Completed navigation, logging, summary, detail, history, target, and
    persistence regression testing
-   Verified Gear, Zone, and Power prescription workflows

------------------------------------------------------------------------

# Current Status

The application now supports three prescription families through a
common architecture:

-   Gear (G1--G8)
-   Power (P1--P3)
-   Aerobic (Z1--Z2)

Current capabilities include:

-   Five modalities
-   Unified prescription engine
-   Gear-only target management
-   Independent Gear target histories by modality
-   Dynamic workout logging for Gear, Aerobic, and Power
-   Power protocol support with modality-specific interval counts and
    scoring
-   Persistent workout history
-   Persistent Gear target history
-   Migration-safe persistence
-   Workout History → Workout Summary → Workout Detail navigation
-   Derived workout totals and interval averages
-   Continuous-workout durations longer than 99:59

------------------------------------------------------------------------

# Analytics Philosophy

## Store Facts

The application permanently stores only athlete-entered data and
prescription definitions.

Examples:

-   Workout date
-   Modality
-   Prescription
-   Interval results
-   Duration
-   Notes
-   Targets

Stored data should never depend on a calculation that could change in
the future.

## Derive Insights

All analytics are calculated from stored facts.

Examples include:

-   Workout totals
-   Interval averages
-   Personal Records
-   Execution scores
-   Interval fade
-   Consistency
-   Historical trends
-   Future coaching recommendations

Derived values are never permanently stored.

## Workout Evaluation

Every completed workout is evaluated in two independent ways.

### Performance

Measures the outcome of the workout.

Performance is used for:

-   Personal Records
-   Historical comparison
-   Trend analysis

Performance is specific to the prescription family.

Examples:

-   Gear → Primary performance metric
-   Power → Workout score defined by the prescription
-   Aerobic → Trend metrics only (no Personal Records)

### Execution

Measures how well the prescription was executed.

Execution evaluates consistency rather than absolute performance.

Potential metrics include:

-   Interval fade
-   Fastest vs slowest interval
-   Standard deviation
-   Coefficient of variation

Execution is never considered a Personal Record.

------------------------------------------------------------------------

# Current Sprint

## Sprint 11

Planning

### Primary Objective

Improve workout history so previous workouts are faster to scan and
compare without adding extra workout-entry requirements.

### Initial Candidates

-   Add useful workout information to history list entries
-   Show duration or scoring result where applicable
-   Preserve direct access to Workout Summary
-   Keep all displayed statistics derived from already-recorded workout
    data
-   Avoid adding required logging fields solely for presentation

------------------------------------------------------------------------

# Next Priorities

## History Improvements

-   Better workout history dashboard
-   Workout counts
-   Latest workout summary
-   Trend indicators

## Training Analytics

-   Interval fade detection
-   Consistency analysis
-   Target recommendations for Gear prescriptions
-   Historical performance trends

## Quality of Life

-   Better summary insights
-   Personal best indicators
-   Workout search
-   Filters

------------------------------------------------------------------------

# Future Roadmap

-   Training analytics
-   Trend graphs
-   Performance dashboards
-   Benchmark tracking
-   Weightlifting PRs
-   Search
-   Export
-   Backup
-   Optional cloud sync
-   Coach Mode
-   AI coaching insights

------------------------------------------------------------------------

# Development Notes

The project intentionally remains in a **development/testing
environment**.

Development should continue using placeholder/test workout data until
the application is considered feature complete.

Historical spreadsheet data and historical gear progression will be
imported as a dedicated migration step after MVP completion.
