import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';
import 'home_widgets.dart'; // MedicineCard reuse

class CategoryProductsScreen extends StatefulWidget {
  final String categoryName;

  const CategoryProductsScreen({super.key, required this.categoryName});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  // Variable to store search text
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    // 1. Wrap Scaffold with GestureDetector to handle "Click outside to Unfocus"
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF285D66),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            widget.categoryName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  // 2. Update Search Query on Change
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search in ${widget.categoryName} ...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),

            // Grid
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('medicines')
                    .where('category', isEqualTo: widget.categoryName)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No products found in ${widget.categoryName}",
                      ),
                    );
                  }

                  // 3. Filter Logic (Client Side)
                  var allProducts = snapshot.data!.docs;

                  var displayedProducts = allProducts.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String productName = (data['name'] ?? '')
                        .toString()
                        .toLowerCase();

                    // Check if name contains search query
                    return productName.contains(_searchQuery);
                  }).toList();

                  // If search result is empty
                  if (displayedProducts.isEmpty) {
                    return const Center(
                      child: Text("No items match your search"),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                    itemCount: displayedProducts.length,
                    itemBuilder: (context, index) {
                      var data =
                          displayedProducts[index].data()
                              as Map<String, dynamic>;
                      List<String> images = List<String>.from(
                        data['images'] ?? [],
                      );

                      return GestureDetector(
                        onTap: () {
                          // Dismiss keyboard before navigating
                          FocusScope.of(context).unfocus();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsScreen(
                                name: data['name'] ?? 'N/A',
                                price: data['price'] ?? '0',
                                brand: data['brand'] ?? 'Unknown',
                                images: images,
                                description:
                                    data['description'] ??
                                    "No description available.",
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
                        },
                        child: MedicineCard(
                          name: data['name'] ?? 'N/A',
                          brand: data['brand'] ?? 'Unknown',
                          price: data['price'] ?? '0',
                          rating: data['rating'] ?? '0.0',
                          color: Color(
                            int.parse(data['color'] ?? "0xFFF3E5F5"),
                          ),
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
            ),
          ],
        ),
      ),
    );
  }
}
