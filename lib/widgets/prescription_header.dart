import 'package:flutter/material.dart';

class PrescriptionHeader extends StatelessWidget {
  final String title;
  final String details;
  final String? target;

  const PrescriptionHeader({
    super.key,
    required this.title,
    required this.details,
    this.target,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Text(details),
        if (target != null && target!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(target!),
        ],
        const SizedBox(height: 30),
      ],
    );
  }
}