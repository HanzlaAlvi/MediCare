import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert'; // 🛡️ Base64 decode karne ke liye laazmi hai
import 'cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String name;
  final String price;
  final String brand;
  final List<String> images;
  final String description;
  final String mfgDate;
  final String expiryDate;

  // NEW VARIABLES ADDED HERE
  final String ingredients;
  final String sideEffects;
  final String safetyAdvice;

  const ProductDetailsScreen({
    super.key,
    required this.name,
    required this.price,
    required this.brand,
    required this.images,
    required this.description,
    required this.mfgDate,
    required this.expiryDate,
    // REQUIRED IN CONSTRUCTOR
    required this.ingredients,
    required this.sideEffects,
    required this.safetyAdvice,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  int _currentImageIndex = 0;
  final Color themeColor = const Color(0xFF285D66);

  Future<void> _addToCart() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please Login first!")));
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .add({
            'name': widget.name,
            'brand': widget.brand,
            'price': widget.price,
            'image': widget.images.isNotEmpty ? widget.images[0] : '',
            'qty': _quantity,
            'timestamp': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Added to Cart!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CartScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // 🛡️ SMART IMAGE BUILDER FOR PRODUCT DETAILS
  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const Icon(
        Icons.image_not_supported,
        size: 80,
        color: Colors.grey,
      );
    }
    if (imageUrl.startsWith('http')) {
      // 1. Internet URL
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.broken_image, size: 80, color: Colors.grey),
      );
    } else if (imageUrl.startsWith('assets/')) {
      // 2. Local Asset
      return Image.asset(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.broken_image, size: 80, color: Colors.grey),
      );
    } else {
      // 3. Base64 String
      try {
        String base64String = imageUrl;
        if (imageUrl.contains(',')) {
          base64String = imageUrl.split(',').last;
        }
        base64String = base64String.replaceAll(RegExp(r'\s+'), '');

        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) =>
              const Icon(Icons.broken_image, size: 80, color: Colors.grey),
        );
      } catch (e) {
        return const Icon(
          Icons.image_not_supported,
          size: 80,
          color: Colors.grey,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light background
      body: Column(
        children: [
          // --- 1. Image & Header ---
          Stack(
            children: [
              SizedBox(
                height: 320,
                width: double.infinity,
                child: widget.images.isNotEmpty
                    ? PageView.builder(
                        itemCount: widget.images.length,
                        onPageChanged: (index) =>
                            setState(() => _currentImageIndex = index),
                        itemBuilder: (context, index) {
                          String imagePath = widget.images[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              top: 60,
                              bottom: 20,
                              left: 20,
                              right: 20,
                            ),
                            child: _buildProductImage(
                              imagePath,
                            ), // 👈 Smart Builder called here
                          );
                        },
                      )
                    : const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Icon(
                          Icons.image_not_supported,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
              ),
              // Back Button
              Positioned(
                top: 50,
                left: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      size: 18,
                      color: Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              // Cart Button
              Positioned(
                top: 50,
                right: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 20,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (c) => const CartScreen()),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // --- 2. Dots Indicator ---
          if (widget.images.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: _currentImageIndex == index ? 16 : 6,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? themeColor
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

          const SizedBox(height: 10),

          // --- 3. Details Container (Scrollable) ---
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand
                    Text(
                      widget.brand.toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Name & Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          widget.price,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                      ],
                    ),

                    // Rating
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 5),
                        const Text(
                          "4.8",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "(124 reviews)",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Quick Info Cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoCard(Icons.medication, "Type", "Tablet"),
                        _buildInfoCard(Icons.scale, "Dose", "Standard"),
                        _buildInfoCard(
                          Icons.local_shipping,
                          "Delivery",
                          "Free",
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Dates
                    Row(
                      children: [
                        _buildDateChip(
                          "MFG",
                          widget.mfgDate,
                          Icons.calendar_today,
                        ),
                        const SizedBox(width: 15),
                        _buildDateChip(
                          "EXP",
                          widget.expiryDate,
                          Icons.event_busy,
                          isExpiry: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // Description
                    const Text(
                      "Description",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        height: 1.6,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- NEW: Expandable Sections ---
                    _buildExpandableTile("Ingredients", widget.ingredients),
                    _buildExpandableTile("Side Effects", widget.sideEffects),
                    _buildExpandableTile("Safety Advice", widget.safetyAdvice),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // --- Bottom Bar ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(
          children: [
            // Quantity
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_quantity > 1) setState(() => _quantity--);
                    },
                    icon: const Icon(Icons.remove, size: 18),
                  ),
                  Text(
                    "$_quantity",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _quantity++),
                    icon: Icon(Icons.add, size: 18, color: themeColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            // Add Button
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    "Add to Cart",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF285D66), size: 24),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip(
    String title,
    String date,
    IconData icon, {
    bool isExpiry = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isExpiry
              ? Colors.red.withValues(alpha: 0.05)
              : Colors.blue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpiry
                ? Colors.red.withValues(alpha: 0.2)
                : Colors.blue.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isExpiry ? Colors.redAccent : Colors.blueAccent,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableTile(String title, String content) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              content,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
