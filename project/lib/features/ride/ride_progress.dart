// ignore_for_file: must_be_immutable
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project/core/constants/my_colors.dart';

Completer<GoogleMapController> googleMapController = Completer();

class Iphone14PlusOneScreen extends StatelessWidget {
  Iphone14PlusOneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.cBackgroundColor,
      body: SafeArea(
        top: false,
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                children: [
                  _buildMapView(context),
                  _buildDriverInfoRow(context),
                  SizedBox(height: 44),
                  _buildArrivalInfoRow(context),
                  SizedBox(height: 8),
                  Container(
                    width: double.maxFinite,
                    margin: EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      height: 8,
                      width: 416,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.75,
                          backgroundColor: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 50),
                  _buildActionButtonsRow(context),
                  SizedBox(height: 58),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section Widget

/// Section Widget
Widget _buildMapView(BuildContext context) {
  return SizedBox(
    height: 600,
    width: double.maxFinite,
    child: GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: LatLng(37.43296265331129, -122.08832357078792),
        zoom: 14.4746,
      ),
      onMapCreated: (GoogleMapController controller) {
        googleMapController.complete(controller);
      },
      zoomControlsEnabled: true,
      zoomGesturesEnabled: true,
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
      buildingsEnabled: true,
    ),
  );
}

/// Section Widget
Widget _buildDriverInfoRow(BuildContext context) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    width: double.maxFinite,
    decoration: BoxDecoration(color: Colors.black),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/icon/person2.png', height: 50, width: 50),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("John D.", style: TextStyle(color: Colors.white)),
                Text(
                  "Toyota Camry • ABC 123",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        Icon(Icons.ice_skating_outlined, color: Colors.white),
      ],
    ),
  );
}

/// Section Widget
Widget _buildArrivalInfoRow(BuildContext context) {
  return Container(
    width: double.maxFinite,
    margin: EdgeInsets.symmetric(horizontal: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Estimated Arrival", style: TextStyle(color: Colors.white)),
        Text("5 mins away", style: TextStyle(color: Colors.white)),
      ],
    ),
  );
}

/// Section Widget
Widget _buildActionButtonsRow(BuildContext context) {
  return Container(
    width: double.maxFinite,
    margin: EdgeInsets.symmetric(horizontal: 6),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton( style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),

            ),

          ),

            child: Container(
              margin: EdgeInsets.only(right: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_filled, color: Colors.white),
                  SizedBox(width: 4),
                  Text("Message",style: TextStyle(color: Colors.white),),
                ],
              ),
            ),
            onPressed: () {},
          ),
        ),
        SizedBox(width: 6),
        Expanded(
          child: OutlinedButton(
            style: ButtonStyle(
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),

              side: MaterialStateProperty.all<BorderSide>(
                BorderSide(color: Colors.red, width: 1), // Red border
              ),
            ),
            child: Container(

              margin: EdgeInsets.only(right: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel_outlined, color: Colors.red),
                  SizedBox(width: 4),
                  Text("Cancel", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            onPressed: () {},
          ),
        ),
      ],
    ),
  );
}
