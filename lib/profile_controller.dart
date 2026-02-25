import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
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
      FirebaseFirestore.instance
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
              // 🛡️ FIX: Agar user logout ho chuka hai, toh error mat dikhao
              if (FirebaseAuth.instance.currentUser != null) {
                print("Firestore Error: $e");
                Get.snackbar("Error", "Failed to load profile.");
              }
            },
          );
    } else {
      isLoading.value = false;
    }
  }
}
