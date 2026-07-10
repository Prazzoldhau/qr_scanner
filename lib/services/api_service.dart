// lib/services/api_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio();
  late PersistCookieJar _cookieJar;
  bool _initialized = false;
  static const String baseUrl = 'https://sajhya.com/patient-app';

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final appDocDir = await getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(
      storage: FileStorage('${appDocDir.path}/.cookies/'),
    );
    _dio.interceptors.add(CookieManager(_cookieJar));

    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.responseType = ResponseType.plain;
  }

  Future<void> _ensureCsrfToken() async {
    await _dio.get('/api/csrf/');
  }

  Future<String> _getCsrfToken() async {
    final cookies = await _cookieJar.loadForRequest(Uri.parse(baseUrl));
    final csrf = cookies.firstWhere(
      (c) => c.name == 'csrftoken',
      orElse: () => Cookie('csrftoken', ''),
    );
    return csrf.value;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      await _ensureCsrfToken();
      final csrf = await _getCsrfToken();

      final response = await _dio.post(
        '/api/login/',
        data: {'username': username, 'password': password},
        options: Options(headers: {'X-CSRFToken': csrf}),
      );

      final rawBody = response.data as String;
      dynamic parsed;
      try {
        parsed = jsonDecode(rawBody);
      } catch (_) {
        throw Exception(
          'Server returned an HTML page.\n'
          'This might be a bot protection block.\n'
          'Please try again later or contact support.',
        );
      }

      if (parsed is Map<String, dynamic>) {
        return parsed;
      } else {
        throw Exception('Unexpected response format: ${parsed.runtimeType}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Login failed (${e.response?.statusCode})');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/api/me/');
      final rawBody = response.data as String;
      return jsonDecode(rawBody) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Not logged in');
    }
  }
  Future<String> debugCookies() async {
    final cookies = await _cookieJar.loadForRequest(Uri.parse(baseUrl));
    if (cookies.isEmpty) return 'NO COOKIES FOUND';
    return cookies.map((c) => '${c.name}=${c.value}').join(', ');
  }

  Future<Map<String, dynamic>> qrLogin(String qrToken) async {
    try {
      final response = await _dio.post(
        '/api/qr-login/',
        data: {'qr_token': qrToken},
      );
      final rawBody = response.data as String;
      dynamic parsed;
      try {
        parsed = jsonDecode(rawBody);
      } catch (_) {
        throw Exception('Unexpected response from server');
      }
      if (parsed is Map<String, dynamic>) return parsed;
      throw Exception('Unexpected response format');
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('QR login failed (${e.response?.statusCode})');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<void> submitFeedback(int exerciseId, String feedbackType, String note) async {
    try {
      final response = await _dio.post(
        '/api/exercise/$exerciseId/feedback/',
        data: {'feedback_type': feedbackType, 'note': note},
      );
      final rawBody = response.data as String;
      final parsed = jsonDecode(rawBody) as Map<String, dynamic>;
      if (parsed['success'] != true) {
        throw Exception(parsed['error'] ?? 'Failed to submit feedback');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Feedback failed (${e.response?.statusCode})');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<void> logout() async {
    try {
      final csrf = await _getCsrfToken();
      await _dio.post(
        '/api/logout/',
        options: Options(headers: {'X-CSRFToken': csrf}),
      );
    } catch (_) {
    } finally {
      await _cookieJar.deleteAll();
    }
  }

  // ── Marketplace ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getCategories() async {
    final r = await _dio.get('/api/categories/');
    final d = jsonDecode(r.data as String);
    return List<Map<String, dynamic>>.from(d['categories']);
  }

  Future<List<Map<String, dynamic>>> getProducts({int? categoryId, String? search}) async {
    final params = <String, dynamic>{};
    if (categoryId != null) params['category'] = categoryId;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final r = await _dio.get('/api/products/', queryParameters: params);
    final d = jsonDecode(r.data as String);
    return List<Map<String, dynamic>>.from(d['products']);
  }

  Future<Map<String, dynamic>> getCart() async {
    final r = await _dio.get('/api/cart/');
    return jsonDecode(r.data as String) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addToCart(int productId) async {
    final csrf = await _getCsrfToken();
    final r = await _dio.post(
      '/api/cart/add/$productId/',
      options: Options(headers: {'X-CSRFToken': csrf}),
    );
    return jsonDecode(r.data as String) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCart(int productId, int quantity) async {
    final csrf = await _getCsrfToken();
    final r = await _dio.post(
      '/api/cart/update/',
      data: {'product_id': productId, 'quantity': quantity},
      options: Options(headers: {'X-CSRFToken': csrf}),
    );
    return jsonDecode(r.data as String) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> placeOrder({required String address, String note = ''}) async {
    final csrf = await _getCsrfToken();
    final r = await _dio.post(
      '/api/order/',
      data: {'delivery_address': address, 'notes': note},
      options: Options(headers: {'X-CSRFToken': csrf}),
    );
    return jsonDecode(r.data as String) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    final r = await _dio.get('/api/orders/');
    final d = jsonDecode(r.data as String);
    return List<Map<String, dynamic>>.from(d['orders']);
  }

  Future<Map<String, dynamic>?> getPhysio() async {
    final r = await _dio.get('/api/physio/');
    final d = jsonDecode(r.data as String) as Map<String, dynamic>;
    return d['physio'] as Map<String, dynamic>?;
  }
}