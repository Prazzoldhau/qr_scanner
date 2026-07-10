import 'package:flutter/material.dart';

/// A reusable card with the same design as used in the Dashboard.
/// Always uses rounded corners, subtle shadow (or elevation: 0 with translucent bg).
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color? color;
  final BorderRadius? borderRadius;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation,
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 0,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
      ),
      color: color ?? Colors.white.withOpacity(0.8),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}