import 'package:flutter_test/flutter_test.dart';

import 'package:mft_gear_matrix/models/workout_metric.dart';
import 'package:mft_gear_matrix/services/misfit_candidate_reader.dart';
import 'package:mft_gear_matrix/services/misfit_workout_normalizer.dart';
import 'package:mft_gear_matrix/services/misfit_workout_parser.dart';

void main() {
  const normalizer = MisfitWorkoutNormalizer();

  MisfitWorkoutCandidate candidate({
    required MisfitWorkoutType type,
    required String prescription,
    required String modality,
    required String programming,
    required String result,
  }) {
    return MisfitWorkoutCandidate(
      sourceRow: 1,
      sourceColumn: 2,
      dateHeader: 'W1D1 April 17',
      programDay: 'W1D1',
      workoutType: type,
      prescription: prescription,
      modality: modality,
      importStatus: MisfitImportStatus.ready,
      statusReason: 'Single supported workout',
      resultDetail: MisfitResultDetail.workoutAverage,
      programmingText: programming,
      resultText: result,
    );
  }

  test('normalizes a Zone bike workout', () {
    final workout = normalizer.normalize(
      candidate(
        type: MisfitWorkoutType.zone,
        prescription: 'Z2',
        modality: 'bikeErg',
        programming: 'Zone 2 C2 Bike',
        result:
            '30 min avg watt - 170\n'
            '30 min avg hr - 128',
      ),
    );

    expect(workout.duration, '00:30:00');
    expect(workout.intervals.single.values, {
      'watts': '170',
      'heartRate': '128',
    });
  });

  test('normalizes a Zone run workout', () {
    final workout = normalizer.normalize(
      candidate(
        type: MisfitWorkoutType.zone,
        prescription: 'Z2',
        modality: 'run',
        programming: 'Zone 2 Run',
        result:
            '60:00 Run in Zone 2 - 5.14 miles\n'
            'Avg HR 129 / Pace 11:40',
      ),
    );

    expect(workout.duration, '01:00:00');
    expect(workout.intervals.single.values, {
      'heartRate': '129',
      'primaryMetric': '11:40',
      'distance': '5.14',
    });
  });

  test('normalizes pace-only Gear intervals', () {
    final workout = normalizer.normalize(
      candidate(
        type: MisfitWorkoutType.gear,
        prescription: 'G1',
        modality: 'bikeErg',
        programming: 'BikeErg - 1st Gear',
        result:
            'Per Rd - '
            '1:50.4/1:50.0/1:50.8/1:50.4',
      ),
    );

    expect(workout.executionPlan.workDuration, '15:00');
    expect(workout.executionPlan.intervalCount, 2);
    expect(
      workout.intervals.map((interval) => interval.values['primaryMetric']),
      ['1:50.4', '1:50.0', '1:50.8', '1:50.4'],
    );
  });

  test('keeps Echo RPM supporting and defaults scoring to calories', () {
    final workout = normalizer.normalize(
      candidate(
        type: MisfitWorkoutType.power,
        prescription: 'P2',
        modality: 'echo',
        programming: 'Echo Bike P2',
        result:
            'Avg Watts/Avg RPM/Cals\n'
            'Rd1 - 691/87/18, '
            'Rd2 - 683/87/20',
      ),
    );

    expect(workout.scoringMetric, WorkoutMetric.calories);
    expect(workout.intervals.first.values, {
      'watts': '691',
      'rpm': '87',
      'calories': '18',
    });
  });

  test('scores an Echo for-meters workout by distance', () {
    final workout = normalizer.normalize(
      candidate(
        type: MisfitWorkoutType.gear,
        prescription: 'G7',
        modality: 'echo',
        programming:
            'Build Echo - 7th Gear\n'
            'AMRAP 2:30 x 5\n'
            'Echo Bike for Meters @ 7th Gear\n'
            'Rest 3:15',
        result:
            'Made it through 3 rounds.\n'
            'RPM/Cals/Watts/KM\n'
            '73/54/434/1.84KM\n'
            '74/56/451/1.86KM\n'
            '74/56/451/1.86KM',
      ),
    );

    expect(workout.scoringMetric, WorkoutMetric.distance);
    expect(workout.executionPlan.intervalCount, 5);
    expect(workout.intervals, hasLength(3));
    expect(workout.intervals.first.values, {
      'rpm': '73',
      'calories': '54',
      'watts': '434',
      'distance': '1840',
    });
  });

  test('normalizes Phase II numbered Row distances', () {
    final workout = normalizer.normalize(
      candidate(
        type: MisfitWorkoutType.gear,
        prescription: 'G7',
        modality: 'row',
        programming:
            'Build CrossFit - 7th Gear\n'
            'AMRAP 2:30 x 5\n'
            'Row for Meters @ 7th Gear',
        result:
            '1-500, 2-238, 3-532, 4-251, 5-522\n'
            'Total - 2043',
      ),
    );

    expect(workout.executionPlan.intervalCount, 5);
    expect(workout.executionPlan.workDuration, '2:30');
    expect(workout.intervals.map((interval) => interval.values['distance']), [
      '500',
      '238',
      '532',
      '251',
      '522',
    ]);
  });

  test('normalizes a duration-only Zone workout', () {
    final workout = normalizer.normalize(
      candidate(
        type: MisfitWorkoutType.zone,
        prescription: 'Z2',
        modality: 'row',
        programming: 'Zone 2 - Row',
        result:
            'No clue at all. PM5 kept messing up on me. '
            'Just rowed with HR below 132 for 50 min.',
      ),
    );

    expect(workout.duration, '00:50:00');
    expect(workout.intervals.length, 1);
    expect(workout.intervals.single.values, isEmpty);
  });

  test('rejects a Zone note with duration only in programming', () {
    expect(
      () => normalizer.normalize(
        candidate(
          type: MisfitWorkoutType.zone,
          prescription: 'Z2',
          modality: 'echo',
          programming:
              'Zone 2 - Echo Bike\n'
              '45:00 Echo Bike @ Zone 2',
          result: 'Too much drama today.',
        ),
      ),
      throwsFormatException,
    );
  });

  test('rejects results with no supported metrics', () {
    expect(
      () => normalizer.normalize(
        candidate(
          type: MisfitWorkoutType.gear,
          prescription: 'G3',
          modality: 'row',
          programming: 'Aerobic Row - 3rd Gear',
          result: 'Felt pretty good today',
        ),
      ),
      throwsFormatException,
    );
  });

  test('uses labeled Echo round values as programmed calories', () {
    final workout = normalizer.normalize(
      candidate(
        type: MisfitWorkoutType.gear,
        prescription: 'G6',
        modality: 'echo',
        programming:
            'Build Echo - 6th Gear\n'
            'AMRAP 3:30 x 4\n'
            'Echo Bike Calories @ 6th Gear\n'
            'Rest 3:00',
        result:
            'Gross - Computer lost info on avg RPMs\n'
            'Rd1 - 68\n'
            'Rd2 - 69\n'
            'Rd3 - 71\n'
            'Rd4 - 70',
      ),
    );

    expect(workout.scoringMetric, WorkoutMetric.calories);
    expect(workout.executionPlan.workDuration, '3:30');
    expect(workout.executionPlan.intervalCount, 4);
    expect(workout.intervals, hasLength(4));
    expect(workout.intervals.map((interval) => interval.values['calories']), [
      '68',
      '69',
      '71',
      '70',
    ]);
  });
}
