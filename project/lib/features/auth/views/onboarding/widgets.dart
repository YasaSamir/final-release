import 'dart:async';

import 'package:flutter/material.dart';

class LetterByLetterText extends StatefulWidget {
  @override
  _LetterByLetterTextState createState() => _LetterByLetterTextState();
}

class _LetterByLetterTextState extends State<LetterByLetterText> {
  String fullText = "Smart Ride Sharing";
  String displayedText = "";
  int index = 0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    Timer.periodic(Duration(milliseconds: 150), (timer) {
      if (index < fullText.length) {
        setState(() {
          displayedText = fullText.substring(0, index + 1);
          index++;
        });
      } else {
        timer.cancel(); // Stop when all letters are shown
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
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
          child: Text(
            displayedText,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}