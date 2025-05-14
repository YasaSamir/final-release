import 'package:flutter/material.dart';
import 'package:project/core/constants/my_colors.dart';

class LeftPass extends StatelessWidget {
  const LeftPass({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: MyColors.cBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.black,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 20),
                  child: Text(
                    'Left Pass',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              'Left Pass',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              '1 week free - \$24.99/mo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              '\$24.99/mo 1 week free',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          SizedBox(height: 16),
          InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Go more places and get more local favorites, all with one membership',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          SizedBox(height: 20),
          FeatureTile(
            img: 'assets/icon/save.png',
            title: 'Savings on every ride',
            description:
                '''Uber Pass has you covered: 10% off every UberX, UberXL, and Comfort ride, 15% off every Black, Premier, and SUV ride in the US.''',
          ),
          SizedBox(height: 20),
          FeatureTile(
            img: 'assets/icon/delivery.png',

            title: 'Free delivery on Uber Eats',
            description:
                'Get a \$0 Delivery Fee + 5% off orders over \$15. Look for the ticket to save at more than 13000 restaurants in your area.',
          ),
          SizedBox(height: 20),
          FeatureTile(
            img: 'assets/icon/cancel.png',
            title: 'Cancel anytime',
            description:
                'Cancel your subscription anytime—no penalties or fees.',
          ),
          SizedBox(height: 20),

          Divider(
            color: Colors.grey.shade800,
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text('learn more',style: TextStyle(color: Colors.white),),
          ),
          SizedBox(height: 20),
          Divider(
            color: Colors.grey.shade800,

          ),
          SizedBox(height: 20),

          Center(
            child: SizedBox(
              width: screenWidth * 0.9,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.cBackgroundColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.white,width: 1),
                  )
                ),
                onPressed: () {},
                child: Text(
                  'Get 1 week free',
                  style: TextStyle(color: Colors.white,fontWeight: FontWeight.w500,fontSize: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureTile extends StatelessWidget {
  final String? img;
  final String title;
  final String description;

  const FeatureTile({
    super.key,
    this.img,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(img ?? 'assets/icon/personal.png', height: 60, width: 60),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white, fontSize: 18,fontWeight: FontWeight.w500)),
                SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(color: Colors.white, fontSize: 14,fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
