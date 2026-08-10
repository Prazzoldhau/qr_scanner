// lib/screens/splash_screen.dart
import 'package:flutter/foundation.dart' show kDebugMode;
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
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final api = ApiService();
      await api.init();

      final patientData = await api.getCurrentUser();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(patientData: patientData),
        ),
      );
    } catch (e) {
      // Guarded by kDebugMode: debugPrint is NOT stripped from release builds,
      // and this path can carry session/account detail into the device log.
      if (kDebugMode) debugPrint('SplashScreen: no active session ($e)');

      if (!mounted) return;
      // Not being logged in is the normal first-launch path, so go straight to
      // login instead of showing the user a raw exception.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
