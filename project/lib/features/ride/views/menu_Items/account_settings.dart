import 'package:flutter/material.dart';
import 'package:project/core/constants/my_colors.dart';

class AccountSettings extends StatelessWidget {
  const AccountSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.cBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          }, // Handle back button
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.black,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 20),
                  child: Text(
                    'Account Settings',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset('assets/icon/person2.png',height: 70,width: 70,),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Dot Phasor",
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8,),
                        RichText(
                          text: TextSpan(
                            text:'+20  ',
                            style: TextStyle(color: Colors.white, fontSize: 15),
                            children: <TextSpan>[
                              TextSpan(
                                text: 'Phone Number',
                                style: TextStyle(color: Colors.blue, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Favorites Section
                const Text(
                  "Favorites",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.home, color: Colors.white),
                  title: const Text(
                    "Add Home",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  onTap: () {}, // Handle action
                ),
                ListTile(
                  leading: const Icon(Icons.work, color: Colors.white),
                  title: const Text(
                    "Add Work",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {}, // Handle action
                ),

                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {}, // Handle more saved places
                  child: const Text(
                    "More Saved Places",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),

                const SizedBox(height: 30),

                // Privacy Section
                ListTile(
                  title: const Text(
                    "Privacy",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: const Text("Manage the data you share with us"),
                  onTap: () {}, // Handle action
                ),

                ListTile(
                  title: const Text(
                    "Security",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: const Text(
                    "Control your account security with 2-step verification",
                  ),
                  onTap: () {}, // Handle action
                ),

                const SizedBox(height: 20),

                // Sign Out Button
                ListTile(
                  title: const Text(
                    "Sign Out",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {}, // Handle sign out
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
