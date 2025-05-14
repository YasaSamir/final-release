// import 'package:flutter/material.dart';
// import 'package:project/features/auth/views/login/login.dart';
// import 'package:project/features/auth/views/login/notification_page.dart';
// import 'package:project/features/auth/views/onboarding/splash_view.dart';
// import 'package:project/features/auth/views/sign_up/choose_role_screen.dart';
// import 'package:project/features/ride/views/menu_Items/left_pass.dart';
// import 'package:project/features/ride/views/menu_Items/payment_screen.dart';
// import 'package:project/features/ride/views/menu_Items/trip_history.dart';
// import 'package:project/features/rider/home/home_screen.dart';
//
// // import '../features/auth/otp.dart';
// import '../features/auth/services/deep_link_services.dart';
// import '../features/auth/views/login/sign_up.dart';
// import '../features/auth/views/onboarding/onboarding_screen.dart';
// import '../features/auth/views/onboarding/start_screen.dart';
// import '../features/driver/views/driver_tracking.dart';
// import '../features/package/recipient_page.dart';
// import '../features/payment/views/payment_selection.dart';
// import '../features/payment/views/terms_conditions.dart';
//
// import '../features/ride/views/menu_Items/message_screen.dart';
// import '../features/ride/views/package_delivery.dart';
// import '../features/ride/views/pickup_location_screen.dart';
// import '../features/ride/views/pickup_point.dart';
// import 'app_router.dart';
//
// class OnGenerateRoute {
//   Route? generateRoute(RouteSettings settings) {
//     switch (settings.name) {
//       case AppRoutes.splashScreen:
//         return MaterialPageRoute(
//           builder: (_) => const SplashView(),
//           settings: settings,
//         );
//       case AppRoutes.onboardingScreen:
//         return MaterialPageRoute(
//           builder: (_) => const OnboardingScreen(),
//           settings: settings,
//         );
//       // case AppRoutes.startScreen:
//       //   return MaterialPageRoute(
//       //     builder: (_) => const  StartScreen(),
//       //     settings: settings,
//       //   );
//       // case AppRoutes.chooseRoleScreen:
//       //     return MaterialPageRoute(
//       //       builder: (_) => const  ChooseRoleScreen(),
//       //       settings: settings,
//       //     );
//       case AppRoutes.loginScreen:
//         return MaterialPageRoute(
//           builder: (_) => const Login(),
//           settings: settings,
//         );
//       case AppRoutes.signUpScreen:
//         return MaterialPageRoute(
//           builder: (_) => const Login(),
//           settings: settings,
//         );
//         case AppRoutes.driverHomeScreen:
//         return MaterialPageRoute(
//           builder: (_) => const DriverRegistrationScreen(),
//           settings: settings,
//         );
//         case AppRoutes.riderHomeScreen:
//         return MaterialPageRoute(
//           builder: (_) => const HomeScreen(),
//           settings: settings,
//         );
//
//       // case AppRoutes.loginWithSocial:
//       //   return MaterialPageRoute(
//       //     builder: (_) => const LoginWithSocial(),
//       //     settings: settings,
//       //   );
//       // case AppRoutes.otp:
//       //   return MaterialPageRoute(
//       //     builder: (_) =>  OtpScreen(),
//       //     settings: settings,
//       //   );
//       // case AppRoutes.homeScreen:
//       //   return MaterialPageRoute(
//       //     builder: (_) =>const  HomeScreen(),
//       //     settings: settings,
//       //   );
//       // case AppRoutes.paymentSelection:
//       //   return MaterialPageRoute(
//       //     builder: (_) => PaymentSelection(),
//       //     settings: settings,
//       //   );
//       // case AppRoutes.termsConditions:
//       //   return MaterialPageRoute(
//       //     builder: (_) => TermsConditions(),
//       //     settings: settings,
//       //   );
//       // case AppRoutes.pickupLocationScreen:
//       //   return MaterialPageRoute(
//       //     builder: (_) => const PickupLocationScreen(),
//       //     settings: settings,
//       //   );
//       // case AppRoutes.packageDelivery:
//       //   return MaterialPageRoute(
//       //     builder: (_) => const PackageDelivery(),
//       //     settings: settings,
//       //   );
//       // case AppRoutes.pickupPoint:
//       //   return MaterialPageRoute(
//       //     builder: (_) => const PickupPoint(),
//       //     settings: settings,
//       //   );
//       // case AppRoutes.recipientScreen:
//       //   return MaterialPageRoute(
//       //     builder: (_) =>const  RecipientPage(),
//       //     settings: settings,
//       //   );
//       // case AppRoutes.messageScreen:
//       //   return MaterialPageRoute(
//       //     builder: (_) => const MessageScreen(),
//       //     settings: settings,
//       //   );
//       // case AppRoutes.tripHistory:
//       //   return MaterialPageRoute(
//       //     builder: (_) => const TripHistory(),
//       //     settings: settings,
//       //   );
//       // case AppRoutes.paymentScreen:
//       //   return MaterialPageRoute(
//       //     builder: (_) =>const PaymentScreen(),
//       //     settings: settings,
//       //   );
//       // case AppRoutes.leftPassScreen:
//       //   return MaterialPageRoute(
//       //     builder: (_) => const LeftPass(),
//       //     settings: settings,
//       //   );
//     }
//     return null;
//   }
// }
