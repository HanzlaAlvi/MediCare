import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please Login First")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        centerTitle: true,
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
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF285D66)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No product history found"));
          }

          List<Map<String, dynamic>> allItems = [];

          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            List<dynamic> orderItems = data['items'] ?? [];

            for (var item in orderItems) {
              allItems.add(item as Map<String, dynamic>);
            }
          }

          allItems.sort((a, b) {
            Timestamp t1 = a['timestamp'] ?? Timestamp.now();
            Timestamp t2 = b['timestamp'] ?? Timestamp.now();
            return t2.compareTo(t1);
          });

          Map<String, List<Map<String, dynamic>>> groupedItems = {};

          for (var item in allItems) {
            Timestamp? t = item['timestamp'];
            String dateKey = "Unknown Date";
            if (t != null) {
              dateKey = DateFormat(
                'MMM dd, yyyy',
              ).format(t.toDate()).toLowerCase();
            }

            if (!groupedItems.containsKey(dateKey)) {
              groupedItems[dateKey] = [];
            }
            groupedItems[dateKey]!.add(item);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: groupedItems.keys.length,
            itemBuilder: (context, index) {
              String dateKey = groupedItems.keys.elementAt(index);
              List<Map<String, dynamic>> itemsForDate = groupedItems[dateKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 15),
                    child: Text(
                      dateKey,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // FIX: .toList() removed from here to fix linter error
                  ...itemsForDate.map((item) => _buildProductItem(item)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
    String name = item['name'] ?? 'Unknown';
    String brand = item['brand'] ?? 'PharmaPro';
    String price = item['price'] ?? "Rs. 0";
    int qty = item['qty'] ?? 1;
    String imagePath = item['image'] ?? '';

    ImageProvider imgProvider;
    if (imagePath.startsWith('http')) {
      imgProvider = NetworkImage(imagePath);
    } else if (imagePath.isNotEmpty) {
      imgProvider = AssetImage(imagePath);
    } else {
      imgProvider = const NetworkImage(
        'https://cdn-icons-png.flaticon.com/512/883/883407.png',
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              image: DecorationImage(image: imgProvider, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  brand,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF285D66),
                  ),
                ),
              ],
            ),
          ),
          Text(
            "x$qty",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF285D66),
            ),
          ),
        ],
      ),
    );
  }
}
