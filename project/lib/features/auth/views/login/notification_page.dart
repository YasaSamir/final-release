import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous page
            // Handle back button press
          },
        ),
        title: Text('Notification'),
        foregroundColor: Colors.black,
      ),
      body: NotificationList(),
    );
  }
}

class NotificationList extends StatelessWidget {
  const NotificationList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        NotificationSection(title: 'Today', notifications: [
          NotificationItem(
              title: 'Payment confirm',
              message:
                  'Lorem ipsum dolor sit amet consectetur. Ultrici es tincidunt eleifend vitae',
              time: '15 min ago'),
          NotificationItem(
              title: 'Payment confirm',
              message:
                  'Lorem ipsum dolor sit amet consectetur. Ultrici es tincidunt eleifend vitae',
              time: '25 min ago'),
        ]),
        NotificationSection(title: 'Yesterday', notifications: [
          NotificationItem(
              title: 'Payment confirm',
              message:
                  'Lorem ipsum dolor sit amet consectetur. Ultrici es tincidunt eleifend vitae',
              time: '15 min ago'),
          NotificationItem(
              title: 'Payment confirm',
              message:
                  'Lorem ipsum dolor sit amet consectetur. Ultrici es tincidunt eleifend vitae',
              time: '25 min ago'),
          NotificationItem(
              title: 'Payment confirm',
              message:
                  'Lorem ipsum dolor sit amet consectetur. Ultricies tincidunt eleifend vitae',
              time: '25 min ago'),
          NotificationItem(
              title: 'Payment confirm',
              message:
                  'Lorem ipsum dolor sit amet consectetur. Liitrici es tincidunt eleifend vitae',
              time: '15 min ago'),
        ]),
      ],
    );
  }
}

class NotificationSection extends StatelessWidget {
  final String title;
  final List<NotificationItem> notifications;

  const NotificationSection(
      {super.key, required this.title, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...notifications,
      ],
    );
  }
}

class NotificationItem extends StatelessWidget {
  final String title;
  final String message;
  final String time;

  const NotificationItem(
      {super.key,
      required this.title,
      required this.message,
      required this.time});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green.shade100, // Light green background
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(message),
            SizedBox(height: 8),
            Text(time, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
