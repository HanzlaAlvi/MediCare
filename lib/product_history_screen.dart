import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductHistoryScreen extends StatelessWidget {
  const ProductHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Please Login First")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Product History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: uid)
            .orderBy('timestamp', descending: true)
            .snapshots(includeMetadataChanges: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF285D66)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No purchase history",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          Map<String, List<Map<String, dynamic>>> groupedHistory = {};

          for (var doc in snapshot.data!.docs) {
            var orderData = doc.data() as Map<String, dynamic>;

            String dateKey = "Today";

            try {
              if (orderData['timestamp'] != null &&
                  orderData['timestamp'] is Timestamp) {
                DateTime dt = (orderData['timestamp'] as Timestamp).toDate();
                dateKey = _formatDate(dt);
              }
            } catch (e) {
              dateKey = "Today"; 
            }

            List items = orderData['items'] ?? [];

            for (var item in items) {
              Map<String, dynamic> itemMap = Map.from(item);
              if (!groupedHistory.containsKey(dateKey)) {
                groupedHistory[dateKey] = [];
              }
              groupedHistory[dateKey]!.add(itemMap);
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: groupedHistory.keys.length,
            itemBuilder: (context, index) {
              String date = groupedHistory.keys.elementAt(index);
              List<Map<String, dynamic>> products = groupedHistory[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20, top: 10),
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Product Items
                  ...products.map((product) => _buildProductItem(product)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // --- SMART DATE FORMATTER ---
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final justDate = DateTime(date.year, date.month, date.day);
    final justNow = DateTime(now.year, now.month, now.day);

    final diff = justNow.difference(justDate).inDays;

    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";

    return DateFormat('MMM dd, yyyy').format(date); // Output: Feb 19, 2026
  }

  // --- UI COMPONENT ---
  Widget _buildProductItem(Map<String, dynamic> item) {
    String name = item['name'] ?? 'Product';
    String brand = item['brand'] ?? 'Unknown';
    String price = item['price']?.toString() ?? '0';
    String imageUrl = item['image'] ?? '';
    bool isNetwork = imageUrl.startsWith('http');
    String qty = item['qty']?.toString() ?? '1';

    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: isNetwork
                    ? Image.network(imageUrl, fit: BoxFit.contain)
                    : Image.asset(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (c, o, s) =>
                            const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 5),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  brand,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  price.contains("Rs") ? price : "Rs. $price",
                  style: const TextStyle(
                    color: Color(0xFF285D66),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              "x$qty",
              style: const TextStyle(
                color: Color(0xFF285D66),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
