import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlong;
import '../config/api_config.dart';
import '../models/ride_model.dart';

class RideService {
  static final RideService _instance = RideService._internal();
  static RideService get instance => _instance;

  final String baseUrl = ApiConfig.baseUrl;

  RideService._internal();

  // Créer une nouvelle demande de trajet
  Future<RideModel> createRide({
    required String riderId,
    required Map<String, dynamic> pickupLocation,
    required Map<String, dynamic> destination,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rides'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'riderId': riderId,
          'pickupLocation': pickupLocation,
          'destination': destination,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Récupérer les détails de la demande de trajet créée
        final rideResponse = await http.get(
          Uri.parse('$baseUrl/api/rides/${data['rideId']}'),
          headers: {'Content-Type': 'application/json'},
        );

        if (rideResponse.statusCode == 200) {
          final rideData = jsonDecode(rideResponse.body);
          return RideModel.fromJson(rideData['ride']);
        } else {
          throw Exception(
              'Échec de la récupération des détails de la demande de trajet');
        }
      } else {
        throw Exception(
            'Échec de la création de la demande de trajet: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la création de la demande de trajet: $e');
      rethrow;
    }
  }

  // Récupérer toutes les demandes de trajet
  Future<List<RideModel>> getRides({
    String? status,
    String? driverId,
    String? riderId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (driverId != null) queryParams['driverId'] = driverId;
      if (riderId != null) queryParams['riderId'] = riderId;

      final uri =
          Uri.parse('$baseUrl/api/rides').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rides = data['rides'] as List;
        return rides.map((ride) => RideModel.fromJson(ride)).toList();
      } else {
        throw Exception(
            'Échec de la récupération des demandes de trajet: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des demandes de trajet: $e');
      rethrow;
    }
  }

  // Récupérer une demande de trajet par son ID
  Future<RideModel> getRideById(String rideId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/rides/$rideId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RideModel.fromJson(data['ride']);
      } else {
        throw Exception(
            'Échec de la récupération de la demande de trajet: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la demande de trajet: $e');
      rethrow;
    }
  }

  // Mettre à jour une demande de trajet
  Future<RideModel> updateRide(
      String rideId, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/rides/$rideId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RideModel.fromJson(data['ride']);
      } else {
        throw Exception(
            'Échec de la mise à jour de la demande de trajet: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la demande de trajet: $e');
      rethrow;
    }
  }

  // Accepter une demande de trajet
  Future<RideModel> acceptRide(String rideId, String driverId) async {
    return updateRide(rideId, {
      'status': 'accepted',
      'driverId': driverId,
    });
  }

  // Démarrer une demande de trajet
  Future<RideModel> startRide(String rideId) async {
    return updateRide(rideId, {
      'status': 'in_progress',
    });
  }

  // Terminer une demande de trajet
  Future<RideModel> completeRide(String rideId) async {
    return updateRide(rideId, {
      'status': 'completed',
    });
  }

  // Get route points between two locations with multiple fallback options
  Future<List<latlong.LatLng>> getRoutePoints(
      double startLat, double startLng, double endLat, double endLng) async {
    try {
      // First try our backend API
      try {
        final url = Uri.parse(
            '$baseUrl/api/route?startLat=$startLat&startLng=$startLng&endLat=$endLat&endLng=$endLng');

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['success'] == true && data['points'] != null) {
            final List<dynamic> points = data['points'];
            final routePoints = points
                .map((point) => latlong.LatLng(point['lat'], point['lng']))
                .toList();

            if (routePoints.length > 2) {
              debugPrint('Got ${routePoints.length} points from backend API');
              return routePoints;
            }
          }
        }
      } catch (backendError) {
        debugPrint('Backend route API error: $backendError');
      }

      // If backend fails, try OSRM API directly
      try {
        final String osrmUrl =
            'https://router.project-osrm.org/route/v1/driving/'
            '$startLng,$startLat;$endLng,$endLat'
            '?overview=full&geometries=polyline';

        final osrmResponse = await http.get(Uri.parse(osrmUrl));

        if (osrmResponse.statusCode == 200) {
          final osrmData = jsonDecode(osrmResponse.body);

          if (osrmData['code'] == 'Ok' &&
              osrmData['routes'] != null &&
              osrmData['routes'].isNotEmpty) {
            final route = osrmData['routes'][0];
            final encodedPolyline = route['geometry'];
            final points = _decodePolyline(encodedPolyline);

            if (points.length > 2) {
              debugPrint('Got ${points.length} points from OSRM API');
              return points;
            }
          }
        }
      } catch (osrmError) {
        debugPrint('OSRM API error: $osrmError');
      }

      // If OSRM fails, try to generate intermediate points
      try {
        return _generateIntermediatePoints(
            latlong.LatLng(startLat, startLng),
            latlong.LatLng(endLat, endLng),
            10 // Generate 10 intermediate points
            );
      } catch (generationError) {
        debugPrint('Error generating intermediate points: $generationError');
      }

      // Final fallback: direct line
      debugPrint('Using direct line as last resort');
      return [
        latlong.LatLng(startLat, startLng),
        latlong.LatLng(endLat, endLng),
      ];
    } catch (e) {
      debugPrint('Error getting route points: $e');
      // Return direct line as fallback
      return [
        latlong.LatLng(startLat, startLng),
        latlong.LatLng(endLat, endLng),
      ];
    }
  }

  // Decode a polyline string into a list of LatLng points
  List<latlong.LatLng> _decodePolyline(String encoded) {
    List<latlong.LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(latlong.LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  // Generate intermediate points between start and end
  List<latlong.LatLng> _generateIntermediatePoints(
      latlong.LatLng start, latlong.LatLng end, int count) {
    List<latlong.LatLng> points = [start];

    // Add some randomness to make it look more like a real route
    final random = Random();
    final distance = _calculateDistance(
        start.latitude, start.longitude, end.latitude, end.longitude);

    // Maximum deviation as a fraction of the total distance
    final maxDeviation = distance * 0.2; // 20% of the total distance

    for (int i = 1; i <= count; i++) {
      // Calculate position along the line
      final fraction = i / (count + 1);
      final lat = start.latitude + (end.latitude - start.latitude) * fraction;
      final lng =
          start.longitude + (end.longitude - start.longitude) * fraction;

      // Add some randomness perpendicular to the line
      final angle = _calculateHeading(
              start.latitude, start.longitude, end.latitude, end.longitude) +
          90; // Perpendicular to the heading

      // Random deviation, stronger in the middle of the route
      final deviation =
          maxDeviation * sin(pi * fraction) * (random.nextDouble() * 2 - 1);

      // Calculate the new point with deviation
      final newLat = lat +
          deviation *
              sin(angle * pi / 180) /
              111111; // approx meters to degrees
      final newLng = lng +
          deviation * cos(angle * pi / 180) / (111111 * cos(lat * pi / 180));

      points.add(latlong.LatLng(newLat, newLng));
    }

    points.add(end);
    debugPrint('Generated ${points.length} intermediate points');
    return points;
  }

  // Calculate distance between two points in kilometers
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // Calculate heading between two points in degrees
  double _calculateHeading(double lat1, double lon1, double lat2, double lon2) {
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double y = sin(dLon) * cos(_degreesToRadians(lat2));
    final double x = cos(_degreesToRadians(lat1)) *
            sin(_degreesToRadians(lat2)) -
        sin(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) * cos(dLon);
    final double heading = atan2(y, x);

    return (heading * 180 / pi + 360) % 360; // Convert to degrees
  }

  // Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
