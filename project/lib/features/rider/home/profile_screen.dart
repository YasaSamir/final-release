import 'package:flutter/material.dart';

import '../../../../core/constants/my_colors.dart';
import 'menu_drawer.dart';



class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const MenuDrawer(),
      appBar: AppBar(
        leading: IconButton(onPressed: ()=>_scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.menu, size: 28, color: Colors.black),
        ),
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/icon/personal.png'), // Replace with your image asset
              ),
              const SizedBox(height: 16),
              const Text(
                'Yaso',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Member since March 2024',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        '4.9',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rating',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(width: 40),
                  Column(
                    children: [
                      Text(
                        '283',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rides',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(width: 40),
                  Column(
                    children: [
                      Text(
                        '2y',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Member',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildProfileListItem(context, 'Personal Information', Icons.person_outline, () {
                // Navigate to Personal Information screen
              }),
              _buildProfileListItem(context, 'Payment Methods', Icons.payment_outlined, () {
                // Navigate to Payment Methods screen
              }),
              _buildProfileListItem(context, 'Ride History', Icons.history_outlined, () {
                // Navigate to Ride History screen
              }),
              _buildProfileListItem(context, 'Favorite Locations', Icons.favorite_border_outlined, () {
                // Navigate to Favorite Locations screen
              }),
              _buildProfileListItem(context, 'Support', Icons.support_agent_outlined, () {
                // Navigate to Support screen
              }),
              _buildProfileListItem(context, 'Settings', Icons.settings_outlined, () {
                // Navigate to Settings screen
              }),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () {
                  // Handle logout
                },
                style: ElevatedButton.styleFrom(
                  side: BorderSide(color:  MyColors.cBackgroundColor, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        color:   MyColors.cBackgroundColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileListItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}