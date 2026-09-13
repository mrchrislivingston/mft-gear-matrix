import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/screens/database_restore_screen.dart';
import 'package:mft_gear_matrix/services/database_restore_service.dart';

DatabaseSnapshotSummary snapshot() {
  return const DatabaseSnapshotSummary(
    schemaVersion: 5,
    tables: [
      'benchmark_attempts',
      'benchmarks',
      'interval_metrics',
      'target_history',
      'workout_intervals',
      'workouts',
    ],
    workoutCount: 129,
    targetCount: 65,
    benchmarkCount: 66,
    benchmarkAttemptCount: 74,
  );
}

void main() {
  testWidgets('validates before enabling a confirmed restore', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var restores = 0;
    var reloads = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: DatabaseRestoreScreen(
          filePicker: () async {
            return SelectedDatabaseFile(
              name: 'mft_gear_matrix.db',
              bytes: Uint8List.fromList([1, 2, 3]),
            );
          },
          validator: (_) async => snapshot(),
          restorer: (_) async {
            restores++;
            return DatabaseRestoreResult(
              snapshot: snapshot(),
              backupPath: '/private/backup.db',
            );
          },
          reloadAppState: () async {
            reloads++;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('databaseSelectButton')));
    await tester.pumpAndSettle();

    expect(find.text('Validated backup'), findsOneWidget);
    expect(find.text('129 workouts'), findsOneWidget);
    expect(find.text('65 target-history records'), findsOneWidget);
    expect(find.text('66 benchmark definitions'), findsOneWidget);
    expect(find.text('74 benchmark attempts'), findsOneWidget);
    expect(find.text('Integrity check: OK'), findsOneWidget);

    FilledButton restoreButton() => tester.widget<FilledButton>(
      find.byKey(const Key('databaseRestoreButton')),
    );

    expect(restoreButton().onPressed, isNull);

    await tester.tap(find.byKey(const Key('databaseRestoreAcknowledgement')));
    await tester.pump();

    expect(restoreButton().onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('databaseRestoreButton')));
    await tester.pumpAndSettle();

    expect(find.text('Replace this phone’s database?'), findsOneWidget);
    expect(restores, 0);

    await tester.tap(find.byKey(const Key('databaseRestoreDialogConfirm')));
    await tester.pumpAndSettle();

    expect(restores, 1);
    expect(reloads, 1);
    expect(
      find.textContaining('Database restored successfully'),
      findsOneWidget,
    );
    expect(find.textContaining('backed up automatically'), findsOneWidget);
  });

  testWidgets('shows validation failure without enabling restore', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DatabaseRestoreScreen(
          filePicker: () async {
            return SelectedDatabaseFile(
              name: 'wrong.db',
              bytes: Uint8List.fromList([1]),
            );
          },
          validator: (_) async {
            throw const DatabaseRestoreException(
              'Unsupported database schema version 4.',
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('databaseSelectButton')));
    await tester.pumpAndSettle();

    expect(find.text('Unsupported database schema version 4.'), findsOneWidget);
    expect(find.byKey(const Key('databaseRestoreButton')), findsNothing);
  });
}
