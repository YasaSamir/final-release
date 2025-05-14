import 'package:flutter/material.dart';

import 'car_rental.dart';

class TransportSelectionScreen extends StatelessWidget {
  final Function(String) onTransportSelected;

  const TransportSelectionScreen({super.key, required this.onTransportSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Select transport'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Select your transport',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TransportOption(
                  label: 'Car',
                  onTap: ()  {
                    onTransportSelected('Car');
                    Navigator.of(context).push(MaterialPageRoute(builder: (context)=>CarDetailsScreen() ));
                  },
                ),
                TransportOption(
                  label: 'Bike',
                  onTap: () => onTransportSelected('Bike'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TransportOption(
                  label: 'Cycle',
                  onTap: () => onTransportSelected('Cycle'),
                ),
                TransportOption(
                  label: 'Taxi',
                  onTap: () => onTransportSelected('Taxi'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TransportOption extends StatelessWidget {
  final String? img;
  final String label;
  final VoidCallback onTap;

  const TransportOption({
    super.key,
    this.img,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 2,
              color: Colors.grey,
            ),
          ),
          color: Colors.teal[50],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(img ?? 'assets/images/personal.png', height: 45, width: 45),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Example usage in your HomeScreen
void _showTransportSelection(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => TransportSelectionScreen(
        onTransportSelected: (selectedTransport) {
          Navigator.pop(context); // Close the bottom sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected transport: $selectedTransport')),
          );
          // Add your logic here for handling the selection
        },
      ),
    ),
  );
}

