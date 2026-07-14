import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';

void main() {
  // Assignment 1.3, Part 2: wrap runApp in ProviderScope. This is the
  // ONLY place ProviderScope is added — CareerHubApp itself stays a
  // plain StatelessWidget, since it never reads a provider directly.
  runApp(const ProviderScope(child: CareerHubApp()));
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
