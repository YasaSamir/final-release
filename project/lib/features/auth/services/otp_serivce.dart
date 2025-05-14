import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class OtpService {
  final _authService = AuthService.instance;

  Future<Map<String, dynamic>> generateOTP(String email) async {
    return await _authService.resendOtp(email);
  }

  Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    return await _authService.verifyOtp(email, otp);
  }
}
