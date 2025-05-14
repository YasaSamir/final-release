import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:project/core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../models/driver_model.dart';
// import '../../core/config/api_config.dart';

class DriverService {
  static final String baseUrl = ApiConfig.baseUrl;
  static final _api = ApiService.instance;

  static Future<List<DriverModel>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    double radius = 5.0, // Default 5km radius
  }) async {
    try {
      final response = await _api.get(
        '/drivers/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
        },
      );

      return (response['drivers'] as List)
          .map((driver) => DriverModel.fromJson(driver))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch nearby drivers: $e');
    }
  }

  static Future<void> requestRide({
    required String driverId,
    required String pickupLocation,
    required String destinationLocation,
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    try {
      // تصحيح نوع البيانات المرسلة
      final data = {
        'driverId': driverId,
        'pickupLocation': pickupLocation,
        'destinationLocation': destinationLocation,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'destinationLat': destinationLat,
        'destinationLng': destinationLng,
      };

      await _api.post(
        '/rides/request',
        ApiConfig.getHeaders(),
        data: data,
      );
    } catch (e) {
      throw Exception('Failed to request ride: $e');
    }
  }

  Future<DriverModel> getDriverDetails(String driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/drivers/$driverId'),
        headers: {
          'Content-Type': 'application/json',
          // Add authorization header if needed
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DriverModel.fromJson(data);
      } else {
        throw Exception('Failed to fetch driver details');
      }
    } catch (e) {
      throw Exception('Error getting driver details: $e');
    }
  }

  Future<void> cancelRide(String rideId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          // Add authorization header if needed
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel ride');
      }
    } catch (e) {
      throw Exception('Error canceling ride: $e');
    }
  }

  Future<void> rateDriver({
    required String rideId,
    required String driverId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/rate'),
        headers: {
          'Content-Type': 'application/json',
          // Add authorization header if needed
        },
        body: json.encode({
          'driver_id': driverId,
          'rating': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to rate driver');
      }
    } catch (e) {
      throw Exception('Error rating driver: $e');
    }
  }
}
