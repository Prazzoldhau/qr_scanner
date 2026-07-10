// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/custom_card.dart';
import 'login_screen.dart';
import 'marketplace_screen.dart';
import 'physio_contact_screen.dart';

// --- Models ---
class Exercise {
  final int id;
  final String exerciseName;
  final String? exerciseUrl;
  final int sets;
  final int reps;
  final int holdTimeSec;
  final int restTimeSec;

  Exercise({
    required this.id,
    required this.exerciseName,
    this.exerciseUrl,
    required this.sets,
    required this.reps,
    required this.holdTimeSec,
    required this.restTimeSec,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? 0,
      exerciseName: json['exercise_name'] ?? 'Unnamed exercise',
      exerciseUrl: json['exercise_url'],
      sets: json['sets'] ?? 3,
      reps: json['reps'] ?? 10,
      holdTimeSec: json['hold_time_sec'] ?? 0,
      restTimeSec: json['rest_time_sec'] ?? 60,
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
// DASHBOARD SCREEN
// ---------------------------------------------------------------------------
class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;

  const DashboardScreen({super.key, required this.patientData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final patientName = widget.patientData['patient_name'] ?? 'Patient';
    final diagnosis = widget.patientData['diagnosis'] ?? 'Not specified';
    final rawPrescription = widget.patientData['latest_prescription'];

    final Prescription? prescription = rawPrescription != null
        ? Prescription.fromJson(rawPrescription)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(patientName, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
            onPressed: () async {
              await ApiService().logout();
              if (mounted) Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListView(
              children: [
                // Quick action row
                Row(
                  children: [
                    Expanded(
                      child: _quickAction(
                        icon: Icons.storefront_outlined,
                        label: 'Marketplace',
                        color: const Color(0xFF0A6EBD),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MarketplaceScreen(patientData: widget.patientData)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _quickAction(
                        icon: Icons.person_pin_outlined,
                        label: 'My Physio',
                        color: const Color(0xFF6C63FF),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PhysioContactScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Exercise section header
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Exercise Prescriptions',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                ),
                if (prescription == null)
                  _buildEmptyState()
                else ...[
                  _buildExerciseFeed(prescription.exercises),
                  if (prescription.notes != null && prescription.notes!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildNotesCard(prescription.notes!),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickAction({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const CustomCard(
      color: Colors.grey,
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No Prescriptions Yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          SizedBox(height: 4),
          Text(
            'You do not have any exercise prescriptions.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseFeed(List<Exercise> exercises) {
    if (exercises.isEmpty) {
      return const CustomCard(
        color: Colors.grey,
        child: Text(
          'No exercises assigned.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exercises.length,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemBuilder: (context, index) => _ExerciseFeedItem(exercise: exercises[index]),
    );
  }

  Widget _buildNotesCard(String notes) {
    return CustomCard(
      color: Colors.grey[800]!,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Prescription Notes',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            notes,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EXERCISE FEED ITEM – stateful for done/feedback state
// ---------------------------------------------------------------------------
class _ExerciseFeedItem extends StatefulWidget {
  final Exercise exercise;
  const _ExerciseFeedItem({required this.exercise});

  @override
  State<_ExerciseFeedItem> createState() => _ExerciseFeedItemState();
}

class _ExerciseFeedItemState extends State<_ExerciseFeedItem> {
  bool _isDone = false;
  String? _selectedFeedback; // 'normal' | 'hard' | 'painful' | 'increased_symptom'
  bool _isSubmitted = false;
  bool _isSubmitting = false;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedFeedback == null) return;
    setState(() => _isSubmitting = true);
    try {
      await ApiService().submitFeedback(
        widget.exercise.id,
        _selectedFeedback!,
        _noteController.text.trim(),
      );
      if (mounted) setState(() => _isSubmitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - 24;
    final thumbnailHeight = cardWidth * 9 / 16;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: thumbnailHeight,
              color: Colors.grey[900],
              child: exercise.exerciseUrl != null
                  ? Image.network(
                      exercise.exerciseUrl!,
                      width: double.infinity,
                      height: thumbnailHeight,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _noImage(thumbnailHeight),
                    )
                  : _noImage(thumbnailHeight),
            ),
          ),
          const SizedBox(height: 8),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              exercise.exerciseName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),

          // Dose row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _doseChip('Sets', '${exercise.sets}'),
                _doseChip('Reps', '${exercise.reps}'),
                if (exercise.holdTimeSec > 0)
                  _doseChip('Hold', '${exercise.holdTimeSec}s'),
                _doseChip('Rest', '${exercise.restTimeSec}s'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Mark Done button or feedback panel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _isDone ? _buildFeedbackPanel() : _buildMarkDoneButton(),
          ),

          const SizedBox(height: 8),
          Divider(color: Colors.grey[850], thickness: 1),
        ],
      ),
    );
  }

  Widget _noImage(double height) {
    return Container(
      height: height,
      color: Colors.grey[800],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  Widget _doseChip(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkDoneButton() {
    return OutlinedButton.icon(
      onPressed: () => setState(() => _isDone = true),
      icon: const Icon(Icons.check_circle_outline, size: 18),
      label: const Text('Mark as Done'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.greenAccent,
        side: const BorderSide(color: Colors.greenAccent),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildFeedbackPanel() {
    if (_isSubmitted) {
      return const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
          SizedBox(width: 6),
          Text(
            'Feedback recorded',
            style: TextStyle(color: Colors.greenAccent, fontSize: 13),
          ),
        ],
      );
    }

    final needsNote = _selectedFeedback != null && _selectedFeedback != 'normal';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How did it feel?',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // Feedback buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _feedbackBtn('normal', 'Normal', Colors.green),
              _feedbackBtn('hard', 'Hard', Colors.amber),
              _feedbackBtn('painful', 'Painful', Colors.orange),
              _feedbackBtn('increased_symptom', 'Symptoms Worsening', Colors.red),
            ],
          ),

          // Note field — only for Hard / Painful / Increased Symptom
          if (needsNote) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLength: 300,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Describe what you felt...',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                counterStyle: TextStyle(color: Colors.grey[600], fontSize: 11),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              ElevatedButton(
                onPressed: _selectedFeedback == null || _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 13),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => setState(() {
                  _isDone = false;
                  _selectedFeedback = null;
                  _noteController.clear();
                }),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feedbackBtn(String value, String label, Color color) {
    final selected = _selectedFeedback == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFeedback = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: selected ? color : Colors.grey[700]!,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Colors.grey[500],
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
