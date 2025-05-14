// import 'package:flutter/material.dart';
// import 'package:project/core/widgets/my_buttons.dart';
// import 'package:rflutter_alert/rflutter_alert.dart';
//
// import '../../../routes/app_router.dart';
//
// class PaymentSelection extends StatelessWidget {
//   PaymentSelection({super.key});
//
//   late String phoneNumber;
//
//   Widget _buildIconTextButton(String img, String text) {
//     return InkWell(
//       splashColor: Colors.black,
//       onTap: () {},
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           Container(
//             width: 50,
//             height: 50,
//             child: Image(image: AssetImage(img)),
//           ),
//           SizedBox(width: 40),
//           Text(text, style: TextStyle(color: Colors.white, fontSize: 24)),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double screenWidth = MediaQuery.of(context).size.width;
//     double screenHeight = MediaQuery.of(context).size.height;
//     return SafeArea(
//       child: Scaffold(
//         backgroundColor: Color(0xff1A1A1A),
//         body: Container(
//           margin: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.start,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Align(
//                 alignment: Alignment.topRight,
//                 child: TextButton(
//                   onPressed: () {
//                     Alert(
//                       context: context,
//                       onWillPopActive: false,
//                       style: AlertStyle(
//                         backgroundColor: const Color(0xff252525),
//                         descStyle: const TextStyle(
//                           fontSize: 18,
//                           color: Colors.white,
//                           fontFamily: 'Outfit',
//                         ),
//                       ),
//                       desc:
//                           "You won’t be able to request a ride without adding a payment method",
//                       content: Column(
//                         children: [
//                           DialogButton(
//                             onPressed: () {
//                               // Handle payment method action
//                             },
//                             color: Colors.black,
//                             child: const Text(
//                               'Add Payment Method Now',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.w700,
//                                 fontFamily: 'Outfit',
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 10), // Space between buttons
//                           DialogButton(
//                             onPressed: () {
//                               Navigator.of(
//                                 context,
//                               ).pushNamed(AppRoutes.pickupLocationScreen);
//                             },
//                             color: Colors.black,
//                             child: const Text(
//                               'DO THIS LATER',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.w700,
//                                 fontFamily: 'Outfit',
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ).show();
//                   },
//                   child: Text(
//                     'DO THIS LATER',
//                     style: TextStyle(color: Colors.blue, fontSize: 20),
//                   ),
//                 ),
//               ),
//               SizedBox(height: screenHeight * 0.05),
//               Center(
//                 child: Text(
//                   'Select your preferred payment method',
//                   style: TextStyle(fontSize: 18, color: Colors.white),
//                 ),
//               ),
//               SizedBox(height: screenHeight * 0.05),
//               _buildIconTextButton(
//                 'assets/images/Credit Card.png',
//                 'Credit Card',
//               ),
//               _buildIconTextButton('assets/images/Cash.png', 'Cash'),
//               SizedBox(height: screenHeight * 0.5),
//               PrimaryButton(text: 'Next', onClick: () {
//                 Navigator.of(
//                   context,
//                 ).pushNamed(AppRoutes.pickupLocationScreen);
//               }),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
