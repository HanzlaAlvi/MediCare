import 'package:flutter/material.dart';
import 'home_screen.dart'; // To go back home
import 'order_screen.dart'; // To track order

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text("Payment", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Big Circle Placeholder
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7FA), // Very light teal
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.check, size: 80, color: Color(0xFF285D66)), // Placeholder for Illustration
              ),
            ),
            const SizedBox(height: 40),

            const Text(
              "Payment Success",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 15),
            const Text(
              "Your Payment was successfull!\nJust wait for your medicine to arrive at home",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
            ),
            
            const SizedBox(height: 50),

            // Track Order Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {

                   Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF285D66),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text("Track Your Order", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 15),


            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                   // Go back to Home Screen (Remove all previous routes)
                   Navigator.pushAndRemoveUntil(
                    context, 
                    MaterialPageRoute(builder: (context) => const HomeScreen()), 
                    (route) => false
                   );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0E0E0), // Light grey
                  foregroundColor: const Color(0xFF285D66), // Text color
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  elevation: 0,
                ),
                child: const Text("Continue Shopping", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}