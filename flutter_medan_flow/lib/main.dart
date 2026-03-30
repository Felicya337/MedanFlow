import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/tracking_provider.dart';
import 'screens/landing_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TrackingProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medan Flow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0083B0)),
        useMaterial3: true,
      ),
      home: const LandingPage(),
    );
  }
}