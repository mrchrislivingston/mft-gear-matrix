import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/app_state.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppState.instance.loadLogs();

  if (!kIsWeb) {
    final sqliteWorkouts =
        await DatabaseService.instance.getWorkouts();

    debugPrint(
      'Persistence comparison: '
      'shared_preferences=${AppState.instance.logs.length}, '
      'SQLite=${sqliteWorkouts.length}',
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