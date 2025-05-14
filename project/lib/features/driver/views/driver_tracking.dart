import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../../core/services/api_service.dart';
import '../../../core/config/api_config.dart';
import '../../auth/views/login/login.dart';
// import 'driver_map_screen.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  _DriverRegistrationScreenState createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  // final supabase = Supabase.instance.client;
  XFile? _profileImage;
  XFile? _licenseImage;
  XFile? _registrationImage;
  XFile? _insuranceImage;
  final ImagePicker _picker = ImagePicker();

  // Form controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  String? _vehicleType;

  Future<void> _pickImage(String type) async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          switch (type) {
            case 'profile':
              _profileImage = pickedFile;
              break;
            case 'license':
              _licenseImage = pickedFile;
              break;
            case 'registration':
              _registrationImage = pickedFile;
              break;
            case 'insurance':
              _insuranceImage = pickedFile;
              break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<String?> _uploadImage(XFile image, String folder) async {
    try {
      final fileBytes = await image.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      // Instead of using Supabase, upload the image to your backend if needed, or skip this step.
      return null; // Placeholder return, actual implementation needed
    } catch (e) {
      if (kDebugMode) print('Upload error: $e');
      return null;
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Upload images and get URLs
      String? profileUrl = _profileImage != null
          ? await _uploadImage(_profileImage!, 'profiles')
          : null;
      String? licenseUrl = _licenseImage != null
          ? await _uploadImage(_licenseImage!, 'licenses')
          : null;
      String? registrationUrl = _registrationImage != null
          ? await _uploadImage(_registrationImage!, 'registrations')
          : null;
      String? insuranceUrl = _insuranceImage != null
          ? await _uploadImage(_insuranceImage!, 'insurance')
          : null;

      // Instead of using Supabase, use your API:
      await ApiService.instance.post(
        '/drivers/register',
        ApiConfig.getHeaders(),
        data: {
          'full_name': _fullNameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'license_number': _licenseNumberController.text,
          'vehicle_type': _vehicleType ?? '',
          'vehicle_year': int.parse(_vehicleYearController.text),
          'profile_image_url': profileUrl ?? '',
          'license_image_url': licenseUrl ?? '',
          'registration_image_url': registrationUrl ?? '',
          'insurance_image_url': insuranceUrl ?? '',
          'status': 'pending', // Initial status
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully')),
      );

      // Clear form
      _formKey.currentState!.reset();
      setState(() {
        _profileImage = null;
        _licenseImage = null;
        _registrationImage = null;
        _insuranceImage = null;
        _vehicleType = null;
      });

      // Navigate to driver map screen after successful registration
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DriverMapScreen()),
      );
    } catch (e) {
      if (kDebugMode) print('Submission error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting application: $e')),
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseNumberController.dispose();
    _vehicleYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Registration")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () => _pickImage('profile'),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImage != null
                          ? FileImage(File(_profileImage!.path))
                          : null,
                      child: _profileImage == null
                          ? const Icon(Icons.camera_alt,
                              size: 30, color: Colors.grey)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: "Full Name"),
                  validator: (value) =>
                      value!.isEmpty ? "Enter your name" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email Address"),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value!.contains("@") ? null : "Enter a valid email",
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: "Phone Number"),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value!.isEmpty ? "Enter phone number" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _licenseNumberController,
                  decoration: const InputDecoration(
                      labelText: "Driver's License Number"),
                  validator: (value) =>
                      value!.isEmpty ? "Enter license number" : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Vehicle Type"),
                  value: _vehicleType,
                  items: ["Car", "Motorcycle", "Van", "Truck"]
                      .map((type) =>
                          DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => setState(() => _vehicleType = value),
                  validator: (value) =>
                      value == null ? "Select vehicle type" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _vehicleYearController,
                  decoration:
                      const InputDecoration(labelText: "Vehicle Model Year"),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty || int.tryParse(value) == null
                          ? "Enter a valid year"
                          : null,
                ),
                const SizedBox(height: 20),
                const Text("Required Documents",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ListTile(
                  title: const Text("Driver's License"),
                  trailing: TextButton(
                    onPressed: () => _pickImage('license'),
                    child: Text(_licenseImage == null ? "Upload" : "Uploaded"),
                  ),
                ),
                ListTile(
                  title: const Text("Vehicle Registration"),
                  trailing: TextButton(
                    onPressed: () => _pickImage('registration'),
                    child: Text(
                        _registrationImage == null ? "Upload" : "Uploaded"),
                  ),
                ),
                ListTile(
                  title: const Text("Insurance Document"),
                  trailing: TextButton(
                    onPressed: () => _pickImage('insurance'),
                    child:
                        Text(_insuranceImage == null ? "Upload" : "Uploaded"),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitApplication,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 40),
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text("Submit Application",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DriverMapScreen extends StatelessWidget {
  const DriverMapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Map'),
      ),
      body: const Center(
        child: Text(
          'Welcome to the Driver Map Screen!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختر نوع المستخدم')),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Login(),
                  ),
                );
              },
              child: const Text('Rider'),
            ),
            const SizedBox(width: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const Login(),
                  ),
                );
              },
              child: const Text('Driver'),
            ),
          ],
        ),
      ),
    );
  }
}

// class DriverMapScreen extends StatefulWidget {
//   const DriverMapScreen({super.key});
//
//   @override
//   _DriverMapScreenState createState() => _DriverMapScreenState();
// }
//
// class _DriverMapScreenState extends State<DriverMapScreen> {
//   final supabase = Supabase.instance.client;
//   List<Map<String, dynamic>> nearbyDrivers = [];
//   RealtimeChannel? _channel;
//
//   @override
//   void initState() {
//     super.initState();
//     _subscribeToDriverLocations();
//   }
//
//   void _subscribeToDriverLocations() {
//     _channel = supabase
//         .from('driver_locations')
//         .on(
//       RealtimeListenTypes.postgresInsert,
//           (payload) {
//         _fetchNearbyDrivers();
//       },
//     )
//         .subscribe();
//
//     _fetchNearbyDrivers();
//   }
//
//   Future<void> _fetchNearbyDrivers() async {
//     try {
//       // Example: Rider's current location (hardcoded for demo)
//       const riderLat = 40.730610;
//       const riderLng = -73.935242;
//
//       final response = await supabase.rpc('nearby_drivers', params: {
//         'rider_lat': riderLat,
//         'rider_lng': riderLng,
//         'radius': 5000, // 5km radius
//       });
//
//       if (response != null) {
//         setState(() {
//           nearbyDrivers = List<Map<String, dynamic>>.from(response as List);
//         });
//       }
//     } catch (e) {
//       if (kDebugMode) print('Error fetching drivers: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching nearby drivers: $e')),
//       );
//     }
//   }
//
//   @override
//   void dispose() {
//     if (_channel != null) {
//       supabase.removeChannel(_channel!);
//     }
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Nearby Drivers')),
//       body: nearbyDrivers.isEmpty
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//         itemCount: nearbyDrivers.length,
//         itemBuilder: (context, index) {
//           final driver = nearbyDrivers[index];
//           return ListTile(
//             title: Text('Driver ${driver['driver_id'] ?? 'Unknown'}'),
//             subtitle: Text('Lat: ${driver['lat'] ?? 'N/A'}, Lng: ${driver['lng'] ?? 'N/A'}'),
//           );
//         },
//       ),
//     );
//   }
// }
//
