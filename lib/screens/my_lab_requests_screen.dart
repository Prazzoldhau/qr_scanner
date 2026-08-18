// lib/screens/my_lab_requests_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MyLabRequestsScreen extends StatefulWidget {
  const MyLabRequestsScreen({super.key});

  @override
  State<MyLabRequestsScreen> createState() => _MyLabRequestsScreenState();
}

class _MyLabRequestsScreenState extends State<MyLabRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final requests = await ApiService().getLabRequests();
      setState(() {
        _requests = requests;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green[700]!;
      case 'sample_collected':
        return const Color(0xFF0A6EBD);
      case 'cancelled':
        return Colors.red[700]!;
      default: // pending
        return Colors.orange[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Lab Requests', style: TextStyle(color: Colors.black87, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(child: Text('No lab requests yet', style: TextStyle(color: Colors.grey[600])))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _requests.length,
                    itemBuilder: (_, i) => _requestCard(_requests[i]),
                  ),
                ),
    );
  }

  Widget _requestCard(Map<String, dynamic> r) {
    final tests = List<String>.from(r['tests'] ?? []);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(r['request_number'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _statusColor(r['status'] ?? '').withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  r['status_display'] ?? '',
                  style: TextStyle(color: _statusColor(r['status'] ?? ''), fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(tests.join(', '), style: TextStyle(color: Colors.grey[700], fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(r['created_at'] ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              Text('NPR ${r['total']}', style: TextStyle(color: Colors.green[700], fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
