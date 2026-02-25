import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'admin_controller.dart';
import 'add_edit_medicine_screen.dart';
import '../login_screen.dart';
import 'admin_orders_screen.dart';
import 'payment_verification_screen.dart';
// Note: OrdersScreen aur baaki files ke imports yahan add karein

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminController());

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      // --- 📱 SIDEBAR (DRAWER) ---
      drawer: _buildSidebar(context),

      appBar: AppBar(
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text("MediCare Admin"),
        actions: [
          IconButton(
            onPressed: () => Get.to(() => const AddEditMedicineScreen()),
            icon: const Icon(Icons.add_box_rounded),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF285D66)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.medicines.length,
          itemBuilder: (context, index) {
            var doc = controller.medicines[index];
            var data = doc.data() as Map<String, dynamic>;
            List images = data['images'] ?? [];
            String imagePath = images.isNotEmpty ? images[0] : "";

            return Card(
              color: context.theme.cardColor,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: _buildMedicineImage(imagePath),
                title: Text(
                  data['name'] ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Stock: ${data['stock']}"),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF285D66),
                  ),
                  onPressed: () => Get.to(
                    () => AddEditMedicineScreen(
                      medicineData: data,
                      docId: doc.id,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // --- 🛠️ SIDEBAR WIDGET ---
  Widget _buildSidebar(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF285D66)),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.admin_panel_settings,
                color: Color(0xFF285D66),
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

          _sidebarItem(
            Icons.inventory_2_outlined,
            "Inventory",
            () => Get.back(),
          ),

          // 📦 ORDERS ITEM
          _sidebarItem(Icons.shopping_bag_outlined, "Customer Orders", () {
            Get.back();
            Get.to(() => const AdminOrdersScreen()); // Is screen ka code nichay hai
          }),
          // AdminDashboard file ke Drawer method mein ye add karein:
          _sidebarItem(Icons.verified_outlined, "Verify Payments", () {
            Navigator.pop(context); // Drawer close
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => const PaymentVerificationScreen(),
              ),
            );
          }),

          const Divider(),

          // 🌓 DARK MODE TOGGLE
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

  // Smart Image Logic (Jo hum ne pehle discuss kiya tha)
  Widget _buildMedicineImage(String path) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.withValues(alpha: 0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: path.startsWith('http')
            ? Image.network(
                path,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
              )
            : Image.asset(
                path,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    const Icon(Icons.image_not_supported),
              ),
      ),
    );
  }
}
