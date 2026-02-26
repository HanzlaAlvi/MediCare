import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'reward_controller.dart';
//import 'reward_success_screen.dart';

class OffersCouponsScreen extends StatelessWidget {
  const OffersCouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller initialize
    final controller = Get.put(RewardsController());
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF285D66),
        title: const Text(
          "My Rewards",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF285D66)),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildResponsiveHeader(controller, size),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.05,
                  vertical: 20,
                ),
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
                    _buildStreakCard(controller, size),
                    const SizedBox(height: 30),
                    const Text(
                      "Special Offers",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCouponItem(
                      "5% Discount Code",
                      100,
                      controller.points.value,
                      Icons.local_offer,
                      Colors.orange,
                    ),
                    _buildCouponItem(
                      "Free Consultation",
                      500,
                      controller.points.value,
                      Icons.medical_services,
                      Colors.blue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // --- Responsive Header ---
  Widget _buildResponsiveHeader(RewardsController controller, Size size) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(bottom: 30, top: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF285D66),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
      ),
      child: Column(
        children: [
          const Text(
            "Points Balance",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 40),
              const SizedBox(width: 10),
              Text(
                "${controller.points.value}",
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Referral Code Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.referralCode.value,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: controller.referralCode.value),
                    );
                    Get.snackbar(
                      "Copied",
                      "Referral code copied to clipboard",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.white,
                    );
                  },
                  child: const Icon(Icons.copy, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Streak Card ---
  Widget _buildStreakCard(RewardsController controller, Size size) {
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
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  bool isDone = index < controller.streak.value;
                  bool isCurrent = index == controller.streak.value;
                  return Column(
                    children: [
                      Text(
                        "+${(index == 6) ? 100 : (index + 1) * 10}",
                        style: TextStyle(
                          fontSize: 10,
                          color: isCurrent ? Colors.orange : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 5),
                      CircleAvatar(
                        radius: size.width * 0.04, // Responsive radius
                        backgroundColor: isDone
                            ? const Color(0xFF285D66)
                            : (isCurrent ? Colors.amber : Colors.grey.shade100),
                        child: isDone
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : Text(
                                "${index + 1}",
                                style: TextStyle(
                                  color: isCurrent
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ],
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            // child: ElevatedButton(
            //   onPressed: controller.isClaimedToday.value
            //       ? null
            //       : () {}, // Logic here
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: const Color(0xFF285D66),
            //     disabledBackgroundColor: Colors.grey.shade300,
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(15),
            //     ),
            //   ),
            //   child: Text(
            //     controller.isClaimedToday.value
            //         ? "Claimed Today"
            //         : "Claim Day ${controller.streak.value + 1} Reward",
            //     style: const TextStyle(
            //       fontWeight: FontWeight.bold,
            //       color: Colors.white,
            //     ),
            //   ),
            // ),
            // offers_coupons_screen.dart mein button change karein
            child: ElevatedButton(
              onPressed: controller.isClaimedToday.value
                  ? null // Agar aaj claim ho chuka hai toh button disable hoga
                  : () => controller
                        .claimDailyReward(), // 👈 Naya function call kiya
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF285D66),
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                controller.isClaimedToday.value
                    ? "Claimed Today"
                    : "Claim Day ${controller.streak.value + 1} Reward",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
    bool isLocked = balance < cost;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLocked ? Colors.transparent : color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Cost: $cost Points",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Icon(
            isLocked ? Icons.lock_outline : Icons.check_circle,
            color: isLocked ? Colors.grey : Colors.green,
          ),
        ],
      ),
    );
  }
}
