import 'package:flutter/material.dart';
import 'package:project/core/constants/my_colors.dart';

import 'onboarding_screen.dart';


class ChangeLanguageView extends StatefulWidget {
  const ChangeLanguageView({super.key});

  @override
  State<ChangeLanguageView> createState() => _ChangeLanguageViewState();
}

class _ChangeLanguageViewState extends State<ChangeLanguageView> {
  List listArr = ["Arabic", "English", "French", "German", "Spanish"];

  int selectChange = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choose language",
              style: TextStyle(
                  color:MyColors.cBackgroundColor,
                  fontSize: 25,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(
              height: 15,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: listArr.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: (){
                      setState(() {
                        selectChange = index;
                      });
                      context.push( const OnboardingScreen() );
                    },
                    title: Text(
                      listArr[index],
                      style: TextStyle(
                          color: index == selectChange
                              ? MyColors.cBackgroundColor
                              : MyColors.cBackgroundColor,
                          fontSize: 16),
                    ),
                    trailing: index == selectChange
                        ? Image.asset("assets/images/check_tick.png", width: 25)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
