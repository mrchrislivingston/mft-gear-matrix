import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/screens/database_export_screen.dart';
import 'package:mft_gear_matrix/services/database_export_service.dart';
import 'package:mft_gear_matrix/services/database_restore_service.dart';

DatabaseExportSnapshot snapshot() => DatabaseExportSnapshot(
  fileName: 'mft_backup.db', bytes: Uint8List.fromList([1, 2, 3]),
  summary: const DatabaseSnapshotSummary(schemaVersion: 5, tables: [],
    workoutCount: 129, targetCount: 73, benchmarkCount: 66, benchmarkAttemptCount: 74),
);

void main() {
  testWidgets('save receives bytes and success displays record counts', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: DatabaseExportScreen(
      exporter: () async => snapshot(),
      saver: (value) async {
        expect(value.bytes, orderedEquals([1, 2, 3]));
        expect(value.fileName, 'mft_backup.db');
        return Uri.file('/backups/mft_backup.db');
      },
    )));
    await tester.tap(find.byKey(const Key('databaseExportButton')));
    await tester.pumpAndSettle();
    expect(find.text('Database backup saved.'), findsOneWidget);
    expect(find.text('129 workouts'), findsOneWidget);
    expect(find.text('73 target-history records'), findsOneWidget);
  });

  testWidgets('cancel does not claim a backup was saved', (tester) async {
    await tester.pumpWidget(MaterialApp(home: DatabaseExportScreen(
      exporter: () async => snapshot(), saver: (_) async => null,
    )));
    await tester.tap(find.byKey(const Key('databaseExportButton')));
    await tester.pumpAndSettle();
    expect(find.text('Export canceled. No backup was saved.'), findsOneWidget);
    expect(find.text('Database backup saved.'), findsNothing);
  });

  testWidgets('failure permits retry and clears the error on success', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(home: DatabaseExportScreen(
      exporter: () async => snapshot(),
      saver: (_) async {
        if (++attempts == 1) throw StateError('disk full');
        return Uri.file('/backup.db');
      },
    )));
    await tester.tap(find.byKey(const Key('databaseExportButton')));
    await tester.pumpAndSettle();
    expect(find.textContaining('disk full'), findsOneWidget);
    await tester.tap(find.byKey(const Key('databaseExportButton')));
    await tester.pumpAndSettle();
    expect(find.textContaining('disk full'), findsNothing);
    expect(find.text('Database backup saved.'), findsOneWidget);
  });

  testWidgets('in-progress export disables duplicate requests', (tester) async {
    final pending = Completer<DatabaseExportSnapshot>();
    await tester.pumpWidget(MaterialApp(home: DatabaseExportScreen(
      exporter: () => pending.future, saver: (_) async => null,
    )));
    await tester.tap(find.byKey(const Key('databaseExportButton')));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byKey(const Key('databaseExportButton'))).onPressed, isNull);
    pending.complete(snapshot());
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byKey(const Key('databaseExportButton'))).onPressed, isNotNull);
  });
}
