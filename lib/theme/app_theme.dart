// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFF0A6EBD),      // primary blue
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0A6EBD),
      secondary: Color(0xFF6C63FF),
      tertiary: Color(0xFF03DAC6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF0A6EBD), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      labelStyle: const TextStyle(fontWeight: FontWeight.w500),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF0A6EBD),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        minimumSize: const Size(double.infinity, 56),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0A6EBD),
      ),
    ),
  );
}