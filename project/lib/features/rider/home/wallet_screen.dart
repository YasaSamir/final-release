import 'package:flutter/material.dart';
import '../../../../core/constants/my_colors.dart';
import 'menu_drawer.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: MenuDrawer(),
      backgroundColor:  Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: Icon(Icons.menu, size: 28, color: Colors.black),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('Wallet', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.symmetric(vertical: 14),
              minimumSize: Size(double.infinity, 50),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AmountScreen()));
            },
            child: Text('Add Money', style: TextStyle(fontSize: 18, color: Colors.black)),

          ),
            SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available Balance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700])),
                  SizedBox(height: 8),
                  Text('\$500', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(height: 30),
         Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Expanded(
        child: ListView(
          children: [
            ListTile(
              leading: CircleAvatar(child: Text('W')),
              title: Text('Welton'),
              subtitle: Text('Today at 22:00 am'),
              trailing: Text('-\$570', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
      ],),
      ),
    );
  }
}

class AmountScreen extends StatefulWidget {
  @override
  _AmountScreenState createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  final TextEditingController _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Amount', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Enter Amount',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(vertical: 14),
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SuccessScreen(amount: _amountController.text),
                  ),
                );
              },
              child: Text('Confirm', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class SuccessScreen extends StatelessWidget {
  final String amount;

  SuccessScreen({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 100, color: Colors.green),
            SizedBox(height: 16),
            Text('Success!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Your money has been added successfully', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            SizedBox(height: 8),
            Text('\$$amount', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(vertical: 14),
                minimumSize: Size(200, 50),
              ),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Text('Back Home', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}


class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Payment Method', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.credit_card),
              title: Text('Visa **** 8970'),
              subtitle: Text('Expires 12/26'),
            ),
            ListTile(
              leading: Icon(Icons.payment),
              title: Text('PayPal mailaddress@gmail'),
              subtitle: Text('Expires 12/26'),
            ),
            ListTile(
              leading: Icon(Icons.money),
              title: Text('Cash'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(vertical: 14),
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SuccessScreen(amount: '200',)));
              },
              child: Text('Save Payment Method', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
