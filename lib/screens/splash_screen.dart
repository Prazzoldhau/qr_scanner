// lib/screens/splash_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final api = ApiService();
      await api.init();

      // ✅ Debug: print what cookies exist before calling /api/me/
      final cookies = await api.debugCookies();
      debugPrint('=== COOKIES ON SPLASH: $cookies');

      final patientData = await api.getCurrentUser();
      debugPrint('=== getCurrentUser success: $patientData');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(patientData: patientData),
        ),
      );
    } catch (e) {
      debugPrint('=== SplashScreen error: $e');
      if (!mounted) return;
      // ✅ Show error on screen instead of silently going to login
      setState(() => _debugInfo = e.toString());
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (_debugInfo.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _debugInfo,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}