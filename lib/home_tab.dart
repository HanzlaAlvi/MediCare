import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_controller.dart';
import 'home_widgets.dart';
import 'product_details_screen.dart';
import 'viewall_screen.dart';

// 1. Ise StatefulWidget bana diya
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // 🎯 2. Stream ko yahan save kar liya taake Keyboard khulne pe reload na ho
  late final Stream<QuerySnapshot> _medicinesStream;

  @override
  void initState() {
    super.initState();
    _medicinesStream = FirebaseFirestore.instance
        .collection('medicines')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return GestureDetector(
      onTap: () => FocusScope.of(
        context,
      ).unfocus(), // Bahar click karne se keyboard band hoga
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: const HomeAppBar(),
        body: StreamBuilder<QuerySnapshot>(
          stream: _medicinesStream, // 👈 3. Ab yahan saved stream pass kiya
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF285D66)),
              );
            }

            return Obx(() {
              var allDocs = snapshot.hasData ? snapshot.data!.docs : [];

              // Search aur Category filter logic
              var filteredDocs = allDocs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                String name = data['name'].toString().toLowerCase();
                String category = data['category'] ?? "All";

                // 🔍 Search ko behtar karne k liye toLowerCase() add kiya
                bool matchesSearch = name.contains(
                  controller.searchQuery.value.toLowerCase(),
                );
                bool matchesCategory =
                    (controller.selectedCategory.value == "All") ||
                    (category == controller.selectedCategory.value);
                return matchesSearch && matchesCategory;
              }).toList();

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: PromoBanner()),
                  const SliverToBoxAdapter(child: CategorySelector()),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Popular Medicines",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Get.to(() => const ViewAllScreen()),
                            child: const Text(
                              "See All",
                              style: TextStyle(color: Color(0xFF285D66)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  filteredDocs.isEmpty
                      ? const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Text("No items found")),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 15,
                                  mainAxisSpacing: 15,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              var data =
                                  filteredDocs[index].data()
                                      as Map<String, dynamic>;
                              List<String> images = List<String>.from(
                                data['images'] ?? [],
                              );

                              return MedicineCard(
                                name: data['name'] ?? 'N/A',
                                brand: data['brand'] ?? 'Unknown',
                                price: data['price'] ?? '0',
                                rating: data['rating'] ?? '0.0',
                                color: Color(
                                  int.parse(data['color'] ?? "0xFFF3E5F5"),
                                ),
                                imageUrl: images.isNotEmpty ? images[0] : "",
                                onCartTap: () => controller.addToCart(data),
                                onTap: () => Get.to(
                                  () => ProductDetailsScreen(
                                    name: data['name'],
                                    price: data['price'],
                                    brand: data['brand'],
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
                                ),
                              );
                            }, childCount: filteredDocs.length),
                          ),
                        ),
                  // Bottom space taake bar items ko cover na kare
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              );
            });
          },
        ),
      ),
    );
  }
}
