import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart'; // Import GetX

// Screens
import 'package:medi_care/help_support_screen.dart';
import 'package:medi_care/offers_coupons_screen.dart';
import 'change_password_screen.dart';
import 'saved_info_screen.dart';
import 'my_prescriptions_screen.dart';
import 'edit_profile_screen.dart';

// Controllers
import 'auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // --- GETX DIALOG FOR LOGOUT ---
  void _handleLogout() {
    Get.defaultDialog(
      title: "Confirm Logout",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      middleText: "Are you sure you want to log out?",
      backgroundColor: Colors.white,
      radius: 20,
      contentPadding: const EdgeInsets.all(20),

      // Cancel Button
      textCancel: "Cancel",
      cancelTextColor: Colors.grey,
      onCancel: () {}, // Dialog band ho jayega
      // Confirm Button
      textConfirm: "Logout",
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFF285D66),
      onConfirm: () {
        // Dialog band karne ki zaroorat nahi, AuthController seedha Login screen pe le jayega
        AuthController.instance.logout();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Please Login First")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back_ios),
        //   onPressed: () => Get.back(), // GetX Navigation
        // ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          String name = currentUser.displayName ?? "User";
          String email = currentUser.email ?? "No Email";
          ImageProvider imageProvider = const NetworkImage(
            'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
          );
          String picData = "";

          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            name = data['username'] ?? name;
            email = data['email'] ?? email;
            if (data['profilePic'] != null && data['profilePic'] != "") {
              try {
                picData = data['profilePic'];
                imageProvider = MemoryImage(base64Decode(picData));
              } catch (e) {
                debugPrint("Image Error: $e");
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: imageProvider,
                        backgroundColor: Colors.grey.shade200,
                      ),
                      GestureDetector(
                        onTap: () {
                          // GetX Navigation
                          Get.to(
                            () => EditProfileScreen(
                              currentName: name,
                              currentEmail: email,
                              currentPic: picData,
                            ),
                          );
                        },
                        child: const CircleAvatar(
                          backgroundColor: Color(0xFF285D66),
                          radius: 18,
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 30),

                // Options List (Updated with GetX calls)
                _buildProfileOption(
                  Icons.description_outlined,
                  "My Prescriptions",
                  () => const MyPrescriptionsScreen(),
                ),
                _buildProfileOption(
                  Icons.help_outline,
                  "Help and Support",
                  () => const HelpSupportScreen(),
                ),
                _buildProfileOption(
                  Icons.bookmark_border,
                  "Saved Info",
                  () => const SavedInfoScreen(),
                ),
                _buildProfileOption(
                  Icons.lock_outline,
                  "Change Password",
                  () => const ChangePasswordScreen(),
                ),
                _buildProfileOption(
                  Icons.local_offer_outlined,
                  "Offers & Coupons",
                  () => const OffersCouponsScreen(),
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _handleLogout, // Calls GetX Dialog
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF285D66),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Updated Widget (Removed Context)
  Widget _buildProfileOption(
    IconData icon,
    String title,
    Widget Function() screen,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF285D66)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF285D66),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: () => Get.to(() => screen()), // GetX Navigation
      ),
    );
  }
}
