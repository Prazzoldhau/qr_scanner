import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'qr_scanner_screen.dart';
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
  String _debugInfo = ''; // ✅ ADDED

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _debugInfo = ''; // ✅ ADDED
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
      setState(() {
        _debugInfo = e.toString(); // ✅ ADDED
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
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
                      'Sign in with your Patient Code and Security PIN',
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
                      label: 'Security PIN (Phone)',
                      prefixIcon: Icons.lock,
                      obscureText: true,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your PIN';
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
                          onPressed: () {
                            // TODO: implement forgot PIN logic
                          },
                          child: const Text('Forgot your PIN?'),
                        ),
                      ],
                    ),
                    // ✅ ADDED: debug box shown only on error
                    if (_debugInfo.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        color: Colors.red.shade50,
                        child: SelectableText(
                          _debugInfo,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
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