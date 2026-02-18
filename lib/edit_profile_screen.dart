import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'components.dart';
import 'notification_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final String currentPic;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentEmail,
    required this.currentPic,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _unfocus() => FocusScope.of(context).unfocus();

  Future<void> _pickImage() async {
    _unfocus();
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  // --- RE-AUTHENTICATION DIALOG ---
  Future<String?> _showPasswordDialog() async {
    String? password;
    await showDialog(
      context: context,
      builder: (context) {
        String enteredPassword = "";
        return AlertDialog(
          title: const Text("Re-authentication Required"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("To change your email, please enter your password."),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                onChanged: (value) => enteredPassword = value,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                password = enteredPassword;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF285D66)),
              child: const Text("Confirm", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    return password;
  }

  Future<void> _saveProfile() async {
    _unfocus();
    
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String newName = _nameController.text.trim();
    String newEmail = _emailController.text.trim();
    bool emailChanged = widget.currentEmail != newEmail;

    // --- EMAIL CHANGE LOGIC ---
    if (emailChanged) {
      // 1. Password Maango
      String? password = await _showPasswordDialog();
      if (password == null || password.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password required to change email.")),
        );
        return; 
      }

      setState(() => _isLoading = true);

      try {
        // 2. Re-authenticate
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);

        // 3. Try Update Email (CHECKING DUPLICATE HERE)
        await user.verifyBeforeUpdateEmail(newEmail);

      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);
        String errorMessage = "Error updating email.";

        // --- SPECIFIC ERROR HANDLING ---
        if (e.code == 'email-already-in-use') {
          errorMessage = "This email is already linked to another account. Please use a different email.";
        } else if (e.code == 'invalid-email') {
          errorMessage = "This email address is invalid.";
        } else if (e.code == 'wrong-password') {
          errorMessage = "Incorrect password.";
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return; // Stop execution here if email fails
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
        return;
      }
    } else {
      setState(() => _isLoading = true);
    }

    // --- FIRESTORE UPDATE (Sirf tab chalega agar Email Update Pass ho gaya) ---
    try {
      Map<String, dynamic> updateData = {
        'username': newName,
        if (emailChanged) 'email': newEmail, // Update email in DB only if successful
      };

      if (_imageBytes != null) {
        updateData['profilePic'] = base64Encode(_imageBytes!);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      if (newName != widget.currentName) {
        await user.updateDisplayName(newName);
      }

      // Notification
      if (emailChanged) {
        await NotificationService().triggerManualNotification(
          title: "Security Alert 🔒",
          message: "Verification email sent to $newEmail. Please verify it.",
          type: "feature",
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emailChanged
                ? "Saved! Check $newEmail to verify & change login."
                : "Profile updated successfully!",
          ),
          backgroundColor: const Color(0xFF285D66),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Database Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider img;
    if (_imageBytes != null) {
      img = MemoryImage(_imageBytes!);
    } else if (widget.currentPic.isNotEmpty) {
      img = MemoryImage(base64Decode(widget.currentPic));
    } else {
      img = const NetworkImage(
        'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
      );
    }

    return GestureDetector(
      onTap: _unfocus,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "Edit Profile",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF285D66),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF285D66)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(radius: 65, backgroundImage: img),
                          GestureDetector(
                            onTap: _pickImage,
                            child: const CircleAvatar(
                              backgroundColor: Color(0xFF285D66),
                              radius: 20,
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    MyTextField(hint: "Username", controller: _nameController),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email Address",
                        helperText: "Changing this requires password confirmation",
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF285D66),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          "Save Changes",
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
              ),
      ),
    );
  }
}