import 'package:flutter/material.dart';

class YourTripsScreen extends StatelessWidget {
  final VoidCallback onPastTabPressed;
  final VoidCallback onUpcomingTabPressed;
  final VoidCallback onRetryPressed;

  YourTripsScreen({
    required this.onPastTabPressed,
    required this.onUpcomingTabPressed,
    required this.onRetryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back when pressed
          },
        ),
        title: Text(
          'Your Trips',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: onPastTabPressed,
                  child: Text(
                    'Past',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                TextButton(
                  onPressed: onUpcomingTabPressed,
                  child: Text(
                    'Upcoming',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'You haven\'t taken a trip yet',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: onRetryPressed,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white),
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}