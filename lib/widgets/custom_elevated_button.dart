// lib/widgets/custom_elevated_button.dart
import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final Widget? icon;

  const CustomElevatedButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) icon!,
                  if (icon != null) const SizedBox(width: 8),
                  Text(label),
                ],
              ),
      ),
    );
  }
}