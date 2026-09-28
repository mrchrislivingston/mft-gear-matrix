import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/screens/fitr_daily_screen.dart';
import 'package:mft_gear_matrix/services/fitr_daily_service.dart';

class FakeDailyService extends FitrDailyService {
  String result = '';
  String notes = '';
  String scoreEntry = '';
  Map<String,dynamic> metadata = {};
  bool completed = false;
  bool failSave = false;
  bool failRefresh = false;
  @override
  Future<List<DailyPlan>> loadWeek(DateTime monday) async => [DailyPlan(
    id: '1', date: dailyDate(monday), planTitle: 'Misfit', fetchedAt: '2026-09-21T09:00:00',
    instructions: 'Perform Lift 1. Add 0-2 of the following.', pieces: [
      DailyPiece(id: 'lift', title: 'Lift 1', description: 'Clean and jerk', priority: 'required',
        result: result, notes: notes, completed: completed, metadata: metadata, scoreEntry: scoreEntry),
      const DailyPiece(id: 'skill', title: 'Skill/REPs', description: 'Toes to bar', priority: 'optional'),
    ],
  )];
  @override
  Future<int> refresh(DateTime monday) async {
    if (failRefresh) throw StateError('Offline');
    return 1;
  }
  @override
  Future<void> saveStructuredEntry(DailyPiece piece, {required String result, required String notes,
    required bool completed, required String scoreEntry}) async {
    await saveEntry(piece.id, result: result, notes: notes, completed: completed);
    this.scoreEntry = scoreEntry;
  }
  @override
  Future<void> saveEntry(String id, {required String result, required String notes, required bool completed}) async {
    if (failSave) throw StateError('Disk unavailable');
    this.result = result; this.notes = notes; this.completed = completed;
  }
}

void main() {
  testWidgets('phone view saves results and completion independently of priority', (tester) async {
    final service = FakeDailyService();
    await tester.pumpWidget(MaterialApp(home: FitrDailyScreen(service: service, initialDate: DateTime(2026, 9, 21))));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);
    await tester.tap(find.text('Results / notes').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '225 lb');
    await tester.enterText(find.byType(TextField).at(1), 'Strong singles');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(service.result, '225 lb');
    expect(service.notes, 'Strong singles');
    expect(service.completed, isTrue);
    expect(find.text('Required'), findsOneWidget);
    expect(find.text('Result: 225 lb'), findsOneWidget);
  });
  testWidgets('failed save keeps typed text for retry and cancel makes no change', (tester) async {
    final service = FakeDailyService()..failSave = true;
    await tester.pumpWidget(MaterialApp(home: FitrDailyScreen(service: service, initialDate: DateTime(2026, 9, 21))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Results / notes').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '225 lb');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not save.'), findsOneWidget);
    expect(find.text('225 lb'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.result, isEmpty);
  });
  testWidgets('FITR round fields save individual values and display their sum', (tester) async {
    final service = FakeDailyService()..metadata = {'score_score': {
      'id': 10, 'measure':'reps', 'count_sub_value':3, 'custom_type':'sum_all', 'direction':'ascending'}};
    await tester.pumpWidget(MaterialApp(home: FitrDailyScreen(service:service,initialDate:DateTime(2026,9,21))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Results / notes').first);
    await tester.pumpAndSettle();
    expect(find.text('Entry 3 (reps)'),findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0),'30');
    await tester.enterText(find.byType(TextField).at(1),'31');
    await tester.enterText(find.byType(TextField).at(2),'32');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(service.scoreEntry,contains('"30","31","32"'));
    expect(find.textContaining('Sum of entries: 93 reps'),findsOneWidget);
  });
  testWidgets('desktop grid displays coach instructions and survives refresh error', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = FakeDailyService()..failRefresh = true;
    await tester.pumpWidget(MaterialApp(home: FitrDailyScreen(service: service, initialDate: DateTime(2026, 9, 21))));
    await tester.pumpAndSettle();
    expect(find.byType(Table), findsOneWidget);
    expect(find.text('Perform Lift 1. Add 0-2 of the following.'), findsOneWidget);
    await tester.tap(find.text('Refresh from FITR'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Saved programming is still available.'), findsOneWidget);
    expect(find.text('Clean and jerk'), findsOneWidget);
  });
}
