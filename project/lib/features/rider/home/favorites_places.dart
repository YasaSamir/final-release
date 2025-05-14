import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'menu_drawer.dart';

class FavoritePlacesList extends StatefulWidget {


   const FavoritePlacesList({super.key});

  @override
  State<FavoritePlacesList> createState() => _FavoritePlacesListState();
}

class _FavoritePlacesListState extends State<FavoritePlacesList> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, String>> favoritePlaces = [
    {"type": "Office", "address": "2972 Westheimer Rd. Santa Ana, Illinois 85486"},
    {"type": "Home", "address": "2972 Westheimer Rd. Santa Ana, Illinois 85486"},
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      key: _scaffoldKey,
      drawer: const MenuDrawer(),
      appBar: AppBar(
        leading: IconButton(onPressed: ()=>_scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.menu, size: 28, color: Colors.black),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('Favorite Places'),
      ),
      body: ListView.builder(
        itemCount: favoritePlaces.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: Icon(Icons.location_on),
              title: Text(favoritePlaces[index]['type']!),
              subtitle: Text(favoritePlaces[index]['address']!),
              trailing: IconButton(
                icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () {
                  setState(() {
                    favoritePlaces.removeAt(index);
                    (context as Element).markNeedsBuild();
                  });
                  // Rebuild to update the UI
                  // Implement remove functionality here
                  // (e.g., update the favoritePlaces list and rebuild)
                  if (kDebugMode) {
                    print('Remove item at index $index');
                  }
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: OutlinedButton(

          onPressed: (){
            _addFavoritePlace(context);
          },
          child: Icon(Icons.add)
      )
    );
  }
  void _addFavoritePlace(BuildContext context) {
    String newType = '';
    String newAddress = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Favorite Place'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                decoration: InputDecoration(labelText: 'Type (e.g., Home, Office)'),
                onChanged: (value) {
                  newType = value;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Address'),
                onChanged: (value) {
                  newAddress = value;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                if (newType.isNotEmpty && newAddress.isNotEmpty) {
                  setState(() {
                    favoritePlaces.add({"type": newType, "address": newAddress});
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
