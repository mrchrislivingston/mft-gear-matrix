import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
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