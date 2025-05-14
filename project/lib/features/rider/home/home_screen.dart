import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:project/core/services/socket_service.dart';
import 'package:project/core/services/ride_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  latlong.LatLng? _currentPosition;
  final latlong.LatLng _defaultPosition = latlong.LatLng(37.7749, -122.4194);
  List<Marker> _markers = [];
  List<latlong.LatLng> _polylinePoints = [];
  bool _isMapInitialized = false;
  latlong.LatLng? _carPosition;
  List<latlong.LatLng> _routePoints = [];
  late TextEditingController toController;
  bool _rideCompleted = false;
  String _selectedRole = 'transport';
  final RideService _rideService = RideService.instance;

  // Variables para la información de la ruta en tiempo real
  double? _rideProgress;
  double? _rideDistanceRemaining;
  Duration? _rideEstimatedTime;
  double? _rideSpeed;
  bool _isRideInfoPanelVisible = false;
  String? _currentDriverId;
  String? _currentDriverName;
  String? _currentVehicleInfo;

  // قائمة لتخزين الاشتراكات النشطة للتنظيف عند التخلص من الشاشة
  final List<Function()> _activeSubscriptions = [];

  @override
  void initState() {
    super.initState();
    toController = TextEditingController();
    _getCurrentLocation();
    _isMapInitialized = true;

    // Connect to Socket.IO server
    SocketService.instance.connect();

    // Listen for ride sharing opportunities
    _listenForRideSharingOpportunities();

    // Listen for available drivers
    _listenForAvailableDrivers();
  }

  // قائمة لتخزين السائقين المتاحين
  final List<Map<String, dynamic>> _availableDrivers = [];

  // الاستماع للسائقين المتاحين
  void _listenForAvailableDrivers() {
    // استخدام الدالة المساعدة للاستماع للأحداث
    final driverLocationSubscription = SocketService.instance.listenTo(
      'driver:broadcast_location',
      (data) {
        if (!mounted) return;

        debugPrint('Received driver location broadcast: $data');

        final driverId = data['driverId'];
        final location = data['location'];
        final isAvailable = data['isAvailable'] ?? false;

        // تحديث قائمة السائقين المتاحين
        setState(() {
          // البحث عن السائق في القائمة
          final driverIndex = _availableDrivers
              .indexWhere((driver) => driver['driverId'] == driverId);

          if (driverIndex >= 0) {
            // تحديث موقع السائق الموجود
            if (isAvailable) {
              _availableDrivers[driverIndex]['location'] = location;
              _availableDrivers[driverIndex]['lastUpdate'] =
                  DateTime.now().millisecondsSinceEpoch;
            } else {
              // إزالة السائق إذا لم يعد متاحًا
              _availableDrivers.removeAt(driverIndex);
            }
          } else if (isAvailable) {
            // إضافة سائق جديد
            _availableDrivers.add({
              'driverId': driverId,
              'location': location,
              'lastUpdate': DateTime.now().millisecondsSinceEpoch,
            });
          }

          // تحديث علامات السائقين على الخريطة
          _updateDriverMarkers();
        });
      },
    );

    // تسجيل دالة التنظيف للاستدعاء لاحقًا
    _activeSubscriptions.add(() {
      driverLocationSubscription.cancel();
    });

    // إزالة السائقين غير النشطين كل 30 ثانية
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      const expiryTime = 60 * 1000; // 60 seconds in milliseconds

      setState(() {
        _availableDrivers
            .removeWhere((driver) => now - driver['lastUpdate'] > expiryTime);
        _updateDriverMarkers();
      });
    });
  }

  // تحديث علامات السائقين على الخريطة
  void _updateDriverMarkers() {
    // إزالة علامات السائقين الحالية
    _markers.removeWhere((marker) {
      final widget = marker.builder(context);
      return widget is Icon &&
          (widget.icon == Icons.local_taxi ||
              widget.icon == Icons.directions_car);
    });

    // إضافة علامات للسائقين المتاحين
    for (final driver in _availableDrivers) {
      final location = driver['location'];
      final driverPosition = latlong.LatLng(location['lat'], location['lng']);
      final isAvailable = driver['isAvailable'] ?? true;

      _markers.add(
        Marker(
          point: driverPosition,
          width: 60,
          height: 60,
          builder: (context) => GestureDetector(
            onTap: () => _showDriverInfo(driver),
            child: Stack(
              children: [
                // خلفية دائرية مع تأثير ظل
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAvailable ? Colors.green : Colors.orange,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.local_taxi,
                    color: isAvailable ? Colors.green : Colors.orange,
                    size: 30,
                  ),
                ),

                // مؤشر الحالة
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green : Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // تحديث علامة السائق مع التدوير حسب الاتجاه
  void _updateDriverMarker(latlong.LatLng position, double heading) {
    setState(() {
      // إزالة علامة السائق السابقة
      _markers.removeWhere((m) {
        final widget = m.builder(context);
        if (widget is Icon) {
          return widget.icon == Icons.directions_car;
        } else if (widget is Transform) {
          final child = widget.child;
          if (child is Icon) {
            return child.icon == Icons.directions_car;
          } else if (child is Container) {
            final containerChild = child.child;
            if (containerChild is Icon) {
              return containerChild.icon == Icons.directions_car;
            }
          }
        }
        return false;
      });

      // إضافة علامة السائق الجديدة مع تدوير حسب الاتجاه
      _markers.add(
        Marker(
          point: position,
          builder: (context) => Transform.rotate(
            angle: heading * (pi / 180), // تحويل من درجات إلى راديان
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.withValues(
                    red: 0,
                    green: 122,
                    blue: 255,
                    alpha: 204), // 0.8 * 255 = 204
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                        red: 0, green: 0, blue: 0, alpha: 51), // 0.2 * 255 = 51
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.directions_car,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      );
    });
  }

  // عرض معلومات السائق
  void _showDriverInfo(Map<String, dynamic> driver) {
    if (!mounted) return;

    final isAvailable = driver['isAvailable'] ?? true;
    final driverId = driver['driverId'];
    final lastUpdate = driver['lastUpdate'];
    final location = driver['location'];

    // حساب المسافة بين الموقع الحالي وموقع السائق
    double distance = 0;
    if (_currentPosition != null && location != null) {
      distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        location['lat'],
        location['lng'],
      );
    }

    // حساب الوقت المقدر للوصول (بافتراض سرعة 30 كم/ساعة)
    final estimatedTime = (distance / 30 * 60).round(); // بالدقائق

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.local_taxi,
              color: isAvailable ? Colors.green : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              isAvailable ? 'سائق متاح' : 'سائق مشغول',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAvailable
                      ? Colors.green.withAlpha(100)
                      : Colors.orange.withAlpha(100),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isAvailable ? Icons.check_circle : Icons.access_time,
                        color: isAvailable ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAvailable
                            ? 'هذا السائق متاح حاليًا لقبول رحلات جديدة'
                            : 'هذا السائق مشغول حاليًا في رحلة أخرى',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      const Text('معرف السائق:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          driverId,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.update, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      const Text('آخر تحديث:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(lastUpdate),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  if (distance > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.directions_car,
                            color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        const Text('المسافة:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Text(
                          '${distance.toStringAsFixed(1)} كم',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        const Text('الوقت المقدر:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Text(
                          '$estimatedTime دقيقة',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('إغلاق'),
          ),
          if (isAvailable)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // طلب رحلة من هذا السائق
                _requestRideFromDriver(driver);
              },
              icon: const Icon(Icons.directions_car),
              label: const Text('طلب رحلة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // حساب المسافة بين نقطتين باستخدام صيغة هافرساين (بالكيلومتر)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // نصف قطر الأرض بالكيلومتر

    // تحويل الإحداثيات من درجات إلى راديان
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    // صيغة هافرساين
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // تحويل من درجات إلى راديان
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// حساب الاتجاه (بالدرجات) بين نقطتين
  double _calculateHeading(double lat1, double lon1, double lat2, double lon2) {
    // تحويل الإحداثيات من درجات إلى راديان
    final phi1 = lat1 * (pi / 180);
    final phi2 = lat2 * (pi / 180);
    final lambda1 = lon1 * (pi / 180);
    final lambda2 = lon2 * (pi / 180);

    // حساب الاتجاه
    final y = sin(lambda2 - lambda1) * cos(phi2);
    final x =
        cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(lambda2 - lambda1);
    final theta = atan2(y, x);

    // تحويل من راديان إلى درجات
    var heading = (theta * (180 / pi) + 360) % 360;

    return heading;
  }

  // تنسيق الطابع الزمني
  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'منذ ${difference.inSeconds} ثانية';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'منذ ${difference.inHours} ساعة';
    }
  }

  // طلب رحلة من سائق محدد
  void _requestRideFromDriver(Map<String, dynamic> driver) async {
    if (_currentPosition == null || _markers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد وجهتك أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (driver['driverId'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('معرف السائق غير صالح'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!(SocketService.instance.socket?.connected ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل الاتصال بالخادم'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      _showLoadingDialog('جاري إرسال طلب الرحلة...');

      final riderId = await _getUserId();

      SocketService.instance.socket?.emit('ride:direct_request', {
        'riderId': riderId,
        'driverId': driver['driverId'],
        'pickupLocation': {
          'lat': _currentPosition!.latitude,
          'lng': _currentPosition!.longitude,
        },
        'destination': {
          'lat': _markers.first.point.latitude,
          'lng': _markers.first.point.longitude,
        },
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال طلب الرحلة إلى السائق'),
            backgroundColor: Colors.green,
          ),
        );

        _showWaitingForDriverPopup(context);
        _setupRideListeners(null);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال طلب الرحلة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // الاستماع لفرص مشاركة الرحلات
  void _listenForRideSharingOpportunities() {
    // استخدام الدالة المساعدة للاستماع للأحداث
    final sharingOpportunitySubscription = SocketService.instance.listenTo(
      'ride:sharing_opportunity',
      (data) {
        if (!mounted) return;

        debugPrint('Received ride sharing opportunity: $data');

        // عرض إشعار بفرصة مشاركة الرحلة
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('هناك رحلة متاحة للمشاركة بالقرب منك!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'عرض',
                onPressed: () {
                  // عرض تفاصيل فرصة المشاركة
                  _showRideSharingOpportunityDialog(data);
                },
              ),
            ),
          );
        }
      },
    );

    // تسجيل دالة التنظيف للاستدعاء لاحقًا
    _activeSubscriptions.add(() {
      sharingOpportunitySubscription.cancel();
    });
  }

  // عرض مربع حوار فرصة مشاركة الرحلة
  void _showRideSharingOpportunityDialog(dynamic data) {
    if (!mounted) return;

    final activeRideId = data['activeRideId'];
    final pickupLocation = data['pickupLocation'];
    final destination = data['destination'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.share, color: Colors.green),
            SizedBox(width: 8),
            Text('فرصة مشاركة رحلة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'هناك رحلة متاحة للمشاركة بالقرب منك. هل ترغب في مشاركة هذه الرحلة؟'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('نقطة الالتقاط:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                      '${pickupLocation['lat'].toStringAsFixed(4)}, ${pickupLocation['lng'].toStringAsFixed(4)}'),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.location_pin, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('الوجهة:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                      '${destination['lat'].toStringAsFixed(4)}, ${destination['lng'].toStringAsFixed(4)}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // طلب مشاركة الرحلة
              _requestRideSharing(activeRideId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('طلب المشاركة'),
          ),
        ],
      ),
    );
  }

  // طلب مشاركة الرحلة
  void _requestRideSharing(String activeRideId) async {
    if (!mounted) return;

    try {
      // عرض مؤشر التحميل
      _showLoadingDialog('جاري إرسال طلب مشاركة الرحلة...');

      // الحصول على معرف المستخدم
      final riderId = await _getUserId();

      // Get current location
      if (_currentPosition == null) {
        // Close loading indicator
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Current location not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // إرسال طلب مشاركة الرحلة
      SocketService.instance.socket?.emit('ride:sharing_request', {
        'rideId': activeRideId,
        'newRiderId': riderId,
        'newPickupLocation': {
          'lat': _currentPosition!.latitude,
          'lng': _currentPosition!.longitude,
        },
        'newDestination': _markers.isNotEmpty
            ? {
                'lat': _markers.first.point.latitude,
                'lng': _markers.first.point.longitude,
              }
            : {
                'lat': _currentPosition!.latitude + 0.01,
                'lng': _currentPosition!.longitude + 0.01,
              },
      });

      // استخدام الدالة المساعدة للاستماع للأحداث
      late final StreamSubscription responseSubscription;

      responseSubscription = SocketService.instance.listenTo(
        'ride:sharing_requested',
        (response) {
          // إغلاق مؤشر التحميل
          if (mounted) {
            try {
              Navigator.of(context, rootNavigator: true).pop();
            } catch (_) {}
          }

          if (response['success'] == true) {
            // عرض رسالة نجاح
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إرسال طلب مشاركة الرحلة بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );

              // عرض تفاصيل التنبؤ
              _showPredictionDetailsDialog(response['prediction']);
            }
          } else {
            // عرض رسالة خطأ
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'فشل في إرسال طلب مشاركة الرحلة: ${response['message']}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }

          // إلغاء الاشتراك بعد تلقي الرد
          responseSubscription.cancel();
        },
      );

      // تسجيل دالة التنظيف للاستدعاء لاحقًا
      _activeSubscriptions.add(() {
        responseSubscription.cancel();
      });
    } catch (e) {
      debugPrint('خطأ في طلب مشاركة الرحلة: $e');

      // إغلاق مؤشر التحميل
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في طلب مشاركة الرحلة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // الحصول على معرف المستخدم
  Future<String> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId != null && userId.isNotEmpty) {
        return userId;
      } else {
        // إنشاء معرف مستخدم جديد إذا لم يكن موجودًا
        final newUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('user_id', newUserId);
        return newUserId;
      }
    } catch (e) {
      debugPrint('خطأ في الحصول على معرف المستخدم: $e');
      // إرجاع معرف افتراضي في حالة الخطأ
      return 'user_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Show loading indicator
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  // عرض تفاصيل التنبؤ
  void _showPredictionDetailsDialog(dynamic prediction) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue),
            SizedBox(width: 8),
            Text('تحليل الذكاء الاصطناعي'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تحليل الذكاء الاصطناعي لطلب مشاركة الرحلة:'),
              const SizedBox(height: 16),

              // تفاصيل التنبؤ
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          prediction['shouldAddRider']
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: prediction['shouldAddRider']
                              ? Colors.green
                              : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          prediction['shouldAddRider']
                              ? 'مشاركة الرحلة مفيدة'
                              : 'مشاركة الرحلة غير مفيدة',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'درجة الثقة: ${(prediction['score'] * 100).toStringAsFixed(1)}%'),
                    Text('كفاءة المشاركة: ${prediction['efficiency']}%'),

                    // تفاصيل التكلفة إذا كانت متوفرة
                    if (prediction['fareDetails'] != null) ...[
                      const SizedBox(height: 16),
                      const Text('تفاصيل التكلفة:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                          'التوفير الإجمالي: ${prediction['fareDetails']['totalSavings']} ج.م'),
                      Text(
                          'توفير الراكب الأصلي: ${prediction['fareDetails']['originalRider']['savings']} ج.م'),
                      Text(
                          'توفير الراكب الجديد: ${prediction['fareDetails']['newRider']['savings']} ج.م'),
                    ],

                    // تفاصيل التأثير البيئي إذا كانت متوفرة
                    if (prediction['environmentalImpact'] != null) ...[
                      const SizedBox(height: 16),
                      const Text('التأثير البيئي:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                          'تقليل انبعاثات CO2: ${prediction['environmentalImpact']['co2Reduction']} كجم'),
                      Text(
                          'توفير الوقود: ${prediction['environmentalImpact']['fuelSaved']} لتر'),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // تنظيف وحدات التحكم
    toController.dispose();

    // تنظيف جميع الاشتراكات النشطة
    for (final disposeFunction in _activeSubscriptions) {
      disposeFunction();
    }
    _activeSubscriptions.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const Drawer(),
      body: _buildFlutterMapPage(),
    );
  }

  Future<bool> _checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      debugPrint('Location permissions permanently denied');
      return false;
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions denied');
        return false;
      }
    }
    return true;
  }

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
    debugPrint('Decoded ${points.length} points from polyline');
    return points;
  }

  // فك تشفير خط Google المشفر
  List<latlong.LatLng> _decodeGooglePolyline(String encoded) {
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

  // توليد نقاط وسيطة بين نقطتين
  List<latlong.LatLng> _generateIntermediatePoints(
      latlong.LatLng start, latlong.LatLng end, int count) {
    List<latlong.LatLng> points = [start];

    // إضافة نقاط وسيطة
    for (int i = 1; i < count; i++) {
      double fraction = i / count;
      double lat = start.latitude + (end.latitude - start.latitude) * fraction;
      double lng =
          start.longitude + (end.longitude - start.longitude) * fraction;

      // إضافة بعض العشوائية للمسار ليبدو أكثر واقعية
      if (i > 1 && i < count - 1) {
        // إضافة انحراف عشوائي صغير (±0.0005 درجة)
        double randomLat = (Random().nextDouble() - 0.5) * 0.001;
        double randomLng = (Random().nextDouble() - 0.5) * 0.001;
        lat += randomLat;
        lng += randomLng;
      }

      points.add(latlong.LatLng(lat, lng));
    }

    points.add(end);
    return points;
  }

  Future<void> _drawRouteAndAnimate(
      latlong.LatLng start, latlong.LatLng end) async {
    if (!_isMapInitialized) {
      debugPrint('Map not initialized yet');
      return;
    }

    // أولاً نرسم مسار بسيط وسريع للعرض الفوري
    _drawSimpleRoute(start, end);

    // ثم نحاول الحصول على مسار تفصيلي في الخلفية
    Future.microtask(() async {
      try {
        await _drawDetailedRoute(start, end);
      } catch (e) {
        debugPrint('خطأ أثناء رسم المسار التفصيلي: $e');
      }
    });
  }

  // رسم مسار بسيط وسريع (نفس الطريقة المستخدمة في شاشة السائق)
  void _drawSimpleRoute(latlong.LatLng start, latlong.LatLng end) {
    try {
      setState(() {
        // إزالة علامة السيارة السابقة
        _markers.removeWhere((m) {
          final widget = m.builder(context);
          return widget is Icon && widget.icon == Icons.directions_car;
        });

        // التأكد من وجود علامات البداية والنهاية
        bool hasStartMarker = false;
        bool hasEndMarker = false;

        for (var marker in _markers) {
          if (marker.point.latitude == start.latitude &&
              marker.point.longitude == start.longitude) {
            hasStartMarker = true;
          }
          if (marker.point.latitude == end.latitude &&
              marker.point.longitude == end.longitude) {
            hasEndMarker = true;
          }
        }

        if (!hasStartMarker) {
          _markers.add(
            Marker(
              point: start,
              builder: (context) => const Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 30,
              ),
            ),
          );
        }

        if (!hasEndMarker) {
          _markers.add(
            Marker(
              point: end,
              builder: (context) => const Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 40,
              ),
            ),
          );
        }

        // إضافة علامة السيارة
        _markers.add(
          Marker(
            point: start,
            builder: (context) => const Icon(
              Icons.directions_car,
              color: Colors.blue,
              size: 40,
            ),
          ),
        );

        // رسم خط مستقيم بين البداية والنهاية
        _polylinePoints = [start, end];
      });

      // تحريك الخريطة لتظهر المسار كاملاً
      _mapController.move(
        latlong.LatLng(
          (start.latitude + end.latitude) / 2,
          (start.longitude + end.longitude) / 2,
        ),
        13.0,
      );
    } catch (e) {
      debugPrint('خطأ أثناء رسم المسار البسيط: $e');
    }
  }

  // رسم مسار تفصيلي مع تحسينات للدقة والموثوقية
  Future<void> _drawDetailedRoute(
      latlong.LatLng start, latlong.LatLng end) async {
    if (!mounted) return;

    try {
      // عرض مؤشر التحميل
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('جاري حساب المسار الفعلي...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // تسجيل معلومات التصحيح
      debugPrint('بدء رسم المسار التفصيلي من $start إلى $end');

      setState(() {
        // إزالة علامة السيارة السابقة
        _markers.removeWhere((m) {
          final widget = m.builder(context);
          return widget is Icon &&
              (widget.icon == Icons.directions_car ||
                  widget.icon == Icons.car_crash);
        });

        // التأكد من وجود علامات البداية والنهاية
        bool hasStartMarker = false;
        bool hasEndMarker = false;

        for (var marker in _markers) {
          if (marker.point.latitude == start.latitude &&
              marker.point.longitude == start.longitude) {
            hasStartMarker = true;
          }
          if (marker.point.latitude == end.latitude &&
              marker.point.longitude == end.longitude) {
            hasEndMarker = true;
          }
        }

        if (!hasStartMarker) {
          _markers.add(
            Marker(
              point: start,
              builder: (context) => Container(
                decoration: BoxDecoration(
                  color: Colors.blue
                      .withValues(red: 0, green: 122, blue: 255, alpha: 180),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          );
        }

        if (!hasEndMarker) {
          _markers.add(
            Marker(
              point: end,
              builder: (context) => const Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 40,
              ),
            ),
          );
        }
      });

      debugPrint('Drawing route from $start to $end');

      // نستخدم عدة طرق للحصول على المسار الأفضل
      List<latlong.LatLng>? routePoints;

      // أولاً: نحاول الحصول على المسار من خدمة المسارات الداخلية
      try {
        final points = await _rideService.getRoutePoints(
            start.latitude, start.longitude, end.latitude, end.longitude);

        if (points.isNotEmpty && points.length > 2) {
          debugPrint(
              'تم الحصول على المسار من خدمة المسارات الداخلية: ${points.length} نقطة');
          routePoints = points;
        }
      } catch (serviceError) {
        debugPrint(
            'خطأ في الحصول على المسار من الخدمة الداخلية: $serviceError');
      }

      // ثانياً: إذا فشلت الطريقة الأولى، نستخدم OSRM API
      if (routePoints == null) {
        try {
          // نستخدم OSRM API مع خيار الخطوات التفصيلية والتعليقات
          final String url = 'https://router.project-osrm.org/route/v1/driving/'
              '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
              '?overview=full&geometries=polyline&steps=true&annotations=true';

          debugPrint('OSRM API URL: $url');

          final response = await http.get(Uri.parse(url));
          debugPrint('OSRM API Response status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            debugPrint('OSRM API Response code: ${data['code']}');

            if (data['code'] == 'Ok' &&
                data['routes'] != null &&
                data['routes'].isNotEmpty) {
              final route = data['routes'][0];
              final encodedPolyline = route['geometry'];

              // التحقق من وجود البيانات المشفرة
              if (encodedPolyline != null && encodedPolyline.isNotEmpty) {
                final points = _decodePolyline(encodedPolyline);

                if (points.isNotEmpty && points.length > 2) {
                  debugPrint(
                      'تم الحصول على المسار من OSRM API: ${points.length} نقطة');

                  // الحصول على معلومات إضافية عن المسار
                  final distance = route['distance']; // بالأمتار
                  final duration = route['duration']; // بالثواني

                  // تنسيق المسافة والمدة
                  final formattedDistance =
                      (distance / 1000).toStringAsFixed(1); // كم
                  final formattedDuration = (duration / 60).round(); // دقائق

                  // عرض معلومات المسار
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'المسار: $formattedDistance كم، $formattedDuration دقيقة'),
                        backgroundColor: Colors.blue,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }

                  // استخراج معلومات الخطوات للحصول على مسار أكثر تفصيلاً
                  final List<dynamic> legs = route['legs'] ?? [];
                  if (legs.isNotEmpty) {
                    final List<latlong.LatLng> detailedPoints = [];

                    for (var leg in legs) {
                      final steps = leg['steps'] ?? [];
                      for (var step in steps) {
                        if (step['geometry'] != null) {
                          final stepPoints = _decodePolyline(step['geometry']);
                          detailedPoints.addAll(stepPoints);
                        }
                      }
                    }

                    if (detailedPoints.isNotEmpty) {
                      debugPrint(
                          'تم استخراج ${detailedPoints.length} نقطة تفصيلية من الخطوات');
                      routePoints = detailedPoints;
                    } else {
                      routePoints = points;
                    }
                  } else {
                    routePoints = points;
                  }
                }
              } else {
                debugPrint(
                    'لم يتم العثور على بيانات مشفرة للمسار في استجابة OSRM API');
              }
            } else {
              debugPrint(
                  'خطأ في استجابة OSRM API: ${data['code'] ?? 'غير معروف'}');
            }
          } else {
            debugPrint(
                'فشل طلب OSRM API: ${response.statusCode} - ${response.reasonPhrase}');
          }
        } catch (apiError) {
          debugPrint('خطأ في الحصول على المسار من OSRM API: $apiError');
        }
      }

      // ثالثاً: إذا فشلت الطريقتان السابقتان، نستخدم Google Directions API
      if (routePoints == null) {
        try {
          const String apiKey =
              'AIzaSyA6QI378BHt9eqBbiJKtqWHTSAZxcSwN6M'; // استخدم مفتاح API الخاص بك
          final String url =
              'https://maps.googleapis.com/maps/api/directions/json'
              '?origin=${start.latitude},${start.longitude}'
              '&destination=${end.latitude},${end.longitude}'
              '&mode=driving'
              '&key=$apiKey';

          final response = await http.get(Uri.parse(url));
          debugPrint(
              'Google Directions API Response status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['status'] == 'OK' &&
                data['routes'] != null &&
                data['routes'].isNotEmpty) {
              final route = data['routes'][0];
              final legs = route['legs'];

              if (legs != null && legs.isNotEmpty) {
                final List<latlong.LatLng> points = [];

                // استخراج النقاط من الخطوات
                for (var leg in legs) {
                  final steps = leg['steps'];
                  if (steps != null) {
                    for (var step in steps) {
                      final startLocation = step['start_location'];
                      final endLocation = step['end_location'];

                      if (startLocation != null) {
                        points.add(latlong.LatLng(
                            startLocation['lat'], startLocation['lng']));
                      }

                      if (endLocation != null) {
                        points.add(latlong.LatLng(
                            endLocation['lat'], endLocation['lng']));
                      }

                      // استخراج النقاط من الخط المشفر إذا كان متاحاً
                      if (step['polyline'] != null &&
                          step['polyline']['points'] != null) {
                        final polyPoints =
                            _decodeGooglePolyline(step['polyline']['points']);
                        if (polyPoints.isNotEmpty) {
                          points.addAll(polyPoints);
                        }
                      }
                    }
                  }
                }

                if (points.isNotEmpty) {
                  debugPrint(
                      'تم الحصول على المسار من Google Directions API: ${points.length} نقطة');

                  // الحصول على معلومات إضافية عن المسار
                  final distance = legs[0]['distance']['value']; // بالأمتار
                  final duration = legs[0]['duration']['value']; // بالثواني

                  // تنسيق المسافة والمدة
                  final formattedDistance =
                      (distance / 1000).toStringAsFixed(1); // كم
                  final formattedDuration = (duration / 60).round(); // دقائق

                  // عرض معلومات المسار
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'المسار: $formattedDistance كم، $formattedDuration دقيقة'),
                        backgroundColor: Colors.blue,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }

                  routePoints = points;
                }
              }
            }
          }
        } catch (googleApiError) {
          debugPrint(
              'خطأ في الحصول على المسار من Google Directions API: $googleApiError');
        }
      }

      // أخيراً: إذا فشلت جميع الطرق، نستخدم خط مستقيم بين النقطتين
      if (routePoints == null || routePoints.isEmpty) {
        debugPrint('استخدام خط مستقيم كحل أخير');
        routePoints = _generateIntermediatePoints(start, end, 10);
      }

      // معالجة نقاط المسار وتحديث الخريطة
      if (mounted && routePoints.isNotEmpty) {
        _processRoutePoints(routePoints);
      }
    } catch (e) {
      debugPrint('Error drawing route: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في رسم المسار: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // معالجة نقاط المسار وتحديث الخريطة
  void _processRoutePoints(List<latlong.LatLng> points) {
    if (!mounted || points.isEmpty) return;

    debugPrint('معالجة ${points.length} نقطة للمسار');

    setState(() {
      _routePoints = points;
      _polylinePoints = points;

      // إضافة علامة للسيارة في بداية المسار
      _carPosition = points.first;

      // إزالة أي خطوط مسار سابقة
      _markers.removeWhere((m) {
        final widget = m.builder(context);
        return widget is Icon &&
            (widget.icon == Icons.directions_car ||
                widget.icon == Icons.car_crash);
      });

      // إضافة علامة السيارة
      _markers.add(
        Marker(
          point: _carPosition!,
          builder: (context) => Container(
            decoration: BoxDecoration(
              color: Colors.blue
                  .withValues(red: 0, green: 122, blue: 255, alpha: 220),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(red: 0, green: 0, blue: 0, alpha: 51),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.directions_car,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      );
    });

    // عرض رسالة تأكيد
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم رسم المسار بنجاح (${points.length} نقطة)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // حساب حدود المسار لضبط الخريطة
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    // Añadir padding a los límites
    const paddingValue = 0.01; // Aproximadamente 1km
    minLat -= paddingValue;
    maxLat += paddingValue;
    minLng -= paddingValue;
    maxLng += paddingValue;

    // Centrar el mapa para mostrar toda la ruta
    _mapController.move(
      latlong.LatLng(
        (minLat + maxLat) / 2,
        (minLng + maxLng) / 2,
      ),
      13.0, // Nivel de zoom para mostrar toda la ruta
    );

    // Iniciar la animación del coche
    _startCarAnimation();
  }

  // Versión simplificada y más estable de la animación del coche
  void _startCarAnimation() {
    if (_routePoints.isEmpty) return;

    // Iniciar con el primer punto
    _updateCarPosition(0);

    // Usar un temporizador simple en lugar de un Isolate
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Obtener el índice actual
      int currentIndex = _carAnimationIndex + 1;

      // Verificar si hemos llegado al final
      if (currentIndex >= _routePoints.length) {
        setState(() {
          _rideCompleted = true;
        });
        timer.cancel();
        return;
      }

      // Actualizar la posición del coche
      _updateCarPosition(currentIndex);
    });
  }

  // Índice para seguir la posición actual en la animación
  int _carAnimationIndex = 0;

  // Actualizar la posición del coche en el mapa con mejoras
  void _updateCarPosition(int index) {
    if (index < 0 || index >= _routePoints.length || !mounted) return;

    setState(() {
      _carAnimationIndex = index;
      _carPosition = _routePoints[index];

      // Calcular la dirección (heading) para rotar el coche
      double heading = 0;
      if (index > 0) {
        final prevPoint = _routePoints[index - 1];
        heading = _calculateHeading(
          prevPoint.latitude,
          prevPoint.longitude,
          _carPosition!.latitude,
          _carPosition!.longitude,
        );
      }

      // Eliminar TODOS los marcadores de coches para evitar duplicados
      _markers.removeWhere((m) {
        final widget = m.builder(context);
        // Verificar si es un icono de coche o un contenedor que contiene un icono de coche
        if (widget is Icon) {
          return widget.icon == Icons.directions_car ||
              widget.icon == Icons.car_crash;
        } else if (widget is Container) {
          // Intentar verificar si el contenedor tiene un icono de coche
          final child = widget.child;
          if (child is Padding && child.child is Icon) {
            final icon = child.child as Icon;
            return icon.icon == Icons.directions_car ||
                icon.icon == Icons.car_crash;
          }
        } else if (widget is Transform) {
          // Verificar si es un Transform que contiene un icono de coche
          final child = widget.child;
          if (child is Container && child.child is Padding) {
            final padding = child.child as Padding;
            if (padding.child is Icon) {
              final icon = padding.child as Icon;
              return icon.icon == Icons.directions_car ||
                  icon.icon == Icons.car_crash;
            }
          } else if (child is Icon) {
            return child.icon == Icons.directions_car ||
                child.icon == Icons.car_crash;
          }
        }
        return false;
      });

      // Añadir el nuevo marcador del coche con rotación según la dirección
      _markers.add(
        Marker(
          point: _carPosition!,
          builder: (context) => Transform.rotate(
            angle: heading * (pi / 180), // Convertir de grados a radianes
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue
                    .withValues(red: 0, green: 122, blue: 255, alpha: 220),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      );

      // No movemos el mapa automáticamente para evitar mareos al usuario
      // Solo actualizamos la posición del coche
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services disabled');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يرجى تفعيل خدمات الموقع'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      bool hasPermission = await _checkAndRequestPermission();
      if (!hasPermission) {
        debugPrint('Location permissions denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم رفض إذن الموقع'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // عرض مؤشر التحميل
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('جاري تحديد موقعك...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      setState(() {
        _currentPosition =
            latlong.LatLng(position.latitude, position.longitude);

        // إزالة علامة الموقع الحالي السابقة
        _markers.removeWhere((marker) {
          final widget = marker.builder(context);
          return widget is Icon &&
              (widget.icon == Icons.location_on ||
                  widget.icon == Icons.my_location);
        });

        // إضافة علامة الموقع الحالي الجديدة
        _markers.add(
          Marker(
            point: _currentPosition!,
            builder: (context) => Container(
              decoration: BoxDecoration(
                color: Colors.blue
                    .withValues(red: 0, green: 122, blue: 255, alpha: 180),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        );

        debugPrint('Current location: $_currentPosition');
      });

      if (_isMapInitialized) {
        _mapController.move(_currentPosition!, 15.0);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث موقعك بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديد الموقع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onMapTap(latlong.LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String address =
            "${placemark.name ?? ''}, ${placemark.locality ?? ''}, ${placemark.country ?? ''}";
        setState(() {
          _markers.clear();
          // Add marker for current position
          if (_currentPosition != null) {
            _markers.add(
              Marker(
                point: _currentPosition!,
                builder: (context) =>
                    const Icon(Icons.my_location, color: Colors.blue, size: 30),
              ),
            );
          }
          // Add marker for destination
          _markers.add(
            Marker(
              point: position,
              builder: (context) =>
                  const Icon(Icons.location_pin, color: Colors.red, size: 40),
            ),
          );
        });

        // لا نرسم المسار تلقائياً عند تحديد الوجهة
        // سنرسم المسار فقط عندما يقبل السائق الرحلة

        if (mounted) {
          _showAddressPopup(context, toAddress: address, toPosition: position);
        }
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reverse geocoding: $e')),
        );
      }
    }
  }

  Future<void> _searchLocation(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        latlong.LatLng searchedPosition =
            latlong.LatLng(location.latitude, location.longitude);

        if (_isMapInitialized) {
          _mapController.move(searchedPosition, 14.0);
        }

        setState(() {
          _markers.clear();
          _markers.add(
            Marker(
              point: searchedPosition,
              builder: (context) =>
                  const Icon(Icons.location_pin, color: Colors.blue, size: 40),
            ),
          );
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not found')),
        );
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching location: $e')),
        );
      }
    }
  }

  void _updateMarkers(List<Marker> newMarkers) {
    setState(() => _markers = newMarkers);
  }

  void _refreshMap() {
    setState(() {
      _markers.clear();
      _polylinePoints.clear();
      _routePoints.clear();
      _carPosition = null;
      _rideCompleted = false;
      toController.clear();
      if (_currentPosition != null) {
        _markers.add(
          Marker(
            point: _currentPosition!,
            builder: (context) =>
                const Icon(Icons.location_pin, color: Colors.blue, size: 40),
          ),
        );
        if (_isMapInitialized) {
          _mapController.move(_currentPosition!, 14.0);
        }
      }
    });
  }

  Widget _buildFlutterMapPage() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _currentPosition ?? _defaultPosition,
            zoom: 16.0,
            onTap: (tapPosition, point) => _onMapTap(point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _polylinePoints,
                  color: Colors.blue,
                  strokeWidth: 4.0,
                ),
              ],
            ),
            MarkerLayer(markers: _markers),
          ],
        ),
        Positioned(
          top: 40,
          left: 16,
          child: OutlinedButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            child: const Icon(Icons.menu, size: 28, color: Colors.black),
          ),
        ),
        Positioned(
          top: 40,
          right: 16,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const NotificationPage(),
              ),
            ),
            child: const Icon(
              Icons.notifications_none,
              size: 28,
              color: Colors.black,
            ),
          ),
        ),
        Positioned(
          top: 100,
          left: 20,
          right: 20,
          child: MapSearchBar(
            onSearch: _searchLocation,
            onMarkersUpdated: _updateMarkers,
          ),
        ),
        Positioned(
          bottom: 80,
          left: 20,
          right: 20,
          child: _buildTransportSelector(),
        ),
        Positioned(
          bottom: 140,
          left: 20,
          right: 20,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: toController,
                  decoration: const InputDecoration(
                    fillColor: Colors.white70,
                    filled: true,
                    prefixIcon: Icon(Icons.location_on_outlined),
                    labelText: 'Where would you go?',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() {}),
                  onSubmitted: (value) {
                    if (toController.text.isNotEmpty) {
                      _searchLocation(toController.text);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white70,
                child: IconButton(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(
                    Icons.location_on,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_rideCompleted)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _refreshMap,
              child: const Text(
                "Refresh and Start Over",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        // Panel de información de la ruta en tiempo real
        if (_isRideInfoPanelVisible)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! > 300) {
                  _hideRideInfoPanel();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(red: 0, green: 0, blue: 0, alpha: 25),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'معلومات الرحلة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _hideRideInfoPanel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_rideProgress != null)
                      _buildProgressBar(_rideProgress!),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.location_on,
                      title: 'المسافة المتبقية',
                      value: _rideDistanceRemaining != null
                          ? '${_rideDistanceRemaining!.toStringAsFixed(1)} كم'
                          : 'غير معروف',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.access_time,
                      title: 'الوقت المقدر للوصول',
                      value: _rideEstimatedTime != null
                          ? '${_rideEstimatedTime!.inMinutes} دقيقة'
                          : 'غير معروف',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.speed,
                      title: 'السرعة الحالية',
                      value: _rideSpeed != null
                          ? '${_rideSpeed!.toStringAsFixed(0)} كم/ساعة'
                          : 'غير معروف',
                    ),
                    if (_currentDriverName != null ||
                        _currentVehicleInfo != null)
                      const Divider(height: 32),
                    if (_currentDriverName != null)
                      _buildInfoRow(
                        icon: Icons.person,
                        title: 'السائق',
                        value: _currentDriverName!,
                      ),
                    if (_currentVehicleInfo != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildInfoRow(
                          icon: Icons.directions_car,
                          title: 'المركبة',
                          value: _currentVehicleInfo!,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.phone),
                            label: const Text('اتصال'),
                            onPressed: _contactDriver,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.cancel),
                            label: const Text('إلغاء الرحلة'),
                            onPressed: _cancelCurrentRide,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Construir la barra de progreso
  Widget _buildProgressBar(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('تقدم الرحلة'),
            Text('${progress.toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  /// Construir una fila de información
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(value),
      ],
    );
  }

  void _showAddressPopup(
    BuildContext context, {
    String? toAddress,
    latlong.LatLng? toPosition,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AddressPopup(
        currentPosition: _currentPosition,
        onSearch: _searchLocation,
        onRouteConfirmed: _drawRouteAndAnimate,
        onSendRideRequest: _sendRideRequest,
        initialToAddress: toAddress,
        initialToPosition: toPosition,
      ),
    );
  }

  Widget _buildTransportSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white70,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          _roleButton('Transport', 'transport'),
          _roleButton('Delivery', 'delivery'),
        ],
      ),
    );
  }

  Expanded _roleButton(String text, String role) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedRole = role);
          _showAddressPopup(
            context,
            toAddress: toController.text.isNotEmpty ? toController.text : null,
            toPosition: _markers.isNotEmpty ? _markers.first.point : null,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isSelected ? Colors.green : Colors.white70,
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendRideRequest(latlong.LatLng destination) async {
    try {
      // Check if widget is still mounted before proceeding
      if (!mounted) return;

      // Show waiting popup
      _showWaitingForDriverPopup(context);

      // Get user ID from local storage or state management
      final userId = await _getUserId();

      // لا نرسم المسار تلقائياً عند تحديد الوجهة
      // سنرسم المسار فقط عندما يقبل السائق الرحلة

      // Créer la demande de trajet via l'API
      try {
        final ride = await _rideService.createRide(
          riderId: userId,
          pickupLocation: {
            'lat': _currentPosition?.latitude ?? 0,
            'lng': _currentPosition?.longitude ?? 0,
          },
          destination: {
            'lat': destination.latitude,
            'lng': destination.longitude,
          },
        );

        debugPrint('Ride created successfully with ID: ${ride.id}');

        // Envoyer également via Socket pour la notification en temps réel
        SocketService.instance.requestRide(
          riderId: userId,
          pickupLocation: {
            'lat': _currentPosition?.latitude ?? 0,
            'lng': _currentPosition?.longitude ?? 0,
          },
          destination: {
            'lat': destination.latitude,
            'lng': destination.longitude,
          },
        );

        // Configurer les écouteurs pour les réponses
        _setupRideListeners(ride.id);

        // No automatic ride start - wait for driver to accept and start the ride
      } catch (apiError) {
        debugPrint('Error creating ride via API: $apiError');

        // Fallback to Socket.IO only if API fails
        SocketService.instance.requestRide(
          riderId: userId,
          pickupLocation: {
            'lat': _currentPosition?.latitude ?? 0,
            'lng': _currentPosition?.longitude ?? 0,
          },
          destination: {
            'lat': destination.latitude,
            'lng': destination.longitude,
          },
        );

        // Configurer les écouteurs pour les réponses
        _setupRideListeners(null);

        // No automatic ride start - wait for driver to accept and start the ride
      }
    } catch (e) {
      // Check if widget is still mounted before using context
      if (mounted) {
        Navigator.pop(context); // Close waiting popup
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إرسال طلب الرحلة: $e')),
        );
      }
    }
  }

  void _setupRideListeners(String? rideId) {
    // الاستماع لقبول الرحلة
    final acceptSubscription =
        SocketService.instance.onRideAccepted.listen((data) {
      if (mounted) {
        // إغلاق نافذة الانتظار
        try {
          Navigator.pop(context);
        } catch (e) {
          debugPrint('Error closing dialog: $e');
        }

        // عرض رسالة تأكيد
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم قبول طلب الرحلة! جاري تحضير الرحلة...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // معالجة قبول الرحلة وبدء الرحلة
        _handleRideAccepted(data);
      }
    });

    // الاستماع لقبول وبدء الرحلة معاً (الميزة الجديدة)
    final acceptAndStartSubscription = SocketService.instance.listenTo(
      'ride:accept_and_start',
      (data) {
        if (!mounted) return;

        final receivedRideId = data['rideId'];
        if (rideId != null && receivedRideId != rideId) {
          // تجاهل الإشعارات التي لا تخص هذه الرحلة
          return;
        }

        debugPrint('تم استلام إشعار قبول وبدء الرحلة معاً: $data');

        // إغلاق نافذة الانتظار إذا كانت مفتوحة
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (e) {
          debugPrint('Error closing dialog: $e');
        }

        // عرض رسالة تأكيد
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم قبول الرحلة وبدأت! السائق في الطريق إليك...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // استخراج معلومات الرحلة
        final driverId = data['driverId'];
        final driverName = data['driverName'] ?? 'سائق';
        final vehicleInfo = data['vehicleInfo'] ?? 'سيارة';

        // تحديث معلومات السائق
        setState(() {
          _currentDriverId = driverId;
          _currentDriverName = driverName;
          _currentVehicleInfo = vehicleInfo;
          _isRideInfoPanelVisible = true; // إظهار لوحة معلومات الرحلة
        });

        // الحصول على المواقع
        final pickupLocation = latlong.LatLng(
          data['pickupLocation']['lat'],
          data['pickupLocation']['lng'],
        );

        final destination = latlong.LatLng(
          data['destination']['lat'],
          data['destination']['lng'],
        );

        // الحصول على موقع السائق الحالي
        final driverPosition = data['currentLocation'] != null
            ? latlong.LatLng(
                data['currentLocation']['lat'],
                data['currentLocation']['lng'],
              )
            : latlong.LatLng(
                pickupLocation.latitude - 0.005,
                pickupLocation.longitude - 0.005,
              );

        // بدء الرحلة فوراً
        _startRide(
          driverPosition: driverPosition,
          pickupLocation: pickupLocation,
          destination: destination,
          rideId: receivedRideId,
          driverId: driverId,
        );

        // الاستماع لتحديثات موقع السائق
        _listenForDriverLocationUpdates(driverId);
      },
    );

    // Añadir las suscripciones a la lista para limpiar después
    _activeSubscriptions.add(() {
      acceptSubscription.cancel();
    });

    _activeSubscriptions.add(() {
      acceptAndStartSubscription.cancel();
    });

    // الاستماع لتحديثات المسار البسيط
    final routeUpdateSubscription = SocketService.instance.listenTo(
      'ride:route_update',
      (data) {
        if (!mounted) return;

        final receivedRideId = data['rideId'];
        if (rideId != null && receivedRideId != rideId) {
          // تجاهل التحديثات التي لا تخص هذه الرحلة
          return;
        }

        debugPrint('تم استلام تحديث للمسار: $data');

        try {
          final route = data['route'];
          if (route != null && route['points'] != null) {
            final List<dynamic> points = route['points'];
            final List<latlong.LatLng> routePoints = points.map((point) {
              return latlong.LatLng(
                double.parse(point['lat'].toString()),
                double.parse(point['lng'].toString()),
              );
            }).toList();

            // تحديث المسار على الخريطة
            if (routePoints.length >= 2) {
              setState(() {
                _polylinePoints = routePoints;
              });
            }
          }
        } catch (e) {
          debugPrint('خطأ في معالجة تحديث المسار: $e');
        }
      },
    );

    // Añadir la suscripción a la lista para limpiar después
    _activeSubscriptions.add(() {
      routeUpdateSubscription.cancel();
    });

    // الاستماع لتحديثات المسار التفصيلي
    final detailedRouteUpdateSubscription = SocketService.instance.listenTo(
      'ride:detailed_route_update',
      (data) {
        if (!mounted) return;

        final receivedRideId = data['rideId'];
        if (rideId != null && receivedRideId != rideId) {
          // تجاهل التحديثات التي لا تخص هذه الرحلة
          return;
        }

        debugPrint('تم استلام تحديث للمسار التفصيلي: $data');

        try {
          final route = data['route'];
          if (route != null && route['points'] != null) {
            final List<dynamic> points = route['points'];
            final List<latlong.LatLng> routePoints = points.map((point) {
              return latlong.LatLng(
                double.parse(point['lat'].toString()),
                double.parse(point['lng'].toString()),
              );
            }).toList();

            // تحديث المسار التفصيلي على الخريطة
            if (routePoints.length >= 2) {
              setState(() {
                _polylinePoints = routePoints;
                _routePoints = routePoints;
              });
            }
          }
        } catch (e) {
          debugPrint('خطأ في معالجة تحديث المسار التفصيلي: $e');
        }
      },
    );

    // Añadir la suscripción a la lista para limpiar después
    _activeSubscriptions.add(() {
      detailedRouteUpdateSubscription.cancel();
    });

    // الاستماع لتحديثات المسار الفعلي
    final actualRouteUpdateSubscription = SocketService.instance.listenTo(
      'ride:actual_route_update',
      (data) {
        if (!mounted) return;

        final receivedRideId = data['rideId'];
        if (rideId != null && receivedRideId != rideId) {
          // تجاهل التحديثات التي لا تخص هذه الرحلة
          return;
        }

        debugPrint('تم استلام تحديث للمسار الفعلي: $data');

        try {
          final actualRoute = data['actualRoute'];
          if (actualRoute != null) {
            final List<dynamic> points = actualRoute;
            final List<latlong.LatLng> routePoints = points.map((point) {
              return latlong.LatLng(
                double.parse(point['lat'].toString()),
                double.parse(point['lng'].toString()),
              );
            }).toList();

            // تحديث المسار الفعلي على الخريطة
            if (routePoints.length >= 2) {
              setState(() {
                _polylinePoints = routePoints;
                _routePoints = routePoints;
              });

              // تحديث موقع السيارة
              if (data['currentLocation'] != null) {
                final lat = data['currentLocation']['lat'];
                final lng = data['currentLocation']['lng'];
                final heading = data['heading'] ?? 0.0;

                _updateDriverMarker(
                  latlong.LatLng(
                    double.parse(lat.toString()),
                    double.parse(lng.toString()),
                  ),
                  heading,
                );
              }

              // تحديث معلومات الرحلة
              _updateRideInfo(
                progress:
                    data['progress'] != null ? data['progress'] / 100 : null,
                speed: data['speed'],
              );
            }
          }
        } catch (e) {
          debugPrint('خطأ في معالجة تحديث المسار الفعلي: $e');
        }
      },
    );

    // Añadir la suscripción a la lista para limpiar después
    _activeSubscriptions.add(() {
      actualRouteUpdateSubscription.cancel();
    });

    // الاستماع لبدء الرحلة في الوقت الفعلي
    final startedRealtimeSubscription = SocketService.instance.listenTo(
      'ride:started_realtime',
      (data) {
        if (!mounted) return;

        final receivedRideId = data['rideId'];
        if (rideId != null && receivedRideId != rideId) {
          // تجاهل الإشعارات التي لا تخص هذه الرحلة
          return;
        }

        debugPrint('Received real-time ride start notification: $data');

        // إغلاق نافذة الانتظار إذا كانت مفتوحة
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (e) {
          debugPrint('Error closing dialog: $e');
        }

        // عرض رسالة بدء الرحلة
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم بدء الرحلة! السائق في الطريق إليك...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // استخراج معلومات الرحلة
        final driverId = data['driverId'];
        final pickupLocation = latlong.LatLng(
          data['pickupLocation']['lat'],
          data['pickupLocation']['lng'],
        );
        final destination = latlong.LatLng(
          data['destination']['lat'],
          data['destination']['lng'],
        );

        // محاكاة موقع السائق (بالقرب من نقطة الالتقاط)
        final driverPosition = latlong.LatLng(
          pickupLocation.latitude - 0.005,
          pickupLocation.longitude - 0.005,
        );

        // بدء الرحلة تلقائيًا
        _startRide(
          driverPosition: driverPosition,
          pickupLocation: pickupLocation,
          destination: destination,
          rideId: receivedRideId,
          driverId: driverId,
        );
      },
    );

    // الاستماع للوصول إلى نقطة الالتقاط
    final pickupReachedSubscription = SocketService.instance.listenTo(
      'ride:pickup_reached',
      (data) {
        if (!mounted) return;

        final receivedRideId = data['rideId'];
        if (rideId != null && receivedRideId != rideId) {
          // تجاهل الإشعارات التي لا تخص هذه الرحلة
          return;
        }

        debugPrint('Driver reached pickup location: $data');

        // عرض رسالة الوصول إلى نقطة الالتقاط
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('وصل السائق إلى نقطة الالتقاط! جاري بدء الرحلة...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      },
    );

    // الاستماع للوصول إلى الوجهة
    final destinationReachedSubscription = SocketService.instance.listenTo(
      'ride:destination_reached',
      (data) {
        if (!mounted) return;

        final receivedRideId = data['rideId'];
        if (rideId != null && receivedRideId != rideId) {
          // تجاهل الإشعارات التي لا تخص هذه الرحلة
          return;
        }

        debugPrint('Driver reached destination: $data');

        // عرض رسالة الوصول إلى الوجهة
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('وصلت إلى وجهتك! انتهت الرحلة.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // إعادة تعيين الخريطة
        setState(() {
          _polylinePoints = [];
          _markers.removeWhere((m) =>
              m.builder(context) is Icon &&
              (m.builder(context) as Icon).icon == Icons.directions_car);
        });
      },
    );

    // تسجيل الاشتراكات للتنظيف لاحقًا
    _activeSubscriptions.add(() {
      acceptSubscription.cancel();
      startedRealtimeSubscription.cancel();
      pickupReachedSubscription.cancel();
      destinationReachedSubscription.cancel();
    });

    // الاستماع لرفض الرحلة
    final rejectSubscription =
        SocketService.instance.onRideRejected.listen((data) {
      if (mounted) {
        // إغلاق نافذة الانتظار
        Navigator.pop(context);

        // عرض رسالة الرفض
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تم رفض الطلب'),
            content: const Text(
                'للأسف، تم رفض طلب الرحلة من قبل السائق. يمكنك المحاولة مرة أخرى أو تجربة خيارات أخرى.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('حسناً'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // إعادة محاولة طلب رحلة جديدة
                  if (_markers.isNotEmpty) {
                    _sendRideRequest(_markers.first.point);
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        );
      }
    });

    // تكوين مهلة انتظار للطلبات التي لم يتم الرد عليها
    Timer? timeoutTimer;
    if (rideId != null) {
      timeoutTimer = Timer(const Duration(minutes: 2), () async {
        try {
          if (!mounted) return;

          // التحقق من حالة الطلب
          final ride = await _rideService.getRideById(rideId);

          // إذا كان الطلب لا يزال في حالة انتظار، قم بإلغائه
          if (ride.status == 'pending' && mounted) {
            await _rideService.updateRide(rideId, {'status': 'cancelled'});

            // إغلاق نافذة الانتظار إذا كانت لا تزال مفتوحة
            if (mounted) {
              try {
                Navigator.of(context, rootNavigator: true).pop();
              } catch (e) {
                debugPrint('Error closing dialog: $e');
              }
            }

            if (mounted) {
              // عرض رسالة انتهاء المهلة
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('انتهت مهلة الانتظار'),
                  content: const Text(
                      'لم يتم العثور على سائق متاح خلال الوقت المحدد. يرجى المحاولة مرة أخرى لاحقًا.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('حسناً'),
                    ),
                  ],
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('Error checking ride status: $e');
        }
      });
    }

    // تنظيف الاشتراكات عند الانتهاء
    void disposeListeners() {
      acceptSubscription.cancel();
      rejectSubscription.cancel();
      timeoutTimer?.cancel();
    }

    // تسجيل دالة التنظيف للاستدعاء لاحقًا
    _activeSubscriptions.add(disposeListeners);
  }

  // تم نقل هذه القائمة إلى أعلى الملف

  void _showWaitingForDriverPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false, // منع الرجوع بزر العودة
        child: AlertDialog(
          title: const Text('انتظار السائق'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              const Text('جاري البحث عن سائقين متاحين...'),
              const SizedBox(height: 8),
              StreamBuilder<int>(
                stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
                builder: (context, snapshot) {
                  final seconds = snapshot.data ?? 0;
                  return Text(
                    'وقت الانتظار: $seconds ثانية',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // إلغاء طلب الرحلة
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إلغاء طلب الرحلة')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('إلغاء الطلب'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRide({
    required latlong.LatLng driverPosition,
    required latlong.LatLng pickupLocation,
    required latlong.LatLng destination,
    required String rideId,
    required String driverId,
  }) async {
    // Mettre à jour l'interface pour afficher le trajet complet
    setState(() {
      _markers.clear();

      // Ajouter le marqueur du conducteur
      _markers.add(
        Marker(
          point: driverPosition,
          builder: (context) => const Icon(
            Icons.directions_car,
            color: Colors.blue,
            size: 40,
          ),
        ),
      );

      // Ajouter le marqueur du point de ramassage
      _markers.add(
        Marker(
          point: pickupLocation,
          builder: (context) => const Icon(
            Icons.location_on,
            color: Colors.green,
            size: 40,
          ),
        ),
      );

      // Ajouter le marqueur de la destination
      _markers.add(
        Marker(
          point: destination,
          builder: (context) => const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    });

    // تسجيل معلومات التصحيح
    debugPrint(
        'بدء الرحلة: من $driverPosition إلى $pickupLocation ثم إلى $destination');

    // رسم المسار من موقع السائق إلى نقطة الالتقاط
    try {
      // رسم المسار التفصيلي مباشرة بدلاً من استخدام _drawRouteAndAnimate
      await _drawDetailedRoute(driverPosition, pickupLocation);

      // تحديث حالة الرحلة
      await _rideService.updateRide(rideId, {'status': 'accepted'});

      // عرض رسالة تأكيد
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم قبول الرحلة! السائق في الطريق إليك...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // الاستماع لتحديثات موقع السائق
      _listenForDriverLocationUpdates(driverId);

      // بعد فترة، نرسم المسار من نقطة الالتقاط إلى الوجهة
      Future.delayed(const Duration(seconds: 8), () async {
        if (mounted) {
          // محاكاة وصول السائق إلى نقطة الالتقاط
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('وصل السائق إلى نقطة الالتقاط! جاري بدء الرحلة...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // رسم المسار التفصيلي من نقطة الالتقاط إلى الوجهة
          await _drawDetailedRoute(pickupLocation, destination);

          // تحديث حالة الرحلة
          await _rideService.updateRide(rideId, {'status': 'in_progress'});

          // عرض رسالة تأكيد
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('بدأت الرحلة! في الطريق إلى الوجهة...'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      });
    } catch (e) {
      debugPrint('خطأ في بدء الرحلة: $e');

      // استخدام طريقة بديلة في حالة فشل الطريقة الأولى
      _drawRouteAndAnimate(driverPosition, pickupLocation);

      // بعد فترة، نرسم المسار من نقطة الالتقاط إلى الوجهة
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) {
          _drawRouteAndAnimate(pickupLocation, destination);
        }
      });
    }
  }

  // طريقة احتياطية في حالة فشل واجهة برمجة التطبيقات
  // ملاحظة: هذه الدالة غير مستخدمة حالياً بعد التحسينات التي تمت على النظام
  // تم الاحتفاظ بها كطريقة احتياطية في حالة فشل الطرق الأخرى
  void _startSimpleRide() {
    // بدء الرحلة بالبيانات المتاحة
    if (_currentPosition != null && _markers.isNotEmpty) {
      _drawRouteAndAnimate(_currentPosition!, _markers.first.point);
    }
  }

  /// الاستماع لتحديثات موقع السائق مع عرض المسار الفعلي
  void _listenForDriverLocationUpdates(String driverId) {
    debugPrint('بدء الاستماع لتحديثات موقع السائق: $driverId');

    // قائمة لتخزين نقاط مسار السائق الفعلي
    final List<latlong.LatLng> driverPathPoints = [];

    // إلغاء الاشتراكات السابقة لتجنب التكرار
    SocketService.instance.socket?.off('driver:location_update');

    // الاشتراك في تحديثات موقع السائق
    SocketService.instance.socket?.on('driver:location_update', (data) {
      if (!mounted) return;

      debugPrint('تم استلام تحديث موقع السائق: $data');

      if (data['driverId'] == driverId) {
        try {
          final lat = data['location']['lat'];
          final lng = data['location']['lng'];

          if (lat == null || lng == null) {
            debugPrint('بيانات موقع السائق غير صالحة: $data');
            return;
          }

          // تحويل الإحداثيات إلى كائن LatLng
          final driverLocation = latlong.LatLng(
              double.parse(lat.toString()), double.parse(lng.toString()));

          // استخراج المعلومات الإضافية إذا كانت متوفرة
          final double? speed = data['speed'] != null
              ? double.parse(data['speed'].toString())
              : null;
          final double? heading = data['heading'] != null
              ? double.parse(data['heading'].toString())
              : null;
          final double? progress = data['progress'] != null
              ? double.parse(data['progress'].toString())
              : null;
          final double? distanceRemaining = data['distanceRemaining'] != null
              ? double.parse(data['distanceRemaining'].toString())
              : null;
          final int? eta = data['eta'];

          // تحديث معلومات السائق إذا كانت متوفرة
          if (data['driverName'] != null && _currentDriverName == null) {
            setState(() {
              _currentDriverName = data['driverName'];
            });
          }

          if (data['vehicleInfo'] != null && _currentVehicleInfo == null) {
            setState(() {
              _currentVehicleInfo = data['vehicleInfo'];
            });
          }

          // إضافة النقطة الحالية إلى مسار السائق
          if (driverPathPoints.isEmpty ||
              _calculateDistance(
                      driverPathPoints.last.latitude,
                      driverPathPoints.last.longitude,
                      driverLocation.latitude,
                      driverLocation.longitude) >
                  0.01) {
            // إضافة النقطة فقط إذا كانت على بعد أكثر من 10 متر من النقطة السابقة
            driverPathPoints.add(driverLocation);
          }

          setState(() {
            // إزالة علامة السائق السابقة
            _markers.removeWhere((m) {
              final widget = m.builder(context);
              return widget is Icon &&
                  (widget.icon == Icons.directions_car ||
                      widget.icon == Icons.car_crash);
            });

            // إضافة علامة السائق الجديدة بتصميم أفضل وتدوير حسب الاتجاه
            _markers.add(
              Marker(
                point: driverLocation,
                width: 60,
                height: 60,
                builder: (context) => Transform.rotate(
                  angle: heading != null
                      ? heading * (pi / 180)
                      : 0, // تحويل من درجات إلى راديان
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(
                          red: 0, green: 122, blue: 255, alpha: 220),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(red: 0, green: 0, blue: 0, alpha: 51),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            );

            // تحديث موقع السيارة في الرسوم المتحركة
            if (_carPosition != null) {
              _carPosition = driverLocation;
            }

            // رسم مسار السائق الفعلي
            if (driverPathPoints.length > 1) {
              // إزالة المسار السابق
              _polylinePoints = List.from(driverPathPoints);

              // إذا كان هناك وجهة محددة في المسار الحالي، نحافظ عليها
              if (_polylinePoints.isNotEmpty && _markers.isNotEmpty) {
                // نفترض أن آخر علامة هي الوجهة
                final destinationMarker = _markers.lastWhere(
                  (marker) =>
                      marker.builder(context) is Icon &&
                      (marker.builder(context) as Icon).icon ==
                          Icons.location_pin,
                  orElse: () => _markers.last,
                );

                // إضافة الوجهة إلى نهاية المسار إذا لم تكن موجودة بالفعل
                if (_polylinePoints.isEmpty ||
                    _calculateDistance(
                            _polylinePoints.last.latitude,
                            _polylinePoints.last.longitude,
                            destinationMarker.point.latitude,
                            destinationMarker.point.longitude) >
                        0.01) {
                  _polylinePoints.add(destinationMarker.point);
                }
              }
            }

            // عرض معلومات الرحلة إذا كانت متوفرة
            if (progress != null || distanceRemaining != null || eta != null) {
              _updateRideInfo(
                progress: progress,
                distanceRemaining: distanceRemaining,
                estimatedTime: eta != null ? Duration(seconds: eta) : null,
                speed: speed,
              );
            }
          });

          // تحريك الخريطة لتتبع السائق إذا كان بعيدًا عن مركز الخريطة الحالي
          final currentCenter = _mapController.center;
          final distance = _calculateDistance(
              currentCenter.latitude,
              currentCenter.longitude,
              driverLocation.latitude,
              driverLocation.longitude);

          // إذا كان السائق على بعد أكثر من 300 متر من مركز الخريطة الحالي، نحرك الخريطة
          if (distance > 0.3) {
            _mapController.move(driverLocation, _mapController.zoom);
          }
        } catch (e) {
          debugPrint('خطأ في معالجة تحديث موقع السائق: $e');
        }
      }
    });

    // إرسال طلب أولي للحصول على الموقع الحالي للسائق
    SocketService.instance.socket?.emit('request:driver_location', {
      'driverId': driverId,
    });

    // إرسال طلبات دورية للحصول على تحديثات موقع السائق
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      SocketService.instance.socket?.emit('request:driver_location', {
        'driverId': driverId,
      });
    });
  }

  /// تحديث معلومات الرحلة في واجهة المستخدم
  void _updateRideInfo({
    double? progress,
    double? distanceRemaining,
    Duration? estimatedTime,
    double? speed,
  }) {
    // تحديث متغيرات حالة الرحلة
    setState(() {
      _rideProgress = progress;
      _rideDistanceRemaining = distanceRemaining;
      _rideEstimatedTime = estimatedTime;
      _rideSpeed = speed;
    });

    // عرض لوحة معلومات الرحلة إذا لم تكن معروضة بالفعل
    if (!_isRideInfoPanelVisible && mounted) {
      setState(() {
        _isRideInfoPanelVisible = true;
      });
    }

    // عرض إشعار سريع بالمعلومات المحدثة
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تحديث معلومات الرحلة (${progress?.toStringAsFixed(0) ?? "0"}%)',
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.blue.shade700,
        ),
      );
    }
  }

  /// إخفاء لوحة معلومات الرحلة
  void _hideRideInfoPanel() {
    if (mounted) {
      setState(() {
        _isRideInfoPanelVisible = false;
      });
    }
  }

  /// إلغاء الرحلة الحالية
  /// ملاحظة: هذه الدالة تحتاج إلى تحسين لإضافة منطق إلغاء الرحلة على الخادم
  /// حالياً تقوم فقط بإخفاء معلومات الرحلة محلياً دون إرسال أي إشعار للسائق أو تحديث حالة الرحلة
  void _cancelCurrentRide() {
    // عرض مربع حوار للتأكيد
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الرحلة'),
        content: const Text('هل أنت متأكد من رغبتك في إلغاء الرحلة الحالية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لا'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              // TODO: إضافة منطق إلغاء الرحلة على الخادم
              // مثال:
              // if (_currentRideId != null) {
              //   _rideService.updateRide(_currentRideId!, {'status': 'cancelled'});
              //   SocketService.instance.socket?.emit('ride:cancelled', {
              //     'rideId': _currentRideId,
              //     'riderId': _currentUserId,
              //     'timestamp': DateTime.now().toIso8601String(),
              //   });
              // }

              _hideRideInfoPanel();
              _refreshMap();

              // عرض رسالة تأكيد
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إلغاء الرحلة'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('نعم'),
          ),
        ],
      ),
    );
  }

  /// الاتصال بالسائق
  /// ملاحظة: هذه الدالة تحتاج إلى تحسين لإضافة منطق الاتصال بالسائق
  /// حالياً تعرض فقط رسالة تأكيد دون تنفيذ أي إجراء فعلي
  void _contactDriver() {
    // عرض مربع حوار للاتصال
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الاتصال بالسائق'),
        content: const Text('هل ترغب في الاتصال بالسائق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              // TODO: إضافة منطق الاتصال بالسائق
              // مثال:
              // if (_currentDriverId != null) {
              //   // يمكن استخدام مكتبة url_launcher لفتح تطبيق الهاتف
              //   // final Uri phoneUri = Uri.parse('tel:$_currentDriverPhoneNumber');
              //   // launchUrl(phoneUri);
              //
              //   // أو إرسال إشعار للسائق عبر Socket
              //   // SocketService.instance.socket?.emit('rider:contact_request', {
              //   //   'driverId': _currentDriverId,
              //   //   'riderId': _currentUserId,
              //   //   'timestamp': DateTime.now().toIso8601String(),
              //   // });
              // }

              // عرض رسالة تأكيد
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('جاري الاتصال بالسائق...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('اتصال'),
          ),
        ],
      ),
    );
  }

  // دالة معالجة قبول الرحلة مع تحسينات
  // ملاحظة: هذه الدالة لا تزال مستخدمة للتوافق مع الإشعارات القديمة من نوع 'ride:accepted'
  // ولكن الطريقة المفضلة الآن هي استخدام إشعار 'ride:accept_and_start' الذي يبدأ الرحلة تلقائياً
  Future<void> _handleRideAccepted(Map<String, dynamic> data) async {
    try {
      // عرض مؤشر التحميل
      _showLoadingDialog('جاري تحميل معلومات الرحلة...');

      // استخراج معلومات الرحلة
      final String rideId = data['rideId'] ?? '';
      final String driverId = data['driverId'] ?? '';

      // استخراج معلومات السائق إذا كانت متوفرة
      final String driverName = data['driverName'] ?? 'سائق $driverId';
      final String vehicleInfo = data['vehicleInfo'] ?? 'سيارة عادية';

      // تحديث معلومات السائق في الحالة
      setState(() {
        _currentDriverId = driverId;
        _currentDriverName = driverName;
        _currentVehicleInfo = vehicleInfo;
      });

      debugPrint('تم قبول الرحلة: $rideId من السائق: $driverId');

      // الحصول على تفاصيل الرحلة من الخادم
      final ride = await _rideService.getRideById(rideId);

      // الحصول على مواقع الالتقاط والوجهة
      final pickupLocation = latlong.LatLng(
        ride.pickupLocation['lat'],
        ride.pickupLocation['lng'],
      );

      final destination = latlong.LatLng(
        ride.destination['lat'],
        ride.destination['lng'],
      );

      // إغلاق مؤشر التحميل
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // عرض إشعار قبول الرحلة
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم قبول الرحلة! السائق في الطريق إليك...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // الاستماع لتحديثات موقع السائق
      _listenForDriverLocationUpdates(driverId);

      // محاكاة موقع السائق (بالقرب من نقطة الالتقاط)
      final driverPosition = latlong.LatLng(
        pickupLocation.latitude - 0.005,
        pickupLocation.longitude - 0.005,
      );

      // بدء الرحلة مباشرة عند قبول السائق بدون انتظار
      setState(() {
        _isRideInfoPanelVisible = true; // إظهار لوحة معلومات الرحلة
      });

      // رسم المسار مباشرة
      _drawDetailedRoute(driverPosition, pickupLocation);

      // بدء الرحلة
      _startRide(
        driverPosition: driverPosition,
        pickupLocation: pickupLocation,
        destination: destination,
        rideId: rideId,
        driverId: driverId,
      );

      // إرسال إشعار بأن الرحلة قد بدأت (لضمان التزامن مع السائق)
      // ملاحظة: هذا الإشعار قد يكون زائداً الآن مع وجود إشعار 'ride:accept_and_start'
      SocketService.instance.socket?.emit('ride:started_realtime', {
        'rideId': rideId,
        'driverId': driverId,
        'timestamp': DateTime.now().toIso8601String(),
        'pickupLocation': ride.pickupLocation,
        'destination': ride.destination,
      });

      // Show driver info in a bottom sheet that doesn't block the map
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isDismissible: true,
          isScrollControlled: false,
          builder: (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('تم قبول الرحلة',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('السائق في الطريق إليك للالتقاط.'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person,
                              color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text('معرف السائق: $driverId'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                              'الوصول المتوقع: ${data['estimatedPickupTime'] ?? '5'} دقائق'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                              'الرحلة قيد التقدم. يمكنك رؤية المسار على الخريطة.'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('حسناً'),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Listen for ride started event
      SocketService.instance.listenTo('ride:started_realtime', (startData) {
        if (startData['rideId'] == rideId && mounted) {
          // Draw route when the driver starts the ride
          if (_currentPosition != null) {
            _drawRouteAndAnimate(pickupLocation, destination);
          }

          // Show notification
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('بدأت الرحلة! السائق في الطريق إليك...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('خطأ في معالجة قبول الرحلة: $e');

      // إغلاق مؤشر التحميل إذا كان مفتوحًا
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }

      if (mounted) {
        // عرض رسالة الخطأ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في معالجة قبول الرحلة: $e'),
            backgroundColor: Colors.red,
          ),
        );

        // استخدام طريقة بديلة لبدء الرحلة في حالة فشل API
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تم قبول الرحلة!'),
            content: const Text('قبل سائق طلب رحلتك. ستبدأ رحلتك قريبًا.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // بدء الرحلة بالطريقة البسيطة
                  _startSimpleRide();
                },
                child: const Text('حسنًا'),
              ),
            ],
          ),
        );
      }
    }
  }
}

class MapSearchBar extends StatelessWidget {
  final Function(String) onSearch;
  final Function(List<Marker>) onMarkersUpdated;

  const MapSearchBar({
    super.key,
    required this.onSearch,
    required this.onMarkersUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(red: 0, green: 0, blue: 0, alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'Search for a location',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search),
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            onSearch(value);
          }
        },
      ),
    );
  }
}

class AddressPopup extends StatelessWidget {
  final latlong.LatLng? currentPosition;
  final Function(String) onSearch;
  final Function(latlong.LatLng, latlong.LatLng) onRouteConfirmed;
  final Function(latlong.LatLng) onSendRideRequest;
  final String? initialToAddress;
  final latlong.LatLng? initialToPosition;

  const AddressPopup({
    super.key,
    this.currentPosition,
    required this.onSearch,
    required this.onRouteConfirmed,
    required this.onSendRideRequest,
    this.initialToAddress,
    this.initialToPosition,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController toController =
        TextEditingController(text: initialToAddress ?? '');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: toController,
            decoration: const InputDecoration(
              labelText: 'Destination',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                onSearch(value);
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (currentPosition != null && initialToPosition != null) {
                    onRouteConfirmed(currentPosition!, initialToPosition!);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please select a destination')),
                    );
                  }
                },
                child: const Text('Preview Route'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (initialToPosition != null) {
                    onSendRideRequest(initialToPosition!);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please select a destination')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Request Ride'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: const Center(
        child: Text('No notifications available'),
      ),
    );
  }
}
