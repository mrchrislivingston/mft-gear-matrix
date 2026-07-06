import 'package:flutter/material.dart';
import 'models/gear.dart';

void main() {
  runApp(const GearMatrixApp());
}

class LogEntry {
  final int gearNumber;
  final DateTime date;
  final String actualWork;
  final String actualRest;
  final String notes;
  final bool success;

  LogEntry({
    required this.gearNumber,
    required this.date,
    required this.actualWork,
    required this.actualRest,
    required this.notes,
    required this.success,
  });
}
class GearMatrixApp extends StatelessWidget {
  const GearMatrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MFT Gear Matrix',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const HomeRouter(),
    );
  }
}

class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chris Livingston')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Base Phase', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 30),

            MenuButton(
              label: 'Matrix',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MatrixScreen()),
                );
              },
            ),

            const SizedBox(height: 10),

            MenuButton(label: 'Benchmarks', onTap: () {}),

            const SizedBox(height: 10),

            MenuButton(label: 'Weightlifting', onTap: () {}),
          ],
        ),
      ),
    );
  }
}

class MatrixScreen extends StatelessWidget {
  const MatrixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matrix')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Modality', style: TextStyle(fontSize: 18)),
            SizedBox(height: 30),
            ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RunGridScreen()),
    );
  },
  child: const Text('Run'),
),
            SizedBox(height: 10),
            ElevatedButton(onPressed: () {}, child: const Text('Echo Bike')),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () {}, child: const Text('C2 Bike')),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () {}, child: const Text('Row')),
            SizedBox(height: 10),
            ElevatedButton(onPressed: () {}, child: const Text('Ski')),
          ],
        ),
      ),
    );
  }
}

class MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const MenuButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(onPressed: onTap, child: Text(label)),
    );
  }
}
class RunGridScreen extends StatelessWidget {
  const RunGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gears = [
  Gear(number: 1, work: '15:00', rest: '1:00', intervals: 2),
  Gear(number: 2, work: '13:00', rest: '1:15', intervals: 2),
  Gear(number: 3, work: '8:00', rest: '1:30', intervals: 3),
  Gear(number: 4, work: '6:00', rest: '2:30', intervals: 3),
  Gear(number: 5, work: '4:00', rest: '2:45', intervals: 4),
  Gear(number: 6, work: '3:30', rest: '3:00', intervals: 4),
  Gear(number: 7, work: '2:30', rest: '3:15', intervals: 5),
  Gear(number: 8, work: '1:30', rest: '3:30', intervals: 7),
];
    final logs = <LogEntry>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Run Grid')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
children: [
  for (final gear in gears) ...[
    GestureDetector(
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => GearDetailScreen(gear: gear, logs: logs),
    ),
  );
},
  child: GearCard(gear: gear),
),
    const SizedBox(height: 10),
  ]
],
        ),
      ),
    );
  }
}
class GearCard extends StatelessWidget {
  final Gear gear;

  const GearCard({super.key, required this.gear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        'Gear ${gear.number} — ${gear.work} / ${gear.rest} / ${gear.intervals}',
      ),
    );
  }
}
class GearDetailScreen extends StatelessWidget {
  final Gear gear;
  final List<LogEntry> logs;

  const GearDetailScreen({
  super.key,
  required this.gear,
  required this.logs,
});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gear ${gear.number}')),
     body: Padding(
  padding: const EdgeInsets.all(20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Work: ${gear.work}', style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 10),
      Text('Rest: ${gear.rest}', style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 10),
      Text('Intervals: ${gear.intervals}', style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 30),
     ElevatedButton(
  onPressed: () {
  logs.add(
    LogEntry(
      gearNumber: gear.number,
      date: DateTime.now(),
      actualWork: gear.work,
      actualRest: gear.rest,
      notes: 'placeholder',
      success: true,
    ),
  );

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Logged')),
  );
},
  child: const Text('Log Workout'),
),
    ],
  ),
),
    );
  }
}