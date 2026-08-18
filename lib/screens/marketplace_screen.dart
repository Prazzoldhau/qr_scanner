import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final String title;
  // Pharmacy is a separate section on the backend (dedicated endpoint,
  // excluded from the regular Marketplace listing) rather than just another
  // category - this reuses the same screen/cart flow with the right API
  // calls instead of a separate implementation.
  final bool isPharmacy;

  const MarketplaceScreen({
    super.key,
    required this.patientData,
    this.title = 'Marketplace',
    this.isPharmacy = false,
  });

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  int? _selectedCategory;
  bool _loading = true;
  int _cartCount = 0;
  Map<int, int> _quantities = {}; // productId -> quantity in cart
  final _searchController = TextEditingController();

  Map<int, int> _quantitiesFromCart(Map<String, dynamic> cart) {
    // Sum across all lines for a product -- a product can have more than one
    // cart line when different variants of it were added separately.
    final items = List<Map<String, dynamic>>.from(cart['items'] ?? []);
    final result = <int, int>{};
    for (final item in items) {
      final pid = item['product_id'] as int;
      result[pid] = (result[pid] ?? 0) + (item['quantity'] as int);
    }
    return result;
  }

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
        widget.isPharmacy ? api.getPharmacyProducts() : api.getProducts(),
        widget.isPharmacy ? Future.value(<Map<String, dynamic>>[]) : api.getCategories(),
        api.getCart(),
      ]);
      setState(() {
        _products = results[0] as List<Map<String, dynamic>>;
        _categories = results[1] as List<Map<String, dynamic>>;
        final cart = results[2] as Map<String, dynamic>;
        _cartCount = cart['count'] ?? 0;
        _quantities = _quantitiesFromCart(cart);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadProducts() async {
    final prods = widget.isPharmacy
        ? await ApiService().getPharmacyProducts(search: _searchController.text.trim())
        : await ApiService().getProducts(
            categoryId: _selectedCategory,
            search: _searchController.text.trim(),
          );
    setState(() => _products = prods);
  }

  /// Add to Cart now lives on the product detail page (with description and
  /// variant picking), not the grid -- tapping a card just opens that page.
  Future<void> _openProductDetail(Map<String, dynamic> product) async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
    if (added == true) _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleSpacing: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.isPharmacy ? 'Search medicines...' : 'Search products...',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              isDense: true,
              prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[500], size: 18),
                      onPressed: () { _searchController.clear(); _loadProducts(); },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onSubmitted: (_) => _loadProducts(),
            onChanged: (v) { if (v.isEmpty) _loadProducts(); setState(() {}); },
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
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
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 8),
                // Category browse row - circular icons, Pharmacy has no
                // sub-categories to filter by
                if (!widget.isPharmacy)
                  SizedBox(
                    height: 66,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _categories.length + 1,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return _categoryCircle(id: null, iconData: Icons.apps, label: 'All');
                        }
                        final c = _categories[i - 1];
                        return _categoryCircle(
                          id: c['id'],
                          emoji: c['icon']?.toString(),
                          imageUrl: c['icon_url']?.toString(),
                          label: c['name']?.toString() ?? '',
                        );
                      },
                    ),
                  ),
                // Section header
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Products', style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.bold)),
                      Text('${_products.length} items', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                // Product grid
                Expanded(
                  child: _products.isEmpty
                      ? Center(child: Text('No products found', style: TextStyle(color: Colors.grey[600])))
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

  Widget _categoryCircle({required dynamic id, IconData? iconData, String? emoji, String? imageUrl, required String label}) {
    final selected = _selectedCategory == id;
    const size = 40.0;
    return GestureDetector(
      onTap: () { setState(() => _selectedCategory = id); _loadProducts(); },
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF0A6EBD) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: selected ? const Color(0xFF0A6EBD) : Colors.grey[300]!, width: selected ? 2 : 1),
                boxShadow: selected ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 150),
                        errorWidget: (_, __, ___) => _categoryFallbackIcon(iconData, emoji, selected),
                      ),
                    )
                  : Center(child: _categoryFallbackIcon(iconData, emoji, selected)),
            ),
            const SizedBox(height: 3),
            SizedBox(
              width: 56,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? const Color(0xFF0A6EBD) : Colors.grey[700],
                  fontSize: 9,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryFallbackIcon(IconData? iconData, String? emoji, bool selected) {
    return iconData != null
        ? Icon(iconData, color: selected ? Colors.white : Colors.grey[700], size: 16)
        : Text(emoji ?? '🏷️', style: const TextStyle(fontSize: 16));
  }

  Widget _productCard(Map<String, dynamic> p) {
    final id = p['id'] as int;
    final qty = _quantities[id] ?? 0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openProductDetail(p),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    color: Colors.white,
                    child: p['image_url'] != null
                        ? Image.network(p['image_url'], fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),
                  ),
                ),
                if (qty > 0)
                  Positioned(
                    right: 6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF0A6EBD), borderRadius: BorderRadius.circular(10)),
                      child: Text('×$qty', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['name'] ?? '',
                      style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w600, height: 1.25),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Smaller and tighter, like Daraz's cards -- price
                    // stays legible without needing to be physically big,
                    // the accent color already makes it the thing that
                    // stands out on the card.
                    Text('NPR ${p['price']}', style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(height: 110, color: Colors.grey[200],
      child: Icon(Icons.medical_services_outlined, color: Colors.grey[400], size: 36));
}
