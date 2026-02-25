import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

  // Observables
  var searchQuery = "".obs;
  var selectedCategory = "All".obs;

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  // Method to update index
  var selectedIndex = 0.obs;
  // ... baaki variables ...

  void changeTabIndex(int index) {
    selectedIndex.value = index;
  }  
  // Method to update search
  void updateSearch(String value) {
    searchQuery.value = value.toLowerCase();
  }

  // Clear search
  void clearSearch() {
    searchController.clear();
    searchQuery.value = "";
    searchFocusNode.unfocus();
  }

  // Add to Cart Logic
  Future<void> addToCart(Map<String, dynamic> product) async {
    try {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart');

      final doc = await cartRef.doc(product['name']).get();

      if (doc.exists) {
        int currentQty = doc.data()?['qty'] ?? 1;
        await cartRef.doc(product['name']).update({'qty': currentQty + 1});
      } else {
        await cartRef.doc(product['name']).set({
          ...product,
          'qty': 1,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
      Get.snackbar(
        "Cart Updated",
        "${product['name']} added to cart!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF285D66),
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      debugPrint("Cart Error: $e");
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }
}
