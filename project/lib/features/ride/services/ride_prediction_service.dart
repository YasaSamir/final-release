import '../../../core/services/api_service.dart';
import '../../../core/config/api_config.dart';

class RidePredictionService {
  static final RidePredictionService _instance =
      RidePredictionService._internal();
  static RidePredictionService get instance => _instance;

  final _apiService = ApiService.instance;

  RidePredictionService._internal();

  Future<Map<String, dynamic>> predictRideSharing({
    required double originalDistance,
    required double distanceAfterAddingRider,
    required double newRiderDistance,
  }) async {
    try {
      // تصحيح أسماء المفاتيح لتتطابق مع ما يتوقعه الخادم
      final data = {
        'originalDistance': originalDistance,
        'distanceAfterAddingRider': distanceAfterAddingRider,
        'newRiderDistance': newRiderDistance,
      };

      final response = await _apiService.post(
        '/api/predict-ride-sharing',
        ApiConfig.getHeaders(),
        data: data,
      );

      return response;
    } catch (e) {
      print('Error predicting ride sharing: $e');
      rethrow;
    }
  }
}
