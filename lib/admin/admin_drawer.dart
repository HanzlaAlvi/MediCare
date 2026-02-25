import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'admin_dashboard.dart';
import 'medicine_inventory_screen.dart'; // Nayi screen jo hum banayenge
import 'admin_orders_screen.dart';
import 'payment_verification_screen.dart';
import '../login_screen.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xFF285D66);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: themeColor),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.admin_panel_settings,
                color: themeColor,
                size: 40,
              ),
            ),
            accountName: const Text(
              "Admin Portal",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              FirebaseAuth.instance.currentUser?.email ?? "admin@medicare.com",
            ),
          ),

          _sidebarItem(Icons.dashboard_outlined, "Dashboard", () {
            Get.offAll(
              () => const AdminDashboard(),
            ); // Dashboard pe janay k liye back stack clear karega
          }),

          _sidebarItem(Icons.inventory_2_outlined, "Medicine Inventory", () {
            Get.back(); // Pehle drawer close karega
            Get.to(() => const MedicineInventoryScreen());
          }),

          _sidebarItem(Icons.shopping_bag_outlined, "Customer Orders", () {
            Get.back();
            Get.to(() => const AdminOrdersScreen());
          }),

          _sidebarItem(Icons.verified_outlined, "Verify Payments", () {
            Get.back();
            Get.to(() => const PaymentVerificationScreen());
          }),

          const Divider(),

          // Dark Mode Toggle
          ListTile(
            leading: Icon(Get.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            title: Text(Get.isDarkMode ? "Switch to Light" : "Switch to Dark"),
            trailing: Switch(
              value: Get.isDarkMode,
              onChanged: (value) {
                Get.changeTheme(
                  Get.isDarkMode ? ThemeData.light() : ThemeData.dark(),
                );
              },
            ),
          ),

          const Spacer(),
          _sidebarItem(Icons.logout_rounded, "Logout", () async {
            await FirebaseAuth.instance.signOut();
            Get.offAll(() => const LoginScreen());
          }, color: Colors.red),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF285D66)),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
