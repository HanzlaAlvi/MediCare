import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'prescription_controller.dart';
import 'prescription_detail_screen.dart';
import 'upload_prescription_screen.dart';

class MyPrescriptionsScreen extends StatelessWidget {
  const MyPrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller ko initialize karna
    final controller = Get.put(PrescriptionController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "My Prescription",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            onPressed: () => Get.to(() => const UploadPrescriptionScreen()),
            icon: const Icon(Icons.add_circle_outline, size: 28),
          ),
        ],
      ),
      body: Obx(() {
        // 1. Loading State
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF285D66)),
          );
        }

        // 2. Empty State
        if (controller.prescriptions.isEmpty) {
          return _buildEmptyState();
        }

        // 3. Data List
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          itemCount: controller.prescriptions.length,
          itemBuilder: (context, index) {
            final item =
                controller.prescriptions[index].data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () => Get.to(() => PrescriptionDetailScreen(data: item)),
              child: _buildPrescriptionCard(item),
            );
          },
        );
      }),
    );
  }

  // --- UI Card Widget ---
  Widget _buildPrescriptionCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1), // Original Light Teal
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB2DFDB), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['id'] ?? 'Unknown ID',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF285D66),
                ),
              ),
              _buildStatusBadge(item['status'] ?? 'Pending'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item['doctor'] ?? 'Unknown Doctor',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: Color(0xFF1B4D55),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item['note'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Uploaded ${item['date'] ?? ''}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Text(
                "View Comment",
                style: TextStyle(
                  color: Color(0xFF285D66),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Status Badge Helper ---
  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Approved':
        color = Colors.green.shade600;
        break;
      case 'Pending':
        color = Colors.orange.shade700;
        break;
      case 'Rejected':
        color = Colors.red.shade600;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- Empty State UI ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_late_outlined,
            size: 80,
            color: Colors.teal.shade100,
          ),
          const SizedBox(height: 15),
          const Text(
            "Nothing here yet!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
