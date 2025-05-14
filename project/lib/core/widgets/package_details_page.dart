import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:project/core/widgets/my_buttons.dart';
import '../../core/constants/my_colors.dart';
import '../../core/widgets/phone_number_field.dart';

class PackageDetailsPage extends StatelessWidget {
  final bool isReceiver; // Determines if it's for the receiver or sender

  const PackageDetailsPage({Key? key, required this.isReceiver}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: MyColors.cBackgroundColor,
      appBar: AppBar(
        backgroundColor: MyColors.cBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: screenWidth * 0.0381),
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
                  'assets/icon/person.png',
                  height: screenHeight * 0.054,
                  width: screenWidth * 0.119,
                ),
                AutoSizeText(
                  "Contacts",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                isReceiver
                    ? "Who’s receiving the package?"
                    : "Who’s sending the package?",
                style: const TextStyle(color: Colors.white, fontSize: 33),
              ),
            ),
            SizedBox(height: screenHeight * 0.0431),
            Text(
              isReceiver
                  ? "The receiver will be contacted to confirm the delivery. The driver may contact the receiver to complete the delivery."
                  : "The sender will be contacted to confirm the delivery. The driver may contact the sender to complete the delivery.",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            SizedBox(height: screenHeight * 0.0323),
            const Text(
              "Name",
              style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: screenHeight * 0.02155),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: MyColors.cBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                hintText: "Enter name",
                hintStyle: const TextStyle(color: Colors.white54),
              ),
            ),
            SizedBox(height: screenHeight * 0.02155),
            const Text(
              "Phone number",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: screenHeight * 0.02155),
            PhoneNumberField(
              controller: TextEditingController(),
            ),
            SizedBox(height: screenHeight * 0.2974),
            PrimaryButton(
              text: isReceiver ? "Confirm recipient" : "Confirm sender",
              onClick: () {},
            ),
          ],
        ),
      ),
    );
  }
}
