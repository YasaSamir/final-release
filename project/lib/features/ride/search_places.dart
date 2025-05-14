// map_search_bar.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';

class MapSearchBar extends StatefulWidget {
  final GoogleMapController? mapController;
  final Set<Marker> markers;
  final LatLng? currentPosition;
  final Function(Set<Marker>) onMarkersUpdated;

  const MapSearchBar({
    super.key,
    required this.mapController,
    required this.markers,
    required this.currentPosition,
    required this.onMarkersUpdated,
  });

  @override
  _MapSearchBarState createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  List<Prediction> _placePredictions = [];
  final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: 'AIzaSyD58dUq8ZOuF4hXKOpCBS1U78iMRU-Fupo');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch place predictions for autocomplete
  Future<void> _getPlacePredictions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _placePredictions = [];
      });
      return;
    }

    try {
      final response = await _places.autocomplete(
        input,
        location: widget.currentPosition != null
            ? Location(lng:widget.currentPosition!.longitude, lat:widget.currentPosition!.latitude)
            : null,
        radius: 10000, // Search within 10km radius
      );
      if (response.isOkay) {
        setState(() {
          _placePredictions = response.predictions;
        });
      } else {
        if (kDebugMode) {
          print("Autocomplete error: ${response.errorMessage}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching place predictions: $e");
      }
    }
  }

  // Select a place and update the map
  Future<void> _selectPlace(Prediction prediction) async {
    try {
      final placeDetails = await _places.getDetailsByPlaceId(prediction.placeId!);
      if (placeDetails.isOkay) {
        final location = placeDetails.result.geometry!.location;
        LatLng searchedPosition = LatLng(location.lat, location.lng);
        String address = placeDetails.result.formattedAddress ?? prediction.description!;

        // Only animate the camera if mapController is available
        if (widget.mapController != null) {
          widget.mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: searchedPosition, zoom: 14.0),
            ),
          );
        }

        setState(() {
          widget.markers.clear();
          widget.markers.add(
            Marker(
              markerId: const MarkerId('searched_location'),
              position: searchedPosition,
              infoWindow: InfoWindow(title: address),
            ),
          );
          widget.onMarkersUpdated(widget.markers); // Notify parent to update markers
          _searchController.text = address; // Update search field
          _placePredictions = []; // Clear suggestions
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error selecting place: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 160,
      left: 20,
      right: 20,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _getPlacePredictions(value);
                    },
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _selectPlace(_placePredictions.isNotEmpty
                            ? _placePredictions.first
                            : Prediction(description: value));
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: "Where would you go?",
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Display place suggestions
          if (_placePredictions.isNotEmpty)
            Container(
              color: Colors.white,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _placePredictions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_placePredictions[index].description!),
                    onTap: () {
                      _selectPlace(_placePredictions[index]);
                      _searchController.text = _placePredictions[index].description!;
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}