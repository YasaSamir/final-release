import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class EmailService {
  final _authService = AuthService.instance;

  Future<void> sendEmail({
    required BuildContext context,
    required String email,
  }) async {
    try {
      await _authService.forgotPassword(email);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent successfully')),
      );
    } catch (error) {
      // Handle errors gracefully
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
