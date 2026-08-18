// lib/screens/lab_service_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'my_lab_requests_screen.dart';

class LabServiceScreen extends StatefulWidget {
  const LabServiceScreen({super.key});

  @override
  State<LabServiceScreen> createState() => _LabServiceScreenState();
}

class _LabServiceScreenState extends State<LabServiceScreen> {
  List<Map<String, dynamic>> _tests = [];
  final Set<int> _selectedIds = {};
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    setState(() => _loading = true);
    try {
      final tests = await ApiService().getLabTests();
      setState(() {
        _tests = tests;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // Preserves the order tests arrive in from the API (grouped by category,
  // then name -- see LabTest.Meta.ordering on the backend) rather than
  // re-sorting client-side.
  Map<String, List<Map<String, dynamic>>> get _grouped {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final t in _tests) {
      final category = t['category_display']?.toString() ?? 'Other';
      map.putIfAbsent(category, () => []).add(t);
    }
    return map;
  }

  double get _total {
    double sum = 0;
    for (final t in _tests) {
      if (_selectedIds.contains(t['id'])) {
        sum += double.tryParse(t['price']?.toString() ?? '0') ?? 0;
      }
    }
    return sum;
  }

  Future<void> _submit() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final result = await ApiService().submitLabRequest(_selectedIds.toList());
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            title: Row(children: [
              Icon(Icons.check_circle, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text('Request Sent', style: TextStyle(color: Colors.black87)),
            ]),
            content: Text(
              'Request #${result['request_number']}\nTotal: NPR ${result['total']}\n\n'
              'The clinic will contact you, or you can visit the lab directly.',
              style: const TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // dialog
                  Navigator.pop(context); // this screen
                },
                child: Text('Done', style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // dialog
                  Navigator.pop(context); // this screen
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MyLabRequestsScreen()));
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A6EBD)),
                child: const Text('View My Requests', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Blood Investigation', style: TextStyle(color: Colors.black87, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'My Requests',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyLabRequestsScreen())),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tests.isEmpty
              ? Center(child: Text('No tests available right now', style: TextStyle(color: Colors.grey[600])))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 12),
                        children: [
                          for (final entry in _grouped.entries) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                              child: Text(
                                entry.key,
                                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                              ),
                            ),
                            for (final t in entry.value) _testTile(t),
                          ],
                        ],
                      ),
                    ),
                    _footer(),
                  ],
                ),
    );
  }

  Widget _testTile(Map<String, dynamic> t) {
    final id = t['id'] as int;
    final selected = _selectedIds.contains(id);
    final prep = (t['prep_instructions'] as String?) ?? '';
    final turnaround = (t['turnaround_time'] as String?) ?? '';
    final subtitleParts = [if (prep.isNotEmpty) prep, if (turnaround.isNotEmpty) 'Result: $turnaround'];

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => setState(() => selected ? _selectedIds.remove(id) : _selectedIds.add(id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                activeColor: const Color(0xFF0A6EBD),
                onChanged: (_) => setState(() => selected ? _selectedIds.remove(id) : _selectedIds.add(id)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['name'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
                    if (subtitleParts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitleParts.join(' · '), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('NPR ${t['price']}', style: TextStyle(color: Colors.green[700], fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    final count = _selectedIds.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count test${count == 1 ? '' : 's'} selected', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text('NPR ${_total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: (count == 0 || _submitting) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A6EBD),
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              // The app-wide theme defaults every ElevatedButton to
              // minimumSize: Size(double.infinity, 56) (see AppTheme). Left
              // unset here, that swallows this whole Row and squeezes the
              // total text next to it down to ~0 width. See cart_screen.dart
              // for the same fix.
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: _submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Request Tests', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
