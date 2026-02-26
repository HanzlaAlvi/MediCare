import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'reward_success_screen.dart';

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

  // Future<void> claimDailyReward() async {
  //     if (isClaimedToday.value) return; // Agar pehle hi claim hai to kuch na karo

  //     try {
  //       // Aaj ki date aur reward calculate karna
  //       int dailyReward = (streak.value + 1) * 10;
  //       if (streak.value >= 6) dailyReward = 100; // 7th Day Jackpot

  //       await FirebaseFirestore.instance
  //           .collection('users')
  //           .doc(user!.uid)
  //           .update({
  //             'points': FieldValue.increment(dailyReward),
  //             'streak': (streak.value >= 6) ? 0 : FieldValue.increment(1),
  //             'lastCheckIn':
  //                 FieldValue.serverTimestamp(), // Aaj ki date save ho jayegi
  //           });

  //       Get.snackbar(
  //         "Jackpot!",
  //         "You earned $dailyReward points!",
  //         snackPosition: SnackPosition.BOTTOM,
  //       );
  //     } catch (e) {
  //       Get.snackbar("Error", "Could not claim: $e");
  //     }
  //   }
  // }
  // rewards_controller.dart mein yeh method add karein

  Future<void> claimDailyReward() async {
    if (user == null || isClaimedToday.value) return;

    try {
      // Reward calculate karna (e.g., Day 1 = 10 points, Day 7 = 100 points)
      int currentStreak = streak.value;
      int rewardAmount = (currentStreak == 6) ? 100 : (currentStreak + 1) * 10;

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid);

      await userRef.update({
        'points': FieldValue.increment(rewardAmount),
        'streak': currentStreak >= 6 ? 0 : FieldValue.increment(1),
        'lastCheckIn': FieldValue.serverTimestamp(),
      });

      // Success Screen par bhejna
      Get.to(
        () => RewardSuccessScreen(
          rewardName: "Daily Check-in Reward",
          cost: "+$rewardAmount Points",
        ),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to claim reward: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
