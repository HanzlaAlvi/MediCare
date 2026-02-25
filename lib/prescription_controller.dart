import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class PrescriptionController extends GetxController {
  final user = FirebaseAuth.instance.currentUser;

  // Observable list jo UI ko auto-update karegi
  var prescriptions = <QueryDocumentSnapshot>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    if (user != null) {
      fetchPrescriptions();
    }
  }

  void fetchPrescriptions() {
    // Real-time listener setup
    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('prescriptions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            prescriptions.value = snapshot.docs;
            isLoading.value = false;
          },
          onError: (error) {
            isLoading.value = false;
            Get.snackbar("Error", "Failed to fetch data: $error");
          },
        );
  }
}
