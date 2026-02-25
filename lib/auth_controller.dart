import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login_screen.dart';
import '../home_screen.dart';
import '../onboarding_screen.dart';
import '../notification_service.dart';
// 🚨 ZAROORI: Apni Admin Dashboard ki file zaroor import karein
import '../admin/admin_dashboard.dart'; // <-- Path apne folder k hisaab se theek kar lein

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  // Variables
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late SharedPreferences prefs;
  var isLoading = false.obs;

  @override
  void onReady() {
    super.onReady();
    _checkAutoLogoutLogic();
  }

  // --- 5 DAYS AUTO LOGOUT LOGIC ---

  Future<void> _checkAutoLogoutLogic() async {
    prefs = await SharedPreferences.getInstance();
    User? user = _auth.currentUser;

    bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

    if (user != null) {
      // Last opened time check karein
      int? lastOpened = prefs.getInt('last_opened_timestamp');
      int currentTime = DateTime.now().millisecondsSinceEpoch;

      if (lastOpened != null) {
        int difference = currentTime - lastOpened;
        int fiveDaysInMillis = 5 * 24 * 60 * 60 * 1000;

        if (difference > fiveDaysInMillis) {
          // 5 din se zyada ho gaye -> Logout
          await _auth.signOut();
          Get.offAll(() => const LoginScreen());
          return;
        }
      }
      // Time update karein (Timer reset)
      await prefs.setInt('last_opened_timestamp', currentTime);

      // 🛡️ ADMIN CHECK YAHAN LAGA HAI
      if (user.email == 'hanzlaalvi0@gmail.com') {
        // <-- Agar apna email rakha hai to yahan change karein
        Get.offAll(() => const AdminDashboard());
      } else {
        Get.offAll(() => const HomeScreen());
      }
    } else {
      // User logged in nahi hai -> Onboarding ya Login
      if (seenOnboarding) {
        Get.offAll(() => const LoginScreen());
      } else {
        Get.offAll(() => const OnboardingScreen());
      }
    }
  }

  // --- LOGIN FUNCTION ---
  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Login successful -> Time save karo
      await prefs.setInt(
        'last_opened_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      isLoading.value = false;

      // 🛡️ ADMIN CHECK LOGIN K BAAD BHI LAGA HAI
      if (_auth.currentUser?.email == 'hanzlaalvi0@gmail.com') {
        // <-- Yahan bhi same email likhein
        Get.offAll(() => const AdminDashboard());
      } else {
        Get.offAll(() => const HomeScreen());
      }
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      String message = "Login Failed";
      if (e.code == 'user-not-found') {
        message = "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        message = "Wrong password provided.";
      }

      Get.snackbar(
        "Error",
        message,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // --- LOGOUT FUNCTION ---
  Future<void> logout() async {
    // 1. Notification Service band karein
    NotificationService().stopMonitoring();

    // 2. Firebase Signout
    await _auth.signOut();

    // 3. Navigate to Login
    Get.offAll(() => const LoginScreen());
  }
}
