// import 'package:auto_size_text/auto_size_text.dart';
// import 'package:flutter/material.dart';
// import 'package:project/routes/app_router.dart';
//
// import '../../../core/constants/my_colors.dart';
//
// class PickupPoint extends StatelessWidget {
//   const PickupPoint({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     double screenWidth = MediaQuery.of(context).size.width;
//     double screenHeight = MediaQuery.of(context).size.height;
//     return Scaffold(
//       backgroundColor: MyColors.cBackgroundColor,
//       appBar: AppBar(
//         backgroundColor: MyColors.cBackgroundColor,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Colors.white, size: 16),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         actions: [
//           Padding(
//             padding: EdgeInsets.only(right: screenWidth * 0.038),
//             child: Row(
//               children: [
//                 Image.asset(
//                   'assets/icon/person.png',
//                   height: screenHeight * 0.054,
//                   width: screenWidth * 0.119,
//                 ),
//                 AutoSizeText(
//                   "Contacts",
//                   style: TextStyle(color: Colors.white, fontSize: 16),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TextField(
//               decoration: InputDecoration(
//                 filled: true,
//                 fillColor: Colors.black,
//                 hintText: "Enter pickup point",
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 hintStyle: TextStyle(
//                   fontWeight: FontWeight.w400,
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontFamily: 'Roboto',
//                 ),
//               ),
//             ),
//             SizedBox(height: 10),
//             TextField(
//               decoration: InputDecoration(
//                 filled: true,
//                 fillColor: Colors.black,
//                 hintText: "Where to?",
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 hintStyle: TextStyle(
//                   fontWeight: FontWeight.w400,
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontFamily: 'Roboto',
//                 ),
//               ),
//             ),
//             SizedBox(height: 20),
//             ListTile(
//               leading: Image.asset(
//                 'assets/icon/saved_places.png',
//                 height: 30,
//                 width: 30,
//               ),
//               title: Text(
//                 "Saved Places",
//                 style: TextStyle(color: Colors.white),
//               ),
//               onTap: () {
//                 Navigator.of(context).pushNamed(AppRoutes.recipientScreen);
//               },
//             ),
//             ListTile(
//               leading: Image.asset(
//                 'assets/icon/location.png',
//                 height: 30,
//                 width: 30,
//               ),
//               title: Text(
//                 "Set location on map",
//                 style: TextStyle(color: Colors.white),
//               ),
//               onTap: () {},
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
