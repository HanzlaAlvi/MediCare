import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // url_launch.dart ki jagah package use karein
import 'faqs_screen.dart';
import 'livechat_screen.dart';
import 'order_history.dart'; // Import Order History
//import 'prescription_detail_screen.dart'; // Order Screen ka import (Jahan bhi track order ho)
import 'order_screen.dart';
// Note: Agar aapki Order Screen ka naam kuch aur hai to yahan import change karein
// import 'order_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  // Dialer Helper
  void openDialer(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        title: const Text(
          "Help and Support",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.edit_square), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Contact Us",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // --- CONTACT OPTIONS ---
            _buildContactOption(
              context,
              icon: Icons.chat_bubble_outline,
              title: "Live Chat",
              subtitle: "Usually responds in minutes",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatSupportScreen(),
                  ),
                );
              },
            ),
            _buildContactOption(
              context,
              icon: Icons.email,
              title: "Email",
              subtitle: "support@pharmdelivery.com",
              onTap: () {
                // Email launch logic here
              },
            ),
            _buildContactOption(
              context,
              icon: Icons.phone,
              title: "Phone",
              iconColor: Colors.red,
              subtitle: "+92 321 1234567",
              onTap: () {
                openDialer('+92 321 1234567');
              },
            ),

            const SizedBox(height: 25),
            const TextWidgetCustom(text: "Quick Help"),
            const SizedBox(height: 15),

            // --- QUICK HELP (UPDATED) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Track Order
                _buildQuickHelpBox(
                  context: context,
                  icon: Icons.local_shipping_outlined,
                  bgColor: Colors.red.shade100,
                  iconColor: Colors.red,
                  title: "Track Order",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrdersScreen(),
                      ),
                    );
                  },
                ),

                // 2. Order History
                _buildQuickHelpBox(
                  context: context,
                  icon: Icons.history,
                  bgColor: Colors.teal.shade100,
                  iconColor: Colors.teal,
                  title: "Order History",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderHistoryScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 25),
            const TextWidgetCustom(text: "FAQ's"),
            const SizedBox(height: 15),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FAQScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Frequently Asked Questions",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = const Color(0xFF285D66),
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // --- UPDATED QUICK HELP BOX (With onTap) ---
  Widget _buildQuickHelpBox({
    required BuildContext context,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required String title,
    required VoidCallback onTap, // Clickable banane ke liye
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.43, // Responsive Width
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TextWidgetCustom extends StatelessWidget {
  final String text;
  const TextWidgetCustom({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
