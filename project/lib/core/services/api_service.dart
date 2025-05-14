import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  static ApiService get instance => _instance;

  final String baseUrl = ApiConfig.baseUrl;
  final Map<String, String> _headers = {'Content-Type': 'application/json'};

  ApiService._internal();

  // Get stored token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Store token
  void setToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  // Clear token
  void clearToken() {
    _headers.remove('Authorization');
  }

  // Generic GET request
  Future<dynamic> get(String endpoint,
      {required Map<String, double> queryParameters}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to make GET request: ${e.toString()}');
    }
  }

  // Generic POST request
  Future<dynamic> post(String endpoint, Map<String, String> map,
      {Map<String, dynamic>? body, required Map<String, Object> data}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to make POST request: ${e.toString()}');
    }
  }

  // Generic PUT request
  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to make PUT request: ${e.toString()}');
    }
  }

  // Generic DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to make DELETE request: ${e.toString()}');
    }
  }

  // Handle API response
  dynamic _handleResponse(http.Response response) {
    print('API Response: ${response.statusCode} - ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    String message;
    dynamic data;

    try {
      final errorBody = jsonDecode(response.body);
      message = errorBody['message'] ?? 'Unknown error occurred';
      data = errorBody;
    } catch (e) {
      message = response.body.isNotEmpty
          ? response.body
          : 'HTTP Error ${response.statusCode}';
    }

    throw ApiException(message, statusCode: response.statusCode, data: data);
  }
}
