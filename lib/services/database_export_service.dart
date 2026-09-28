import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'database_restore_service.dart';
import 'database_service.dart';

class DatabaseExportSnapshot {
  final String fileName;
  final Uint8List bytes;
  final DatabaseSnapshotSummary summary;

  const DatabaseExportSnapshot({
    required this.fileName,
    required this.bytes,
    required this.summary,
  });
}

class DatabaseExportService {
  final Future<Database> Function() _databaseLoader;
  final Future<DatabaseSnapshotSummary> Function(Uint8List) _validator;
  final Future<Directory> Function() _temporaryDirectory;
  final DateTime Function() _clock;

  DatabaseExportService({
    Future<Database> Function()? databaseLoader,
    Future<DatabaseSnapshotSummary> Function(Uint8List)? validator,
    Future<Directory> Function()? temporaryDirectory,
    DateTime Function()? clock,
  }) : _databaseLoader = databaseLoader ?? (() => DatabaseService.instance.database),
       _validator = validator ?? DatabaseRestoreService().validateBytes,
       _temporaryDirectory = temporaryDirectory ?? (() => Directory.systemTemp.createTemp('mft_export_')),
       _clock = clock ?? DateTime.now;

  Future<DatabaseExportSnapshot> createSnapshot() async {
    final database = await _databaseLoader();
    final directory = await _temporaryDirectory();
    try {
      final destination = path.join(directory.path, 'snapshot.db');
      // SQLite creates a consistent standalone snapshot, including committed
      // WAL data, without closing or replacing the live database.
      await database.execute('VACUUM INTO ?', [destination]);
      final bytes = await File(destination).readAsBytes();
      final summary = await _validator(bytes);
      final timestamp = _clock().toUtc().toIso8601String().replaceAll(':', '-');
      return DatabaseExportSnapshot(
        fileName: 'mft_gear_matrix_$timestamp.db',
        bytes: bytes,
        summary: summary,
      );
    } finally {
      if (await directory.exists()) await directory.delete(recursive: true);
    }
  }
}
