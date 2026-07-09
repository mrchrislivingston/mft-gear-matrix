import 'package:flutter/material.dart';

import '../models/gear.dart';
import '../services/app_state.dart';

class TargetManagerScreen extends StatefulWidget {
  final Gear gear;

  const TargetManagerScreen({
    super.key,
    required this.gear,
  });

  @override
  State<TargetManagerScreen> createState() => _TargetManagerScreenState();
}

class _TargetManagerScreenState extends State<TargetManagerScreen> {
  late final TextEditingController lowTargetController;
  late final TextEditingController highTargetController;

  @override
  void initState() {
    super.initState();

    final currentTarget = widget.gear.targets.first.history.last;

    lowTargetController = TextEditingController(
      text: currentTarget.lowTarget,
    );

    highTargetController = TextEditingController(
      text: currentTarget.highTarget,
    );
  }

  @override
  void dispose() {
    lowTargetController.dispose();
    highTargetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTarget = widget.gear.targets.first.history.last;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Gear ${widget.gear.number} Target'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current target: ${currentTarget.displayTarget} / mile'),

            const SizedBox(height: 24),

            TextField(
              controller: lowTargetController,
              decoration: const InputDecoration(
                labelText: 'Low Target',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: highTargetController,
              decoration: const InputDecoration(
                labelText: 'High Target',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

           ElevatedButton(
  onPressed: () {
    AppState.instance.updateRunPaceTarget(
      gearNumber: widget.gear.number,
      lowTarget: lowTargetController.text,
      highTarget: highTargetController.text,
    );

    Navigator.pop(context);
  },
  child: const Text('Save'),
),
          ],
        ),
      ),
    );
  }
}