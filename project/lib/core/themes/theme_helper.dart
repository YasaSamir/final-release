// import 'package:flutter/material.dart';
// import 'package:project/core/app_export.dart';
// import 'package:project/core/themes/theme_helper.dart';
// String _appTheme = "lightCode";
//
// LightCodeColors get appTheme => ThemeHelper().themeColor();
// ThemeData get theme => ThemeHelper().themeData();
//
// /// Helper class for managing themes and colors.
// class ThemeHelper {
//   // A map of custom color themes supported by the app
//   Map<String, LightCodeColors> _supportedCustomColor = {
//     "lightCode": LightCodeColors()
//   };
//
//   // A map of color schemes supported by the app
//   Map<String, ColorScheme> _supportedColorScheme = {
//     "lightCode": ColorSchemes.lightCodeColorScheme
//   };
//
//   /// Changes the app theme to [_newTheme].
//   void changeTheme(String newTheme) {
//     _appTheme = newTheme;
//   }
//
//   /// Returns the LightCode colors for the current theme.
//   LightCodeColors _getThemeColors() {
//     return _supportedCustomColor[_appTheme] ?? LightCodeColors();
//   }
//
//   /// Returns the current theme data.
//   ThemeData _getThemeData() {
//     var colorScheme = _supportedColorScheme[_appTheme] ?? ColorSchemes.lightCodeColorScheme;
//
//     return ThemeData(
//       colorScheme: colorScheme,
//       textTheme: TextThemes.textTheme(colorScheme),
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: colorScheme.secondaryContainer,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8.h),
//           ),
//           elevation: 0,
//           visualDensity: const VisualDensity(
//             vertical: -4,
//             horizontal: -4,
//           ),
//           padding: EdgeInsets.zero,
//         ),
//       ),
//       outlinedButtonTheme: OutlinedButtonThemeData(
//         style: OutlinedButton.styleFrom(
//           backgroundColor: Colors.transparent,
//           side: BorderSide(
//             color: appTheme.blueGray10001,
//             width: 1.h,
//           ),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8.h),
//           ),
//           visualDensity: const VisualDensity(
//             vertical: -4,
//             horizontal: -4,
//           ),
//           padding: EdgeInsets.zero,
//         ),
//       ),
//     );
//   }
// }
// /// Returns the LightCode colors for the current theme.
// LightCodeColors themeColor() => _getThemeColors();
//
// /// Returns the current theme data.
// ThemeData themeData() => _getThemeData();
//
// /// Class containing the supported text theme styles.
// class TextThemes {
//   static TextTheme textTheme(ColorScheme colorScheme) => TextTheme(
//     bodyLarge: TextStyle(
//       color: appTheme.whiteA700,
//       fontSize: 16.5fSize,
//       fontFamily: 'Roboto',
//       fontWeight: FontWeight.w400,
//     ),
//     bodyMedium: TextStyle(
//       color: appTheme.whiteA700,
//       fontSize: 14.5fSize,
//       fontFamily: 'Roboto',
//       fontWeight: FontWeight.w400,
//     ),
//     titleLarge: TextStyle(
//       color: appTheme.whiteA700,
//       fontSize: 28.5fSize,
//       fontFamily: 'Roboto',
//       fontWeight: FontWeight.w600,
//     ),
//     titleMedium: TextStyle(
//       color: appTheme.whiteA700,
//       fontSize: 16.5fSize,
//       fontFamily: 'Roboto',
//       fontWeight: FontWeight.w600,
//     ),
//   );
// }
//
// /// Class containing the supported color schemes.
// class ColorSchemes {
//   static final lightCodeColorScheme = ColorScheme.light(
//     primary: Color(0xFFF80000),
//     secondaryContainer: Color(0xFF5135AF),
//     onPrimary: Color(0xFF191919),
//     onPrimaryContainer: Color(0xFF797979),
//   );
// }
//
// /// Class containing custom colors for a lightCode theme.
// class LightCodeColors {
//   // Blue
//   Color get blue50 => Color(0xFFDBEDAF);
//   Color get blueA100 => Color(0xFF8EC7FF);
//   Color get blueA200 => Color(0xFF73B9FF);
//   Color get blueA700 => Color(0xFF253E8B);
//
//   // BlueGray
//   Color get blueGray100 => Color(0xFFC9D9DD);
//   Color get blueGray10001 => Color(0xFFDD5DBB);
//
//   // Gray
//   Color get gray50 => Color(0xFFF8F8FB);
//   Color get gray100 => Color(0xFFF5F5F5);
//   Color get gray200 => Color(0x
// }
//
// final darkCodeColorScheme = ColorScheme.dark(
//       primary: Color(0xFF121212),
//   secondaryContainer: Color(0xFF1F1B24),
//   onPrimary: Color(0xFFFFFFFF),
//   onPrimaryContainer: Color(0xFFB0B0B0),
//   );
