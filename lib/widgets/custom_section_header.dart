import 'package:flutter/material.dart';
import 'custom_card.dart';   // 👈 add this line

class CustomSectionHeader extends StatelessWidget {
  final String patientName;
  final String diagnosis;

  const CustomSectionHeader({
    super.key,
    required this.patientName,
    required this.diagnosis,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              patientName[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Diagnosis: $diagnosis',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}