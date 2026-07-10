import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'cart_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;
  const MarketplaceScreen({super.key, required this.patientData});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  int? _selectedCategory;
  bool _loading = true;
  int _cartCount = 0;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final api = ApiService();
      final results = await Future.wait([
        api.getCategories(),
        api.getProducts(categoryId: _selectedCategory),
        api.getCart(),
      ]);
      setState(() {
        _categories = results[0] as List<Map<String, dynamic>>;
        _products = results[1] as List<Map<String, dynamic>>;
        final cart = results[2] as Map<String, dynamic>;
        _cartCount = cart['count'] ?? 0;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadProducts() async {
    final prods = await ApiService().getProducts(
      categoryId: _selectedCategory,
      search: _searchController.text.trim(),
    );
    setState(() => _products = prods);
  }

  Future<void> _addToCart(int productId) async {
    try {
      final result = await ApiService().addToCart(productId);
      setState(() => _cartCount = result['cart_count'] ?? _cartCount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Added to cart'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Marketplace', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CartScreen(patientData: widget.patientData),
                  ));
                  _loadAll();
                },
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$_cartCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[900],
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () { _searchController.clear(); _loadProducts(); },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: (_) => _loadProducts(),
                    onChanged: (v) { if (v.isEmpty) _loadProducts(); setState(() {}); },
                  ),
                ),
                // Category chips
                SizedBox(
                  height: 42,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _categories.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) return _catChip(null, 'All');
                      final c = _categories[i - 1];
                      return _catChip(c['id'], '${c['icon']}  ${c['name']}');
                    },
                  ),
                ),
                // Product grid
                Expanded(
                  child: _products.isEmpty
                      ? const Center(child: Text('No products found', style: TextStyle(color: Colors.grey)))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (_, i) => _productCard(_products[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _catChip(dynamic id, String label) {
    final selected = _selectedCategory == id;
    return GestureDetector(
      onTap: () { setState(() => _selectedCategory = id); _loadProducts(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0A6EBD) : Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF0A6EBD) : Colors.grey[700]!),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey[400], fontSize: 12)),
        ),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> p) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: p['image_url'] != null
                ? Image.network(p['image_url'], height: 110, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Text('NPR ${p['price']}', style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _addToCart(p['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A6EBD),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('+ Cart', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(height: 110, color: Colors.grey[800],
      child: const Icon(Icons.medical_services_outlined, color: Colors.grey, size: 36));
}
