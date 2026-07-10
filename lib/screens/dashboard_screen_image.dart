import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// MODELS
// These mirror the fields used in your Django template
// (latest_prescription + exercises loop). Adjust field names here if your
// DRF serializer uses different keys.
// ---------------------------------------------------------------------------

class Exercise {
  final String exerciseName;
  final String? exerciseUrl;

  Exercise({required this.exerciseName, this.exerciseUrl});

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      exerciseName: json['exercise_name'] ?? 'Unnamed exercise',
      exerciseUrl: json['exercise_url'],
    );
  }
}

class Prescription {
  final int id;
  final String createdAt;
  final String status;
  final String? notes;
  final List<Exercise> exercises;

  Prescription({
    required this.id,
    required this.createdAt,
    required this.status,
    this.notes,
    required this.exercises,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'],
      createdAt: json['created_at'] ?? '',
      status: json['status'] ?? 'active',
      notes: json['prescription_notes'],
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => Exercise.fromJson(e))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN
// patientData is expected to look like:
// {
//   "patient_name": "...",
//   "diagnosis": "...",
//   "latest_prescription": { ...see Prescription.fromJson above... }
// }
//
// This mirrors how DashboardScreen already receives patientData, so you can
// pass the same map (or fetch it separately) into this screen.
// ---------------------------------------------------------------------------

class PrescriptionsScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;

  const PrescriptionsScreen({super.key, required this.patientData});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  bool _isExpanded = true;

  // Tracks which exercises the patient has marked as done, by index.
  // This adds the "progress" functionality your web template's progress
  // bar was set up for but didn't yet have logic to populate.
  final Set<int> _completedExercises = {};

  @override
  Widget build(BuildContext context) {
    final patientName = widget.patientData['patient_name'] ?? 'Patient';
    final diagnosis = widget.patientData['diagnosis'] ?? 'Not specified';
    final rawPrescription = widget.patientData['latest_prescription'];

    final Prescription? prescription = rawPrescription != null
        ? Prescription.fromJson(rawPrescription)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Prescriptions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // --- Header (mirrors .patient-info block) ---
            Text(
              patientName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Diagnosis: $diagnosis',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),

            if (prescription == null)
              _buildEmptyState()
            else
              _buildPrescriptionCard(prescription),
          ],
        ),
      ),
    );
  }

  // --- Empty state (mirrors .empty-state block) ---
  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: const [
            Icon(Icons.assignment_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No Prescriptions Yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              'You do not have any exercise prescriptions.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // --- Prescription card (mirrors .prescription-card block) ---
  Widget _buildPrescriptionCard(Prescription prescription) {
    final total = prescription.exercises.length;
    final completed = _completedExercises.length;
    final progress = total == 0 ? 0.0 : completed / total;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header: title, status badge, progress, toggle ---
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Prescription ${prescription.createdAt}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildStatusBadge(prescription.status),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$completed/$total',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),

          // --- Body: exercises list + notes ---
          if (_isExpanded) ...[
            const Divider(height: 1),
            if (prescription.exercises.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No exercises assigned in this prescription.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: prescription.exercises.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final exercise = prescription.exercises[index];
                  final isDone = _completedExercises.contains(index);
                  return ListTile(
                    leading: exercise.exerciseUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              exercise.exerciseUrl!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildNoImagePlaceholder(),
                            ),
                          )
                        : _buildNoImagePlaceholder(),
                    title: Text(exercise.exerciseName),
                    trailing: Checkbox(
                      value: isDone,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _completedExercises.add(index);
                          } else {
                            _completedExercises.remove(index);
                          }
                        });
                      },
                    ),
                  );
                },
              ),

            // --- Notes section ---
            if (prescription.notes != null &&
                prescription.notes!.trim().isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Prescription Notes:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(prescription.notes!),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.blue;
        break;
      case 'paused':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}