import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';
import 'package:project/core/services/socket_service.dart';
import 'package:project/core/services/driver_service.dart';
import 'package:project/core/services/ride_service.dart';
import 'package:project/core/services/voice_recognition_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Imports no utilizados eliminados
import '../widgets/voice_recognition_button.dart';

/// فئة لتخزين معلومات السائق
class DriverInfo {
  final String id;
  final String name;
  final String vehicleInfo;

  DriverInfo({
    required this.id,
    required this.name,
    required this.vehicleInfo,
  });
}

/// فئة لتخزين معلومات الرحلة
class RideInfo {
  final String id;
  final latlong.LatLng pickupLocation;
  final latlong.LatLng destination;
  final Map<String, dynamic> pickupLocationMap;
  final Map<String, dynamic> destinationMap;

  RideInfo({
    required this.id,
    required this.pickupLocation,
    required this.destination,
    required this.pickupLocationMap,
    required this.destinationMap,
  });
}

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final MapController _mapController = MapController();
  latlong.LatLng? _currentPosition;
  final latlong.LatLng _defaultPosition = latlong.LatLng(37.7749, -122.4194);
  final List<Marker> _markers = [];
  List<latlong.LatLng> _polylinePoints = [];
  bool _isAvailable = true;
  Timer? _rideRequestTimer;
  Timer? _pendingRidesTimer;
  String? _driverId;
  final RideService _rideService = RideService.instance;
  final DriverService _driverService = DriverService.instance;

  // خدمة التعرف على الصوت
  final VoiceRecognitionService _voiceService =
      VoiceRecognitionService.instance;
  bool _isListening = false;
  // تخزين اشتراك الأوامر الصوتية للتنظيف لاحقاً
  StreamSubscription<VoiceCommand>? _voiceCommandSubscription;

  // تخزين طلب الرحلة الحالي الذي يتم عرضه
  RideRequest? _currentRideRequest;

  // تخزين معلومات الرحلة الحالية
  Map<String, dynamic>? _currentRideInfo;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initializeDriver();
    _connectToSocketService();
    _startFetchingPendingRides();
    _initializeVoiceRecognition();
  }

  // تهيئة خدمة التعرف على الصوت مع تحسينات
  Future<void> _initializeVoiceRecognition() async {
    try {
      // تهيئة خدمة التعرف على الصوت
      final isInitialized = await _voiceService.initialize();

      if (isInitialized) {
        debugPrint('✅ تم تهيئة خدمة التعرف على الصوت بنجاح');

        // إلغاء الاشتراك السابق إذا كان موجوداً
        _voiceCommandSubscription?.cancel();

        // الاستماع للأوامر الصوتية
        _voiceCommandSubscription = _voiceService.onCommand.listen((command) {
          debugPrint('🎤 تم التعرف على الأمر الصوتي: $command');

          // معالجة الأمر الصوتي
          if (mounted) {
            _handleVoiceCommand(command);
          }
        });

        // عرض رسالة تأكيد
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تفعيل ميزة التعرف على الصوت'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // إعلان صوتي عن جاهزية الميزة
        _voiceService.speak('تم تفعيل ميزة التعرف على الصوت');
      } else {
        debugPrint('❌ فشل في تهيئة خدمة التعرف على الصوت');

        // عرض رسالة خطأ
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل في تفعيل ميزة التعرف على الصوت'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة التعرف على الصوت: $e');

      // عرض رسالة خطأ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تفعيل ميزة التعرف على الصوت: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // معالجة الأوامر الصوتية بشكل محسن
  void _handleVoiceCommand(VoiceCommand command) {
    debugPrint('🎤 معالجة الأمر الصوتي: $command');

    // إغلاق مربع الحوار الحالي إذا كان مفتوحًا
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (_currentRideRequest != null) {
      // إذا كان هناك طلب رحلة حالي
      final rideId = _currentRideRequest!.id;

      switch (command) {
        case VoiceCommand.acceptRide:
          // قبول الرحلة الحالية
          debugPrint('🎤 تنفيذ أمر: قبول الرحلة $rideId');
          _voiceService.speak('تم قبول الرحلة');

          // عرض رسالة تأكيد
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم قبول الرحلة بواسطة الأمر الصوتي'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // تنفيذ قبول الرحلة وبدء الرحلة تلقائياً
          _acceptRideAndStart(rideId);

          // إعادة تعيين طلب الرحلة الحالي
          setState(() {
            _currentRideRequest = null;
          });
          break;

        case VoiceCommand.rejectRide:
          // رفض الرحلة الحالية
          debugPrint('🎤 تنفيذ أمر: رفض الرحلة $rideId');
          _voiceService.speak('تم رفض الرحلة');

          // عرض رسالة تأكيد
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم رفض الرحلة بواسطة الأمر الصوتي'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );

          // تنفيذ رفض الرحلة
          _rejectRide(rideId);

          // إعادة تعيين طلب الرحلة الحالي
          setState(() {
            _currentRideRequest = null;
          });
          break;

        default:
          // أمر غير معروف
          debugPrint('🎤 أمر غير معروف');
          _voiceService.speak('لم أفهم الأمر، يرجى المحاولة مرة أخرى');

          // إعادة تشغيل الاستماع
          Future.delayed(const Duration(seconds: 1), () {
            _startVoiceRecognition();
          });
          break;
      }
    } else if (_currentRideInfo != null) {
      // إذا كانت هناك رحلة نشطة
      switch (command) {
        case VoiceCommand.startRide:
          // بدء الرحلة
          debugPrint('🎤 تنفيذ أمر: بدء الرحلة');
          _voiceService.speak('تم بدء الرحلة');

          // عرض رسالة تأكيد
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم بدء الرحلة بواسطة الأمر الصوتي'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // تنفيذ بدء الرحلة
          _reachedPickupLocation();
          break;

        case VoiceCommand.completeRide:
          // إنهاء الرحلة
          debugPrint('🎤 تنفيذ أمر: إنهاء الرحلة');
          _voiceService.speak('تم إنهاء الرحلة');

          // عرض رسالة تأكيد
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إنهاء الرحلة بواسطة الأمر الصوتي'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // تنفيذ إنهاء الرحلة
          _completeRide();
          break;

        default:
          // أمر غير معروف
          debugPrint('🎤 أمر غير معروف');
          _voiceService.speak('لم أفهم الأمر، يرجى المحاولة مرة أخرى');

          // إعادة تشغيل الاستماع
          Future.delayed(const Duration(seconds: 1), () {
            _startVoiceRecognition();
          });
          break;
      }
    } else {
      // لا توجد رحلة نشطة
      debugPrint('🎤 لا توجد رحلة نشطة');
      _voiceService.speak('لا توجد رحلة نشطة حالياً');

      // عرض رسالة توضيحية
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('لا توجد رحلة نشطة حالياً للتفاعل معها بالأوامر الصوتية'),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 3),
        ),
      );
    }

    // إيقاف الاستماع بعد معالجة الأمر
    _voiceService.stopListening();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _initializeDriver() async {
    // Récupérer ou créer un ID de conducteur
    final prefs = await SharedPreferences.getInstance();
    String? driverId = prefs.getString('driver_id');

    if (driverId == null) {
      try {
        // Créer un nouveau conducteur dans la base de données
        driverId = await _driverService.createDriver(
          name: 'Driver ${DateTime.now().millisecondsSinceEpoch}',
          vehicleType: 'Car',
          vehicleNumber: 'ABC-123',
          latitude: _currentPosition?.latitude,
          longitude: _currentPosition?.longitude,
        );

        // Sauvegarder l'ID du conducteur
        await prefs.setString('driver_id', driverId);
      } catch (e) {
        debugPrint('Erreur lors de la création du conducteur: $e');
        // Utiliser un ID temporaire en cas d'échec
        driverId = 'driver_${DateTime.now().millisecondsSinceEpoch}';
      }
    }

    setState(() {
      _driverId = driverId;
    });

    debugPrint('Driver ID: $_driverId');
  }

  void _startFetchingPendingRides() {
    // Récupérer les demandes de trajet en attente toutes les 10 secondes
    _pendingRidesTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchPendingRides();
    });

    // Récupérer les demandes immédiatement au démarrage
    _fetchPendingRides();
  }

  void _connectToSocketService() {
    // تسجيل السائق كمتاح
    SocketService.instance.connect();

    // الحصول على معرف السائق (يمكن استخدام SharedPreferences أو غيرها)
    _getDriverId().then((driverId) {
      if (driverId.isNotEmpty) {
        _driverId = driverId;

        if (_isAvailable) {
          SocketService.instance.setDriverAvailable(driverId);
        }
        SocketService.instance.setDriverId(driverId);

        // الاستماع لطلبات الرحلات الجديدة
        SocketService.instance.onNewRideRequest.listen((rideRequest) {
          if (_isAvailable) {
            _showRideRequestPopup(rideRequest);
          }
        });

        // الاستماع لطلبات مشاركة الرحلة
        SocketService.instance.onRideSharingRequest.listen((sharingRequest) {
          if (_isAvailable) {
            _showRideSharingRequestPopup(sharingRequest);
          }
        });

        // بدء إرسال موقع السائق بشكل دوري لجميع المستخدمين
        _startBroadcastingDriverLocation();
      }
    });
  }

  // Timer لإرسال موقع السائق
  Timer? _locationBroadcastTimer;

  // بدء إرسال موقع السائق بشكل دوري
  void _startBroadcastingDriverLocation() {
    // إلغاء أي مؤقت سابق
    _locationBroadcastTimer?.cancel();

    // إرسال موقع السائق فوراً
    _broadcastCurrentLocation();

    // إرسال موقع السائق كل 5 ثوانٍ
    _locationBroadcastTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _broadcastCurrentLocation();
    });
  }

  // إرسال الموقع الحالي للسائق
  void _broadcastCurrentLocation() {
    // إرسال الموقع الحالي للسائق لجميع المستخدمين
    if (_currentPosition != null && _driverId != null) {
      SocketService.instance.broadcastDriverLocation(
        location: {
          'lat': _currentPosition!.latitude,
          'lng': _currentPosition!.longitude,
        },
        isAvailable: _isAvailable &&
            _currentRideInfo == null, // متاح فقط إذا لم تكن هناك رحلة نشطة
      );

      debugPrint(
          'Broadcasting driver location: $_currentPosition, available: ${_isAvailable && _currentRideInfo == null}');
    }
  }

  Future<String> _getDriverId() async {
    if (_driverId != null) {
      return _driverId!;
    }

    // Récupérer l'ID du conducteur depuis les préférences
    final prefs = await SharedPreferences.getInstance();
    String? driverId = prefs.getString('driver_id');

    // Utiliser un ID temporaire si aucun ID n'est trouvé (usando operador ??=)
    driverId ??= 'driver_${DateTime.now().millisecondsSinceEpoch}';

    return driverId;
  }

  Future<void> _fetchPendingRides() async {
    if (!_isAvailable || _driverId == null) {
      return;
    }

    try {
      // Récupérer les demandes de trajet en attente
      final pendingRides = await _driverService.getPendingRides();

      if (pendingRides.isNotEmpty) {
        debugPrint(
            'Demandes de trajet en attente trouvées: ${pendingRides.length}');

        // Traiter chaque demande de trajet
        for (final ride in pendingRides) {
          // Vérifier si la demande a déjà été traitée
          final isProcessed = await _isRideAlreadyProcessed(ride['id']);
          if (!isProcessed) {
            // Convertir en objet RideRequest pour l'afficher
            final rideRequest = RideRequest(
              id: ride['id'],
              pickupLocation: ride['pickupLocation'],
              destination: ride['destination'],
              status: ride['status'],
              riderId: ride['riderId'],
            );

            // Afficher la demande de trajet si le conducteur est disponible
            if (_isAvailable && mounted) {
              _showRideRequestPopup(rideRequest);
              break; // Afficher une seule demande à la fois
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des demandes de trajet: $e');
    }
  }

  Future<bool> _isRideAlreadyProcessed(String rideId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final processedRides = prefs.getStringList('processed_rides') ?? [];
      return processedRides.contains(rideId);
    } catch (e) {
      debugPrint('Erreur lors de la vérification des demandes traitées: $e');
      return false;
    }
  }

  @override
  void dispose() {
    // إلغاء جميع المؤقتات والاشتراكات
    _rideRequestTimer?.cancel();
    _pendingRidesTimer?.cancel();
    _locationBroadcastTimer?.cancel();
    _voiceCommandSubscription?.cancel();

    super.dispose();
  }

  void _showRideRequestPopup(RideRequest rideRequest) {
    // تخزين طلب الرحلة الحالي
    setState(() {
      _currentRideRequest = rideRequest;
    });

    // تحويل الإحداثيات إلى كائنات LatLng
    final pickupLocation = latlong.LatLng(
      rideRequest.pickupLocation['lat'],
      rideRequest.pickupLocation['lng'],
    );

    final destination = latlong.LatLng(
      rideRequest.destination['lat'],
      rideRequest.destination['lng'],
    );

    // حساب المسافة التقريبية (بالكيلومتر)
    double distanceToPickup = 0;
    if (_currentPosition != null) {
      distanceToPickup = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          pickupLocation.latitude,
          pickupLocation.longitude);
    }

    // حساب الوقت التقريبي (بالدقائق) بافتراض سرعة متوسطة 30 كم/ساعة
    final estimatedTime = (distanceToPickup / 30 * 60).round();

    // حساب الأرباح المتوقعة (مثال بسيط)
    final estimatedEarnings = (distanceToPickup * 2.5).round();

    // بدء الاستماع للأوامر الصوتية
    _startVoiceRecognition();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.amber),
            SizedBox(width: 8),
            Text('طلب رحلة جديد'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات الرحلة
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
                      '${pickupLocation.latitude.toStringAsFixed(4)}, ${pickupLocation.longitude.toStringAsFixed(4)}'),
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
                      '${destination.latitude.toStringAsFixed(4)}, ${destination.longitude.toStringAsFixed(4)}'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // معلومات إضافية
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoItem(Icons.route,
                    '${distanceToPickup.toStringAsFixed(1)} كم', 'المسافة'),
                _infoItem(
                    Icons.access_time, '$estimatedTime دقيقة', 'الوقت المقدر'),
                _infoItem(Icons.attach_money, '$estimatedEarnings ج.م',
                    'الأرباح المتوقعة'),
              ],
            ),
            const SizedBox(height: 16),

            // سؤال القبول
            const Text('هل تريد قبول هذه الرحلة؟',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

            // إضافة قسم للتعرف على الصوت
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  const Text(
                    'يمكنك استخدام الأوامر الصوتية',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'قل "قبول" أو "رفض"',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  VoiceRecognitionButton(
                    onPressed: _toggleVoiceRecognition,
                    isListening: _voiceService.isListening,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectRide(rideRequest.id);

              // إعادة تعيين طلب الرحلة الحالي
              setState(() {
                _currentRideRequest = null;
              });

              // إيقاف التعرف على الصوت
              _voiceService.stopListening();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('رفض'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // استخدام الدالة الجديدة لقبول الرحلة وبدء الرحلة تلقائياً
              _acceptRideAndStart(rideRequest.id);

              // إعادة تعيين طلب الرحلة الحالي
              setState(() {
                _currentRideRequest = null;
              });

              // إيقاف التعرف على الصوت
              _voiceService.stopListening();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('قبول الرحلة'),
          ),
        ],
      ),
    );
  }

  // بدء التعرف على الصوت تلقائيًا عند وصول طلب رحلة مع تحسينات
  void _startVoiceRecognition() {
    // إعلان صوتي عن وصول طلب رحلة جديد
    _voiceService.speak('لديك طلب رحلة جديد. هل ترغب في قبوله؟');

    // عرض رسالة توضيحية فورية
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سيبدأ الاستماع للأوامر الصوتية خلال ثانيتين...'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );
    }

    // إيقاف أي استماع سابق
    _voiceService.stopListening();

    // بدء الاستماع تلقائيًا بعد ثانيتين من الإعلان
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      // تأكد من أن الخدمة جاهزة
      _voiceService.initialize().then((isInitialized) {
        if (isInitialized) {
          _voiceService.startListening();
          setState(() {
            _isListening = true;
          });

          // عرض رسالة توضيحية للسائق
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('جاري الاستماع... قل "قبول" أو "رفض"'),
                duration: Duration(seconds: 5),
                backgroundColor: Colors.blue,
              ),
            );
          }

          // إعادة تشغيل الاستماع إذا لم يتم التعرف على أي أمر خلال 10 ثوانٍ
          Future.delayed(const Duration(seconds: 10), () {
            if (_isListening && mounted) {
              _voiceService.stopListening();
              _voiceService.startListening();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'لم يتم التعرف على أي أمر. جاري إعادة الاستماع...'),
                    duration: Duration(seconds: 3),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          });
        } else {
          // إذا فشلت التهيئة، عرض رسالة خطأ
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'فشل في تهيئة خدمة التعرف على الصوت. يرجى المحاولة مرة أخرى.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      });
    });
  }

  // تبديل حالة التعرف على الصوت
  void _toggleVoiceRecognition() {
    if (_voiceService.isListening) {
      _voiceService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      _voiceService.startListening();
      setState(() {
        _isListening = true;
      });
    }
  }

  // عنصر معلومات للعرض في نافذة طلب الرحلة
  Widget _infoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // عرض نافذة طلب مشاركة الرحلة
  void _showRideSharingRequestPopup(SharingRequest sharingRequest) {
    // تحويل الإحداثيات إلى كائنات LatLng
    final pickupLocation = latlong.LatLng(
      sharingRequest.newPickupLocation['lat'],
      sharingRequest.newPickupLocation['lng'],
    );

    final destination = latlong.LatLng(
      sharingRequest.newDestination['lat'],
      sharingRequest.newDestination['lng'],
    );

    // حساب المسافة التقريبية (بالكيلومتر)
    double distanceToPickup = 0;
    if (_currentPosition != null) {
      distanceToPickup = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          pickupLocation.latitude,
          pickupLocation.longitude);
    }

    // حساب الوقت التقريبي (بالدقائق) بافتراض سرعة متوسطة 30 كم/ساعة
    final estimatedTime = (distanceToPickup / 30 * 60).round();

    // حساب الأرباح المتوقعة (مثال بسيط)
    final estimatedEarnings = (distanceToPickup * 2.5).round();

    // استخراج معلومات التنبؤ
    final prediction = sharingRequest.prediction;
    final detourDistance = prediction['detourDistance'] ?? 0;
    final timeImpact = prediction['timeImpact'] ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_add, color: Colors.green),
            SizedBox(width: 8),
            Text('Add New Rider'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات الرحلة
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
                      Text('Pickup Location:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                      '${pickupLocation.latitude.toStringAsFixed(4)}, ${pickupLocation.longitude.toStringAsFixed(4)}'),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.location_pin, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Destination:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                      '${destination.latitude.toStringAsFixed(4)}, ${destination.longitude.toStringAsFixed(4)}'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // معلومات إضافية
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoItem(Icons.route,
                    '${distanceToPickup.toStringAsFixed(1)} km', 'Distance'),
                _infoItem(Icons.access_time, '$estimatedTime min', 'Est. Time'),
                _infoItem(Icons.attach_money, '$estimatedEarnings \$',
                    'Est. Earnings'),
              ],
            ),
            const SizedBox(height: 16),

            // معلومات التأثير
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Impact on Current Ride:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Detour: +${detourDistance.toStringAsFixed(1)} km'),
                      Text('Time: +${timeImpact.toStringAsFixed(1)} min'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // سؤال القبول
            const Text('Would you like to add this rider to your current ride?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectRideSharing(
                  sharingRequest.rideId, sharingRequest.newRiderId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptRideSharing(
                  sharingRequest.rideId, sharingRequest.newRiderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Accept Rider'),
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

  /// قبول الرحلة وبدء الرحلة تلقائياً فوراً
  ///
  /// تقوم هذه الدالة بقبول طلب الرحلة وبدء الرحلة فوراً دون الحاجة للضغط على زر "وصلت لنقطة الالتقاط"
  /// كما تقوم بإرسال إشعار للراكب بأن الرحلة قد بدأت
  Future<void> _acceptRideAndStart(String rideId) async {
    if (!mounted) return;

    // تعيين السائق كغير متاح
    _setDriverAvailability(false);

    try {
      // عرض مؤشر التحميل
      _showLoadingDialog('جاري قبول الرحلة وبدء الرحلة...');

      // جمع معلومات السائق والرحلة
      final driverInfo = await _collectDriverInfo();
      final rideInfo = await _acceptAndStartRideOnServer(rideId, driverInfo.id);

      // تحديث واجهة المستخدم وإرسال الإشعارات
      await _updateUIAndNotifyRider(rideId, driverInfo, rideInfo);

      // رسم المسار وبدء التحديثات
      _initializeRouteAndUpdates(rideId, rideInfo);
    } catch (e) {
      _handleRideAcceptError(e);
    }
  }

  /// جمع معلومات السائق
  Future<DriverInfo> _collectDriverInfo() async {
    final id = await _getDriverId();
    final name = await _getDriverName();
    final vehicleInfo = await _getVehicleInfo();

    return DriverInfo(
      id: id,
      name: name,
      vehicleInfo: vehicleInfo,
    );
  }

  /// قبول وبدء الرحلة على الخادم
  Future<RideInfo> _acceptAndStartRideOnServer(
      String rideId, String driverId) async {
    // تحديث حالة الرحلة عبر API
    final updatedRide = await _rideService.acceptRide(rideId, driverId);

    // تسجيل الرحلة كمعالجة
    _markRideAsProcessed(rideId);

    // بدء الرحلة فوراً
    await _rideService.startRide(rideId);

    // استخراج إحداثيات نقطة الالتقاط والوجهة
    final pickupLocation = latlong.LatLng(
      updatedRide.pickupLocation['lat'],
      updatedRide.pickupLocation['lng'],
    );

    final destination = latlong.LatLng(
      updatedRide.destination['lat'],
      updatedRide.destination['lng'],
    );

    return RideInfo(
      id: rideId,
      pickupLocation: pickupLocation,
      destination: destination,
      pickupLocationMap: updatedRide.pickupLocation,
      destinationMap: updatedRide.destination,
    );
  }

  /// تحديث واجهة المستخدم وإرسال إشعار للراكب
  Future<void> _updateUIAndNotifyRider(
      String rideId, DriverInfo driverInfo, RideInfo rideInfo) async {
    // تخزين معلومات الرحلة الحالية
    setState(() {
      _currentRideInfo = {
        'rideId': rideId,
        'driverId': driverInfo.id,
        'pickupLocation': rideInfo.pickupLocation,
        'destination': rideInfo.destination,
        'status': 'in_progress'
      };
    });

    // إرسال إشعار قبول الرحلة وبدء الرحلة معاً
    _sendRideAcceptAndStartNotification(rideId, driverInfo, rideInfo);

    // إغلاق مؤشر التحميل
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();

      // عرض رسالة تأكيد
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم قبول الرحلة وبدء الرحلة!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// إرسال إشعار قبول وبدء الرحلة
  void _sendRideAcceptAndStartNotification(
      String rideId, DriverInfo driverInfo, RideInfo rideInfo) {
    SocketService.instance.socket?.emit('ride:accept_and_start', {
      'rideId': rideId,
      'driverId': driverInfo.id,
      'driverName': driverInfo.name,
      'vehicleInfo': driverInfo.vehicleInfo,
      'timestamp': DateTime.now().toIso8601String(),
      'pickupLocation': rideInfo.pickupLocationMap,
      'destination': rideInfo.destinationMap,
      'currentLocation': _getCurrentLocationMap() ?? rideInfo.pickupLocationMap,
      'status': 'in_progress',
      'syncId': 'sync_${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  /// الحصول على الموقع الحالي كخريطة
  Map<String, dynamic>? _getCurrentLocationMap() {
    return _currentPosition != null
        ? {
            'lat': _currentPosition!.latitude,
            'lng': _currentPosition!.longitude,
          }
        : null;
  }

  /// تهيئة المسار وبدء التحديثات
  void _initializeRouteAndUpdates(String rideId, RideInfo rideInfo) {
    if (_currentPosition != null) {
      // رسم المسار إلى نقطة الالتقاط
      _drawSimpleRoute(_currentPosition!, rideInfo.pickupLocation);

      // إرسال المسار المخطط له
      _drawRoute(_currentPosition!, rideInfo.destination);

      // بدء تحديثات الموقع
      _startLocationUpdates(rideId);
    }
  }

  /// معالجة أخطاء قبول الرحلة
  void _handleRideAcceptError(dynamic error) {
    debugPrint('خطأ أثناء قبول وبدء الرحلة: $error');

    // إغلاق مؤشر التحميل إذا كان مفتوحًا
    if (mounted) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}

      // عرض رسالة الخطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $error'),
          backgroundColor: Colors.red,
        ),
      );

      // إعادة السائق إلى حالة متاح
      _setDriverAvailability(true);
    }
  }

  /// تعيين حالة توفر السائق
  void _setDriverAvailability(bool isAvailable) {
    setState(() {
      _isAvailable = isAvailable;
    });
  }

  // تم نقل الفئات إلى المستوى الأعلى من الملف

  // تم حذف دالة _acceptRide لأنها استبدلت بدالة _acceptRideAndStart

  // عرض مؤشر التحميل
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
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  // دالة للوصول إلى نقطة الالتقاط
  // ملاحظة: هذه الدالة لم تعد مستخدمة بعد التحسينات التي تمت، حيث تبدأ الرحلة تلقائياً عند قبولها
  // تم الاحتفاظ بها للتوافق مع الكود القديم
  void _reachedPickupLocation() {
    if (_currentRideInfo == null) return;

    final rideId = _currentRideInfo!['rideId'];
    final driverId = _currentRideInfo!['driverId'];
    final pickupLocation =
        _currentRideInfo!['pickupLocation'] as latlong.LatLng;
    final destination = _currentRideInfo!['destination'] as latlong.LatLng;

    // إظهار إشعار الوصول إلى نقطة الالتقاط
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم الوصول إلى نقطة الالتقاط. جاري بدء الرحلة...'),
        backgroundColor: Colors.green,
      ),
    );

    // رسم المسار إلى الوجهة بشكل مباشر
    _drawSimpleRoute(pickupLocation, destination);

    // تحديث المسار التفصيلي في الخلفية
    Future.microtask(() async {
      try {
        await _drawRoute(pickupLocation, destination);
      } catch (e) {
        debugPrint('خطأ أثناء رسم المسار التفصيلي إلى الوجهة: $e');
      }
    });

    // إرسال إشعار بالوصول إلى نقطة الالتقاط
    SocketService.instance.socket?.emit('ride:pickup_reached', {
      'rideId': rideId,
      'driverId': driverId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // دالة لإنهاء الرحلة
  void _completeRide() {
    if (_currentRideInfo == null) return;

    final rideId = _currentRideInfo!['rideId'];
    final driverId = _currentRideInfo!['driverId'];

    // إظهار إشعار الوصول إلى الوجهة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم الوصول إلى الوجهة. انتهت الرحلة.'),
        backgroundColor: Colors.green,
      ),
    );

    // إنهاء الرحلة
    SocketService.instance.completeRide(
      rideId: rideId,
      driverId: driverId,
    );

    // إعادة السائق إلى حالة متاح
    setState(() {
      _isAvailable = true;
      _polylinePoints = [];
      _currentRideInfo = null;
    });

    // إرسال إشعار بالوصول إلى الوجهة
    SocketService.instance.socket?.emit('ride:destination_reached', {
      'rideId': rideId,
      'driverId': driverId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // رسم مسار بسيط وسريع - تحسين لإظهار السيارة فقط
  // تم تحسين هذه الدالة لاستخدام _updateDriverMarker بدلاً من إنشاء علامة جديدة في كل مرة
  void _drawSimpleRoute(latlong.LatLng start, latlong.LatLng end) {
    try {
      // حساب الاتجاه
      final heading = _calculateHeading(
          start.latitude, start.longitude, end.latitude, end.longitude);

      // تحديث علامة السائق
      _updateDriverMarker(start, heading);

      setState(() {
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

      // إرسال معلومات المسار لجميع العملاء المتصلين
      if (_currentRideInfo != null && _currentRideInfo!['rideId'] != null) {
        // إنشاء كائن المسار
        final Map<String, dynamic> routeData = {
          'start': {
            'lat': start.latitude,
            'lng': start.longitude,
          },
          'end': {
            'lat': end.latitude,
            'lng': end.longitude,
          },
          'points': [
            {'lat': start.latitude, 'lng': start.longitude},
            {'lat': end.latitude, 'lng': end.longitude},
          ],
        };

        // إرسال تحديث المسار باستخدام الدالة المحسنة
        SocketService.instance.sendPlannedRouteUpdate(
          rideId: _currentRideInfo!['rideId'],
          route: routeData,
        );
      }
    } catch (e) {
      debugPrint('خطأ أثناء رسم المسار البسيط: $e');
    }
  }

  /// الحصول على اسم السائق من التفضيلات
  Future<String> _getDriverName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverName = prefs.getString('driver_name');

      if (driverName != null && driverName.isNotEmpty) {
        return driverName;
      } else {
        // استخدام اسم افتراضي إذا لم يكن موجودًا
        final driverId = await _getDriverId();
        final defaultName = 'Driver ${driverId.substring(driverId.length - 4)}';
        await prefs.setString('driver_name', defaultName);
        return defaultName;
      }
    } catch (e) {
      debugPrint('خطأ في الحصول على اسم السائق: $e');
      // إرجاع اسم افتراضي في حالة الخطأ
      return 'Driver';
    }
  }

  /// الحصول على معلومات المركبة من التفضيلات
  Future<String> _getVehicleInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vehicleInfo = prefs.getString('vehicle_info');

      if (vehicleInfo != null && vehicleInfo.isNotEmpty) {
        return vehicleInfo;
      } else {
        // استخدام معلومات افتراضية إذا لم تكن موجودة
        const defaultInfo = 'Standard Vehicle';
        await prefs.setString('vehicle_info', defaultInfo);
        return defaultInfo;
      }
    } catch (e) {
      debugPrint('خطأ في الحصول على معلومات المركبة: $e');
      // إرجاع معلومات افتراضية في حالة الخطأ
      return 'Standard Vehicle';
    }
  }

  /// بدء إرسال تحديثات الموقع مع معلومات إضافية للمسار الفعلي
  Future<void> _startLocationUpdates(String rideId) async {
    // في تطبيق حقيقي، سنستخدم موقع GPS الفعلي
    // هنا نقوم بمحاكاة تحديثات الموقع

    // مؤشر لتتبع الموقع الحالي في المسار
    int currentPointIndex = 0;

    // إجمالي عدد النقاط في المسار (للحساب النسبة المئوية للتقدم)
    final totalPoints = _polylinePoints.length;

    // الحصول على معلومات السائق والمركبة مسبقاً
    final driverName = await _getDriverName();
    final vehicleInfo = await _getVehicleInfo();

    // المسافة الإجمالية للرحلة (بالكيلومتر)
    double totalDistance = 0;

    // حساب المسافة الإجمالية للرحلة
    if (_polylinePoints.length > 1) {
      for (int i = 0; i < _polylinePoints.length - 1; i++) {
        totalDistance += _calculateDistance(
          _polylinePoints[i].latitude,
          _polylinePoints[i].longitude,
          _polylinePoints[i + 1].latitude,
          _polylinePoints[i + 1].longitude,
        );
      }
    }

    // الوقت المقدر للوصول (بالثواني)
    final estimatedTotalTime =
        (totalDistance / 30) * 3600; // بافتراض سرعة 30 كم/ساعة

    debugPrint('بدء تحديثات الموقع للرحلة $rideId');
    debugPrint('إجمالي المسافة: $totalDistance كم');
    debugPrint('الوقت المقدر: ${(estimatedTotalTime / 60).round()} دقيقة');

    // تحديث الموقع كل ثانية
    Timer.periodic(const Duration(seconds: 1), (timer) {
      // التحقق من أن الواجهة لا تزال موجودة
      if (!mounted) {
        timer.cancel();
        return;
      }

      // التحقق من وجود نقاط المسار
      if (_polylinePoints.isEmpty) {
        timer.cancel();
        return;
      }

      // الحصول على النقطة الحالية من المسار
      latlong.LatLng currentPoint;

      // حساب السرعة والاتجاه
      double speed = 0;
      double heading = 0;
      double distanceRemaining = 0;
      double progress = 0;
      int estimatedArrivalTime = 0;

      // إذا كان هناك أكثر من نقطتين في المسار، نتحرك على طول المسار
      if (_polylinePoints.length > 2) {
        // زيادة المؤشر للانتقال إلى النقطة التالية
        currentPointIndex = (currentPointIndex + 1) % _polylinePoints.length;
        currentPoint = _polylinePoints[currentPointIndex];

        // حساب النسبة المئوية للتقدم
        progress = (currentPointIndex / totalPoints) * 100;

        // حساب المسافة المتبقية
        distanceRemaining = 0;
        for (int i = currentPointIndex; i < _polylinePoints.length - 1; i++) {
          distanceRemaining += _calculateDistance(
            _polylinePoints[i].latitude,
            _polylinePoints[i].longitude,
            _polylinePoints[i + 1].latitude,
            _polylinePoints[i + 1].longitude,
          );
        }

        // حساب الوقت المقدر للوصول (بالثواني)
        estimatedArrivalTime = ((distanceRemaining / 30) * 3600)
            .round(); // بافتراض سرعة 30 كم/ساعة

        // حساب السرعة (كم/ساعة)
        if (currentPointIndex > 0) {
          final prevPoint = _polylinePoints[currentPointIndex - 1];
          final distanceToPrev = _calculateDistance(
            prevPoint.latitude,
            prevPoint.longitude,
            currentPoint.latitude,
            currentPoint.longitude,
          );
          speed = distanceToPrev * 3600; // تحويل إلى كم/ساعة

          // حساب الاتجاه (بالدرجات)
          heading = _calculateHeading(
            prevPoint.latitude,
            prevPoint.longitude,
            currentPoint.latitude,
            currentPoint.longitude,
          );
        }
      } else {
        // إذا كان هناك نقطتان فقط، نقوم بحساب نقطة وسيطة
        final startPoint = _polylinePoints.first;
        final endPoint = _polylinePoints.last;

        // حساب النسبة المئوية للتقدم (0-1)
        final progressRatio = timer.tick / 20.0; // 20 ثانية للوصول
        final clampedProgress = progressRatio.clamp(0.0, 1.0);

        // حساب النسبة المئوية للتقدم (0-100)
        progress = clampedProgress * 100;

        // حساب النقطة الوسيطة
        currentPoint = latlong.LatLng(
          startPoint.latitude +
              (endPoint.latitude - startPoint.latitude) * clampedProgress,
          startPoint.longitude +
              (endPoint.longitude - startPoint.longitude) * clampedProgress,
        );

        // حساب المسافة المتبقية
        distanceRemaining = _calculateDistance(
          currentPoint.latitude,
          currentPoint.longitude,
          endPoint.latitude,
          endPoint.longitude,
        );

        // حساب الوقت المقدر للوصول (بالثواني)
        estimatedArrivalTime = ((distanceRemaining / 30) * 3600)
            .round(); // بافتراض سرعة 30 كم/ساعة

        // حساب السرعة (كم/ساعة)
        speed = 30; // سرعة ثابتة للتبسيط

        // حساب الاتجاه (بالدرجات)
        heading = _calculateHeading(
          startPoint.latitude,
          startPoint.longitude,
          endPoint.latitude,
          endPoint.longitude,
        );
      }

      // إنشاء معلومات المسار
      final Map<String, dynamic> routeInfo = {
        'totalDistance': totalDistance,
        'distanceRemaining': distanceRemaining,
        'estimatedTotalTime': estimatedTotalTime,
        'currentSegment': currentPointIndex,
        'totalSegments': totalPoints,
      };

      // إرسال تحديث الموقع مع معلومات إضافية وبيانات السائق
      SocketService.instance.updateDriverLocation(
        rideId: rideId,
        location: {
          'lat': currentPoint.latitude,
          'lng': currentPoint.longitude,
        },
        routeInfo: routeInfo,
        speed: speed,
        heading: heading,
        estimatedArrivalTime: estimatedArrivalTime,
        distanceRemaining: distanceRemaining,
        progress: progress,
        // إضافة معلومات السائق والمركبة للتزامن بين العملاء
        driverName: driverName,
        vehicleInfo: vehicleInfo,
      );

      // إرسال موقع السائق لجميع المستخدمين
      SocketService.instance.broadcastDriverLocation(
        location: {
          'lat': currentPoint.latitude,
          'lng': currentPoint.longitude,
        },
        isAvailable: false, // السائق مشغول في رحلة
        routeInfo: routeInfo,
        speed: speed,
        heading: heading,
      );

      // تحديث موقع السائق على الخريطة باستخدام الدالة المحسنة
      if (mounted) {
        // تحديث علامة السائق
        _updateDriverMarker(currentPoint, heading);

        // تحديث نقاط المسار الفعلي إذا كان هناك أكثر من نقطة
        if (currentPointIndex > 0 && _polylinePoints.length > 1) {
          setState(() {
            // إنشاء مسار جديد يتضمن النقاط المتبقية فقط
            _polylinePoints = _polylinePoints.sublist(currentPointIndex);

            // إضافة النقطة الحالية في بداية المسار
            _polylinePoints.insert(0, currentPoint);
          });
        }

        // إرسال تحديث المسار الفعلي لجميع العملاء باستخدام الدالة المحسنة
        if (_currentRideInfo != null && _currentRideInfo!['rideId'] != null) {
          // تحويل نقاط المسار إلى تنسيق للإرسال
          final List<Map<String, dynamic>> actualRoutePoints = _polylinePoints
              .map((point) => {
                    'lat': point.latitude,
                    'lng': point.longitude,
                  })
              .toList();

          // الحصول على معلومات السائق والمركبة
          _getDriverName().then((driverName) {
            _getVehicleInfo().then((vehicleInfo) {
              // إرسال تحديث المسار الفعلي باستخدام الدالة المحسنة
              SocketService.instance.sendActualRouteUpdate(
                rideId: _currentRideInfo!['rideId'],
                routePoints: actualRoutePoints,
                currentLocation: {
                  'lat': currentPoint.latitude,
                  'lng': currentPoint.longitude,
                },
                heading: heading,
                speed: speed,
                progress: progress,
                driverName: driverName,
                vehicleInfo: vehicleInfo,
              );
            });
          });
        }
      }

      // إلغاء المؤقت بعد 30 ثانية (محاكاة انتهاء الرحلة) أو عند الوصول إلى نهاية المسار
      if (timer.tick > 30 ||
          (currentPointIndex == totalPoints - 1 &&
              _polylinePoints.length > 2)) {
        timer.cancel();
      }
    });
  }

  /// تحديث علامة السائق مع التدوير حسب الاتجاه
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

  /// حساب الاتجاه (بالدرجات) بين نقطتين
  double _calculateHeading(double lat1, double lon1, double lat2, double lon2) {
    // تحويل الإحداثيات من درجات إلى راديان
    final phi1 = lat1 * (3.14159265359 / 180);
    final phi2 = lat2 * (3.14159265359 / 180);
    final lambda1 = lon1 * (3.14159265359 / 180);
    final lambda2 = lon2 * (3.14159265359 / 180);

    // حساب الاتجاه
    final y = sin(lambda2 - lambda1) * cos(phi2);
    final x =
        cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(lambda2 - lambda1);
    final theta = atan2(y, x);

    // تحويل من راديان إلى درجات
    var heading = (theta * (180 / 3.14159265359) + 360) % 360;

    return heading;
  }

  void _markRideAsProcessed(String rideId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final processedRides = prefs.getStringList('processed_rides') ?? [];
      processedRides.add(rideId);
      await prefs.setStringList('processed_rides', processedRides);
    } catch (e) {
      debugPrint('Erreur lors du marquage de la demande comme traitée: $e');
    }
  }

  Future<void> _rejectRide(String rideId) async {
    try {
      // عرض مؤشر التحميل
      _showLoadingDialog('جاري رفض الرحلة...');

      final driverId = await _getDriverId();

      // تحديث حالة الرحلة عبر API
      await _rideService.updateRide(rideId, {
        'status': 'rejected',
        'rejectedBy': driverId,
      });

      // إرسال إشعار رفض الرحلة عبر Socket للتحديث في الوقت الفعلي
      SocketService.instance.rejectRide(
        rideId: rideId,
        driverId: driverId,
      );

      // تسجيل الرحلة كمعالجة
      _markRideAsProcessed(rideId);

      // إغلاق مؤشر التحميل
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        // عرض رسالة تأكيد
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفض الرحلة'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }

      debugPrint('Driver $driverId rejected ride $rideId');
    } catch (e) {
      debugPrint('خطأ أثناء رفض الرحلة: $e');

      // إغلاق مؤشر التحميل إذا كان مفتوحًا
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // قبول طلب مشاركة الرحلة مع تحسينات للتزامن وتكامل الذكاء الاصطناعي
  Future<void> _acceptRideSharing(String rideId, String newRiderId) async {
    try {
      // عرض مؤشر التحميل
      _showLoadingDialog('Adding new rider...');

      final driverId = await _getDriverId();
      final driverName = await _getDriverName();
      final vehicleInfo = await _getVehicleInfo();

      // الحصول على معلومات الرحلة الحالية
      final currentRideInfo = _currentRideInfo;
      Map<String, dynamic> routeData = {};

      if (currentRideInfo != null) {
        // إضافة معلومات المسار الحالي
        routeData = {
          'currentPickupLocation': currentRideInfo['pickupLocation'] != null
              ? {
                  'lat': (currentRideInfo['pickupLocation'] as latlong.LatLng)
                      .latitude,
                  'lng': (currentRideInfo['pickupLocation'] as latlong.LatLng)
                      .longitude,
                }
              : null,
          'currentDestination': currentRideInfo['destination'] != null
              ? {
                  'lat': (currentRideInfo['destination'] as latlong.LatLng)
                      .latitude,
                  'lng': (currentRideInfo['destination'] as latlong.LatLng)
                      .longitude,
                }
              : null,
          'currentStatus': currentRideInfo['status'],
        };
      }

      // إرسال إشعار قبول مشاركة الرحلة عبر Socket للتحديث في الوقت الفعلي
      // مع إضافة معلومات إضافية للتزامن بين العملاء
      SocketService.instance.socket?.emit('ride:sharing_response', {
        'rideId': rideId,
        'sharingRequestId': newRiderId,
        'accepted': true,
        'driverId': driverId,
        'driverName': driverName,
        'vehicleInfo': vehicleInfo,
        'timestamp': DateTime.now().toIso8601String(),
        'syncId': 'sync_${DateTime.now().millisecondsSinceEpoch}',
        'currentLocation': _currentPosition != null
            ? {
                'lat': _currentPosition!.latitude,
                'lng': _currentPosition!.longitude,
              }
            : null,
        'routeData': routeData,
        'aiEnabled': true, // تفعيل ميزة الذكاء الاصطناعي
      });

      // إغلاق مؤشر التحميل
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        // عرض رسالة تأكيد
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New rider added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // إرسال إشعار صوتي بإضافة راكب جديد
      _voiceService.speak('تم إضافة راكب جديد إلى الرحلة الحالية.');

      // تحديث حالة الرحلة في قاعدة البيانات
      try {
        await _rideService.updateRide(rideId, {
          'hasSharedRider': true,
          'sharedRiderIds': [newRiderId],
          'aiMatchingUsed': true,
        });

        // إرسال تحديث الموقع الحالي لجميع الركاب
        if (_currentPosition != null) {
          // إرسال تحديث الموقع لجميع العملاء المتصلين
          SocketService.instance.socket
              ?.emit('ride:location_update_all_clients', {
            'rideId': rideId,
            'driverId': driverId,
            'location': {
              'lat': _currentPosition!.latitude,
              'lng': _currentPosition!.longitude,
            },
            'timestamp': DateTime.now().toIso8601String(),
            'syncId': 'sync_${DateTime.now().millisecondsSinceEpoch}',
            'driverName': driverName,
            'vehicleInfo': vehicleInfo,
            'aiEnabled': true,
            'sharedRide': true,
            'sharedRiderIds': [newRiderId],
          });
        }
      } catch (updateError) {
        debugPrint('خطأ أثناء تحديث حالة الرحلة: $updateError');
      }

      debugPrint(
          'Driver $driverId accepted sharing request from $newRiderId for ride $rideId');
    } catch (e) {
      debugPrint('Error accepting ride sharing: $e');

      // إغلاق مؤشر التحميل إذا كان مفتوحًا
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // رفض طلب مشاركة الرحلة مع تحسينات للتزامن وتكامل الذكاء الاصطناعي
  Future<void> _rejectRideSharing(String rideId, String newRiderId) async {
    try {
      // عرض مؤشر التحميل
      _showLoadingDialog('Declining rider request...');

      final driverId = await _getDriverId();
      final driverName = await _getDriverName();
      final vehicleInfo = await _getVehicleInfo();

      // إرسال إشعار رفض مشاركة الرحلة عبر Socket للتحديث في الوقت الفعلي
      SocketService.instance.socket?.emit('ride:sharing_response', {
        'rideId': rideId,
        'sharingRequestId': newRiderId,
        'accepted': false,
        'driverId': driverId,
        'driverName': driverName,
        'vehicleInfo': vehicleInfo,
        'timestamp': DateTime.now().toIso8601String(),
        'syncId': 'sync_${DateTime.now().millisecondsSinceEpoch}',
        'reason': 'Driver declined the request',
        'currentLocation': _currentPosition != null
            ? {
                'lat': _currentPosition!.latitude,
                'lng': _currentPosition!.longitude,
              }
            : null,
        'aiEnabled': true, // تفعيل ميزة الذكاء الاصطناعي للتسجيل
      });

      // إغلاق مؤشر التحميل
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // إرسال إشعار صوتي برفض طلب مشاركة الرحلة
      _voiceService.speak('تم رفض طلب مشاركة الرحلة.');

      if (mounted) {
        // عرض رسالة تأكيد
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rider request declined'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // تحديث حالة الرحلة في قاعدة البيانات
      try {
        await _rideService.updateRide(rideId, {
          'rejectedSharingRequests': [newRiderId],
          'aiMatchingAttempted': true,
        });
      } catch (updateError) {
        debugPrint('خطأ أثناء تحديث حالة الرحلة: $updateError');
      }

      debugPrint(
          'Driver $driverId rejected sharing request from $newRiderId for ride $rideId');
    } catch (e) {
      debugPrint('Error rejecting ride sharing: $e');

      // إغلاق مؤشر التحميل إذا كان مفتوحًا
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _drawRoute(latlong.LatLng start, latlong.LatLng end) async {
    try {
      // Limpiar todos los marcadores y mostrar solo el coche
      setState(() {
        // Eliminar todos los marcadores
        _markers.clear();

        // Añadir solo el marcador del coche con rotación
        _markers.add(
          Marker(
            point: start,
            builder: (context) => Transform.rotate(
              angle: _calculateHeading(start.latitude, start.longitude,
                      end.latitude, end.longitude) *
                  (pi / 180),
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
                          red: 0,
                          green: 0,
                          blue: 0,
                          alpha: 51), // 0.2 * 255 = 51
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

      // First try to get detailed route from OSRM API with turn-by-turn directions
      try {
        // Use route service with detailed steps
        final String url = 'https://router.project-osrm.org/route/v1/driving/'
            '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
            '?overview=full&geometries=polyline&steps=true&annotations=true';

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['code'] != 'Ok') {
            throw Exception('OSRM API error: ${data["code"]}');
          }

          if (data['routes'] != null && data['routes'].isNotEmpty) {
            final route = data['routes'][0];
            final encodedPolyline = route['geometry'];
            final List<latlong.LatLng> points =
                _decodePolyline(encodedPolyline);

            // Get additional route information
            final distance = route['distance']; // in meters
            final duration = route['duration']; // in seconds

            // Get detailed steps for turn-by-turn navigation
            final List<dynamic> legs = route['legs'] ?? [];
            final List<Map<String, dynamic>> steps = [];

            // Extract all steps from all legs
            for (var leg in legs) {
              final legSteps = leg['steps'] ?? [];
              for (var step in legSteps) {
                final maneuver = step['maneuver'] ?? {};
                final stepGeometry = step['geometry'] ?? '';
                final stepDistance = step['distance'] ?? 0;
                final stepDuration = step['duration'] ?? 0;
                final stepName = step['name'] ?? '';

                steps.add({
                  'maneuver': maneuver,
                  'geometry': stepGeometry,
                  'distance': stepDistance,
                  'duration': stepDuration,
                  'name': stepName,
                  'points': _decodePolyline(stepGeometry),
                });
              }
            }

            // Format distance and duration
            final formattedDistance =
                (distance / 1000).toStringAsFixed(1); // km
            final formattedDuration = (duration / 60).round(); // minutes

            // Create waypoints for major turns and intersections
            final List<Marker> routeMarkers = [];

            for (var step in steps) {
              if (step['maneuver'] != null &&
                  step['maneuver']['type'] != 'depart' &&
                  step['maneuver']['type'] != 'arrive') {
                final maneuver = step['maneuver'];
                final location = latlong.LatLng(
                    maneuver['location'][1], maneuver['location'][0]);

                // Only add markers for significant turns
                if (maneuver['type'] == 'turn' ||
                    maneuver['type'] == 'roundabout' ||
                    maneuver['type'] == 'fork' ||
                    maneuver['type'] == 'merge') {
                  // Get turn direction
                  String direction = maneuver['modifier'] ?? 'straight';
                  IconData directionIcon;

                  // Choose appropriate icon based on direction
                  switch (direction) {
                    case 'right':
                      directionIcon = Icons.turn_right;
                      break;
                    case 'left':
                      directionIcon = Icons.turn_left;
                      break;
                    case 'slight right':
                      directionIcon = Icons.turn_slight_right;
                      break;
                    case 'slight left':
                      directionIcon = Icons.turn_slight_left;
                      break;
                    case 'sharp right':
                      directionIcon = Icons.turn_right;
                      break;
                    case 'sharp left':
                      directionIcon = Icons.turn_left;
                      break;
                    case 'uturn':
                      directionIcon = Icons.u_turn_right;
                      break;
                    default:
                      directionIcon = Icons.straight;
                  }

                  routeMarkers.add(
                    Marker(
                      point: location,
                      width: 30,
                      height: 30,
                      builder: (context) => Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(204),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: Icon(
                          directionIcon,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }
              }
            }

            setState(() {
              _polylinePoints = points;

              // No añadir marcadores de giro, solo actualizar los puntos de la ruta

              // Añadir solo el marcador del coche con rotación
              _markers.clear();
              _markers.add(
                Marker(
                  point: start,
                  builder: (context) => Transform.rotate(
                    angle: _calculateHeading(start.latitude, start.longitude,
                            points[1].latitude, points[1].longitude) *
                        (pi / 180),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(
                            red: 0, green: 122, blue: 255, alpha: 204),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                                red: 0, green: 0, blue: 0, alpha: 51),
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

            // Enviar la ruta detallada a todos los clientes
            if (_currentRideInfo != null &&
                _currentRideInfo!['rideId'] != null) {
              // Convertir los puntos a formato para enviar
              final List<Map<String, dynamic>> routePointsForSync = points
                  .map((point) => {
                        'lat': point.latitude,
                        'lng': point.longitude,
                      })
                  .toList();

              // Crear objeto de ruta
              final Map<String, dynamic> routeData = {
                'start': {
                  'lat': start.latitude,
                  'lng': start.longitude,
                },
                'end': {
                  'lat': end.latitude,
                  'lng': end.longitude,
                },
                'points': routePointsForSync,
                'steps': steps,
              };

              // Enviar actualización de ruta detallada usando el método mejorado
              SocketService.instance.sendDetailedRouteUpdate(
                rideId: _currentRideInfo!['rideId'],
                route: routeData,
                distance: distance / 1000, // convertir a km
                duration: duration / 60, // convertir a minutos
              );
            }

            // Show route information
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Route: $formattedDistance km, $formattedDuration min, ${steps.length} turns'),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 3),
                ),
              );
            }

            // Calculate bounds to fit the route
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

            // Add padding to bounds
            const paddingValue = 0.01; // Approximately 1km
            minLat -= paddingValue;
            maxLat += paddingValue;
            minLng -= paddingValue;
            maxLng += paddingValue;

            // Center the map to show the entire route
            _mapController.move(
              latlong.LatLng(
                (minLat + maxLat) / 2,
                (minLng + maxLng) / 2,
              ),
              13.0, // Zoom level to show the entire route
            );

            return;
          }
        }
      } catch (e) {
        debugPrint('Error getting detailed route from API: $e');
        // Try alternative API or continue with fallback method
      }

      // Try alternative API (Google Directions API or MapBox) if available
      // For now, fallback to simpler OSRM route if detailed route fails
      try {
        final String url = 'https://router.project-osrm.org/route/v1/driving/'
            '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
            '?overview=full&geometries=polyline';

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['code'] != 'Ok') {
            throw Exception('OSRM API error: ${data["code"]}');
          }

          if (data['routes'] != null && data['routes'].isNotEmpty) {
            final route = data['routes'][0];
            final encodedPolyline = route['geometry'];
            final points = _decodePolyline(encodedPolyline);

            // Get additional route information
            final distance = route['distance']; // in meters
            final duration = route['duration']; // in seconds

            // Format distance and duration
            final formattedDistance =
                (distance / 1000).toStringAsFixed(1); // km
            final formattedDuration = (duration / 60).round(); // minutes

            setState(() {
              _polylinePoints = points;

              // Limpiar todos los marcadores y añadir solo el coche
              _markers.clear();
              _markers.add(
                Marker(
                  point: start,
                  builder: (context) => Transform.rotate(
                    angle: _calculateHeading(
                            start.latitude,
                            start.longitude,
                            points.length > 1
                                ? points[1].latitude
                                : end.latitude,
                            points.length > 1
                                ? points[1].longitude
                                : end.longitude) *
                        (pi / 180),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(
                            red: 0, green: 122, blue: 255, alpha: 204),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                                red: 0, green: 0, blue: 0, alpha: 51),
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

            // Enviar la ruta a todos los clientes
            if (_currentRideInfo != null &&
                _currentRideInfo!['rideId'] != null) {
              // Convertir los puntos a formato para enviar
              final List<Map<String, dynamic>> routePointsForSync = points
                  .map((point) => {
                        'lat': point.latitude,
                        'lng': point.longitude,
                      })
                  .toList();

              // Crear objeto de ruta
              final Map<String, dynamic> routeData = {
                'start': {
                  'lat': start.latitude,
                  'lng': start.longitude,
                },
                'end': {
                  'lat': end.latitude,
                  'lng': end.longitude,
                },
                'points': routePointsForSync,
                'distance': (distance / 1000).toStringAsFixed(1),
                'duration': (duration / 60).round(),
              };

              // Enviar actualización de ruta usando el método mejorado
              SocketService.instance.sendPlannedRouteUpdate(
                rideId: _currentRideInfo!['rideId'],
                route: routeData,
              );
            }

            // Show route information
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Route: $formattedDistance km, $formattedDuration min'),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 3),
                ),
              );
            }

            // Calculate bounds to fit the route
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

            // Add padding to bounds
            const paddingValue = 0.01; // Approximately 1km
            minLat -= paddingValue;
            maxLat += paddingValue;
            minLng -= paddingValue;
            maxLng += paddingValue;

            // Center the map to show the entire route
            _mapController.move(
              latlong.LatLng(
                (minLat + maxLat) / 2,
                (minLng + maxLng) / 2,
              ),
              13.0, // Zoom level to show the entire route
            );

            return;
          }
        }
      } catch (e) {
        debugPrint('Error getting simple route from API: $e');
        // Continue with fallback method
      }

      // Fallback to direct line if all API calls fail
      setState(() {
        _polylinePoints = [start, end];

        // Limpiar todos los marcadores y añadir solo el coche
        _markers.clear();
        _markers.add(
          Marker(
            point: start,
            builder: (context) => Transform.rotate(
              angle: _calculateHeading(start.latitude, start.longitude,
                      end.latitude, end.longitude) *
                  (pi / 180),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue
                      .withValues(red: 0, green: 122, blue: 255, alpha: 204),
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

      // Enviar la ruta simple a todos los clientes usando el método mejorado
      if (_currentRideInfo != null && _currentRideInfo!['rideId'] != null) {
        // Crear objeto de ruta
        final Map<String, dynamic> routeData = {
          'start': {
            'lat': start.latitude,
            'lng': start.longitude,
          },
          'end': {
            'lat': end.latitude,
            'lng': end.longitude,
          },
          'points': [
            {'lat': start.latitude, 'lng': start.longitude},
            {'lat': end.latitude, 'lng': end.longitude},
          ],
          'isFallback': true,
        };

        // Enviar actualización de ruta usando el método mejorado
        SocketService.instance.sendPlannedRouteUpdate(
          rideId: _currentRideInfo!['rideId'],
          route: routeData,
        );
      }

      // Center the map to show the entire route
      _mapController.move(
        latlong.LatLng(
          (start.latitude + end.latitude) / 2,
          (start.longitude + end.longitude) / 2,
        ),
        13.0,
      );
    } catch (e) {
      debugPrint('Error drawing route: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to draw route: $e')),
        );
      }
    }
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
    return points;
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

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions permanently denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'تم رفض إذن الموقع بشكل دائم. يرجى تفعيله من إعدادات الجهاز'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
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
      });

      // تحريك الخريطة إلى الموقع الحالي
      _mapController.move(_currentPosition!, 15.0);

      // إرسال الموقع الحالي للسائق
      _broadcastCurrentLocation();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Mode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _getCurrentLocation();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تحديث الموقع الحالي...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          Switch(
            value: _isAvailable,
            onChanged: (value) {
              setState(() {
                _isAvailable = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isAvailable
                      ? 'You are now online'
                      : 'You are now offline'),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentPosition ?? _defaultPosition,
              zoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
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
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isAvailable ? 'You are online' : 'You are offline',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isAvailable ? Colors.green : Colors.red,
                          ),
                        ),
                        Switch(
                          value: _isAvailable,
                          activeColor: Colors.green,
                          onChanged: (value) {
                            setState(() {
                              _isAvailable = value;
                            });

                            // إرسال حالة السائق للخادم
                            if (value) {
                              SocketService.instance
                                  .setDriverAvailable(_driverId ?? '');
                            } else {
                              SocketService.instance
                                  .setDriverUnavailable(_driverId ?? '');
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_isAvailable
                                    ? 'You are now online'
                                    : 'You are now offline'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isAvailable
                          ? 'Waiting for ride requests...'
                          : 'Go online to receive ride requests',
                    ),

                    // عرض أزرار التحكم في الرحلة إذا كانت هناك رحلة نشطة
                    if (_currentRideInfo != null) ...[
                      const Divider(height: 24),
                      const Text(
                        'Active Ride',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _completeRide,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Complete Ride'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
