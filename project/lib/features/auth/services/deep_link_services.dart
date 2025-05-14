// import 'package:flutter/material.dart';
// import 'package:project/features/auth/models/auth_service.dart';
// import 'package:project/routes/app_router.dart';
//
// class ConfirmEmailScreen extends StatefulWidget {
//   const ConfirmEmailScreen({super.key});
//
//   @override
//   _ConfirmEmailScreenState createState() => _ConfirmEmailScreenState();
// }
//
// class _ConfirmEmailScreenState extends State<ConfirmEmailScreen> {
//   bool _isConfirming = false;
//   final _authService = AuthService.instance;
//
//   @override
//   void initState() {
//     super.initState();
//     _handleDeepLink();
//   }
//
//   Future<void> _handleDeepLink() async {
//     // TODO: Implement deep link handling
//     // This will depend on your deep linking implementation
//   }
//
//   Future<void> _processLink(String link) async {
//     setState(() => _isConfirming = true);
//
//     try {
//       final uri = Uri.parse(link);
//       final token = uri.queryParameters['token'];
//       final email = uri.queryParameters['email'];
//
//       if (token == null || email == null) {
//         throw Exception('Invalid confirmation link');
//       }
//
//       // Verify the token
//       final response = await _authService.verifyOtp(email, token);
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Email confirmed! Profile created.')),
//         );
//
//         // Get user role and navigate accordingly
//         final role = await _authService.getCurrentUserRole();
//         if (role == 'driver') {
//           Navigator.pushReplacementNamed(context, AppRoutes.driverHomeScreen);
//         } else {
//           Navigator.pushReplacementNamed(context, AppRoutes.riderHomeScreen);
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error confirming email: $e')));
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isConfirming = false);
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Confirm Email')),
//       body: Center(
//         child: _isConfirming
//             ? const CircularProgressIndicator()
//             : const Text(
//                 'Please check your email to confirm your account.',
//               ),
//       ),
//     );
//   }
// }
//
// class HomeScreen extends StatelessWidget {
//   final String role;
//   const HomeScreen({super.key, required this.role});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Home')),
//       body: Center(child: Text('Welcome, $role!')),
//     );
//   }
// }
