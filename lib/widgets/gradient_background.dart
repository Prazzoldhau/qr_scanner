import 'package:flutter/material.dart';

/// A container with the same gradient background used on LoginScreen and Dashboard.
class GradientBackground extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const GradientBackground({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F0FE), Color(0xFFFFFFFF)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}