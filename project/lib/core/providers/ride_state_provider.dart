import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../models/ride_model.dart';
import '../services/ride_service.dart';
import '../services/socket_service.dart';

enum RideStatus {
  idle,
  searching,
  driverFound,
  driverAccepted,
  driverArriving,
  inProgress,
  completed,
  cancelled,
}

class RideStateProvider with ChangeNotifier {
  // Services
  final RideService _rideService = RideService.instance;
  final SocketService _socketService = SocketService.instance;

  // State variables
  RideStatus _status = RideStatus.idle;
  RideModel? _currentRide;
  String? _currentRideId;
  String? _currentDriverId;
  latlong.LatLng? _userLocation;
  latlong.LatLng? _destination;
  latlong.LatLng? _driverLocation;
  List<latlong.LatLng> _routePoints = [];
  bool _isRouteDrawn = false;
  double _rideProgress = 0.0;
  StreamSubscription? _driverLocationSubscription;
  StreamSubscription? _rideAcceptedSubscription;
  StreamSubscription? _rideStartedSubscription;
  StreamSubscription? _rideCompletedSubscription;
  Timer? _locationUpdateTimer;

  // Getters
  RideStatus get status => _status;
  RideModel? get currentRide => _currentRide;
  String? get currentRideId => _currentRideId;
  String? get currentDriverId => _currentDriverId;
  latlong.LatLng? get userLocation => _userLocation;
  latlong.LatLng? get destination => _destination;
  latlong.LatLng? get driverLocation => _driverLocation;
  List<latlong.LatLng> get routePoints => _routePoints;
  bool get isRouteDrawn => _isRouteDrawn;
  double get rideProgress => _rideProgress;

  // Initialize the provider
  void initialize() {
    _socketService.connect();
    _setupSocketListeners();
  }

  // Set user location
  void setUserLocation(latlong.LatLng location) {
    _userLocation = location;
    notifyListeners();
  }

  // Set destination
  void setDestination(latlong.LatLng destination) {
    _destination = destination;
    notifyListeners();
  }

  // Draw route between two points
  Future<void> drawRoute(latlong.LatLng start, latlong.LatLng end) async {
    try {
      final routePoints = await _rideService.getRoutePoints(
          start.latitude, start.longitude, end.latitude, end.longitude);

      _routePoints = routePoints;
      _isRouteDrawn = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error drawing route: $e');
      _isRouteDrawn = false;
      notifyListeners();
    }
  }

  // Request a ride
  Future<void> requestRide({
    required String riderId,
    required latlong.LatLng pickupLocation,
    required latlong.LatLng destination,
    String priority = 'normal',
  }) async {
    try {
      _status = RideStatus.searching;
      notifyListeners();

      // Convert LatLng to Map
      final pickupMap = {
        'lat': pickupLocation.latitude,
        'lng': pickupLocation.longitude,
      };

      final destinationMap = {
        'lat': destination.latitude,
        'lng': destination.longitude,
      };

      // Create ride request
      final ride = await _rideService.createRide(
        riderId: riderId,
        pickupLocation: pickupMap,
        destination: destinationMap,
      );

      _currentRide = ride;
      _currentRideId = ride.id;

      // Draw route immediately
      await drawRoute(pickupLocation, destination);

      notifyListeners();
    } catch (e) {
      _status = RideStatus.idle;
      debugPrint('Error requesting ride: $e');
      notifyListeners();
    }
  }

  // Setup socket listeners
  void _setupSocketListeners() {
    // Listen for ride accepted events
    _rideAcceptedSubscription = _socketService.onRideAccepted.listen((data) {
      _currentDriverId = data['driverId'];
      _status = RideStatus.driverAccepted;

      // Start the ride automatically when driver accepts
      _startRideAutomatically(data['rideId'], data['driverId']);

      notifyListeners();
    });

    // Listen for driver location updates
    _driverLocationSubscription =
        _socketService.onDriverLocationUpdate.listen((data) {
      if (data['driverId'] == _currentDriverId) {
        final lat = data['location']['lat'];
        final lng = data['location']['lng'];
        _driverLocation = latlong.LatLng(lat, lng);

        // Update progress if available
        if (data['progress'] != null) {
          _rideProgress = data['progress'] / 100;
        }

        notifyListeners();
      }
    });

    // Listen for ride started events
    _rideStartedSubscription = _socketService.onRideStarted.listen((rideId) {
      if (rideId == _currentRideId) {
        _status = RideStatus.inProgress;
        notifyListeners();
      }
    });

    // Listen for ride completed events
    _rideCompletedSubscription =
        _socketService.onRideCompleted.listen((rideId) {
      if (rideId == _currentRideId) {
        _status = RideStatus.completed;
        _rideProgress = 1.0;
        notifyListeners();
      }
    });
  }

  // Start ride automatically when driver accepts
  Future<void> _startRideAutomatically(String rideId, String driverId) async {
    _status = RideStatus.driverArriving;
    notifyListeners();

    // Get the latest ride data
    try {
      final ride = await _rideService.getRideById(rideId);
      _currentRide = ride;

      // Draw route from driver to pickup location
      if (_driverLocation != null && _userLocation != null) {
        await drawRoute(_driverLocation!, _userLocation!);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error getting ride data: $e');
    }
  }

  // Reset state
  void resetState() {
    _status = RideStatus.idle;
    _currentRide = null;
    _currentRideId = null;
    _currentDriverId = null;
    _destination = null;
    _driverLocation = null;
    _routePoints = [];
    _isRouteDrawn = false;
    _rideProgress = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _driverLocationSubscription?.cancel();
    _rideAcceptedSubscription?.cancel();
    _rideStartedSubscription?.cancel();
    _rideCompletedSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }
}
