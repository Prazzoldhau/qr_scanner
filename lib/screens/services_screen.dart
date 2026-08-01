// lib/screens/services_screen.dart
import 'package:flutter/material.dart';

class _ServiceItem {
  final IconData icon;
  final String label;
  final Color color;

  const _ServiceItem({required this.icon, required this.label, required this.color});
}

const _services = [
  _ServiceItem(icon: Icons.accessibility_new_outlined, label: 'Physiotherapy', color: Color(0xFF6C63FF)),
  _ServiceItem(icon: Icons.medical_services_outlined, label: 'Dental', color: Color(0xFF0A6EBD)),
  _ServiceItem(icon: Icons.restaurant_menu_outlined, label: 'Dietician', color: Color(0xFF16A085)),
  _ServiceItem(icon: Icons.psychology_outlined, label: 'Behavioural Therapy', color: Color(0xFFAA5AC7)),
  _ServiceItem(icon: Icons.record_voice_over_outlined, label: 'Speech Therapy', color: Color(0xFFE0A100)),
  _ServiceItem(icon: Icons.self_improvement_outlined, label: 'Occupational Therapy', color: Color(0xFFD9534F)),
];

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Services', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _services.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final service = _services[index];
          return Material(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${service.label} is coming soon')),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: service.color.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(service.icon, color: service.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        service.label,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Coming soon',
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
