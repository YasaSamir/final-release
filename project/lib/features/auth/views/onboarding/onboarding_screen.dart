import 'package:flutter/material.dart';
import 'package:project/routes/app_router.dart';
import '../login/login.dart';
import '../login/sign_up.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  List<Map<String, String>> onboardingData = [
    {
      "image": "assets/images/onboarding1.jpg",
      "title": "Anywhere you are",
      "description":
          "Sell houses easily with the help of Listenaryo and to make this line big I am writing more.",
    },
    {
      "image": "assets/images/onboarding2.jpg",
      "title": "At anytime",
      "description":
          "Sell houses easily with the help of Listenaryo and to make this line big I am writing more.",
    },
    {
      "image": "assets/images/onboarding3.jpg",
      "title": "Book your car",
      "description":
          "Sell houses easily with the help of Listenaryo and to make this line big I am writing more.",
    },
    {
      "image": "assets/images/onboarding4.jpg",
      "title": "Welcome",
      "description": "Have a better sharing experience.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    double size = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: onboardingData.length,
              itemBuilder: (context, index) {
                return OnboardingPage(
                  image: onboardingData[index]["image"]!,
                  title: onboardingData[index]["title"]!,
                  description: onboardingData[index]["description"]!,
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              onboardingData.length,
              (index) => buildDot(index, context),
            ),
          ),
          const SizedBox(height: 20),
          _currentPage == onboardingData.length - 1
              ? Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: size*0.8,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 32,
                          ),
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () {
                         Navigator.of(context).push(MaterialPageRoute(builder: (context)=> const SignUpScreen()));
                        },
                        child: const Text(
                          "Create an account",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: size*0.8,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 32,
                          ),
                          side: const BorderSide(color: Colors.green),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context)=> const Login()));

                        },
                        child: const Text(
                          "Log in",
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () {
                    if (_currentPage == onboardingData.length - 1) {
                      Navigator.pushNamed(context, AppRoutes.loginScreen);
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    }
                  },
                  child: Icon(
                    _currentPage == onboardingData.length - 1
                        ? Icons.check
                        : Icons.arrow_forward,
                    color: Colors.white,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget buildDot(int index, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 5),
      height: 8,
      width: _currentPage == index ? 20 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.green : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String image, title, description;

  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(image, height: 300),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
