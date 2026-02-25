import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'admin_drawer.dart';
import 'add_edit_medicine_screen.dart'; // Quick action k liye import
import 'payment_verification_screen.dart'; // Quick action k liye import

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xFF285D66);

    // Aaj ki date nikalne k liye
    DateTime now = DateTime.now();
    List<String> months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    String todayDate = "${now.day} ${months[now.month - 1]}, ${now.year}";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), // Soft background
      drawer: const AdminDrawer(),
      appBar: AppBar(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. WELCOME BANNER ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF285D66), Color(0xFF458B96)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todayDate,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Welcome Back, Admin! 👋",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Here is what's happening with your store today.",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- 2. QUICK ACTIONS ---
            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _quickActionButton(
                    title: "Add Medicine",
                    icon: Icons.add_box_rounded,
                    color: Colors.blueAccent,
                    onTap: () => Get.to(() => const AddEditMedicineScreen()),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _quickActionButton(
                    title: "Verify Payments",
                    icon: Icons.verified_user_rounded,
                    color: Colors.purpleAccent,
                    onTap: () =>
                        Get.to(() => const PaymentVerificationScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- 3. METRICS GRID ---
            const Text(
              "Store Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.0, // Cards ko thora square shape diya
              children: [
                _buildStatCard(
                  'users',
                  'Total Users',
                  Icons.people_alt_rounded,
                  const Color(0xFF4A90E2),
                ),
                _buildStatCard(
                  'orders',
                  'Total Orders',
                  Icons.shopping_cart_rounded,
                  const Color(0xFFF39C12),
                ),
                _buildQueryStatCard(
                  'Pending Orders',
                  Icons.pending_actions_rounded,
                  const Color(0xFFE74C3C),
                  'Pending',
                ),
                _buildQueryStatCard(
                  'Delivered',
                  Icons.check_circle_rounded,
                  const Color(0xFF2ECC71),
                  'Delivered',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  // Quick Action Button UI
  Widget _quickActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              radius: 22,
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Normal Collection Count
  Widget _buildStatCard(
    String collectionName,
    String title,
    IconData icon,
    Color color,
  ) {
    return FutureBuilder<AggregateQuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection(collectionName)
          .count()
          .get(),
      builder: (context, snapshot) {
        String count = "0";
        if (snapshot.hasData) {
          count = snapshot.data!.count.toString();
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          count = "...";
        }
        return _statCardUI(title, count, icon, color);
      },
    );
  }

  // Query Base Count
  Widget _buildQueryStatCard(
    String title,
    IconData icon,
    Color color,
    String status,
  ) {
    return FutureBuilder<AggregateQuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: status)
          .count()
          .get(),
      builder: (context, snapshot) {
        String count = "0";
        if (snapshot.hasData) {
          count = snapshot.data!.count.toString();
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          count = "...";
        }
        return _statCardUI(title, count, icon, color);
      },
    );
  }

  // Premium Stat Card UI
  Widget _statCardUI(String title, String count, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        // Stack use kiya taake background watermark icon laga sakein
        children: [
          // Background Watermark Icon
          Positioned(
            right: -15,
            bottom: -15,
            child: Icon(icon, size: 90, color: color.withValues(alpha: 0.1)),
          ),
          // Main Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const Spacer(),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
