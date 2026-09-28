import 'package:sqflite/sqflite.dart';

Future<void> createDailyTables(DatabaseExecutor db) async {
  await db.execute('''CREATE TABLE fitr_days (
    id TEXT PRIMARY KEY, workout_date TEXT NOT NULL, plan_title TEXT NOT NULL,
    instructions TEXT NOT NULL, fetched_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE fitr_pieces (
    id TEXT PRIMARY KEY, day_id TEXT NOT NULL, position INTEGER NOT NULL,
    title TEXT NOT NULL, description TEXT NOT NULL, priority TEXT NOT NULL,
    active INTEGER NOT NULL DEFAULT 1, result TEXT NOT NULL DEFAULT '',
    notes TEXT NOT NULL DEFAULT '', completed INTEGER NOT NULL DEFAULT 0,
    source_json TEXT NOT NULL DEFAULT '{}', score_entry_json TEXT NOT NULL DEFAULT '',
    prescription_snapshot TEXT,
    FOREIGN KEY(day_id) REFERENCES fitr_days(id) ON DELETE CASCADE)''');
  await createWorkingMaxTable(db);
  await db.execute('CREATE INDEX index_fitr_days_date ON fitr_days(workout_date)');
  await db.execute('CREATE INDEX index_fitr_pieces_day ON fitr_pieces(day_id)');
}


Future<void> createWorkingMaxTable(DatabaseExecutor db) async {
  await db.execute("""CREATE TABLE working_max_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT, lift_id TEXT NOT NULL,
    pounds REAL, effective_date TEXT NOT NULL)""");
}

Future<void> upgradeDailyScoring(DatabaseExecutor db) async {
  await db.execute("ALTER TABLE fitr_pieces ADD COLUMN source_json TEXT NOT NULL DEFAULT '{}'");
  await db.execute("ALTER TABLE fitr_pieces ADD COLUMN score_entry_json TEXT NOT NULL DEFAULT ''");
  await db.execute('ALTER TABLE fitr_pieces ADD COLUMN prescription_snapshot TEXT');
  await createWorkingMaxTable(db);
}
