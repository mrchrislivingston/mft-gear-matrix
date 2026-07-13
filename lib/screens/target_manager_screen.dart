import 'package:flutter/material.dart';

import '../models/gear.dart';
import '../models/modality.dart';
import '../services/app_state.dart';

class TargetManagerScreen extends StatefulWidget {
  final Gear gear;
  final Modality modality;

  const TargetManagerScreen({
    super.key,
    required this.gear,
    required this.modality,
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

    final target = widget.gear.targetForModality(widget.modality);
    final currentTarget = target?.currentTarget;

    lowTargetController = TextEditingController(
      text: currentTarget?.lowTarget ?? '',
    );

    highTargetController = TextEditingController(
      text: currentTarget?.highTarget ?? '',
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
    final target = widget.gear.targetForModality(widget.modality);
    final currentTarget = target?.currentTarget;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit ${widget.modality.displayName} Gear '
          '${widget.gear.number} Target',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            currentTarget == null
                ? 'No target currently set'
                : 'Current target: ${currentTarget.displayTarget}',
          ),

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
            onPressed: () async {
              final lowTarget = lowTargetController.text.trim();
              final highTarget = highTargetController.text.trim();

              if (lowTarget.isEmpty || highTarget.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Enter both a low target and a high target.',
                    ),
                  ),
                );
                return;
              }

              await AppState.instance.updateTarget(
                gearNumber: widget.gear.number,
                modality: widget.modality,
                lowTarget: lowTarget,
                highTarget: highTarget,
              );

              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(
              currentTarget == null ? 'Create Target' : 'Save Target',
            ),
          ),
        ],
      ),
    );
  }
}