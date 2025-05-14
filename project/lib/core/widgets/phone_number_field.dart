import 'package:flutter/material.dart';

class PhoneNumberField extends StatelessWidget {
  final String countryName;
  final TextEditingController controller;
  final Color textColor;

  const PhoneNumberField({
    Key? key,
    this.countryName = 'eg',
    required this.controller,
    this.textColor = Colors.white,
  }) : super(key: key);

  /// Generates a country flag emoji from the country code
  String generateCountryFlag() {
    return countryName.toUpperCase().replaceAllMapped(
      RegExp(r'[A-Z]'),
          (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Text(
              '${generateCountryFlag()}  +20' ,
              style: TextStyle(
                fontSize: 18,
                letterSpacing: 2.0,
                color: textColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: TextFormField(
              controller: controller,
              cursorColor: textColor,
              style: TextStyle(
                fontSize: 18,
                letterSpacing: 2.0,
                color: textColor,
              ),
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number.';
                } else if (value.length < 11) {
                  return 'Please enter a valid phone number.';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }
}
