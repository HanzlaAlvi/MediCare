import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'prescription_detail_screen.dart'; // Detail screen import
import 'upload_prescription_screen.dart'; // Upload screen import

class MyPrescriptionsScreen extends StatelessWidget {
  const MyPrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Current User ID for Database Query
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "My Prescription",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UploadPrescriptionScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 30),
          ),
        ],
      ),
      // --- DATABASE CONNECTION START ---
      body: user == null
          ? const Center(child: Text("Please login to view prescriptions"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('prescriptions')
                  .orderBy('timestamp', descending: true) // Latest first
                  .snapshots(),
              builder: (context, snapshot) {
                // 1. Loading State
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 2. Empty State
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "No prescriptions uploaded yet.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // 3. Data Loaded
                final prescriptions = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: prescriptions.length,
                  itemBuilder: (context, index) {
                    // Get data from Firestore Document
                    final item =
                        prescriptions[index].data() as Map<String, dynamic>;

                    return GestureDetector(
                      onTap: () {
                        // Navigate to Detail Screen with REAL Data
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PrescriptionDetailScreen(data: item),
                          ),
                        );
                      },
                      // --- UI CARD (SAME AS YOUR MOCK) ---
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1), // Light Teal bg
                          borderRadius: BorderRadius.circular(20),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                _buildStatusBadge(item['status'] ?? 'Pending'),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item['doctor'] ?? 'Unknown Doctor',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              item['note'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Uploaded ${item['date']}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "View Pharmacist Comment",
                              style: TextStyle(
                                color: Color(0xFF285D66),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  // --- Helper Widget for Status Colors ---
  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Approved':
        color = Colors.green;
        break;
      case 'Pending':
        color = Colors.orangeAccent;
        break;
      case 'Rejected':
        color = Colors.redAccent;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
