import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 Yeh import zaroori hai
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'notification_service.dart';
import 'auth_controller.dart';

// 🎯 Apni screens ke hisaab se inke paths theek kar lijiye ga
import 'login_screen.dart';
import 'home_screen.dart';
import 'admin/admin_dashboard.dart'; // Agar folder alag hai toh path theek kar lein

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService().init();

  Get.put(AuthController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medi Care',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF285D66)),
        useMaterial3: true,
      ),
      // 🎯 StreamBuilder automatically check karega login status
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. Agar Firebase abhi check kar raha hai toh Loading show karein
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF285D66)),
              ),
            );
          }

          // 2. Agar User logged in hai
          if (snapshot.hasData && snapshot.data != null) {
            // 🛡️ Admin Email Check
            if (snapshot.data!.email == 'admin@gmail.com') {
              return const AdminDashboard(); // Admin screen
            } else {
              return const HomeScreen(); // Normal user screen
            }
          }

          // 3. Agar User logged in nahi hai toh Login Screen
          return const LoginScreen();
        },
      ),
    );
  }
}
