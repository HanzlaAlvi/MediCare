import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_controller.dart';
import 'cart_screen.dart';
import 'notification_screen.dart';

// --- CUSTOM APP BAR ---
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key}); // Yeh line add karein
  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 10,
      title: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextField(
          controller: controller.searchController,
          focusNode: controller.searchFocusNode,
          onChanged: controller.updateSearch,
          onSubmitted: (_) => controller.searchFocusNode.unfocus(),
          decoration: InputDecoration(
            hintText: 'Search medicines...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xFF285D66),
              size: 22,
            ),
            suffixIcon: Obx(
              () => controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onPressed: controller.clearSearch,
                    )
                  : const SizedBox(),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      actions: [
        _buildActionIcon(
          icon: Icons.shopping_bag_outlined,
          onTap: () => Get.to(() => const CartScreen()),
          showBadge: true,
          userId: userId,
        ),
        _buildActionIcon(
          icon: Icons.notifications_none_outlined,
          onTap: () => Get.to(() => const NotificationScreen()),
          showBadge: false,
          userId: userId,
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback onTap,
    required bool showBadge,
    required String userId,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: const Color(0xFF285D66), size: 28),
        ),
        if (showBadge)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('cart')
                .snapshots(),
            builder: (context, snapshot) {
              int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
              if (count == 0) return const SizedBox();
              return Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    "$count",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// --- CATEGORY SELECTOR ---
class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key}); // Yeh line add karein
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final categories = ['All', 'Tablets', 'Syrup', 'Painkiller', 'Vitamins'];

    return SizedBox(
      height: 65,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Obx(() {
            bool isSelected =
                controller.selectedCategory.value == categories[index];
            return GestureDetector(
              onTap: () =>
                  controller.selectedCategory.value = categories[index],
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF285D66) : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF285D66,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Center(
                  child: Text(
                    categories[index],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }
}
// --- MEDICINE CARD ---
class MedicineCard extends StatelessWidget {
  final String name, brand, price, rating, imageUrl;
  final Color color;
  final VoidCallback onCartTap;
  final VoidCallback onTap;

  const MedicineCard({
    super.key,
    required this.name,
    required this.brand,
    required this.price,
    required this.rating,
    required this.color,
    required this.imageUrl,
    required this.onCartTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 🛡️ SMART IMAGE BUILDER: Yeh khud check karega image kis type ki hai
    Widget buildImage() {
      if (imageUrl.isEmpty) {
        return Icon(Icons.medication, size: 50, color: color);
      }
      if (imageUrl.startsWith('http')) {
        // 1. Internet URL
        return Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => Icon(Icons.broken_image, color: color),
        );
      } else if (imageUrl.startsWith('assets/')) {
        // 2. Local Asset
        return Image.asset(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => Icon(Icons.broken_image, color: color),
        );
      } else {
        // 3. Base64 String (Jo aapne database me upload ki hai)
        try {
          return Image.memory(
            base64Decode(imageUrl),
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => Icon(Icons.broken_image, color: color),
          );
        } catch (e) {
          return Icon(Icons.medication, size: 50, color: color);
        }
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ IMAGE SECTION
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8), // Image ko thora space denge
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Hero(
                  tag: name,
                  child:
                      buildImage(), // 👈 Yahan humne naya function call kar diya
                ),
              ),
            ),

            // 📝 DETAILS SECTION
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brand.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2), // Halka sa gap
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // 🛡️ SPACER: Yeh price aur Plus button ko HAMESHA bottom pe push karega
                    const Spacer(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF285D66),
                          ),
                        ),
                        InkWell(
                          onTap: onCartTap,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF285D66),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// --- PROMO BANNER ---
class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF285D66), Color(0xFF4DB6AC)],
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "Get 5% OFF",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "On your first prescription upload",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.local_pharmacy,
              size: 120,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
