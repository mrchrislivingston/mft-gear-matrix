import 'package:flutter/material.dart';

import '../models/gear.dart';

class GearCard extends StatelessWidget {
  final Gear gear;

  const GearCard({
    super.key,
    required this.gear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('Gear ${gear.number}'),
        subtitle: Text(
          'Work: ${gear.work}   Rest: ${gear.rest}',
        ),
        trailing: Text('${gear.intervals}x'),
      ),
    );
  }
}