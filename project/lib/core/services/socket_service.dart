import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';

class RideRequest {
  final String id;
  final Map<String, dynamic> pickupLocation;
  final Map<String, dynamic> destination;
  final String
      status; // 'pending', 'accepted', 'rejected', 'in_progress', 'completed'
  final String? driverId;
  final String riderId;
  final List<String>? sharedRiders;

  RideRequest({
    required this.id,
    required this.pickupLocation,
    required this.destination,
    required this.status,
    this.driverId,
    required this.riderId,
    this.sharedRiders,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    List<String>? sharedRiders;
    if (json['sharedRiders'] != null) {
      sharedRiders = List<String>.from(json['sharedRiders']);
    }

    return RideRequest(
      id: json['id'],
      pickupLocation: json['pickupLocation'],
      destination: json['destination'],
      status: json['status'],
      driverId: json['driverId'],
      riderId: json['riderId'],
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
      'sharedRiders': sharedRiders,
    };
  }
}

class SharingRequest {
  final String rideId;
  final String newRiderId;
  final Map<String, dynamic> newPickupLocation;
  final Map<String, dynamic> newDestination;
  final Map<String, dynamic> prediction;

  SharingRequest({
    required this.rideId,
    required this.newRiderId,
    required this.newPickupLocation,
    required this.newDestination,
    required this.prediction,
  });

  factory SharingRequest.fromJson(Map<String, dynamic> json) {
    return SharingRequest(
      rideId: json['rideId'],
      newRiderId: json['newRiderId'],
      newPickupLocation: json['newPickupLocation'],
      newDestination: json['newDestination'],
      prediction: json['prediction'],
    );
  }
}

class SocketService {
  static final SocketService _instance = SocketService._internal();
  static SocketService get instance => _instance;

  io.Socket? socket;
  bool _isConnected = false;

  // Stream controllers for different events
  final _rideCreatedController = StreamController<String>.broadcast();
  final _rideAcceptedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _rideRejectedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _rideStartedController = StreamController<String>.broadcast();
  final _rideCompletedController = StreamController<String>.broadcast();
  final _newRideRequestController = StreamController<RideRequest>.broadcast();
  final _driverLocationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _rideSharingRequestController =
      StreamController<SharingRequest>.broadcast();
  final _rideSharingResponseController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Streams
  Stream<String> get onRideCreated => _rideCreatedController.stream;
  Stream<Map<String, dynamic>> get onRideAccepted =>
      _rideAcceptedController.stream;
  Stream<Map<String, dynamic>> get onRideRejected =>
      _rideRejectedController.stream;
  Stream<String> get onRideStarted => _rideStartedController.stream;
  Stream<String> get onRideCompleted => _rideCompletedController.stream;
  Stream<RideRequest> get onNewRideRequest => _newRideRequestController.stream;
  Stream<Map<String, dynamic>> get onDriverLocationUpdate =>
      _driverLocationController.stream;
  Stream<SharingRequest> get onRideSharingRequest =>
      _rideSharingRequestController.stream;
  Stream<Map<String, dynamic>> get onRideSharingResponse =>
      _rideSharingResponseController.stream;

  SocketService._internal() {
    _initializeSocket();
  }

  void _initializeSocket() {
    socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build(),
    );

    socket!.onConnect((_) {
      debugPrint('Socket Connected');
      _isConnected = true;
    });

    socket!.onDisconnect((_) {
      debugPrint('Socket Disconnected');
      _isConnected = false;
    });

    socket!.onConnectError((error) {
      debugPrint('Socket Connect Error: $error');
    });

    socket!.onError((error) {
      debugPrint('Socket Error: $error');
    });

    socket!.onReconnect((_) {
      debugPrint('Socket Reconnected');
    });

    // Set up event listeners
    socket!.on('ride:created', (data) {
      _rideCreatedController.add(data['rideId']);
    });

    socket!.on('ride:accepted', (data) {
      _rideAcceptedController.add(data);
    });

    socket!.on('ride:rejected', (data) {
      _rideRejectedController.add(data);
    });

    socket!.on('ride:started', (data) {
      _rideStartedController.add(data['rideId']);
    });

    socket!.on('ride:completed', (data) {
      _rideCompletedController.add(data['rideId']);
    });

    socket!.on('ride:new_request', (data) {
      _newRideRequestController.add(RideRequest.fromJson(data));
    });

    socket!.on('driver:location_update', (data) {
      _driverLocationController.add(data);
    });

    socket!.on('ride:sharing_request', (data) {
      _rideSharingRequestController.add(SharingRequest.fromJson(data));
    });

    socket!.on('ride:sharing_accepted', (data) {
      _rideSharingResponseController.add({
        'rideId': data['rideId'],
        'accepted': true,
      });
    });

    socket!.on('ride:sharing_rejected', (data) {
      _rideSharingResponseController.add({
        'rideId': data['rideId'],
        'accepted': false,
      });
    });
  }

