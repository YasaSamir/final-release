import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:project/features/auth/views/onboarding/widgets.dart';
import '../../../../main.dart';
import '../login/login.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  String fullText = "Smart Ride Sharing";
  String displayedText = "";
  int index = 0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        if (index < fullText.length) {
          displayedText = fullText.substring(0, index + 1);
          index++;
        } else {
          // Pause for a moment before restarting
          // Future.delayed(Duration(milliseconds: 100), () {
          //   setState(() {
          //     displayedText = "";
          //     index = 0;
          //   });
          // });
        }
      });
    });
  }
  @override
  Widget build(BuildContext context) {

    double screenWidth  = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, // Start color position
            end: Alignment.bottomCenter, // End color position
            colors: [
              Color(0xff1976D2), // First color
              Color(0xff535AFF), // Second color
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              height: screenHeight * 0.15, // Adjust as needed
            ),

            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: screenWidth * 0.45, // Adjust as needed
                    height: screenHeight * 0.2, // Adjust as needed
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      // Rounded corners
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xff1976D2),
                          // First color
                          Color(0xff535AFF),
                          // End color (adjust as needed)
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          // Shadow on the bottom
                          color: Colors.white.withOpacity(0.2),
                          spreadRadius: 0, // Adjust as needed
                          blurRadius: 5, // Adjust as needed
                          offset: const Offset(
                              0, 3), // Positive y-offset for bottom side
                        ),
                        BoxShadow(
                          // Shadow on the right
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 0, // Adjust as needed
                          blurRadius: 5, // Adjust as needed
                          offset: const Offset(
                              3, 0), // Positive x-offset for right side
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        textAlign: TextAlign.center,
                        displayedText,
                        style: const TextStyle(
                          fontSize: 26,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(

                  horizontal: screenWidth * 0.02,
                  vertical: screenHeight * 0.02),

              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                   AutoSizeText(
                     'Move with safety ',
                         style: TextStyle(
                           fontSize: 22,
                           color: Colors.white,
                           fontWeight: FontWeight.bold,
                         ),
                     maxLines: 1,
                   ),
                    ImageIcon(
                      AssetImage('assets/images/shield.png'), // Or NetworkImage, etc.
                      size: 28.0, // Adjust size as needed
                      color: Colors.white, // Optional color
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: const BorderSide(
                    color: Colors.white,
                    width: 2.0,
                  ),
                ),

                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const Login()));
                },
                child:  const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,

                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
