// lib/screens/dashboard_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/custom_card.dart';
import 'activation_scanner_screen.dart';
import 'login_screen.dart';
import 'marketplace_screen.dart';
import 'physio_contact_screen.dart';

// --- Models ---
class StepImage {
  final int order;
  final String imageUrl;
  final String? label;

  StepImage({required this.order, required this.imageUrl, this.label});

  factory StepImage.fromJson(Map<String, dynamic> json) {
    return StepImage(
      order: json['order'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      label: json['label'],
    );
  }
}

class Exercise {
  final int id;
  final String exerciseName;
  final String? exerciseUrl;
  final int sets;
  final int reps;
  final int holdTimeSec;
  final int restTimeSec;
  final bool scheduleMorning;
  final bool scheduleDay;
  final bool scheduleEvening;
  final bool isCompleted;
  final List<StepImage> stepImages;
  final String description;
  final String descriptionNepali;

  Exercise({
    required this.id,
    required this.exerciseName,
    this.exerciseUrl,
    required this.sets,
    required this.reps,
    required this.holdTimeSec,
    required this.restTimeSec,
    required this.scheduleMorning,
    required this.scheduleDay,
    required this.scheduleEvening,
    required this.isCompleted,
    required this.stepImages,
    required this.description,
    required this.descriptionNepali,
  });

