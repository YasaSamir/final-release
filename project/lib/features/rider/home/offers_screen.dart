import 'package:flutter/material.dart';


import '../../../../core/constants/my_colors.dart';
import 'menu_drawer.dart';

class OfferScreen extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, String>> offers = [
    {'discount': '15% off', 'event': 'Black Friday'},
    {'discount': '5% off', 'event': 'Crismus'},
    {'discount': '15% off', 'event': 'Happy New Year'},
    {'discount': '15% off', 'event': 'Black Friday'},
    {'discount': '5% off', 'event': 'Crismus'},
    {'discount': '15% off', 'event': 'Happy New Year'},
  ];

  OfferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: MenuDrawer(),
      backgroundColor:   Colors.white,
      appBar: AppBar(
        centerTitle: true,
        leading:  IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: Icon(Icons.menu, size: 28, color: Colors.black),
            ),
        title: Text('Offer', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor:   Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: offers.length,
          itemBuilder: (context, index) {
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: offers[index]['discount'] == '5% off' ? Colors.purple : Colors.green,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  offers[index]['discount']!,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                subtitle: Text(offers[index]['event']!, style: TextStyle(fontSize: 14, color: Colors.grey)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: () {},
                  child: Text('Collect', style: TextStyle(fontSize: 14, color: Colors.white)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
