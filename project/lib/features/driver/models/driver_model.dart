class DriverModel {
  final String id;
  final String name;
  final String? profileImage;
  final String vehicleType;
  final String vehicleNumber;
  final double rating;
  final int totalTrips;
  final bool isAvailable;
  final double latitude;
  final double longitude;
  final double? distance;

  DriverModel({
    required this.id,
    required this.name,
    this.profileImage,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.rating,
    required this.totalTrips,
    required this.isAvailable,
    required this.latitude,
    required this.longitude,
    this.distance,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      profileImage: json['profileImage'],
      vehicleType: json['vehicleType'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalTrips: json['totalTrips'] ?? 0,
      isAvailable: json['isAvailable'] ?? false,
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      distance: json['distance'] != null
          ? (json['distance'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profileImage': profileImage,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'rating': rating,
      'totalTrips': totalTrips,
      'isAvailable': isAvailable,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
    };
  }
}
