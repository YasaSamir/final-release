import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project/core/constants/my_colors.dart';
import 'package:project/features/auth/views/login/sign_up.dart';
import 'package:project/features/driver/views/driver_home_screen.dart';
import 'package:project/features/driver/views/driver_tracking.dart';
import 'package:project/features/rider/home/home_screen.dart';

import '../../../../core/widgets/custom/custom_outlined_button.dart';
import '../sign_up/service_selection_page.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtPassword = TextEditingController();

  // Future<void> _login({required bool isDriver}) async {
  //   String email = txtEmail.text.trim();
  //   String password = txtPassword.text.trim();
  //
  //   if (email.isEmpty || password.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("يرجى إدخال رقم الهاتف وكلمة المرور")),
  //     );
  //     return;
  //   }
  //
  //   try {
  //     await ServiceCall.login(
  //       mobile: email,
  //       password: password,
  //       userType: isDriver ? 'driver' : 'user',
  //       withSuccess: (response) async {
  //         if (kDebugMode) {
  //           print("Login successful: $response");
  //         }
  //         if (isDriver) {
  //           Navigator.pushReplacement(
  //             context,
  //             MaterialPageRoute(builder: (context) => const HomeView()),
  //           );
  //         } else {
  //           Navigator.pushReplacement(
  //             context,
  //             MaterialPageRoute(
  //                 builder: (context) => const ServiceSelectionPage()),
  //           );
  //         }
  //       },
  //       failure: (error) async {
  //         if (kDebugMode) {
  //           print("Login failed with error: $error");
  //         }
  //         String errorMessage;
  //         if (error.contains("Connection refused")) {
  //           errorMessage = "لا يمكن الاتصال بالخادم. تحقق من اتصالك بالإنترنت.";
  //         } else if (error.contains("timeout")) {
  //           errorMessage = "انتهت مهلة الاتصال. حاول مرة أخرى لاحقًا.";
  //         } else if (error.contains("Invalid credentials")) {
  //           errorMessage = "رقم الهاتف أو كلمة المرور غير صحيحة.";
  //         } else {
  //           errorMessage = "فشل تسجيل الدخول: $error";
  //         }
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text(errorMessage)),
  //         );
  //       },
  //     );
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print("Unexpected error during login: $e");
  //     }
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("حدث خطأ غير متوقع: $e")),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Welcome Back!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Image.asset(
                "assets/images/sign_1.png", // Replace with your asset path
                height: 200,
              ),
              const SizedBox(height: 30),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Email",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: txtEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  hintText: "example@mail.com",
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 15,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Password",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: txtPassword,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  hintText: "********",
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 15,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Handle forgot password logic
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Colors.teal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CustomOutlinedButton(
                text: 'Login as user',
                buttonTextStyle:
                    const TextStyle(color: MyColors.cBackgroundColor),
                onPressed: () {
                  // _login(isDriver: false); // Login as user
                  context.push(ServiceSelectionPage());
                },
              ),
              const SizedBox(height: 15),
              CustomOutlinedButton(
                text: 'Login as Driver',
                buttonTextStyle:
                    const TextStyle(color: MyColors.cBackgroundColor),
                onPressed: () {
                  // _login(isDriver: false); // Login as user
                  context.push(DriverHomeScreen());
                },
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push(const SignUpScreen());
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.teal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
