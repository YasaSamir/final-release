import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/core/constants/my_colors.dart';

import 'change_language_view.dart';


class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);

    // إعداد AnimationController
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // مدة الـ animation
      vsync: this,
    );

    // Fade Animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Scale Animation
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // بدء الـ animation
    _controller.forward();

    // تحميل الشاشة التالية
    load();
  }

  void load() async {
    await Future.delayed(const Duration(seconds: 3));
    loadNextScreen();
  }

  void loadNextScreen() {
      context.push(const ChangeLanguageView());
  }

  @override
  void dispose() {
    _controller.dispose(); // تحرير الموارد
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:MyColors.cGreenColor,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: context.width,
            height: context.height,
            color: MyColors.cGreenColor,
          ),
          // إضافة AnimatedBuilder لتطبيق الـ animation
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value, // تأثير الـ scale
                child: Opacity(
                  opacity: _fadeAnimation.value, // تأثير الـ fade
                  child: Image.asset(
                    "assets/images/logo-removebg-preview.png",
                    width: context.width,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}