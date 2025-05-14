import 'package:flutter/material.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Back',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.greenAccent,
                    child: CircleAvatar(
                      backgroundImage: AssetImage('assets/icon/person2.png'),
                      radius: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Yaso Samir',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Your Email',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text(
                'History',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.report_problem),
              title: const Text(
                'Complain',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.report_gmailerrorred_outlined),
              title: const Text(
                'About Us',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text(
                'Help and Support',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text(
                'Settings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {},
            ),
          ],
        ),
      );
    }

  }
