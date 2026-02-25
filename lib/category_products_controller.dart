import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryProductsController extends GetxController {
  final String categoryName;
  CategoryProductsController(this.categoryName);

  var searchQuery = "".obs;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

  // Search update function
  void updateSearch(String value) {
    searchQuery.value = value.toLowerCase();
  }

  // Add to Cart Logic (Using the same logic as Home)
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
          'name': product['name'],
          'brand': product['brand'],
          'price': product['price'],
          'image': product['image'],
          'qty': 1,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
      Get.snackbar(
        "Success",
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
}
