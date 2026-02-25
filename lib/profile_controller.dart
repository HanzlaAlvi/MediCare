import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  // Observables - Inke change hone par UI khud update hogi
  var name = "User".obs;
  var email = "No Email".obs;
  var profilePicBase64 = "".obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  void fetchUserData() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // .listen use karne se real-time updates milte rahenge bina screen reload kiye
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists) {
                var data = snapshot.data() as Map<String, dynamic>;
                name.value = data['username'] ?? "User";
                email.value = data['email'] ?? "No Email";
                profilePicBase64.value = data['profilePic'] ?? "";
              }
              isLoading.value = false;
            },
            onError: (e) {
              isLoading.value = false;
              Get.snackbar("Error", "Failed to load profile");
            },
          );
    }
  }
}
