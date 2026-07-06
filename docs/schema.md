# Database Schema (V1)

## gear
- gear_number (1–8)
- work_duration_sec
- rest_duration_sec
- interval_count

## matrix_entry
- athlete_id
- modality
- gear_id
- pace_min
- pace_max
- effective_date

## workout
- athlete_id
- gear_id
- modality
- date

## workout_interval
- workout_id
- interval_index
- distance_m
- avg_hr
- pace_sec_per_mile (derived)