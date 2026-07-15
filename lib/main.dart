import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';

void main() {
  // Assignment 1.3, Part 2: wrap runApp in ProviderScope. This is the
  // ONLY place ProviderScope is added.
  runApp(const ProviderScope(child: CareerHubApp()));
}

/// Assignment 1.4: CareerHubApp becomes a ConsumerWidget so it can read the
/// GoRouter out of goRouterProvider, and switches from MaterialApp with a
/// `home:` to MaterialApp.router driven by that router. The URL is now the
/// source of truth for what is on screen — there is no single home widget
/// any more.
class CareerHubApp extends ConsumerWidget {
  const CareerHubApp({super.key});

  // Same deep-teal seed from Assignment 1.1. Part 3a requires reusing it,
  // not choosing a new one — light and dark themes should read as the
  // same app, not two different apps.
  static const Color _seedColor = Color(0xFF00695C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
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
      // Wires GoRouter's parser, delegate and back-button dispatcher in.
      routerConfig: router,
    );
  }
}
