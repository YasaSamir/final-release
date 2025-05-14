import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:project/core/widgets/my_buttons.dart';
import '../../../core/widgets/package_details_page.dart';
class PackageDelivery extends StatelessWidget {
  const PackageDelivery({super.key});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    return Scaffold(
      backgroundColor: Color(0xff191919),
      appBar: AppBar(
        backgroundColor: Color(0xff191919),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.038),
            child: Row(
              children: [
                Image.asset(
                  'assets/icon/what_to_send.png',
                  height: screenHeight * 0.054,
                  width: screenWidth * 0.119,
                ),
                AutoSizeText(
                  "What to send",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight * 0.108),
            // Illustration
            Image.asset(
              'assets/images/van.png', // Change to your asset image
              height: screenHeight * 0.24,
            ),
            SizedBox(height: screenHeight * 0.108),
            // Title
            const Text(
              "Send packages with Connect",
              style: TextStyle(
                color: Colors.white,
                fontSize: 33,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.start,
            ),
            SizedBox(height: screenHeight * 0.010),
            // Subtitle
            const Text(
              "Get it delivered in the time it takes to   drive there",
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w500,
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.start,
            ),
            SizedBox(height: screenHeight * 0.0431),
            // Send a package button
            SizedBox(height: screenHeight * 0.016),
            // Receive a package button
           PrimaryButton( text: 'Send a package',
             onClick:(){
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => const PackageDetailsPage(isReceiver: false)),
               );             } ,),
            SizedBox(height: screenHeight * 0.016),
            PrimaryButton(text: 'Recieve a package',
              onClick:(){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PackageDetailsPage(isReceiver: true)),
                );
              } ,),
          ],
        ),
      ),
    );
  }
}

