import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:project/routes/on_generate_route.dart';

import 'features/auth/views/onboarding/splash_view.dart';
// import "package:flutter_dotenv/flutter_dotenv.dart";// Correct deep link package

void main() async {
  // await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});



  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Uri? _initialUri;
  Uri? _latestUri;
  StreamSubscription<Uri?>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // _handleInitialUri();
    // _listenForDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  // Handle initial deep link (when app is launched)
  // Future<void> _handleInitialUri() async {
  //   try {
  //     final uri = await getInitialUri();
  //     if (uri != null) {
  //       _handleDeepLink(uri);
  //     }
  //   } catch (e) {
  //     debugPrint('Failed to get initial URI: $e');
  //   }
  // }

  // Listen for deep links while the app is running
  // void _listenForDeepLinks() {
  //   _sub = uriLinkStream.listen((Uri? uri) {
  //     if (!mounted || uri == null) return;
  //     _handleDeepLink(uri);
  //   }, onError: (err) {
  //     debugPrint('Error receiving deep link: $err');
  //   });
  // }

  // Handle the deep link logic
  void _handleDeepLink(Uri uri) {
    if (uri.pathSegments.contains('login-callback')) {
      // Navigate to home screen after email confirmation
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashView(),
    );
  }
}
