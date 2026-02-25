import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Customer Orders",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🎯 Direct fetch from 'orders' collection
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF285D66)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No orders found."));
          }

          var orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var orderData = orders[index].data() as Map<String, dynamic>;
              var address = orderData['addressDetails'] ?? {};
              List items = orderData['items'] ?? [];
              String status = orderData['status'] ?? "Pending";

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
                color: context.theme.cardColor,
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(
                      status,
                    ).withValues(alpha: 0.1),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: _getStatusColor(status),
                    ),
                  ),
                  title: Text(
                    "Order ID: ${orderData['orderId']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Customer: ${address['fullName'] ?? 'N/A'}\nTotal: ${orderData['totalAmount']}",
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  children: [
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Delivery Address:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(orderData['deliveryAddress'] ?? "N/A"),
                          const SizedBox(height: 10),
                          const Text(
                            "Items:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...items.map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item['name'] ?? ""),
                              subtitle: Text(
                                "Qty: ${item['qty']} | ${item['price']}",
                              ),
                              leading: _buildItemImage(item['image']),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildStatusUpdater(orders[index].id, status),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Color logic based on status
  Color _getStatusColor(String status) {
    if (status == "Pending") return Colors.orange;
    if (status == "Approved") return Colors.blue;
    if (status == "Delivered") return Colors.green;
    return Colors.red;
  }

  // Item image handling (Asset vs Network)
  Widget _buildItemImage(String? path) {
    if (path == null || path.isEmpty) return const Icon(Icons.medication);
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: path.startsWith('http')
          ? Image.network(path, width: 40, height: 40, fit: BoxFit.cover)
          : Image.asset(path, width: 40, height: 40, fit: BoxFit.cover),
    );
  }

  // Update Status in DB
  Widget _buildStatusUpdater(String docId, String currentStatus) {
    // 🎯 Status options ko DB ke status ke mutabiq sync karein
    final List<String> statusOptions = [
      "Pending",
      "Approved",
      "Delivered",
      "Cancelled",
      "Pending Approval",
    ];

    // 🛡️ Safety Check: Agar DB wala status list mein nahi hai, toh use list mein add kar dein
    if (!statusOptions.contains(currentStatus)) {
      statusOptions.add(currentStatus);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          "Update Status: ",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        DropdownButton<String>(
          value: currentStatus, // Ab yeh crash nahi karega
          items: statusOptions.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Text(s, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              FirebaseFirestore.instance.collection('orders').doc(docId).update(
                {'status': val},
              );
            }
          },
        ),
      ],
    );
  }
}
