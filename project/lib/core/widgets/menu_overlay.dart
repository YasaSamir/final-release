import 'package:flutter/material.dart';
import 'package:project/features/ride/views/menu_Items/account_settings.dart';

import '../../routes/app_router.dart';

class MenuOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        child: Container(
          height: screenHeight,
          width: screenWidth * 0.9,
          color: Colors.black,
          child: Padding(
            padding: const EdgeInsets.only(left: 40, top: 100, right: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 40,
                        child: Image.asset(
                          'assets/icon/person2.png',
                          width: 70,
                          height: 70,
                        ),
                      ),
                      title: Text(
                        "Dot Phasor",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Divider(color: Colors.grey),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: (){
                              // Navigator.of(context).pushNamed(AppRoutes.messageScreen);
                            },
                            child: Row(
                              children: [
                                Text(
                                  'Messages',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                                SizedBox(width: 6),
                                CircleAvatar(
                                  radius: 4,
                                  backgroundColor: Colors.blue,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
                _menuItem(Icons.directions_car, "Your Trips", () {
                  // Navigator.of(context).pushNamed(AppRoutes.tripHistory);
                }),
                _menuItem(Icons.payment, "Payment", () {
                  // Navigator.of(context).pushNamed(AppRoutes.paymentScreen);
                }),
                _menuItem(Icons.card_membership, "Left Pass", () {
                  // Navigator.of(context).pushNamed(AppRoutes.leftPassScreen);
                }),
                _menuItem(Icons.settings, "Settings", () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context)=> AccountSettings()));
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onClick) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w400,
          fontFamily: 'Roboto',
        ),
      ),
      onTap: onClick,
    );
  }
}
