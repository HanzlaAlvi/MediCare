import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

// Screens & Controllers
import 'profile_controller.dart';
import 'auth_controller.dart';
import 'package:medi_care/help_support_screen.dart';
import 'package:medi_care/offers_coupons_screen.dart';
import 'change_password_screen.dart';
import 'saved_info_screen.dart';
import 'my_prescriptions_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller ko inject karna
    final controller = Get.put(ProfileController());
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
        elevation: 0,
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF285D66)),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Profile Picture Section
              _buildAvatarSection(controller),

              const SizedBox(height: 15),

              // Name & Email
              Text(
                controller.name.value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                controller.email.value,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),

              const SizedBox(height: 30),

              // Options List
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

              // Logout Button
              _buildLogoutButton(),
            ],
          ),
        );
      }),
    );
  }

  // --- Sub Widgets ---

  Widget _buildAvatarSection(ProfileController controller) {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: controller.profilePicBase64.value.isNotEmpty
                ? MemoryImage(base64Decode(controller.profilePicBase64.value))
                : const NetworkImage(
                        'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                      )
                      as ImageProvider,
          ),
          GestureDetector(
            onTap: () => Get.to(
              () => EditProfileScreen(
                currentName: controller.name.value,
                currentEmail: controller.email.value,
                currentPic: controller.profilePicBase64.value,
              ),
            ),
            child: const CircleAvatar(
              backgroundColor: Color(0xFF285D66),
              radius: 18,
              child: Icon(Icons.edit, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

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
        onTap: () => Get.to(screen),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _showLogoutDialog,
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
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Container(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: Color(0xFF285D66),
                size: 40,
              ),
              const SizedBox(height: 20),
              const Text(
                "Confirm logout?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF285D66),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF285D66)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Color(0xFF285D66)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // 🛡️ THE ULTIMATE FIX: Memory clear ho jayegi
                        Get.delete<ProfileController>();
                        AuthController.instance.logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF285D66),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
