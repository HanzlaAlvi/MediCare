import 'dart:async'; // 👈 Yeh import zaroori hai
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  var name = "User".obs;
  var email = "No Email".obs;
  var profilePicBase64 = "".obs;
  var isLoading = true.obs;

  StreamSubscription?
  _userSubscription; // 🛡️ Connection ko control karne ke liye

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  void fetchUserData() {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      isLoading.value = false;
      return;
    }

    isLoading.value = true;

    // 🛡️ FIX: Agar purana listener chal raha hai toh usay band karein
    _userSubscription?.cancel();

    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              var data = snapshot.data() as Map<String, dynamic>;
              name.value = data['username'] ?? data['fullName'] ?? "User";
              email.value = data['email'] ?? currentUser.email ?? "No Email";
              profilePicBase64.value = data['profilePic'] ?? "";
            }
            isLoading.value = false;
          },
          onError: (e) {
            isLoading.value = false;
            if (FirebaseAuth.instance.currentUser != null) {
              Get.snackbar("Error", "Failed to load profile.");
            }
          },
        );
  }

  // 🛡️ FIX: Jab GetX is controller ko delete karega, toh Stream bhi band ho jayegi
  @override
  void onClose() {
    _userSubscription?.cancel();
    super.onClose();
  }
}
