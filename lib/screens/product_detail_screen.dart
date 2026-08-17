// lib/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final List<Map<String, dynamic>> _variants;
  Map<String, dynamic>? _selectedVariant;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _variants = List<Map<String, dynamic>>.from(widget.product['variants'] as List? ?? const []);
    if (_variants.isNotEmpty) {
      _selectedVariant = _variants.firstWhere(
        (v) => v['in_stock'] == true,
        orElse: () => _variants.first,
      );
    }
  }

  Future<void> _addToCart() async {
    if (_variants.isNotEmpty && _selectedVariant == null) return;
    setState(() => _adding = true);
    try {
      await ApiService().addToCart(
        widget.product['id'] as int,
        variantId: _selectedVariant?['id'] as int?,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Added to cart'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final imageUrl = (_selectedVariant?['image_url'] ?? p['image_url'])?.toString();
    final price = _selectedVariant?['price'] ?? p['price'];
    final description = (p['description'] ?? '').toString().trim();
    final canAdd = _variants.isEmpty || (_selectedVariant?['in_stock'] == true);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(p['name']?.toString() ?? 'Product', style: const TextStyle(color: Colors.black87, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 260,
                    width: double.infinity,
                    color: Colors.white,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(imageUrl, fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['name']?.toString() ?? '',
                          style: const TextStyle(color: Colors.black87, fontSize: 19, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'NPR $price',
                          style: TextStyle(color: Colors.green[700], fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        if (_variants.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text('Options', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final v in _variants) _variantChip(v),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text('Description', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(
                          description.isNotEmpty ? description : 'No description available.',
                          style: TextStyle(
                            color: description.isNotEmpty ? Colors.black87 : Colors.grey[500],
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_adding || !canAdd) ? null : _addToCart,
                  icon: _adding
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add_shopping_cart, size: 18),
                  label: Text(canAdd ? 'Add to Cart' : 'Out of stock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A6EBD),
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _variantChip(Map<String, dynamic> v) {
    final selected = _selectedVariant != null && _selectedVariant!['id'] == v['id'];
    final inStock = v['in_stock'] == true;
    return GestureDetector(
      onTap: inStock ? () => setState(() => _selectedVariant = v) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0A6EBD) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF0A6EBD) : Colors.grey[300]!),
        ),
        child: Text(
          v['label']?.toString() ?? '',
          style: TextStyle(
            color: inStock ? (selected ? Colors.white : Colors.grey[700]) : Colors.grey[400],
            fontSize: 13,
            fontWeight: FontWeight.w500,
            decoration: inStock ? TextDecoration.none : TextDecoration.lineThrough,
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Center(child: Icon(Icons.medical_services_outlined, color: Colors.grey[400], size: 48));
}
