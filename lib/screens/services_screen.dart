// lib/screens/services_screen.dart
import 'package:flutter/material.dart';
import 'lab_service_screen.dart';

class _ServiceItem {
  final IconData icon;
  final String label;
  final Color color;
  // Null means "coming soon" (shows the placeholder snackbar + badge).
  // Set for the one service that's actually built.
  final WidgetBuilder? builder;

  const _ServiceItem({required this.icon, required this.label, required this.color, this.builder});
}

final _services = [
  _ServiceItem(icon: Icons.accessibility_new_outlined, label: 'Physiotherapy', color: const Color(0xFF6C63FF)),
  _ServiceItem(icon: Icons.medical_services_outlined, label: 'Dental', color: const Color(0xFF0A6EBD)),
  _ServiceItem(icon: Icons.restaurant_menu_outlined, label: 'Dietician', color: const Color(0xFF16A085)),
  _ServiceItem(icon: Icons.psychology_outlined, label: 'Behavioural Therapy', color: const Color(0xFFAA5AC7)),
  _ServiceItem(icon: Icons.record_voice_over_outlined, label: 'Speech Therapy', color: const Color(0xFFE0A100)),
  _ServiceItem(icon: Icons.self_improvement_outlined, label: 'Occupational Therapy', color: const Color(0xFFD9534F)),
  _ServiceItem(icon: Icons.healing_outlined, label: 'Nursing', color: const Color(0xFF17A2B8)),
  _ServiceItem(
    icon: Icons.biotech_outlined,
    label: 'Lab (Blood Investigation)',
    color: const Color(0xFFC0392B),
    builder: (_) => const LabServiceScreen(),
  ),
];

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Services', style: TextStyle(color: Colors.black87)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _services.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final service = _services[index];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (service.builder != null) {
                  Navigator.push(context, MaterialPageRoute(builder: service.builder!));
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${service.label} is coming soon')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: service.color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(service.icon, color: service.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        service.label,
                        style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (service.builder == null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Coming soon',
                          style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      )
                    else
                      Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
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
