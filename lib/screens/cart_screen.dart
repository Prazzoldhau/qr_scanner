import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CartScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;
  const CartScreen({super.key, required this.patientData});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> _items = [];
  String _total = '0';
  bool _loading = true;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _loading = true);
    try {
      final cart = await ApiService().getCart();
      setState(() {
        _items = List<Map<String, dynamic>>.from(cart['items'] ?? []);
        _total = cart['total'] ?? '0';
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateQty(int productId, int qty) async {
    await ApiService().updateCart(productId, qty);
    _loadCart();
  }

  Future<void> _checkout() async {
    final addressController = TextEditingController();
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delivery Details', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: addressController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Delivery address *',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true, fillColor: Colors.grey[800],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notesController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Notes (optional)',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true, fillColor: Colors.grey[800],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (addressController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A6EBD)),
            child: const Text('Place Order', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _placing = true);
    try {
      final result = await ApiService().placeOrder(
        address: addressController.text.trim(),
        note: notesController.text.trim(),
      );
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Row(children: [Icon(Icons.check_circle, color: Colors.greenAccent), SizedBox(width: 8), Text('Order Placed!', style: TextStyle(color: Colors.white))]),
            content: Text('Order #${result['order_number']}\nTotal: NPR ${result['total']}',
                style: const TextStyle(color: Colors.white70)),
            actions: [
              ElevatedButton(
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A6EBD)),
                child: const Text('Done', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('My Cart', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('Your cart is empty', style: TextStyle(color: Colors.grey)))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        itemBuilder: (_, i) => _cartItem(_items[i]),
                      ),
                    ),
                    // Total + checkout
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey[900], border: Border(top: BorderSide(color: Colors.grey[800]!))),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                Text('NPR $_total', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _placing ? null : _checkout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A6EBD),
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _placing
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Place Order', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _cartItem(Map<String, dynamic> item) {
    final qty = item['quantity'] as int;
    final pid = item['product_id'] as int;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item['image_url'] != null && (item['image_url'] as String).isNotEmpty
                ? Image.network(item['image_url'], width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imgPlaceholder())
                : _imgPlaceholder(),
          ),
          const SizedBox(width: 12),
          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('NPR ${item['item_total']}', style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
              ],
            ),
          ),
          // Qty controls
          Row(
            children: [
              _qtyBtn(Icons.remove, () => _updateQty(pid, qty - 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('$qty', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              _qtyBtn(Icons.add, () => _updateQty(pid, qty + 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(width: 60, height: 60, color: Colors.grey[800],
      child: const Icon(Icons.medical_services_outlined, color: Colors.grey, size: 24));
}
