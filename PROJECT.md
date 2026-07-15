# MFT Gear Matrix

## Vision

MFT Gear Matrix is a local-first training application built to replace a living spreadsheet used for endurance pacing and workout tracking.

The goal is not simply to log workouts.

The goal is to preserve the evolution of an athlete over years of training.

Every workout, every target, every improvement, and every change should become permanent history instead of being overwritten.

The application should eventually provide meaningful coaching insights that are impossible to see in a spreadsheet while remaining fast, simple, and entirely owned by the athlete.

---

# Project Philosophy

* Local-first
* No accounts
* No cloud required
* No subscriptions
* Fast
* Simple
* Athlete owns their data
* Preserve history instead of replacing it

Cloud synchronization may be added in the future, but it is **not** part of the MVP.

---

# Team Roles

## Chris

**Product Owner**

Responsibilities

* Defines workflow
* Makes product decisions
* Determines priorities
* Tests every feature
* Approves architecture

No Flutter knowledge is assumed.

Implementation should always be delivered in small, testable steps.

---

## ChatGPT

**Technical Lead**

Responsibilities

* Software architecture
* Flutter implementation
* Data model design
* Code review
* Sprint planning
* Maintain PROJECT.md

Implementation should always be incremental.

Wait for testing before moving to the next step.

---

# Current Architecture

```
Home
├── Matrix
│   └── Modality
│       └── Gear
│           ├── Log Workout
│           ├── Workout Summary
│           ├── Workout History
│           ├── Workout Detail
│           ├── Target Manager
│           └── Target History
│
└── History
```

---

# Core Architecture Decisions

* One Living Matrix
* Eight Gears shared across all modalities
* Local-first persistence
* SharedPreferences for MVP
* Complete workout history is permanent
* Complete target history is permanent
* Every modality owns its own targets
* Navigation always includes Home shortcut
* Small iterative development with testing after every change

---

# Supported Modalities

* Run
* Echo Bike
* C2 BikeErg
* C2 Rower
* C2 SkiErg

---

# Current Features

## Completed

### Navigation

* Home Screen
* Matrix
* Modality selection
* Gear grid
* Gear detail
* History navigation

### Targets

* Independent target per modality
* Target Manager
* Target History
* Persistent targets
* Automatic migration of saved targets
* Automatic initial target creation from first completed workout

### Workout Logging

* Dynamic workout entry
* Modality-specific workout screens
* Dynamic metric engine
* Workout validation
* Target warning dialog
* Workout Summary
* Workout Detail
* Workout History

### Persistence

* SharedPreferences
* JSON serialization
* Workout persistence
* Target persistence
* Automatic save migration
* AppState as single source of truth

---

# Technology

* Flutter
* SharedPreferences
* JSON serialization
* Git
* GitHub

---

# Data Model

## Gear

* number
* work
* rest
* intervals
* targets

## GearTarget

* modality
* metric
* history

## TargetHistory

* lowTarget
* highTarget
* effectiveDate

## LogEntry

* modality
* gear
* workout date
* interval results
* notes

## IntervalResult

* interval number
* dynamic workout metric values

## WorkoutMetric

Dynamic workout metrics used by each modality.

Examples include:

* Distance
* Primary Metric
* Watts
* Calories
* Calories / Hour
* RPM
* Stroke Rate
* Heart Rate
* RPE

Each modality defines which workout metrics are recorded.

---

# Completed Sprints

## Sprint 1

* Project setup
* Navigation
* Initial models

## Sprint 2

* Workout logging
* Validation
* Workout summary

## Sprint 3

* Workout history
* Gear history
* Workout detail

## Sprint 4

* SharedPreferences
* JSON serialization
* Persistent history
* Global Home navigation

## Sprint 5

* Target Manager
* Living Matrix architecture
* GearTarget model
* TargetHistory model
* Persistent targets
* Target History screen
* Default matrix architecture

## Sprint 6

Completed

* Five-modality Living Matrix
* Modality-aware targets
* Generic Gear architecture
* Generic History architecture
* Generic Detail screens
* Generic Summary screens
* Generic Target Manager
* Removed remaining run-specific assumptions

## Sprint 7

Completed

* Dynamic WorkoutMetric engine
* Dynamic interval data model
* Dynamic workout logging
* Dynamic workout summaries
* Dynamic workout detail
* Dynamic workout history
* Automatic first-workout target creation
* Dynamic primary metric support
* Migration-safe persistence

---

# Current Status

The Living Matrix architecture is now complete.

The application supports:

* Five modalities
* Independent target histories
* Dynamic workout logging
* Dynamic workout metrics
* Persistent workout history
* Persistent target history
* Automatic first-target creation
* Migration-safe data model

The application has transitioned from a run-specific logger into a modality-independent training platform.

---

# Next Priorities

## Sprint 8

### History Improvements

* Better workout history dashboard
* Workout counts
* Latest workout summary
* Trend indicators

### Training Analytics

* Interval fade detection
* Consistency analysis
* Target recommendations
* Historical performance trends

### Quality of Life

* Better summary insights
* Personal best indicators
* Workout search
* Filters

---

# Future Roadmap

* Training analytics
* Trend graphs
* Performance dashboards
* Benchmark tracking
* Weightlifting PRs
* Search
* Export
* Backup
* Optional cloud sync
* Coach Mode
* AI coaching insights

---

# Development Notes

The project intentionally remains in a **development/testing environment**.

Development should continue using placeholder/test workout data until the application is considered feature complete.

Historical spreadsheet data and historical gear progression will be imported as a dedicated migration step after MVP completion.
