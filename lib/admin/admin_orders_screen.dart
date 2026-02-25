import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
//import 'package:get/get.dart';
import 'admin_drawer.dart'; // 👈 Sidebar Import

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xFF285D66);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), // Halka background color
      drawer: const AdminDrawer(), // 👈 Sidebar lag gaya
      appBar: AppBar(
        title: const Text(
          "Customer Orders",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: themeColor),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "No orders found.",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          var orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var orderData = orders[index].data() as Map<String, dynamic>;
              String docId = orders[index].id;
              var address = orderData['addressDetails'] ?? {};
              List items = orderData['items'] ?? [];
              String status = orderData['status'] ?? "Pending";

              String orderId = orderData['orderId']?.toString() ?? docId;
              String displayId = orderId.length > 8
                  ? orderId.substring(0, 8)
                  : orderId;
              String totalAmount =
                  (orderData['totalAmount'] ?? orderData['total'] ?? '0')
                      .toString();

              Color statusColor = _getStatusColor(status);

              return Card(
                elevation: 2,
                shadowColor: Colors.black12,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  // Expansion tile ki default lines hatane ke liye
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    backgroundColor: Colors.white,
                    collapsedBackgroundColor: Colors.white,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: statusColor,
                        size: 28,
                      ),
                    ),
                    title: Text(
                      "Order: #$displayId",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  address['fullName'] ?? 'Guest User',
                                  style: TextStyle(color: Colors.grey.shade700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Rs. $totalAmount",
                                style: const TextStyle(
                                  color: themeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              // 🎯 Status Chip ab subtitle mein hai taake Expand arrow ghaib na ho
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    children: [
                      Container(
                        color: Colors.grey.shade50,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 📍 Address Details
                            const Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: themeColor,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Delivery Address",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.only(left: 26.0),
                              child: Text(
                                orderData['deliveryAddress'] ??
                                    "${address['street']}, ${address['city']}",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(),
                            ),

                            // 📦 Items List
                            const Text(
                              "Items Purchased:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...items.map(
                              (item) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: _buildItemImage(
                                    item['image']?.toString(),
                                  ),
                                  title: Text(
                                    item['name'] ?? "Product",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text("Qty: ${item['qty']}"),
                                  trailing: Text(
                                    "Rs. ${item['price']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: themeColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),

                            // 🔄 Status Updater
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Update Status:",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                _buildStatusUpdater(docId, status, themeColor),
                              ],
                            ),
                          ],
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

  // --- Helpers ---

  Color _getStatusColor(String status) {
    switch (status) {
      case "Pending":
      case "Pending Approval":
        return Colors.orange;
      case "Approved":
        return Colors.blue;
      case "Delivered":
        return Colors.green;
      case "Cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildItemImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.medication, color: Colors.grey),
      );
    }
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: path.startsWith('http')
            ? Image.network(
                path,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.image),
              )
            : Image.asset(
                path,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.image),
              ),
      ),
    );
  }

  Widget _buildStatusUpdater(
    String docId,
    String currentStatus,
    Color themeColor,
  ) {
    final List<String> statusOptions = [
      "Pending",
      "Approved",
      "Delivered",
      "Cancelled",
      "Pending Approval",
    ];

    if (!statusOptions.contains(currentStatus)) {
      statusOptions.add(currentStatus);
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: themeColor),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentStatus,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF285D66)),
          dropdownColor: Colors.white,
          items: statusOptions.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Text(
                s,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null && val != currentStatus) {
              FirebaseFirestore.instance.collection('orders').doc(docId).update(
                {'status': val},
              );
            }
          },
        ),
      ),
    );
  }
}
