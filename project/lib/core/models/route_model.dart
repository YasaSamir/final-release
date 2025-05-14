class RouteModel {
  final String startAddress;
  final String endAddress;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final double distance; // in kilometers
  final double duration; // in seconds
  final List<Map<String, double>> polylinePoints;

  RouteModel({
    required this.startAddress,
    required this.endAddress,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.distance,
    required this.duration,
    required this.polylinePoints,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      startAddress: json['startAddress'],
      endAddress: json['endAddress'],
      startLat: json['startLat'],
      startLng: json['startLng'],
      endLat: json['endLat'],
      endLng: json['endLng'],
      distance: json['distance'],
      duration: json['duration'],
      polylinePoints: List<Map<String, double>>.from(
        json['polylinePoints']?.map((point) => {
              'lat': point['lat'],
              'lng': point['lng'],
            }) ??
            [],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startAddress': startAddress,
      'endAddress': endAddress,
      'startLat': startLat,
      'startLng': startLng,
      'endLat': endLat,
      'endLng': endLng,
      'distance': distance,
      'duration': duration,
      'polylinePoints': polylinePoints,
    };
  }
}