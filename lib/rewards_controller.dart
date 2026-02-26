// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';

// class RewardsController extends GetxController {
//   var points = 0.obs;
//   var streak = 0.obs;
//   var isClaimedToday = false.obs;
//   var isLoading = true.obs;
//   var referralCode = "MED-123".obs;

//   final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

//   @override
//   void onInit() {
//     super.onInit();
//     fetchUserRewards();
//   }

//   // 📥 DB se Data lana
//   void fetchUserRewards() {
//     if (userId.isEmpty) return;

//     FirebaseFirestore.instance
//         .collection('users')
//         .doc(userId)
//         .snapshots()
//         .listen((snapshot) {
//           if (snapshot.exists) {
//             var data = snapshot.data() as Map<String, dynamic>;
//             points.value = data['points'] ?? 0;
//             streak.value = data['streak'] ?? 0;

//             // Check karein kya aaj claim kiya hai (lastClaim date se)
//             String lastClaim = data['lastClaimDate'] ?? "";
//             String today = DateTime.now().toString().substring(
//               0,
//               10,
//             ); // YYYY-MM-DD
//             isClaimedToday.value = (lastClaim == today);
//           }
//           isLoading.value = false;
//         });
//   }

//   // 📤 DB mein Reward save karna (Claim Logic)
//   // 🎁 Claim Reward Function (Database Update)
  
// // future<void> claimDailyReward() async {
// //     try {
// //       String today = DateTime.now().toString().substring(0, 10);
// //       int rewardAmount = (streak.value + 1) * 10; // Simple calculation

// //       await FirebaseFirestore.instance.collection('users').doc(userId).update({
// //         'points': FieldValue.increment(rewardAmount),
// //         'streak': streak.value >= 6 ? 0 : FieldValue.increment(1), // 7 din baad reset
// //         'lastClaimDate': today,
// //       });

// //       Get.snackbar("Success", "You earned $rewardAmount points!");
// //     } catch (e) {
// //       Get.snackbar("Error", "Could not claim reward: $e");
// //     }
// //   }
