import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';
import 'home_screen.dart'; // MedicineCard reuse

class ViewAllScreen extends StatelessWidget {
  const ViewAllScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "All Medicines",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No medicines found"));
          }

          final products = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(20),
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

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsScreen(
                        name: data['name'] ?? 'N/A',
                        price: data['price'] ?? '0',
                        brand: data['brand'] ?? 'Unknown',
                        images: images,
                        description: data['description'] ?? "No description",
                        mfgDate: data['mfgDate'] ?? 'N/A',
                        expiryDate: data['expiryDate'] ?? 'N/A',
                        // --- ADDED MISSING PARAMETERS ---
                        ingredients: data['ingredients'] ?? "See package",
                        sideEffects: data['sideEffects'] ?? "Consult doctor",
                        safetyAdvice: data['safetyAdvice'] ?? "Keep away from children",
                      ),
                    ),
                  );
                },
                child: MedicineCard(
                  name: data['name'] ?? 'N/A',
                  brand: data['brand'] ?? 'Unknown',
                  price: data['price'] ?? '0',
                  rating: data['rating'] ?? '0.0',
                  color: Color(int.parse(data['color'] ?? "0xFFF3E5F5")),
                  imageUrl: images.isNotEmpty ? images[0] : "",
                  onCartTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}