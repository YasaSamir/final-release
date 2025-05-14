import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:project/features/auth/services/deep_link_services.dart';

import '../../../../core/constants/my_colors.dart';
import '../../../../core/widgets/custom/icon_title_button.dart';
import '../../../rider/home/favorites_places.dart';
import '../../../rider/home/home_screen.dart';
import '../../../rider/home/offers_screen.dart';
import '../../../rider/home/profile_screen.dart';
import '../../../rider/home/wallet_screen.dart';


class ServiceSelectionPage extends StatefulWidget {
  const ServiceSelectionPage({super.key});

  @override
  State<ServiceSelectionPage> createState() => _ServiceSelectionPageState();
}

class _ServiceSelectionPageState extends State<ServiceSelectionPage> {
  bool isMapReady = false;
  int _selectedIndex = 0;
  final List<Widget Function(BuildContext)> _pageBuilders = [];

  @override
  void initState() {
    super.initState();
    _pageBuilders.addAll([
          (context) => _buildGoogleMapPage(),
          (context) => const FavoritePlacesList(),
          (context) => const WalletScreen(),
          (context) => OfferScreen(),
          (context) => const ProfileScreen(),
    ]);
  }

  @override
  void dispose() {

    super.dispose();
  }

  Widget _buildPromoBannerWidget({
    Color? textColor ,
    required String imagePath,
    required String discountText,
    required String description,
    Color backgroundColor = const Color(0xFF26A69A),
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.25,
            height: MediaQuery.of(context).size.width * 0.25,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.error, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  discountText,
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style:  TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMapPage() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipOval(
                  child: Image.asset(
                    "assets/images/logo-removebg-preview.png",
                    width: 130,
                  ),
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome to Ride Sharing",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: 150,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        children: [
                          _buildPromoBannerWidget(
                            description: "Enjoy Your First Ride",
                            discountText: "50% off",
                            imagePath: "assets/images/convertible car-bro.png",
                          ),
                          _buildPromoBannerWidget(
                            description: "Enjoy Your Second Ride",
                            discountText: "20% off",
                            imagePath: "assets/images/City driver-rafiki.png",
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconTitleButton(
                            title: 'Car',
                            textColor: Colors.black,
                            icon: 'assets/images/modern_car.png',
                            onPressed: () {
                             // context.push(UserHomeView());
                              context.push(const HomeScreen());
                            },
                          ),
                          IconTitleButton(
                            title: 'Package',
                            textColor: Colors.black,

                            icon: 'assets/images/modern_van.png',
                            onPressed: () {
                              // context.push(UserHomeView());
                            },
                          ),
                          IconTitleButton(
                            title: 'Share Car',
                            textColor: Colors.black,

                            icon: 'assets/images/shared_car.png',
                            onPressed: () {
                              // context.push(UserHomeView());
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Where to go?',
                              hintStyle: const TextStyle(color: Colors.grey),
                              suffixIcon: const Icon(Icons.search,
                                  color: Color(0xFF26A69A)),
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              'Check out our latest offers',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 300,
                            child: ListView(
                              scrollDirection: Axis.vertical,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              children: [
                                _buildPromoBannerWidget(
                                backgroundColor: Colors.black12,
                                textColor: Colors.black,
                                description: "Today Offer",
                                discountText: "10% off",
                                imagePath: "assets/images/offer_3.png",
                              ),
                                _buildPromoBannerWidget(
                                  description: "Enjoy Your First Ride",
                                  discountText: "50% off",
                                  textColor: Colors.black,
                                  backgroundColor: Colors.amber.withOpacity(0.1),
                                  imagePath: "assets/images/offer_1.png",
                                ),
                                _buildPromoBannerWidget(
                                  description: "Limited Time Discount",
                                  discountText: "20% off",
                                  textColor: Colors.black,
                                  backgroundColor: Colors.purple.withOpacity(0.2),
                                  imagePath: "assets/images/offer_2.png",
                                ),

                                const SizedBox(
                                  height: 30,
                                )
                              ],
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pageBuilders.isEmpty || _selectedIndex < 0 || _selectedIndex >= _pageBuilders.length) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MyColors.primary,
      body: _pageBuilders[_selectedIndex](context),
      bottomNavigationBar: SafeArea(
        child: CurvedNavigationBar(
          backgroundColor: Colors.white,
          color: MyColors.primary.withOpacity(0.8),
          height: 60,
          index: _selectedIndex,
          items: const [
            Icon(Icons.home, size: 40, color: Colors.white),
            Icon(Icons.favorite, size: 40, color: Colors.white),
            Icon(Icons.account_balance_wallet, size: 40, color: Colors.white),
            Icon(Icons.local_offer, size: 40, color: Colors.white),
            Icon(Icons.person, size: 40, color: Colors.white),
          ],
          onTap: (index) {
            debugPrint("Selected index: $index");
            if (index >= 0 && index < _pageBuilders.length) {
              setState(() {
                _selectedIndex = index;
              });
            }
          },
        ),
      ),
    );
  }
}