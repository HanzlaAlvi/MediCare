import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert'; // 🛡️ Base64 decode karne ke liye laazmi hai

import 'admin_controller.dart';
import 'add_edit_medicine_screen.dart';
import 'admin_drawer.dart'; // Upar wala drawer import karein

class MedicineInventoryScreen extends StatelessWidget {
  const MedicineInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminController());
    const Color themeColor = Color(0xFF285D66);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      drawer: const AdminDrawer(), // 👈 Sidebar yahan bhi lag gaya
      appBar: AppBar(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text("Medicine Inventory"),
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
            child: CircularProgressIndicator(color: themeColor),
          );
        }

        if (controller.medicines.isEmpty) {
          return const Center(child: Text("No medicines found"));
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
                  icon: const Icon(Icons.edit_outlined, color: themeColor),
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

  // 🛡️ SMART IMAGE BUILDER FOR ADMIN PANEL
  Widget _buildMedicineImage(String path) {
    Widget imageWidget;

    // 1. Text ko clean karein (taake extra spaces/newlines khatam ho jayen)
    String cleanPath = path.trim();

    if (cleanPath.isEmpty) {
      imageWidget = const Icon(Icons.medication, color: Colors.grey);
    } else if (cleanPath.startsWith('http')) {
      // 2. Internet URL
      imageWidget = Image.network(
        cleanPath,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    } else if (cleanPath.contains('assets/')) { 
      // 3. Local Asset (contains lagaya taake space ho tab bhi pakar le)
      imageWidget = Image.asset(
        cleanPath,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    } else {
      // 4. Base64 String 
      try {
        String base64String = cleanPath;
        if (cleanPath.contains(',')) {
          base64String = cleanPath.split(',').last;
        }
        
        // Sirf a-z, A-Z, 0-9, +, /, = ko allow karein (Invalid characters remove)
        base64String = base64String.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');

        // Base64 padding fix
        if (base64String.length % 4 != 0) {
          base64String += '=' * (4 - (base64String.length % 4));
        }

        imageWidget = Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        );
      } catch (e) {
        imageWidget = const Icon(Icons.medication, color: Colors.grey);
      }
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.withValues(alpha: 0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageWidget, 
      ),
    );
  }
}
