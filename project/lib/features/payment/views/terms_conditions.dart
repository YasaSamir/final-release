import 'package:flutter/material.dart';
import 'package:project/core/widgets/my_buttons.dart';

import '../../../routes/app_router.dart';

class TermsConditions extends StatelessWidget {
  TermsConditions({super.key});

  late String phoneNumber;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xff1A1A1A),
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
        ),
        backgroundColor: Color(0xff1A1A1A),
        body: Container(
          margin: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.01),
              Center(
                child: CircleAvatar(
                  backgroundColor: Color(0xffC4C4C4),
                  child: Icon(Icons.person, size: 150, color: Colors.black),
                  radius: 75,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                '''By tapping the arrow below, you agree to left’s Terms of Use and acknowledge that you have read the Privacy Policy''',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              SizedBox(height: screenHeight * 0.06),
              RichText(
                text: TextSpan(
                  text:
                      '''Check the box to indicate that you are at least 18 years of age, agree to the ''',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Terms & Conditions',
                      style: TextStyle(
                        color: Colors.blue,
                        // Change the color of the specific word
                        fontSize: 15, // Change the size of the specific word
                      ),
                    ),
                    TextSpan(text: ' and acknowledge the'),
                    TextSpan(
                      text: ' Privacy Policy',
                      style: TextStyle(color: Colors.blue, fontSize: 15),
                    ),
                  ],
                ),
              ),
              PrimaryButton(text: 'Next', onClick: () {
                // Navigator.of(context).pushNamed(AppRoutes.paymentSelection);
              }),
            ],
          ),
        ),
      ),
    );
  }
}
