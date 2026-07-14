import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const CareerHubApp());
}

class CareerHubApp extends StatelessWidget {
  const CareerHubApp({super.key});

  // Same deep-teal seed from Assignment 1.1. Part 3a requires reusing it,
  // not choosing a new one — light and dark themes should read as the
  // same app, not two different apps.
  static const Color _seedColor = Color(0xFF00695C);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareerHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
      ),
      // Follows the device's system setting rather than forcing one mode.
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
