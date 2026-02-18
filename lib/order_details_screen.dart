import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'order_history.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;
  const OrderDetailsScreen({super.key, required this.orderData});

  // --- NEW: FETCH ADDRESS FROM SUB-COLLECTION ---
  Future<String> _fetchUserAddress() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return "User not logged in";

    try {
      // 1. Access the 'addresses' sub-collection
      QuerySnapshot addressSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .limit(1) // Get just one for now
          .get();

      if (addressSnapshot.docs.isNotEmpty) {
        // 2. Get the first document found
        var data = addressSnapshot.docs.first.data() as Map<String, dynamic>;

        // 3. Construct the String
        String street = data['street'] ?? '';
        String city = data['city'] ?? '';
        String country = data['country'] ?? '';

        // Handle cases where fields might be missing
        List<String> parts = [
          street,
          city,
          country,
        ].where((s) => s.isNotEmpty).toList();

        if (parts.isNotEmpty) {
          return parts.join(", ");
        }
      }
    } catch (e) {
      debugPrint("Address Fetch Error: $e");
    }
    return "No address found";
  }

  @override
  Widget build(BuildContext context) {
    String orderId = orderData['orderId']?.toString() ?? 'ORD-000';
    String status = orderData['status'] ?? 'Processing';
    String date = orderData['date']?.toString() ?? 'No Date';

    // --- ADDRESS LOGIC ---
    // If Order has address, use it. If not, fetch from Sub-collection.
    String? orderAddress = orderData['deliveryAddress'] ?? orderData['address'];
    bool fetchFromDb = orderAddress == null || orderAddress.isEmpty;

    double subtotal = 0.0;
    if (orderData['total'] != null) {
      subtotal = double.tryParse(orderData['total'].toString()) ?? 0.0;
    } else if (orderData['totalAmount'] != null) {
      subtotal = double.tryParse(orderData['totalAmount'].toString()) ?? 0.0;
    }

    double tax = 200.0;
    double total = subtotal + tax;

    Color statusColor = status == 'Delivered'
        ? const Color(0xFF8DC63F)
        : const Color(0xFFFFA726);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Order Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER ---
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderId.length > 10
                            ? "#${orderId.substring(0, 8)}..."
                            : "#$orderId",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF285D66),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Placed on $date",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // --- 2. TRACKING ---
            _buildSection(
              title: "Order Tracking",
              child: Column(
                children: [
                  _trackingStep("Pending", "Order received", true),
                  _trackingStep(
                    "Processing",
                    "Packing items",
                    status != "Pending",
                  ),
                  _trackingStep(
                    "Delivered",
                    status == "Delivered" ? "Delivered to you" : "In transit",
                    status == "Delivered",
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- 3. DELIVERY ADDRESS (Using FutureBuilder) ---
            _buildSection(
              title: "Delivery Address",
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2F1),
                    child: Icon(Icons.location_on, color: Color(0xFF285D66)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: fetchFromDb
                        ? FutureBuilder<String>(
                            future: _fetchUserAddress(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text(
                                  "Fetching address...",
                                  style: TextStyle(color: Colors.grey),
                                );
                              }
                              if (snapshot.hasError) {
                                return const Text(
                                  "Error loading address",
                                  style: TextStyle(color: Colors.red),
                                );
                              }
                              return Text(
                                snapshot.data ?? "Address not found",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              );
                            },
                          )
                        : Text(
                            orderAddress , 
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // --- 4. SUMMARY ---
            const Text(
              "Payment Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _summaryRow("Subtotal:", "Rs.${subtotal.toStringAsFixed(0)}"),
            const Divider(),
            _summaryRow("Delivery Fee", "FREE", valueColor: Colors.green),
            _summaryRow("Sales tax:", "Rs.${tax.toStringAsFixed(0)}"),
            const Divider(),
            _summaryRow(
              "Order total:",
              "Rs.${total.toStringAsFixed(0)}",
              isBold: true,
              valueColor: const Color(0xFF285D66),
            ),

            const SizedBox(height: 30),

            // --- 5. BUTTON ---
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderHistoryScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF285D66),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                "View Ordered products",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _trackingStep(
    String title,
    String subtitle,
    bool isDone, {
    bool isLast = false,
  }) {
    return Row(
      children: [
        Column(
          children: [
            Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isDone ? const Color(0xFF285D66) : Colors.grey,
              size: 28,
            ),
            if (!isLast)
              Container(
                height: 30,
                width: 2,
                color: isDone ? const Color(0xFF285D66) : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDone ? Colors.black : Colors.grey,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (!isLast) const SizedBox(height: 20),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color valueColor = Colors.black,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