  void initialize() {
    if (socket == null) {
      socket = io.io(
        ApiConfig.baseUrl, // تأكد من إضافة هذا في ApiConfig
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _initializeSocket();
    }
  }

  void connect() {
    initialize();
    if (!_isConnected) {
      socket?.connect();
      socket?.onConnect((_) {
        _isConnected = true;
        debugPrint('Socket connected: ${socket?.id}');
      });

      socket?.onConnectError((error) {
        debugPrint('Socket connection error: $error');
      });

      socket?.onDisconnect((_) {
        _isConnected = false;
        debugPrint('Socket disconnected');
      });
    }
  }

  void setDriverAvailable(String driverId) {
    if (_isConnected) {
      socket?.emit('driver:available', driverId);
    }
  }

  void setDriverUnavailable(String driverId) {
    if (_isConnected) {
      socket?.emit('driver:unavailable', driverId);
    }
  }

  void requestRide({
    required String riderId,
    required Map<String, dynamic> pickupLocation,
    required Map<String, dynamic> destination,
  }) {
    if (_isConnected) {
      socket?.emit('ride:request', {
        'riderId': riderId,
        'pickupLocation': pickupLocation,
        'destination': destination,
      });
    }
  }

  void acceptRide({
    required String rideId,
    required String driverId,
  }) {
    if (_isConnected) {
      // تخزين معرف السائق للاستخدام في تحديثات الموقع
      setDriverId(driverId);

      socket?.emit('ride:accept', {
        'rideId': rideId,
        'driverId': driverId,
      });

      debugPrint('Driver $driverId accepted ride $rideId');
    } else {
      debugPrint('Socket not connected. Cannot accept ride.');
    }
  }

  void rejectRide({
    required String rideId,
    required String driverId,
  }) {
    if (_isConnected) {
      socket?.emit('ride:reject', {
        'rideId': rideId,
        'driverId': driverId,
      });
    }
  }

  void startRide({
    required String rideId,
  }) {
    if (_isConnected) {
      socket?.emit('ride:start', {
        'rideId': rideId,
      });
    }
  }

  void completeRide({
    required String rideId,
    required String driverId,
  }) {
    if (_isConnected) {
      socket?.emit('ride:complete', {
        'rideId': rideId,
        'driverId': driverId,
      });
    }
  }

  // تخزين معرف السائق مؤقتًا
  String? _driverId;

  // تعيين معرف السائق
  void setDriverId(String driverId) {
    _driverId = driverId;
  }

  // الحصول على معرف السائق
  String? getDriverId() {
    return _driverId;
  }

  /// تحديث موقع السائق مع معلومات إضافية للمسار الفعلي - تحسين للتزامن بين العملاء
  void updateDriverLocation({
    required String rideId,
    required Map<String, dynamic> location,
    Map<String, dynamic>? routeInfo,
    double? speed,
    double? heading,
    double? accuracy,
    int? estimatedArrivalTime,
    double? distanceRemaining,
    double? progress,
    String? driverName,
    String? vehicleInfo,
  }) {
    if (_isConnected) {
      if (_driverId == null) {
        debugPrint('Error: Driver ID is null. Cannot update location.');
        return;
      }

      // إنشاء حزمة بيانات محسنة لإرسالها مع معلومات إضافية للتزامن
      final Map<String, dynamic> locationData = {
        'rideId': rideId,
        'driverId': _driverId,
        'location': location,
        'timestamp': DateTime.now().toIso8601String(),
        'priority': 'high', // إعطاء أولوية عالية لتحديثات الموقع أثناء الرحلة
        'syncId':
            'sync_${DateTime.now().millisecondsSinceEpoch}', // معرف فريد للتزامن
      };

      // إضافة المعلومات الإضافية إذا كانت متوفرة
      if (routeInfo != null) {
        locationData['routeInfo'] = routeInfo;
      }
      if (speed != null) {
        locationData['speed'] = speed;
      }
      if (heading != null) {
        locationData['heading'] = heading;
      }
      if (accuracy != null) {
        locationData['accuracy'] = accuracy;
      }
      if (estimatedArrivalTime != null) {
        locationData['eta'] = estimatedArrivalTime;
      }
      if (distanceRemaining != null) {
        locationData['distanceRemaining'] = distanceRemaining;
      }
      if (progress != null) {
        locationData['progress'] = progress;
      }

      // إضافة معلومات السائق والمركبة للتزامن بين العملاء
      if (driverName != null) {
        locationData['driverName'] = driverName;
      }
      if (vehicleInfo != null) {
        locationData['vehicleInfo'] = vehicleInfo;
      }

      // إرسال البيانات
      socket?.emit('driver:location', locationData);

      debugPrint(
          'Sent enhanced driver location update for ride $rideId: $location');
    } else {
      debugPrint('Socket not connected. Cannot update driver location.');
    }
  }

  /// إرسال موقع السائق لجميع المستخدمين مع معلومات إضافية
  void broadcastDriverLocation({
    required Map<String, dynamic> location,
    bool isAvailable = true,
    Map<String, dynamic>? routeInfo,
    double? speed,
    double? heading,
    String? vehicleType,
    double? rating,
    int? lastActivity,
  }) {
    if (_isConnected) {
      if (_driverId == null) {
        debugPrint('Error: Driver ID is null. Cannot broadcast location.');
        return;
      }

      // إنشاء حزمة بيانات محسنة لإرسالها
      final Map<String, dynamic> broadcastData = {
        'driverId': _driverId,
        'location': location,
        'isAvailable': isAvailable,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // إضافة المعلومات الإضافية إذا كانت متوفرة
      if (routeInfo != null) {
        broadcastData['routeInfo'] = routeInfo;
      }
      if (speed != null) {
        broadcastData['speed'] = speed;
      }
      if (heading != null) {
        broadcastData['heading'] = heading;
      }
      if (vehicleType != null) {
        broadcastData['vehicleType'] = vehicleType;
      }
      if (rating != null) {
        broadcastData['rating'] = rating;
      }
      if (lastActivity != null) {
        broadcastData['lastActivity'] = lastActivity;
      }

      // إرسال البيانات
      socket?.emit('driver:broadcast_location', broadcastData);

      debugPrint('Broadcast enhanced driver location to all users: $location');
    } else {
      debugPrint('Socket not connected. Cannot broadcast driver location.');
    }
  }

  void disconnect() {
    socket?.disconnect();
    _isConnected = false;
  }

  // دالة مساعدة للاستماع للأحداث
  StreamSubscription<dynamic> listenTo(
      String event, Function(dynamic) callback) {
    final controller = StreamController<dynamic>.broadcast();

    socket?.on(event, (data) {
      controller.add(data);
    });

    return controller.stream.listen(callback);
  }

  /// إرسال تحديث المسار الفعلي لجميع العملاء
  void sendActualRouteUpdate({
    required String rideId,
    required List<Map<String, dynamic>> routePoints,
    required Map<String, dynamic> currentLocation,
    double? heading,
    double? speed,
    double? progress,
    String? driverName,
    String? vehicleInfo,
  }) {
    if (_isConnected) {
      if (_driverId == null) {
        debugPrint('Error: Driver ID is null. Cannot send route update.');
        return;
      }

      final Map<String, dynamic> routeData = {
        'rideId': rideId,
        'driverId': _driverId,
        'actualRoute': routePoints,
        'currentLocation': currentLocation,
        'timestamp': DateTime.now().toIso8601String(),
        'syncId': 'sync_${DateTime.now().millisecondsSinceEpoch}',
      };

      if (heading != null) {
        routeData['heading'] = heading;
      }
      if (speed != null) {
        routeData['speed'] = speed;
      }
      if (progress != null) {
        routeData['progress'] = progress;
      }
      if (driverName != null) {
        routeData['driverName'] = driverName;
      }
      if (vehicleInfo != null) {
        routeData['vehicleInfo'] = vehicleInfo;
      }

      socket?.emit('ride:actual_route_update', routeData);
      debugPrint(
          'Sent actual route update for ride $rideId with ${routePoints.length} points');
    } else {
      debugPrint('Socket not connected. Cannot send route update.');
    }
  }

  /// إرسال تحديث المسار المخطط له لجميع العملاء
  void sendPlannedRouteUpdate({
    required String rideId,
    required Map<String, dynamic> route,
  }) {
    if (_isConnected) {
      if (_driverId == null) {
        debugPrint(
            'Error: Driver ID is null. Cannot send planned route update.');
        return;
      }

      final Map<String, dynamic> routeData = {
        'rideId': rideId,
        'driverId': _driverId,
        'route': route,
        'timestamp': DateTime.now().toIso8601String(),
        'syncId': 'sync_${DateTime.now().millisecondsSinceEpoch}',
      };

      socket?.emit('ride:route_update', routeData);
      debugPrint('Sent planned route update for ride $rideId');
    } else {
      debugPrint('Socket not connected. Cannot send planned route update.');
    }
  }

  /// إرسال تحديث المسار التفصيلي لجميع العملاء
  void sendDetailedRouteUpdate({
    required String rideId,
    required Map<String, dynamic> route,
    double? distance,
    double? duration,
  }) {
    if (_isConnected) {
      if (_driverId == null) {
        debugPrint(
            'Error: Driver ID is null. Cannot send detailed route update.');
        return;
      }

      final Map<String, dynamic> routeData = {
        'rideId': rideId,
        'driverId': _driverId,
        'route': route,
        'timestamp': DateTime.now().toIso8601String(),
        'syncId': 'sync_${DateTime.now().millisecondsSinceEpoch}',
      };

      if (distance != null) {
        routeData['distance'] = distance;
      }
      if (duration != null) {
        routeData['duration'] = duration;
      }

      socket?.emit('ride:detailed_route_update', routeData);
      debugPrint('Sent detailed route update for ride $rideId');
    } else {
      debugPrint('Socket not connected. Cannot send detailed route update.');
    }
  }

  void dispose() {
    _rideCreatedController.close();
    _rideAcceptedController.close();
    _rideRejectedController.close();
    _rideStartedController.close();
    _rideCompletedController.close();
    _newRideRequestController.close();
    _driverLocationController.close();
    _rideSharingRequestController.close();
    _rideSharingResponseController.close();
    disconnect();
  }
}
