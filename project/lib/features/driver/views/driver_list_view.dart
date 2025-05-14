import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/driver_model.dart';
import '../services/driver_service.dart';
import 'driver_details_sheet.dart';

class DriverListView extends StatefulWidget {
  const DriverListView({Key? key}) : super(key: key);

  @override
  State<DriverListView> createState() => _DriverListViewState();
}

class _DriverListViewState extends State<DriverListView> {
  List<DriverModel> _drivers = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Please enable location services in your device settings.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error =
                'Location permissions are required to find nearby drivers.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error =
              'Location permissions are permanently denied. Please enable them in app settings.';
          _isLoading = false;
        });
        await Geolocator.openAppSettings();
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      await _fetchNearbyDrivers();
    } catch (e) {
      setState(() {
        _error = 'Unable to get your location. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNearbyDrivers() async {
    if (_isRefreshing || _currentPosition == null) return;

    _isRefreshing = true;
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final drivers = await DriverService.getNearbyDrivers(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      setState(() {
        _drivers = drivers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error =
            'Unable to fetch drivers. Please check your internet connection and try again.';
        _isLoading = false;
      });
    } finally {
      _isRefreshing = false;
    }
  }

  void _showDriverDetails(DriverModel driver) {
    if (_currentPosition == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DriverDetailsSheet(
        driver: driver,
        currentLocation: _currentPosition!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Drivers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNearbyDrivers,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNearbyDrivers,
        child: Stack(
          children: [
            _buildBody(),
            if (_isLoading)
              const Positioned(
                top: 10,
                right: 10,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _drivers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_drivers.isEmpty) {
      return const Center(
        child: Text('No drivers available nearby'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _drivers.length,
      itemBuilder: (context, index) => _buildDriverCard(_drivers[index]),
      separatorBuilder: (context, index) => const SizedBox(height: 16),
    );
  }

  Widget _buildDriverCard(DriverModel driver) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: driver.profileImage != null
              ? NetworkImage(driver.profileImage!)
              : null,
          child: driver.profileImage == null
              ? Text(
                  driver.name.isNotEmpty ? driver.name[0].toUpperCase() : 'D')
              : null,
        ),
        title: Text(driver.name.isNotEmpty ? driver.name : 'Unknown Driver'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${driver.vehicleType.isNotEmpty ? driver.vehicleType : 'Unknown'} - '
              '${driver.vehicleNumber.isNotEmpty ? driver.vehicleNumber : 'N/A'}',
            ),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                Text(' ${driver.rating.toStringAsFixed(1)}'),
                Text(' • ${driver.totalTrips} trips'),
                if (driver.distance != null)
                  Text(' • ${driver.distance!.toStringAsFixed(1)} km away'),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: driver.isAvailable ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            driver.isAvailable ? 'Available' : 'Busy',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        onTap: () => _showDriverDetails(driver),
      ),
    );
  }
}
