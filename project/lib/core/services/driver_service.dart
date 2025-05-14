import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../features/driver/models/driver_model.dart';

class DriverService {
  static final DriverService _instance = DriverService._internal();
  static DriverService get instance => _instance;

  final String baseUrl = ApiConfig.baseUrl;

  DriverService._internal();

  // Créer un nouveau conducteur
  Future<String> createDriver({
    required String name,
    required String vehicleType,
    required String vehicleNumber,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/drivers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'vehicleType': vehicleType,
          'vehicleNumber': vehicleNumber,
          'latitude': latitude ?? 0.0,
          'longitude': longitude ?? 0.0,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['driverId'];
      } else {
        throw Exception('Échec de la création du conducteur: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la création du conducteur: $e');
      rethrow;
    }
  }

  // Récupérer tous les conducteurs
  Future<List<DriverModel>> getDrivers({bool? isAvailable}) async {
    try {
      final queryParams = <String, String>{};
      if (isAvailable != null) queryParams['isAvailable'] = isAvailable.toString();

      final uri = Uri.parse('$baseUrl/api/drivers').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final drivers = data['drivers'] as List;
        return drivers.map((driver) => DriverModel.fromJson(driver)).toList();
      } else {
        throw Exception('Échec de la récupération des conducteurs: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des conducteurs: $e');
      rethrow;
    }
  }

  // Récupérer les conducteurs disponibles
  Future<List<DriverModel>> getAvailableDrivers() async {
    return getDrivers(isAvailable: true);
  }

  // Récupérer les demandes de trajet pour un conducteur
  Future<List<Map<String, dynamic>>> getDriverRides(String driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/rides?driverId=$driverId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['rides']);
      } else {
        throw Exception('Échec de la récupération des demandes de trajet: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des demandes de trajet: $e');
      rethrow;
    }
  }

  // Récupérer les demandes de trajet en attente
  Future<List<Map<String, dynamic>>> getPendingRides() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/rides?status=pending'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['rides']);
      } else {
        throw Exception('Échec de la récupération des demandes de trajet: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des demandes de trajet: $e');
      rethrow;
    }
  }
}
