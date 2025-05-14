import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project/core/constants/my_colors.dart';

class CarDetailsScreen extends StatelessWidget {
  const
  CarDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text("Mustang Shelby GT"),
        backgroundColor: MyColors.cGreenColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.asset(
                  "assets/images/image 3.jpg",
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            const Text("Specifications", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                _buildFeatureCard("Max Power", "2500hp"),
                _buildFeatureCard("Fuel", "Gasoline"),
                _buildFeatureCard("Max Speed", "250km/h"),
                _buildFeatureCard("0-60mph", "3.2s"),
              ],
            ),
            const SizedBox(height: 16.0),
            const Text("Car Features", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Column(
              children: [
                _buildFeatureRow("Model", "GT5000"),
                _buildFeatureRow("Capacity", "760hp"),
                _buildFeatureRow("Color", "Red"),
                _buildFeatureRow("Fuel Type", "Gasoline"),
                _buildFeatureRow("Gear Type", "Automatic"),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  onPressed: () {},
                  child: const Text("Book later"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: MyColors.cGreenColor),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BookingScreen()),
                    );
                  },
                  child: const Text("Ride Now", style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String title, String value) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: Text(value, style: const TextStyle(color: Colors.green)),
    );
  }
}

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  LatLng? startPosition;
  LatLng? endPosition;
  late TextEditingController fromController;
  late TextEditingController toController;
  late String initialFromHint;

  // @override
  // void initState() {
  //   super.initState();
  //   fromController = TextEditingController();
  //   toController = TextEditingController(text: widget.initialToAddress ?? '');
  //   initialFromHint = widget.currentPosition == null
  //       ? 'Current location not available'
  //       : 'Lat: ${widget.currentPosition!.latitude}, Lon: ${widget.currentPosition!.longitude}';
  //   startPosition = widget.currentPosition;
  //   endPosition = widget.initialToPosition;
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Request for rent"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationSection("Current Location", "2972 Westheimer Rd, Santa Ana, Illinois 85486"),
            _buildLocationSection("Office", "1901 Thornridge Cir, Shiloh, Hawaii 81063"),
            const SizedBox(height: 16.0),
            TextField(
              decoration: const InputDecoration(labelText: "Date", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8.0),
            TextField(
              decoration: const InputDecoration(labelText: "Time", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16.0),
            const Text("Select Payment Method", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildPaymentOption(Icons.credit_card, "Visa **** 8970"),
            _buildPaymentOption(Icons.credit_card, "Mastercard **** 8970"),
            _buildPaymentOption(Icons.email, "mailaddress@gmail.com"),
            _buildPaymentOption(Icons.money, "Cash"),
            const SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {},
                // async{
                //   try {
                //     if (startPosition == null) {
                //       List<Location> fromLocations = await locationFromAddress(fromController.text);
                //       if (fromLocations.isEmpty) throw Exception('Invalid start address');
                //       startPosition = LatLng(fromLocations.first.latitude, fromLocations.first.longitude);
                //     }
                //
                //     if (endPosition == null) {
                //       List<Location> toLocations = await locationFromAddress(toController.text);
                //       if (toLocations.isEmpty) throw Exception('Invalid end address');
                //       endPosition = LatLng(toLocations.first.latitude, toLocations.first.longitude);
                //     }
                //
                //     if (kDebugMode) {
                //       print('Confirming route from $startPosition to $endPosition');
                //     }
                //
                //     if (startPosition != null && endPosition != null) {
                //       widget.onRouteConfirmed(startPosition!, endPosition!);
                //       Navigator.of(context).push(MaterialPageRoute(builder: (context) => CarDetailsScreen()));
                //     }
                //   } catch (e) {
                //     if (kDebugMode) print('Error in address lookup: $e');
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       SnackBar(content: Text('Error: $e')),
                //     );
                //   }
                // },
                child: const Text("Confirm Booking"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(String title, String address) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(address, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(text),
      onTap: () {},
    );
  }
}
