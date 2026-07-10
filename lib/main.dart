import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';   // 👈 start with SplashScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sajhya',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}