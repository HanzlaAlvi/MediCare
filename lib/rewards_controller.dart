import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class RewardsController extends GetxController {
  final User? user = FirebaseAuth.instance.currentUser;

  // Observables
  var points = 0.obs;
  var streak = 0.obs;
  var referralCode = "Generating...".obs;
  var isClaimedToday = false.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    if (user != null) {
      _ensureCodeExists();
      listenToUserData();
    }
  }

  // Real-time listener (Super Fast Updates)
  void listenToUserData() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            var data = snapshot.data() as Map<String, dynamic>;
            points.value = data['points'] ?? 0;
            streak.value = data['streak'] ?? 0;
            referralCode.value = data['referralCode'] ?? "Generating...";

            Timestamp? lastCheckIn = data['lastCheckIn'];
            if (lastCheckIn != null) {
              DateTime lastDate = lastCheckIn.toDate();
              DateTime now = DateTime.now();
              isClaimedToday.value =
                  (lastDate.day == now.day &&
                  lastDate.month == now.month &&
                  lastDate.year == now.year);
            }
          }
          isLoading.value = false;
        });
  }

  Future<void> _ensureCodeExists() async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid);
    final doc = await userRef.get();
    if (doc.exists &&
        (doc.data()?['referralCode'] == null ||
            doc.data()?['referralCode'] == "")) {
      await userRef.update({'referralCode': _generateRandomCode()});
    }
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return "MED-${List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join()}";
  }
}
