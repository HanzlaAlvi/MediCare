import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math'; // Random code ke liye
import 'reward_success_screen.dart';

class OffersCouponsScreen extends StatefulWidget {
  const OffersCouponsScreen({super.key});

  @override
  State<OffersCouponsScreen> createState() => _OffersCouponsScreenState();
}

class _OffersCouponsScreenState extends State<OffersCouponsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // --- Naya code generate karne ka helper ---
  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return "MED-${List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join()}";
  }

  // --- Agar code missing ho to auto-generate karke DB mein save karein ---
  Future<void> _ensureCodeExists(Map<String, dynamic>? data) async {
    if (data == null ||
        data['referralCode'] == null ||
        data['referralCode'] == "") {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid);
      await userRef.update({'referralCode': _generateRandomCode()});
    }
  }

  Future<void> _claimDailyReward(int currentStreak, int pointsBalance) async {
    if (user == null) return;
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid);
    DateTime now = DateTime.now();

    try {
      var prescriptionCheck = await userRef
          .collection('prescriptions')
          .limit(1)
          .get();
      if (prescriptionCheck.docs.isEmpty) {
        if (mounted) {
          _showCustomSheet(
            "Unlock Rewards",
            "Pehle ek prescription upload karein! 💊",
            Icons.lock_outline,
          );
        }
        return;
      }

      int dayNumber = currentStreak + 1;
      int rewardPoints = (dayNumber == 7) ? 100 : dayNumber * 10;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return;

        var data = snapshot.data() as Map<String, dynamic>;
        Timestamp? lastCheckIn = data['lastCheckIn'];

        if (lastCheckIn != null) {
          DateTime lastDate = lastCheckIn.toDate();
          if (lastDate.day == now.day &&
              lastDate.month == now.month &&
              lastDate.year == now.year) {
            throw Exception("Aaj ka reward aap le chukay hain!");
          }
        }

        transaction.update(userRef, {
          'points': pointsBalance + rewardPoints,
          'streak': (dayNumber >= 7) ? 0 : dayNumber,
          'lastCheckIn': Timestamp.fromDate(now),
        });

        transaction.set(userRef.collection('point_history').doc(), {
          'title': "Day $dayNumber Bonus",
          'points': "+$rewardPoints",
          'type': 'credit',
          'date': now,
        });
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => RewardSuccessScreen(
              rewardName: "Day $dayNumber Reward",
              cost: "$rewardPoints Pts Added",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted){
        _showCustomSheet(
          "Oops!",
          e.toString().replaceAll("Exception: ", ""),
          Icons.info_outline,
        );}
    }
  }

  void _showCustomSheet(String title, String msg, IconData icon) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (c) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 50, color: const Color(0xFF285D66)),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null){
      return const Scaffold(body: Center(child: Text("Login Required")));
  }
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF285D66),
        title: const Text(
          "My Rewards",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData){            
            return const Center(child: CircularProgressIndicator());
          }
          var userData = snapshot.data!.data() as Map<String, dynamic>?;

          // --- AUTO FIX TRIGGER ---
          _ensureCodeExists(userData);

          int points = userData?['points'] ?? 0;
          int streak = userData?['streak'] ?? 0;
          String refCode = userData?['referralCode'] ?? "Generating...";
          Timestamp? lastCheckIn = userData?['lastCheckIn'];

          bool isClaimedToday = false;
          if (lastCheckIn != null) {
            DateTime lastDate = lastCheckIn.toDate();
            DateTime now = DateTime.now();
            isClaimedToday =
                (lastDate.day == now.day &&
                lastDate.month == now.month &&
                lastDate.year == now.year);
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeaderCard(points, refCode),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Daily Jackpot",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStreakGrid(streak, isClaimedToday, points),
                      const SizedBox(height: 30),
                      const Text(
                        "Locked Coupons",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCouponItem(
                        "5% Discount Code (100 Pts)",
                        100,
                        points,
                        Icons.local_offer_outlined,
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(int points, String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Color(0xFF285D66),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
      ),
      child: Column(
        children: [
          const Text(
            "Total Reward Points",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 35),
              const SizedBox(width: 10),
              Text(
                "$points",
                style: const TextStyle(
                  fontSize: 45,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Your Code: ",
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  code,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                  onPressed: () {
                    if (code != "Generating...") {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Code Copied!")),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Baqi Widgets same rahenge (_buildStreakGrid aur _buildCouponItem) ---
  Widget _buildStreakGrid(int streak, bool claimed, int balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              int dayPts = (index == 6) ? 100 : (index + 1) * 10;
              bool isActive = index == streak;
              bool isDone = index < streak;
              return Column(
                children: [
                  Text(
                    "+$dayPts",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.orange : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isDone
                        ? const Color(0xFF285D66)
                        : (isActive ? Colors.amber : Colors.grey.shade100),
                    child: isDone
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            "${index + 1}",
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.black,
                            ),
                          ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: claimed
                  ? null
                  : () => _claimDailyReward(streak, balance),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF285D66),
                disabledBackgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                claimed
                    ? "Sucessfully Claimed!"
                    : "Collect Day ${streak + 1} Reward",
                style: const TextStyle(fontWeight: FontWeight.bold, color:  Color(0xFF285D66),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponItem(
    String title,
    int cost,
    int balance,
    IconData icon,
    Color color,
  ) {
    bool isUnlocked = balance >= cost;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked ? color.withValues(alpha: 0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.black : Colors.grey,
                  ),
                ),
                Text(
                  "Redeem 100 Pts at Checkout",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Icon(
            isUnlocked ? Icons.check_circle : Icons.lock_outline,
            color: isUnlocked ? Colors.green : Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }
}
