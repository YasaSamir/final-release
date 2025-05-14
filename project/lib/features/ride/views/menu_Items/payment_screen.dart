import 'package:flutter/material.dart';

import '../../../../core/constants/my_colors.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.cBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                  padding: const EdgeInsets.only(left: 8.0, bottom: 20),
                  child: const Text(
                    textAlign: TextAlign.left,
                    'Payment',
                    style: TextStyle(color: Colors.white, fontSize: 48),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          _buildLinkText("Add Payment Method",() {

          },),
          SizedBox(height: 20),
          Divider(
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle("Ride Profiles"),
          const SizedBox(height: 20),

          _buildListTile("Personal", ),
          const SizedBox(height: 20),

          _buildSubText(
            img: 'assets/icon/payment.png',
            "Start using Uber for business",
            "Turn on business travel features",
          ),
          const SizedBox(height: 20),
          Divider(
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle("Promotions"),
          const SizedBox(height: 20),

          _buildListTile("Promotions",img: 'assets/icon/promotion.png' ),
          const SizedBox(height: 20),

          _buildLinkText("Add Promo Code",() {

          },),
          const SizedBox(height: 20),
          _buildSectionTitle("Vouchers"),
          const SizedBox(height: 20),
          _buildListTile("Vouchers",img: 'assets/icon/vouchers.png'),
          const SizedBox(height: 20),
          _buildLinkText("Add Voucher Code" ,() {
          },),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 30),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildListTile(String title, {String? img}) {
    return Padding(
      padding: const EdgeInsets.only(left: 30),
      child: ListTile(
        leading:Image.asset(img ?? 'assets/icon/personal.png', height: 45, width: 45),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSubText(String title, String subtitle,{String? img}) {
    return Padding(
      padding: const EdgeInsets.only(left: 30),
      child: Row(
        children: [
          Image.asset(img ?? 'assets/icon/personal.png', height: 45, width: 45),
          SizedBox(
            width: 20,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.blue, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinkText(String text,VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 30),
      child: InkWell(
        onTap: onTap ?? (){},
        child: Text(
            text, style: const TextStyle(
            color: Color(0xff535AFF),
            fontSize: 18,
            fontWeight: FontWeight.w400

        ),
        ),
      ),
    );
  }
}
