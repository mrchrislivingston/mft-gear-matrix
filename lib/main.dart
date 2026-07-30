import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/app_state.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // This still loads targets and the shared_preferences workout copy.
  await AppState.instance.loadLogs();

  // On native platforms, replace the in-memory workout list with
  // the records read from SQLite.
  //
  // shared_preferences remains available as a temporary backup
  // during the migration.
  if (!kIsWeb) {
    final sqliteWorkouts =
        await DatabaseService.instance.getWorkouts();

    AppState.instance.logs
      ..clear()
      ..addAll(sqliteWorkouts);

    debugPrint(
      'Workout read source: SQLite '
      '(${AppState.instance.logs.length} workouts)',
    );
  }

  runApp(const GearMatrixApp());
}

class GearMatrixApp extends StatelessWidget {
  const GearMatrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MFT Gear Matrix',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}