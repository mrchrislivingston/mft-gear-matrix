import 'package:flutter/material.dart';

import '../models/modality.dart';
import 'gear_grid_screen.dart';

class MatrixScreen extends StatelessWidget {
  const MatrixScreen({super.key});

  void _openModality(
    BuildContext context,
    Modality modality,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GearGridScreen(
          modality: modality,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matrix'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Modality',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _openModality(
                    context,
                    Modality.run,
                  );
                },
                child: const Text('Run'),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _openModality(
                    context,
                    Modality.echo,
                  );
                },
                child: const Text('Echo Bike'),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _openModality(
                    context,
                    Modality.bikeErg,
                  );
                },
                child: const Text('C2 Bike'),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _openModality(
                    context,
                    Modality.row,
                  );
                },
                child: const Text('Row'),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _openModality(
                    context,
                    Modality.ski,
                  );
                },
                child: const Text('Ski'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}