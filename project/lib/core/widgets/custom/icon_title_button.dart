import 'package:flutter/material.dart';
import 'package:project/core/constants/my_colors.dart';


class IconTitleButton extends StatelessWidget {
  final String title;
  final String icon;
  final VoidCallback onPressed;
  final Color? textColor;

  const IconTitleButton(
      {super.key,
        this.textColor,
      required this.title,
      required this.icon,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        children: [
          Image.asset(
            icon,
            width: 70,
            height: 70,
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            title,
            style: TextStyle(color:textColor?? MyColors.cSecondaryColor, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
