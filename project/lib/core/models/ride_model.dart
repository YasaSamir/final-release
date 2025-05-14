class RideModel {
  final String id;
  final Map<String, dynamic> pickupLocation;
  final Map<String, dynamic> destination;
  final String status;
  final String? driverId;
  final String riderId;
  final DateTime timestamp;
  final List<String>? sharedRiders;

  RideModel({
    required this.id,
    required this.pickupLocation,
    required this.destination,
    required this.status,
    this.driverId,
    required this.riderId,
    required this.timestamp,
    this.sharedRiders,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    List<String>? sharedRiders;
    if (json['sharedRiders'] != null) {
      sharedRiders = List<String>.from(json['sharedRiders']);
    }

    return RideModel(
      id: json['id'],
      pickupLocation: json['pickupLocation'],
      destination: json['destination'],
      status: json['status'],
      driverId: json['driverId'],
      riderId: json['riderId'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      sharedRiders: sharedRiders,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pickupLocation': pickupLocation,
      'destination': destination,
      'status': status,
      'driverId': driverId,
      'riderId': riderId,
      'timestamp': timestamp.toIso8601String(),
      'sharedRiders': sharedRiders,
    };
  }
}
