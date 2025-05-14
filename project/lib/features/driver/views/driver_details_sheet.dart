import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/driver_model.dart';
import '../services/driver_service.dart';

class DriverDetailsSheet extends StatefulWidget {
  final DriverModel driver;
  final Position currentLocation;

  const DriverDetailsSheet({
    Key? key,
    required this.driver,
    required this.currentLocation,
  }) : super(key: key);

  @override
  State<DriverDetailsSheet> createState() => _DriverDetailsSheetState();
}

class _DriverDetailsSheetState extends State<DriverDetailsSheet> {
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _requestRide() async {
    if (_pickupController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter pickup and destination locations')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await DriverService.requestRide(
        driverId: widget.driver.id,
        pickupLocation: _pickupController.text,
        destinationLocation: _destinationController.text,
        pickupLat: widget.currentLocation.latitude,
        pickupLng: widget.currentLocation.longitude,
        destinationLat: widget.driver.latitude,
        destinationLng: widget.driver.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride request sent successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to request ride: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: widget.driver.profileImage != null
                    ? NetworkImage(widget.driver.profileImage!)
                    : null,
                child: widget.driver.profileImage == null
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.driver.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.driver.vehicleType} - ${widget.driver.vehicleNumber}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          widget.driver.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.driver.totalTrips} trips',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _pickupController,
            decoration: const InputDecoration(
              labelText: 'Pickup Location',
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _destinationController,
            decoration: const InputDecoration(
              labelText: 'Destination',
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _requestRide,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Request Ride'),
          ),
        ],
      ),
    );
  }
}
