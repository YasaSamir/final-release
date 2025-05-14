
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddressPopup extends StatefulWidget {
  final LatLng? currentPosition;
  final Function(String) onSearch;
  final Function(LatLng, LatLng) onRouteConfirmed;
  final String? initialToAddress;
  final LatLng? initialToPosition;

  const AddressPopup({
    super.key,
    required this.currentPosition,
    required this.onSearch,
    required this.onRouteConfirmed,
    this.initialToAddress,
    this.initialToPosition,
  });

  @override
  _AddressPopupState createState() => _AddressPopupState();
}

class _AddressPopupState extends State<AddressPopup> {
  late TextEditingController fromController;
  late TextEditingController toController;
  late String initialFromHint;
  LatLng? startPosition;
  LatLng? endPosition;

  @override
  void initState() {
    super.initState();
    fromController = TextEditingController();
    toController = TextEditingController(text: widget.initialToAddress ?? '');
    initialFromHint =
    widget.currentPosition == null
        ? 'Current location not available'
        : 'Lat: ${widget.currentPosition!.latitude}, Lon: ${widget.currentPosition!.longitude}';
    startPosition = widget.currentPosition;
    endPosition = widget.initialToPosition;
  }

  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select address',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: fromController,
            decoration: InputDecoration(
              hintText: initialFromHint,
              prefixIcon: const Icon(Icons.location_on_outlined),
              labelText: 'From',
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() {}),
            onSubmitted: (value) {
              if (value.isEmpty) {
                setState(() {
                  fromController.text = initialFromHint;
                });
              }
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: toController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_on_outlined),
              labelText: 'To',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() {}),
            onSubmitted: (value) {
              if (toController.text.isNotEmpty) {
                widget.onSearch(toController.text);
              }
            },
          ),
          const SizedBox(height: 16),
          if (fromController.text.isNotEmpty && toController.text.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    if (startPosition == null) {
                      List<Location> fromLocations = await locationFromAddress(
                        fromController.text,
                      );
                      if (fromLocations.isEmpty)
                        throw Exception('Invalid start address');
                      startPosition = LatLng(
                        fromLocations.first.latitude,
                        fromLocations.first.longitude,
                      );
                    }

                    if (endPosition == null) {
                      List<Location> toLocations = await locationFromAddress(
                        toController.text,
                      );
                      if (toLocations.isEmpty)
                        throw Exception('Invalid end address');
                      endPosition = LatLng(
                        toLocations.first.latitude,
                        toLocations.first.longitude,
                      );
                    }

                    if (kDebugMode) {
                      print(
                        'Confirming route from $startPosition to $endPosition',
                      );
                    }

                    if (startPosition != null && endPosition != null) {
                      widget.onRouteConfirmed(startPosition!, endPosition!);
                      // Navigator.of(context).push(
                      //   MaterialPageRoute(
                      //     builder: (context) => CarDetailsScreen(),
                      //   ),
                      // );

                    }
                  } catch (e) {
                    if (kDebugMode) print('Error in address lookup: $e');
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Confirm Ride',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Recent places',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: ListView(
              children: const [
                ListTile(
                  leading: Icon(Icons.place_outlined),
                  title: Text('Home'),
                  subtitle: Text('123 Main St'),
                ),
                ListTile(
                  leading: Icon(Icons.place_outlined),
                  title: Text('Work'),
                  subtitle: Text('456 Office Rd'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}