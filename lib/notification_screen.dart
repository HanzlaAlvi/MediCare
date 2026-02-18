import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String selectedFilter = 'All';
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _markAllAsRead(List<QueryDocumentSnapshot> docs) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in docs) {
      batch.update(doc.reference, {'isUnread': false});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: uid == null
          ? const Center(child: Text("Please Login to see notifications"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: uid)
                  // REMOVED: .orderBy('timestamp') -> Index issue hatane ke liye
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF285D66)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "No Notifications yet",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // --- NEW LOGIC: Client-Side Sorting ---
                var allDocs = snapshot.data!.docs;

                // Hum yahan sort kar rahe hain taake Index ki zaroorat na pade
                allDocs.sort((a, b) {
                  Timestamp t1 = a['timestamp'] ?? Timestamp.now();
                  Timestamp t2 = b['timestamp'] ?? Timestamp.now();
                  return t2.compareTo(t1); // Latest first
                });

                var displayedDocs = selectedFilter == 'Unread'
                    ? allDocs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return data['isUnread'] == true;
                      }).toList()
                    : allDocs;

                int unreadCount = allDocs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return data['isUnread'] == true;
                }).length;

                return Column(
                  children: [
                    // --- Filter Bar ---
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      child: Row(
                        children: [
                          _buildFilterButton(
                            "All",
                            allDocs.length,
                            selectedFilter == 'All',
                          ),
                          const SizedBox(width: 15),
                          _buildFilterButton(
                            "Unread",
                            unreadCount,
                            selectedFilter == 'Unread',
                          ),
                          const Spacer(),
                          if (unreadCount > 0)
                            TextButton(
                              onPressed: () => _markAllAsRead(allDocs),
                              child: const Text(
                                "Mark all as read",
                                style: TextStyle(
                                  color: Color(0xFF285D66),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // --- List ---
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: displayedDocs.length,
                        itemBuilder: (context, index) {
                          final doc = displayedDocs[index];
                          final item = doc.data() as Map<String, dynamic>;
                          item['docId'] = doc.id;

                          return GestureDetector(
                            onTap: () {
                              FirebaseFirestore.instance
                                  .collection('notifications')
                                  .doc(doc.id)
                                  .update({'isUnread': false});

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      NotificationDetailScreen(
                                        notification: item,
                                      ),
                                ),
                              );
                            },
                            child: _buildNotificationCard(item),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildFilterButton(String label, int count, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF285D66) : const Color(0xFFE0F2F1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF285D66),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFF285D66),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "$count",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    IconData icon;
    Color iconColor;
    bool isUnread = item['isUnread'] ?? false;

    switch (item['type']) {
      case 'confirmed':
        icon = Icons.check_circle_outline;
        iconColor = Colors.green;
        break;
      case 'delivery':
        icon = Icons.local_shipping_outlined;
        iconColor = Colors.orange;
        break;
      case 'prescription':
        icon = Icons.description_outlined;
        iconColor = Colors.blueAccent;
        break;
      case 'offer':
        icon = Icons.local_fire_department;
        iconColor = Colors.redAccent;
        break;
      case 'reminder':
        icon = Icons.shopping_cart_checkout;
        iconColor = Colors.purpleAccent;
        break;
      case 'feature':
        icon = Icons.chat_bubble_outline;
        iconColor = const Color(0xFF285D66);
        break;
      default:
        icon = Icons.notifications_none;
        iconColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFFE0F2F1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isUnread
            ? Border.all(color: const Color(0xFF285D66).withValues(alpha: 0.3))
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          if (!isUnread)
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['title'] ?? 'Notification',
                        style: TextStyle(
                          fontWeight: isUnread
                              ? FontWeight.w800
                              : FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      item['time'] ?? 'Just now',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  item['message'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: isUnread ? Colors.black87 : Colors.black54,
                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isUnread)
            Container(
              margin: const EdgeInsets.only(left: 5, top: 5),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF285D66),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
