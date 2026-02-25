import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart'; // Make sure the filename is correct
import 'components.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  // --- VALIDATION LOGIC ---
  bool _validateInput() {
    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPass = _confirmPasswordController.text.trim();

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPass.isEmpty) {
      _showSnackBar("Please fill all fields.");
      return false;
    }

    // Strict Email Check
    bool emailValid = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
    if (!emailValid || !email.endsWith("@gmail.com")) {
      _showSnackBar("Please enter a valid @gmail.com address.");
      return false;
    }

    // Password Length Check
    if (password.length < 8) {
      _showSnackBar("Password must be at least 8 characters.");
      return false;
    }

    // Match Check
    if (password != confirmPass) {
      _showSnackBar("Passwords do not match.");
      return false;
    }

    return true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF285D66),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- REGISTRATION LOGIC ---
  // --- REGISTRATION LOGIC ---
  Future<void> _handleSignup() async {
    if (!_validateInput()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      if (userCredential.user != null) {
        // 1. Verification email bhejien
        await userCredential.user!.sendEmailVerification();

        // 🎯 ADMIN ROLE LOGIC:
        // Agar username ke sath humne koi secret code likha ho (e.g. "admin_786")
        // Ya aap yahan check kar sakte hain specific email ko
        String role = "user"; // Default role

        if (_usernameController.text.trim().contains("ADMIN123")) {
          role = "admin";
        }

        // 2. Firestore mein user record create karein with ROLE
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'uid': userCredential.user!.uid,
              'username': _usernameController.text.trim().replaceAll(
                "ADMIN123",
                "",
              ), // Code hata kar real name save karein
              'email': _emailController.text.trim(),
              'role': role, // 👈 Yeh field Admin check ke liye zaroori hai
              'profilePic': '',
              'createdAt': FieldValue.serverTimestamp(),
            });

        if (!mounted) return;
        setState(() => _isLoading = false);

        // Success Dialog
        _showSuccessDialog(_emailController.text.trim());
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(e.message ?? "An error occurred during signup.");
    }
  }
  void _showSuccessDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Verify Email",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "A verification link has been sent to $email. Please verify to login.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (c) => const LoginScreen()),
              );
            },
            child: const Text(
              "Go to Login",
              style: TextStyle(color: Color(0xFF285D66)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFADDDE6),
      body: Stack(
        children: [
          const BackgroundCurve(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Create your account to get started',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 40),

                  // Fields
                  MyTextField(
                    hint: 'Username',
                    controller: _usernameController,
                  ),
                  const SizedBox(height: 15),
                  MyTextField(hint: 'Email', controller: _emailController),
                  const SizedBox(height: 15),
                  MyTextField(
                    hint: 'Password',
                    isPassword: true,
                    controller: _passwordController,
                  ),
                  const SizedBox(height: 15),
                  MyTextField(
                    hint: 'Confirm Password',
                    isPassword: true,
                    controller: _confirmPasswordController,
                  ),

                  const SizedBox(height: 30),

                  // Signup Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF285D66),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Navigation to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () => Navigator.pop(context), // Wapis Login pe
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF285D66),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
