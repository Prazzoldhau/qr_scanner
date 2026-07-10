import 'package:flutter/material.dart';

/// A transparent app bar with a primary color title.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Theme.of(context).primaryColor,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}