  // Nepali is the patient-facing language when set; English is the fallback.
  String get displayDescription => descriptionNepali.trim().isNotEmpty ? descriptionNepali : description;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? 0,
      exerciseName: json['exercise_name'] ?? 'Unnamed exercise',
      exerciseUrl: json['exercise_url'],
      sets: json['sets'] ?? 3,
      reps: json['reps'] ?? 10,
      holdTimeSec: json['hold_time_sec'] ?? 0,
      restTimeSec: json['rest_time_sec'] ?? 60,
      scheduleMorning: json['schedule_morning'] ?? true,
      scheduleDay: json['schedule_day'] ?? false,
      scheduleEvening: json['schedule_evening'] ?? false,
      isCompleted: json['is_completed'] ?? false,
      stepImages: ((json['step_images'] as List<dynamic>? ?? [])
              .map((e) => StepImage.fromJson(e))
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order))),
      description: json['description'] ?? '',
      descriptionNepali: json['description_nepali'] ?? '',
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
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = widget.patientData['activation_active'] == true;
  }

  void _onActivated(Map<String, dynamic> result) {
    setState(() => _isActive = result['activation_active'] == true);
  }

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
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: !_isActive
            ? _ActivationGate(onActivated: _onActivated)
            : SafeArea(
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
                    Expanded(
                      child: _quickAction(
                        icon: Icons.local_pharmacy_outlined,
                        label: 'Pharmacy',
                        color: const Color(0xFF16A085),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MarketplaceScreen(
                              patientData: widget.patientData,
                              title: 'Pharmacy',
                              isPharmacy: true,
                            ),
                          ),
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

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Log out?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You will need to sign in again to view your exercises.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ApiService().logout();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Widget _quickAction({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
// ACTIVATION GATE – shown instead of the dashboard when the patient's
// access has expired; redeems a recharge-card-style code (scanned or typed).
// ---------------------------------------------------------------------------
class _ActivationGate extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onActivated;
  const _ActivationGate({required this.onActivated});

  @override
  State<_ActivationGate> createState() => _ActivationGateState();
}

class _ActivationGateState extends State<_ActivationGate> {
  final _codeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _submitCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await ApiService().activate(trimmed);
      if (result['success'] == true) {
        widget.onActivated(result);
      } else {
        _showError(result['error']?.toString() ?? 'Activation failed');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _scanCode() async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ActivationScannerScreen()),
    );
    if (scanned != null) {
      _codeController.text = scanned;
      _submitCode(scanned);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: Colors.greenAccent, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Activation Required',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your access has expired. Scan or enter an activation code to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _scanCode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Activation Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[800])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or', style: TextStyle(color: Colors.grey[600])),
                ),
                Expanded(child: Divider(color: Colors.grey[800])),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              enabled: !_isSubmitting,
              style: const TextStyle(color: Colors.white, letterSpacing: 1.5),
              decoration: InputDecoration(
                hintText: 'A3F7-K9P2-XQ4M',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              onSubmitted: _submitCode,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () => _submitCode(_codeController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A6EBD),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Activate', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EXERCISE FEED ITEM – stateful for done/feedback state
// ---------------------------------------------------------------------------
class _ExerciseFeedItem extends StatefulWidget {
  final Exercise exercise;
  const _ExerciseFeedItem({super.key, required this.exercise});

  @override
  State<_ExerciseFeedItem> createState() => _ExerciseFeedItemState();
}

class _ExerciseFeedItemState extends State<_ExerciseFeedItem> {
  bool _isDone = false;
  String? _selectedFeedback; // 'normal' | 'hard' | 'painful' | 'increased_symptom'
  bool _isSubmitted = false;
  bool _isSubmitting = false;
  bool _isQuickSubmitting = false;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.exercise.isCompleted) {
      _isDone = true;
      _isSubmitted = true;
      _selectedFeedback = 'normal';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Quick tick: mark done instantly with default 'normal' feedback,
  // skipping the "how did it feel" panel entirely.
  Future<void> _quickMarkDone() async {
    setState(() => _isQuickSubmitting = true);
    try {
      await ApiService().submitFeedback(widget.exercise.id, 'normal', '');
      if (mounted) {
        setState(() {
          _isDone = true;
          _selectedFeedback = 'normal';
          _isSubmitted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isQuickSubmitting = false);
    }
  }

  void _showDescription() {
    final description = widget.exercise.displayDescription.trim();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.exercise.exerciseName,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  description.isNotEmpty ? description : 'No instructions added for this exercise yet.',
                  style: TextStyle(
                    color: description.isNotEmpty ? Colors.white70 : Colors.grey[600],
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
          // Thumbnail, or step-by-step slideshow if the physio attached one
          if (exercise.stepImages.isNotEmpty)
            _ExerciseImageCarousel(images: exercise.stepImages, height: thumbnailHeight)
          else
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
          const SizedBox(height: 10),

          // Prescribed schedule (as set by the physio) - shown here instead
          // of grouping the whole feed into separate Morning/Day/Evening lists.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _scheduleBadges(exercise),
          ),
          const SizedBox(height: 12),

          // Mark Done button or feedback panel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _isDone ? _buildFeedbackPanel() : _buildActionRow(),
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

  Widget _scheduleBadges(Exercise exercise) {
    final badges = <Widget>[
      if (exercise.scheduleMorning) _scheduleBadge('☀️', 'Morning'),
      if (exercise.scheduleDay) _scheduleBadge('🌤️', 'Day'),
      if (exercise.scheduleEvening) _scheduleBadge('🌙', 'Evening'),
    ];
    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 4, children: badges);
  }

  Widget _scheduleBadge(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$emoji $label',
        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isQuickSubmitting ? null : () => setState(() => _isDone = true),
            icon: const Icon(Icons.comment_outlined, size: 18),
            label: const Text('Comment'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.greenAccent,
              side: const BorderSide(color: Colors.greenAccent),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _showDescription,
          tooltip: 'Steps',
          icon: const Icon(Icons.list_alt, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: Colors.blueAccent.withOpacity(0.15),
            foregroundColor: Colors.blueAccent,
            shape: const CircleBorder(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _isQuickSubmitting ? null : _quickMarkDone,
          tooltip: 'Quick done (skip feedback)',
          icon: _isQuickSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent),
                )
              : const Icon(Icons.check, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: Colors.greenAccent.withOpacity(0.15),
            foregroundColor: Colors.greenAccent,
            shape: const CircleBorder(),
          ),
        ),
      ],
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

// ---------------------------------------------------------------------------
// EXERCISE STEP IMAGE CAROUSEL – slideshow of a physio's step-by-step photos
// ---------------------------------------------------------------------------
class _ExerciseImageCarousel extends StatefulWidget {
  final List<StepImage> images;
  final double height;

  const _ExerciseImageCarousel({required this.images, required this.height});

  @override
  State<_ExerciseImageCarousel> createState() => _ExerciseImageCarouselState();
}

class _ExerciseImageCarouselState extends State<_ExerciseImageCarousel> {
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  bool _isPlaying = false;
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preload every step image up front so switching between them (via
    // swipe, buttons, or auto-play) always finds the image already
    // decoded and in cache. Without this, Image.network still has to
    // fetch over the network on first display, so by the time it's
    // actually ready to paint the fade-in animation has already finished
    // and the image just pops in instead of fading.
    if (!_precached) {
      _precached = true;
      for (final img in widget.images) {
        precacheImage(NetworkImage(img.imageUrl), context);
      }
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    if (_isPlaying) setState(() => _isPlaying = false);
  }

  void _togglePlay() {
    if (_isPlaying) {
      _stopAutoPlay();
      return;
    }
    setState(() {
      _isPlaying = true;
      // Restart from the beginning if Play is pressed while already on
      // the last frame, so there's something to actually play through.
      if (_currentPage >= widget.images.length - 1) _currentPage = 0;
    });
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      // Play through once and stop on the last frame instead of looping.
      if (_currentPage >= widget.images.length - 1) {
        _stopAutoPlay();
        return;
      }
      _advance(1);
    });
  }

  void _advance(int delta) {
    setState(() {
      _currentPage = (_currentPage + delta + widget.images.length) % widget.images.length;
    });
  }

  void _onManualNavigate(int delta) {
    _stopAutoPlay();
    _advance(delta);
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final current = images[_currentPage];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: double.infinity,
            height: widget.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Colors.grey[900]),
                GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity < -200) {
                      _onManualNavigate(1); // swiped left -> next
                    } else if (velocity > 200) {
                      _onManualNavigate(-1); // swiped right -> previous
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: Image.network(
                      current.imageUrl,
                      key: ValueKey(_currentPage),
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 6,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _carouselButton(Icons.chevron_left, () => _onManualNavigate(-1)),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _carouselButton(Icons.chevron_right, () => _onManualNavigate(1)),
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: _carouselButton(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    _togglePlay,
                    small: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Dot indicator + step label
        Row(
          children: [
            ...List.generate(images.length, (i) {
              final isActive = i == _currentPage;
              return Container(
                margin: const EdgeInsets.only(right: 4),
                width: isActive ? 8 : 6,
                height: isActive ? 8 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.greenAccent : Colors.grey[700],
                ),
              );
            }),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Step ${_currentPage + 1} of ${images.length}'
                '${(current.label != null && current.label!.trim().isNotEmpty) ? ' — ${current.label}' : ''}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _carouselButton(IconData icon, VoidCallback onTap, {bool small = false}) {
    final size = small ? 30.0 : 36.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: small ? 18 : 22),
      ),
    );
  }
}
