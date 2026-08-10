import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'qr_scanner_screen.dart';
import 'signup_screen.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_elevated_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _errorMessage = '';

  /// Maps a thrown error to something safe to show a patient. Raw exception text
  /// can carry server internals (status lines, stack detail, HTML bodies), so it
  /// is never rendered directly.
  String _friendlyError(Object e) {
    final raw = e.toString();
    if (raw.contains('401') || raw.contains('403')) {
      return 'Incorrect Patient Code or PIN. Please try again.';
    }
    if (raw.contains('Network error') || raw.contains('timeout')) {
      return 'Cannot reach Sajhya. Check your internet connection.';
    }
    return 'Sign in failed. Please try again in a moment.';
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final api = ApiService();
      await api.init();
      final result = await api.login(username, password);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(patientData: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = _friendlyError(e);
      setState(() {
        _errorMessage = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F0FE), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.health_and_safety,
                      size: 80,
                      color: Color(0xFF0A6EBD),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome Back',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in with your Patient Code and PIN or Password',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    CustomTextField(
                      controller: _usernameController,
                      label: 'Patient Code',
                      prefixIcon: Icons.person,
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your Patient Code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'PIN or Password',
                      prefixIcon: Icons.lock,
                      obscureText: true,
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your PIN or Password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    CustomElevatedButton(
                      onPressed: _login,
                      label: 'Sign In',
                      isLoading: _isLoading,
                      icon: const Icon(Icons.login_rounded),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                          ),
                          icon: const Icon(Icons.qr_code_scanner, size: 18),
                          label: const Text('Scan QR'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0A6EBD),
                          ),
                        ),
                        TextButton(
                          // No self-service PIN reset exists server-side yet. A
                          // button that silently does nothing reads as a broken
                          // feature during Play review, so point the patient at
                          // the recovery route that does work today.
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Forgot your PIN?'),
                              content: const Text(
                                'Ask your physiotherapist to reset your PIN, or scan '
                                'the QR code they provide to sign in without it.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          ),
                          child: const Text('Forgot your PIN?'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      ),
                      child: const Text("Don't have a profile? Create one"),
                    ),
                    if (_errorMessage.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}