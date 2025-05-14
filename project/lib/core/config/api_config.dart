class ApiConfig {
  // Use your actual server IP address instead of localhost
  // For emulator, use 10.0.2.2 to access host machine's localhost
  // For physical device, use your computer's IP address on the same network
  static const String baseUrl = 'http://10.0.2.2:3000';

  // Route API endpoints
  static const String routeEndpoint = '/api/route';
  static const String locationEndpoint = '/api/location';

  // Ride API endpoints
  static const String ridesEndpoint = '/api/rides';
  static const String driversEndpoint = '/api/drivers';

  // Authentication endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';

  // User profile endpoints
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/update-profile';
  static const String uploadProfileImage = '/users/upload-image';

  // Driver specific endpoints
  static const String driverProfile = '/drivers/profile';
  static const String updateDriverProfile = '/drivers/update-profile';
  static const String uploadDriverDocuments = '/drivers/upload-documents';

  // Rider specific endpoints
  static const String riderProfile = '/riders/profile';
  static const String updateRiderProfile = '/riders/update-profile';

  // Common headers
  static Map<String, String> getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
