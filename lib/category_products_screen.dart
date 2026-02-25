import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'category_products_controller.dart';
import 'product_details_screen.dart';
import 'home_widgets.dart';

class CategoryProductsScreen extends StatelessWidget {
  final String categoryName;
  const CategoryProductsScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    // Controller initialize with unique tag for each category
    final controller = Get.put(
      CategoryProductsController(categoryName),
      tag: categoryName,
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF285D66),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          title: Text(
            categoryName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Get.back(),
          ),
        ),
        body: Column(
          children: [
            // Search Bar Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(
                        alpha: 0.1,
                      ), // Fix: withValues
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: controller.updateSearch,
                  decoration: InputDecoration(
                    hintText: 'Search in $categoryName...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),

            // Products Grid
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('medicines')
                    .where('category', isEqualTo: categoryName)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF285D66),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text("No products found in $categoryName"),
                    );
                  }

                  return Obx(() {
                    var filteredDocs = snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String name = (data['name'] ?? '')
                          .toString()
                          .toLowerCase();
                      return name.contains(controller.searchQuery.value);
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return const Center(
                        child: Text("No items match your search"),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        var data =
                            filteredDocs[index].data() as Map<String, dynamic>;
                        List<String> images = List<String>.from(
                          data['images'] ?? [],
                        );
                        String firstImg = images.isNotEmpty ? images[0] : "";

                        return MedicineCard(
                          name: data['name'] ?? 'N/A',
                          brand: data['brand'] ?? 'Unknown',
                          price: data['price'] ?? '0',
                          rating: data['rating'] ?? '0.0',
                          color: Color(
                            int.parse(data['color'] ?? "0xFFF3E5F5"),
                          ),
                          imageUrl: firstImg,
                          // --- FIX: Added Required onTap ---
                          onTap: () {
                            Get.to(
                              () => ProductDetailsScreen(
                                name: data['name'] ?? 'N/A',
                                price: data['price'] ?? '0',
                                brand: data['brand'] ?? 'Unknown',
                                images: images,
                                description: data['description'] ?? "",
                                mfgDate: data['mfgDate'] ?? 'N/A',
                                expiryDate: data['expiryDate'] ?? 'N/A',
                                ingredients:
                                    data['ingredients'] ?? "See package",
                                sideEffects:
                                    data['sideEffects'] ?? "Consult doctor",
                                safetyAdvice:
                                    data['safetyAdvice'] ??
                                    "Keep away from children",
                              ),
                            );
                          },
                          // --- FIX: Using Controller Cart Logic ---
                          onCartTap: () {
                            controller.addToCart({
                              'name': data['name'],
                              'brand': data['brand'],
                              'price': data['price'],
                              'image': firstImg,
                            });
                          },
                        );
                      },
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
