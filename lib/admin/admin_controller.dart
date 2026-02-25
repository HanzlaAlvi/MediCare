import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  var medicines = <QueryDocumentSnapshot>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    listenToMedicines();
  }

  // Real-time listener for admin to see changes instantly
  void listenToMedicines() {
    _db.collection('medicines').snapshots().listen((snapshot) {
      medicines.value = snapshot.docs;
      isLoading.value = false;
    });
  }

  // Delete Logic
  Future<void> deleteMedicine(String docId) async {
    try {
      await _db.collection('medicines').doc(docId).delete();
      Get.snackbar(
        "Success",
        "Medicine deleted successfully",
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }
}
