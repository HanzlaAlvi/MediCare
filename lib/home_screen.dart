import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_controller.dart';
import 'home_tab.dart';
import 'category_screen.dart';
import 'order_screen.dart';
import 'profile_screen.dart';
import 'upload_prescription_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    final List<Widget> pages = [
      const HomeTab(),
      const CategoriesScreen(),
      const OrdersScreen(),
      const ProfileScreen(),
      const UploadPrescriptionScreen(isFromTab: true), 
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      extendBody: true,

      resizeToAvoidBottomInset: false,

      body: Obx(() => pages[controller.selectedIndex.value]),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Obx(() {
        bool isUploadActive = controller.selectedIndex.value == 4;
        return Container(
          height: 62,
          width: 62,
          margin: const EdgeInsets.only(top: 30),
          child: FloatingActionButton(
            // Navigation ki jagah index badal diya taake bar na chhupay
            onPressed: () => controller.changeTabIndex(4),
            backgroundColor: const Color(0xFF285D66),
            elevation: 4,
            shape: const CircleBorder(),
            child: Icon(
              isUploadActive ? Icons.check_rounded : Icons.add,
              color: Colors.white,
              size: 32,
            ),
          ),
        );
      }),

      bottomNavigationBar: Obx(
        () => Container(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 65,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Side Tabs
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        Icons.home_filled,
                        Icons.home_outlined,
                        "Home",
                        0,
                        controller,
                      ),
                      _buildNavItem(
                        Icons.grid_view_rounded,
                        Icons.grid_view_outlined,
                        "Browse",
                        1,
                        controller,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 60), // FAB Space
                // Right Side Tabs
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        Icons.receipt_long_rounded,
                        Icons.receipt_long_outlined,
                        "Orders",
                        2,
                        controller,
                      ),
                      _buildNavItem(
                        Icons.person_rounded,
                        Icons.person_outline_rounded,
                        "Profile",
                        3,
                        controller,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    int index,
    HomeController controller,
  ) {
    bool isSelected = controller.selectedIndex.value == index;
    Color primaryColor = const Color(0xFF285D66);

    return InkWell(
      onTap: () => controller.changeTabIndex(index),
      splashColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : inactiveIcon,
            color: isSelected ? primaryColor : Colors.grey.shade400,
            size: 24,
          ),
          if (isSelected)
            Text(
              label,
              style: TextStyle(
                color: primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
