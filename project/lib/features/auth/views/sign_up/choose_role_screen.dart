import 'package:flutter/material.dart';
import 'package:project/core/constants/my_colors.dart';
import 'package:project/features/driver/views/driver_tracking.dart';

class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({super.key});

  @override
  _ChooseRoleScreenState createState() => _ChooseRoleScreenState();

}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  String? selectedRole;

  void selectRole(String role) {
    setState(() {
      selectedRole = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:MyColors.cSecondaryColor,
      appBar: AppBar(
        backgroundColor:MyColors.cSecondaryColor,
        title: Text("Choose Your Role"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "How would you like to use our service?",
                style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),
            roleCard(
              title: "I'm a Rider",
              subtitle: "Looking for convenient rides to my destination",
              role: "rider",
            ),
            SizedBox(height: 16),
            roleCard(
            img: 'assets/images/div-1.jpg',
              title: "I'm a Driver",
              subtitle: "Ready to earn by providing ride services",
              role: "driver",
            ),
            Spacer(),
            ElevatedButton(
              onPressed: selectedRole != null ? () {
                if (selectedRole == "driver")
                  {
                    // Navigator.of(context).push(MaterialPageRoute(builder: (context)=> DriverRegistrationScreen()));
                  }else if(selectedRole == "rider")
                  {

                  }
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Continue",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget roleCard({
    String? img,
    required String title,
    required String subtitle,
    required String role,
  }) {
    bool isSelected = selectedRole == role;
    return GestureDetector(
      onTap: () => selectRole(role),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Image.asset(img?? 'assets/images/div.jpg',),
                Spacer(),
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.green : Colors.grey,
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
