import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'physio_pairing_scanner_screen.dart';

class PhysioContactScreen extends StatefulWidget {
  const PhysioContactScreen({super.key});

  @override
  State<PhysioContactScreen> createState() => _PhysioContactScreenState();
}

class _PhysioContactScreenState extends State<PhysioContactScreen> {
  Map<String, dynamic>? _physio;
  bool _loading = true;
  bool _pairing = false;

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

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.redAccent : Colors.green),
    );
  }

  Future<void> _scanAndPair() async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const PhysioPairingScannerScreen()),
    );
    if (scanned == null || scanned.trim().isEmpty) return;

    setState(() => _pairing = true);
    try {
      final result = await ApiService().pairWithPhysio(scanned.trim());
      if (result['success'] == true) {
        _showMessage('Connected to ${result['physio_name'] ?? 'your physio'}!');
        await _load();
      } else {
        _showMessage(result['error']?.toString() ?? 'Pairing failed', isError: true);
      }
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _pairing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Physio', style: TextStyle(color: Colors.black87)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _physio == null
              ? _noPhysioView()
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Avatar
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: const Color(0xFF6C63FF).withOpacity(0.14),
                        child: Text(
                          (_physio!['name'] as String? ?? 'P')[0].toUpperCase(),
                          style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _physio!['name'] ?? 'Your Physio',
                        style: const TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
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
                          color: const Color(0xFF6C63FF).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.25)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF6C63FF), size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Contact your physio directly at your clinic for appointments and queries.',
                                style: TextStyle(color: Colors.black87, fontSize: 13),
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

  Widget _noPhysioView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_outlined, color: Colors.grey[400], size: 56),
            const SizedBox(height: 16),
            const Text(
              'No physio assigned yet',
              style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan your physio\'s pairing QR code to connect with them.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _pairing ? null : _scanAndPair,
              icon: _pairing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.qr_code_scanner),
              label: Text(_pairing ? 'Connecting...' : 'Scan Physio QR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
          Icon(icon, color: Colors.grey[500], size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
