import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // 🛡️ Base64 decode karne ke liye laazmi hai

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please Login First")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Clean premium background
      appBar: AppBar(
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Product History",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .snapshots(includeMetadataChanges: true),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF285D66)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          List<Map<String, dynamic>> allItems = [];

          // 1. Extract and Flatten Items
          for (var doc in snapshot.data!.docs) {
            var orderData = doc.data() as Map<String, dynamic>;
            List<dynamic> orderItems = orderData['items'] ?? [];

            String parsedDate = _getSafeDateKey(orderData);

            Timestamp orderTimestamp = orderData['timestamp'] is Timestamp
                ? orderData['timestamp']
                : Timestamp.now();

            for (var item in orderItems) {
              Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
              itemMap['resolvedDate'] = parsedDate;
              itemMap['orderTimestamp'] = orderTimestamp;
              allItems.add(itemMap);
            }
          }

          // 2. Sort all items locally
          allItems.sort((a, b) {
            Timestamp t1 = a['orderTimestamp'];
            Timestamp t2 = b['orderTimestamp'];
            return t2.compareTo(t1);
          });

          // 3. Group Items
          Map<String, List<Map<String, dynamic>>> groupedItems = {};

          for (var item in allItems) {
            String dateKey = item['resolvedDate'];
            if (!groupedItems.containsKey(dateKey)) {
              groupedItems[dateKey] = [];
            }
            groupedItems[dateKey]!.add(item);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            physics: const BouncingScrollPhysics(),
            itemCount: groupedItems.keys.length,
            itemBuilder: (context, index) {
              String dateKey = groupedItems.keys.elementAt(index);
              List<Map<String, dynamic>> itemsForDate = groupedItems[dateKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateHeader(dateKey),
                  ...itemsForDate.map((item) => _buildPremiumProductCard(item)),
                  const SizedBox(height: 10),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // --- STYLISH DATE HEADER ---
  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 15),
      child: Row(
        children: [
          Container(
            height: 8,
            width: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF285D66),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            date,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D3436),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        ],
      ),
    );
  }

  // --- PREMIUM PRODUCT CARD (CRASH PROOF) ---
  Widget _buildPremiumProductCard(Map<String, dynamic> item) {
    // 🛡️ 1. Safe Data Parsing (Ye String aur Int ka error khatam karega)
    String name = item['name']?.toString() ?? 'Unknown';
    String brand = item['brand']?.toString() ?? 'PharmaPro';
    String price = item['price']?.toString() ?? "0";
    int qty =
        int.tryParse(item['qty']?.toString() ?? '1') ??
        1; // 👈 FIX: Int/String issue solved here

    // 🛡️ 2. Smart Image Builder (Ye Base64 wala error khatam karega)
    String imagePath = item['image']?.toString() ?? '';
    Widget imageWidget;
    String cleanPath = imagePath.trim();

    if (cleanPath.isEmpty) {
      imageWidget = const Icon(Icons.medication, color: Colors.grey);
    } else if (cleanPath.startsWith('http')) {
      imageWidget = Image.network(
        cleanPath,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    } else if (cleanPath.contains('assets/')) {
      imageWidget = Image.asset(
        cleanPath,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    } else {
      try {
        String base64String = cleanPath;
        if (cleanPath.contains(',')) {
          base64String = cleanPath.split(',').last;
        }
        base64String = base64String.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
        if (base64String.length % 4 != 0) {
          base64String += '=' * (4 - (base64String.length % 4));
        }
        imageWidget = Image.memory(
          base64Decode(base64String),
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        );
      } catch (e) {
        imageWidget = const Icon(Icons.medication, color: Colors.grey);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.03,
            ), // Faint, premium shadow
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image Box
          Container(
            height: 75,
            width: 75,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA), // Soft grey background
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageWidget, // 👈 Safe Image yahan show hogi
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      price.contains("Rs") ? price : "Rs. $price",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF285D66),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  brand,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // Bottom Row (Qty Capsule)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F6F7), // Soft Teal-Grey Background
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Qty: $qty",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF285D66),
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

  // --- EMPTY STATE ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFF285D66).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 60,
              color: const Color(0xFF285D66).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "No purchase history",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Your previous orders will show up here.",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // --- BULLETPROOF DATE PARSER ---
  String _getSafeDateKey(Map<String, dynamic> orderData) {
    try {
      if (orderData['timestamp'] != null &&
          orderData['timestamp'] is Timestamp) {
        return _formatDate((orderData['timestamp'] as Timestamp).toDate());
      }
      if (orderData['date'] != null) {
        String dateStr = orderData['date'].toString();
        if (dateStr.contains('-')) {
          List<String> parts = dateStr.split('-');
          if (parts.length == 3) {
            DateTime parsedDate = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
            return _formatDate(parsedDate);
          }
        }
      }
    } catch (e) {
      debugPrint("Date Parsing Error: $e");
    }
    return "Today";
  }

  // --- DATE FORMATTER ---
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final justDate = DateTime(date.year, date.month, date.day);
    final justNow = DateTime(now.year, now.month, now.day);

    final diff = justNow.difference(justDate).inDays;

    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";

    return DateFormat('MMM dd, yyyy').format(date);
  }
}
