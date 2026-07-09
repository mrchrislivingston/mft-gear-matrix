# MFT Gear Matrix

## Vision

MFT Gear Matrix is a local-first training application built to replace a living spreadsheet used for endurance pacing and workout tracking.

The goal is not simply to log workouts.

The goal is to preserve the evolution of an athlete over years of training.

Every workout, every target pace, every improvement should become permanent history instead of being overwritten.

---

# Project Philosophy

- Local-first
- No accounts
- No cloud
- No subscriptions
- Fast
- Simple
- Data belongs to the athlete

Future cloud sync may be added, but it is not part of the MVP.

---

# Team Roles

## Chris

Product Owner

Responsibilities:

- Defines workflow
- Makes design decisions
- Tests every feature
- Determines priorities

No Flutter knowledge is assumed.

Implementation should be explained one small step at a time.

---

## ChatGPT

Technical Lead

Responsibilities:

- Software architecture
- Flutter implementation
- Code review
- Data model design
- Sprint planning
- Maintain PROJECT.md

Never assume Chris wants to learn Flutter.

Provide small, testable changes.

Wait for testing before continuing.

---

# Current Architecture

Home

├── Matrix

│ └── Gear

│ ├── Log Workout

│ └── Gear History

│ └── Workout Detail

└── History

└── Run

└── Gear

└── Workout History

---

## Architecture Decisions

- One Matrix, not separate matrices by modality.
- Local-first storage.
- SharedPreferences for MVP persistence.
- Preserve workout history permanently.
- Preserve target history permanently (planned).
- Home icon on all navigation screens.
- Small iterative development with testing after each change.

---

# Current Features

Completed

- Home Screen
- Matrix navigation
- Run Grid
- Gear Detail
- Workout Logging
- Workout Summary
- Workout History
- Workout Detail
- History
- Validation
- Target display
- Target pace warning dialog
- Local persistence
- SharedPreferences
- Global Home navigation
- GearTarget architecture
- TargetHistory architecture
- Modality enum
- Metric enum

---

# Technology

Flutter

SharedPreferences

JSON serialization

Git

GitHub

---

# Data Model

Current

Gear
- number
- work
- rest
- intervals
- targets

GearTarget
- modality
- metric
- history

TargetHistory
- lowTarget
- highTarget
- effectiveDate

LogEntry
- workout date
- gear
- interval data
- notes

AppState
- workout history
- persistence

---

# Design Decisions

One Matrix only.

NOT separate Run / Row / Echo / Ski matrices.

Each Gear will eventually contain:

- Workout prescription
- Coach notes
- Run target
- Row target
- Ski target
- BikeErg target
- Echo target

---

# Completed Sprints

## Sprint 1

Project setup

Navigation

Models

---

## Sprint 2

Workout logging

Validation

Workout summary

---

## Sprint 3

Workout history

Gear history

Workout detail

---

## Sprint 4

SharedPreferences persistence

JSON serialization

History survives restart

Global Home navigation

---

# Current Sprint

Sprint 5

Completed

- Target Manager screen
- Editable run targets
- Living Matrix stored in AppState
- Gear serialization
- GearTarget serialization
- Matrix persistence
- Target edits survive restart

Next

- Target History screen
- Display historical target changes
- Remove remaining direct run_gears.dart dependencies

---

# Future Roadmap

Living Matrix

Target history

Graphs

Personal records

Training analytics

Search

Export

Backup

Cloud sync (optional)

Coach mode

---

# Git Checkpoints

Sprint 1 complete

Sprint 2 complete

Sprint 3 complete

Sprint 4 complete

---

# Current Status

Project is stable.

Persistence is working.

Navigation is complete.

Ready to begin Living Matrix development.

# Session Notes

## 2026-07-08

## 2026-07-08

Completed

- Refactored target architecture.
- Added GearTarget model.
- Simplified TargetHistory model.
- Added Modality enum.
- Added Metric enum.
- Migrated Gear to target-based architecture.
- Updated workout logging to use new architecture.
- Renamed "View Gear History" to "View Workout History".
- Preserved application compatibility throughout the refactor.

Next Session

Implement Target Manager.

The user will be able to change a target while preserving complete target history.

Future work

- Target history screen
- Multiple modality targets
- Additional metrics per modality