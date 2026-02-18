import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _content = [
    {
      "image": "assets/orb1.png",
      "title": "Find Medicines Easily",
      "desc":
          "Search any medicine in seconds and get real-time availability from nearby pharmacies.",
    },
    {
      "image": "assets/orb2.png",
      "title": "Order with Prescription",
      "desc":
          "Upload your doctor's prescription and we'll handle the rest — quick, safe, and hassle-free.",
    },
    {
      "image": "assets/orb1.png",
      "title": "Fast Delivery to Your Doorstep",
      "desc":
          "Receive your medicines right at your home, safely packed and delivered on time.",
    },
  ];

  // --- SAVE FLAG & NAVIGATE ---
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // SKIP Button
          TextButton(
            onPressed: _completeOnboarding, // Call Updated Function
            child: const Text(
              "SKIP",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Slider Area
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _content.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Image (Illustration)
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(_content[index]['image']!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Title
                      Text(
                        _content[index]['title']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Description
                      Text(
                        _content[index]['desc']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Dots Indicator & Button
          Padding(
            padding: const EdgeInsets.only(bottom: 40, left: 30, right: 30),
            child: Column(
              children: [
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _content.length,
                    (index) => buildDot(index),
                  ),
                ),
                const SizedBox(height: 30),

                // Next / Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _content.length - 1) {
                        _completeOnboarding(); // Last Page -> Save & Login
                      } else {
                        // Next Page
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF285D66), // Dark Teal
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      _currentPage == _content.length - 1 ? "Continue" : "Next",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget for Dots
  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 5),
      height: 8,
      width: _currentPage == index ? 25 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? const Color(0xFF285D66)
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
