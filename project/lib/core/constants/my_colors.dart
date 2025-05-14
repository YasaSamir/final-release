import 'package:flutter/material.dart';

class MyColors {

  static const cSecondaryColor = Color(0xffF9FAFB);

  static const cBackgroundColor = Color(0xff191919);

  static const cGreenColor = Color(0xff08B783);

  static const cBrgndyColor = Color(0xffB7083C);

  static const cErrorColor = Color(0xffF44336);

  static const cSuccessColor = Color(0xff43A048);

  static const cWarningColor = Color(0xffFB8A00);

  static const cInfoColor = Color(0xffB8B8B8);
  static Color get primary => const Color(0xFF26A69A);
  static Color get secondary => const Color(0xff3369FF);
  static Color get primaryText => const Color(0xff282F39);
  static Color get primaryTextW => const Color(0xffFFFFFF);
  static Color get secondaryText => const Color(0xff7F7F7F);
  static Color get placeholder => const Color(0xffBBBBBB);
  static Color get lightGray => const Color(0xffDADEE3);
  static Color get lightWhite => const Color(0xffF2F5F7);

  static Color get red => const Color(0xffF4586C);

  static Color get bg => Colors.white;

}
extension AppContext on BuildContext {
  Size get size => MediaQuery.sizeOf(this);
  double get width => size.width;
  double get height => size.height;

  Future push(Widget widget) async {
    return Navigator.push(
      this,
      MaterialPageRoute(
        builder: (context) => widget,
      ),
    );
  }

  void pop() async {
    return Navigator.pop(this);
  }
}
