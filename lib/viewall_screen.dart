import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'product_details_screen.dart';
import 'home_controller.dart'; // Add this to use cart logic
import 'home_widgets.dart';

class ViewAllScreen extends StatelessWidget {
  const ViewAllScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the existing controller for cart logic
    final controller = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "All Medicines",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF285D66)),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No medicines found"));
          }

          final products = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              var data = products[index].data() as Map<String, dynamic>;
              List<String> images = List<String>.from(data['images'] ?? []);
              String firstImage = images.isNotEmpty ? images[0] : "";

              return MedicineCard(
                name: data['name'] ?? 'N/A',
                brand: data['brand'] ?? 'Unknown',
                price: data['price'] ?? '0',
                rating: data['rating'] ?? '0.0',
                color: Color(int.parse(data['color'] ?? "0xFFF3E5F5")),
                imageUrl: firstImage,
                // --- FIX: Added required onTap ---
                onTap: () {
                  Get.to(
                    () => ProductDetailsScreen(
                      name: data['name'] ?? 'N/A',
                      price: data['price'] ?? '0',
                      brand: data['brand'] ?? 'Unknown',
                      images: images,
                      description: data['description'] ?? "No description",
                      mfgDate: data['mfgDate'] ?? 'N/A',
                      expiryDate: data['expiryDate'] ?? 'N/A',
                      ingredients: data['ingredients'] ?? "See package",
                      sideEffects: data['sideEffects'] ?? "Consult doctor",
                      safetyAdvice:
                          data['safetyAdvice'] ?? "Keep away from children",
                    ),
                  );
                },
                // --- Using Controller's Cart Logic ---
                onCartTap: () {
                  controller.addToCart(data);
                },
              );
            },
          );
        },
      ),
    );
  }
}
