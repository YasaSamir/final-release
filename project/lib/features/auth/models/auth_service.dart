import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/config/api_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;

  final _apiService = ApiService.instance;
  final _socketService = SocketService.instance;

  AuthService._internal();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiConfig.login,
        ApiConfig.getHeaders(),
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response['token'] != null) {
        await _handleSuccessfulAuth(response);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String role,
    String? vehicleModel,
    String? licensePlate,
  }) async {
    try {
      final Map<String, Object> userData = {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'role': role,
        if (role == 'driver') ...{
          'vehicleModel': vehicleModel ?? '',
          'licensePlate': licensePlate ?? '',
        },
      };

      final response = await _apiService.post(
        ApiConfig.register,
        ApiConfig.getHeaders(),
        data: userData,
      );

      if (response['token'] != null) {
        await _handleSuccessfulAuth(response);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.post(
        ApiConfig.logout,
        ApiConfig.getHeaders(),
        data: {},
      );
    } finally {
      await _handleLogout();
    }
  }

  Future<void> _handleSuccessfulAuth(Map<String, dynamic> response) async {
    final token = response['token'];
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      _apiService.setToken(token);
      _socketService.connect();
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _apiService.clearToken();
    _socketService.disconnect();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final response = await _apiService.post(
      ApiConfig.verifyOtp,
      ApiConfig.getHeaders(),
      data: {
        'email': email,
        'otp': otp,
      },
    );

    if (response['token'] != null) {
      await _handleSuccessfulAuth(response);
    }

    return response;
  }

  Future<Map<String, dynamic>> resendOtp(String email) async {
    final response = await _apiService.post(
      ApiConfig.resendOtp,
      ApiConfig.getHeaders(),
      data: {
        'email': email,
      },
    );

    return response;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _apiService.post(
      ApiConfig.forgotPassword,
      ApiConfig.getHeaders(),
      data: {
        'email': email,
      },
    );

    return response;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await _apiService.post(
      ApiConfig.resetPassword,
      ApiConfig.getHeaders(),
      data: {
        'token': token,
        'newPassword': newPassword,
      },
    );

    return response;
  }

  Future<String?> getCurrentUserRole() async {
    try {
      final response = await _apiService.get(
        ApiConfig.userProfile,
        queryParameters: {},
      );
      return response['role'];
    } catch (e) {
      return null;
    }
  }
}
