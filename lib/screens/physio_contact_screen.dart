import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PhysioContactScreen extends StatefulWidget {
  const PhysioContactScreen({super.key});

  @override
  State<PhysioContactScreen> createState() => _PhysioContactScreenState();
}

class _PhysioContactScreenState extends State<PhysioContactScreen> {
  Map<String, dynamic>? _physio;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final physio = await ApiService().getPhysio();
      setState(() { _physio = physio; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('My Physio', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _physio == null
              ? const Center(child: Text('No physio assigned yet', style: TextStyle(color: Colors.grey)))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Avatar
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
                        child: Text(
                          (_physio!['name'] as String? ?? 'P')[0].toUpperCase(),
                          style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _physio!['name'] ?? 'Your Physio',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Physiotherapist',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      // Info card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            if ((_physio!['email'] as String? ?? '').isNotEmpty)
                              _infoRow(Icons.email_outlined, 'Email', _physio!['email']),
                            _infoRow(Icons.badge_outlined, 'Username', _physio!['username']),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF6C63FF), size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Contact your physio directly at your clinic for appointments and queries.',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
