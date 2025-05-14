import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Buttons extends StatelessWidget {
  const Buttons({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton(
        // onPressed: () {
        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => OtpScreen(),
        //     ),
        //   );

        onPressed: () {},
        child: Text(
          'Next',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: Size(400, 50),
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}


class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onClick;

  const PrimaryButton({
    Key? key,
    required this.text,
    required this.onClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      width: double.infinity,
      height: screenHeight*0.06,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onClick,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class LabelButtonWithIcon extends StatelessWidget {
  LabelButtonWithIcon({super.key, required this.label, this.width=20, this.img});
  final String label;
  final double width;
  final String? img;

  @override
  Widget build(BuildContext context) {
    double screenWidth= MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width),
      child: TextField(
        decoration: InputDecoration(
          alignLabelWithHint: false,
          contentPadding: EdgeInsets.all(8),
          suffixIcon: img == null ? null : Image.asset(img!),

          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(color: Colors.black54, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.black54, width: 2),
          ),
        ),
      ),
    );
  }
}
