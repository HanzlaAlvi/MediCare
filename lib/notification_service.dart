import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription? _cartSubscription;
  StreamSubscription? _orderSubscription;
  StreamSubscription? _prescriptionSubscription;
  StreamSubscription? _chatSubscription;
  final List<StreamSubscription> _stockSubscriptions = [];

  // --- 1. DEDUPLICATION MEMORY ---
  final Set<String> _handledEvents = {};

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // --- 2. INITIALIZE ---
  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _notificationsPlugin.initialize(settings: initSettings);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  // --- 3. SHOW NOTIFICATION ---
  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'medicare_channel_id',
          'Medi Care Updates',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // --- 4. START LISTENERS ---
  void startMonitoring() {
    if (_uid == null) return;
    stopMonitoring();

    _monitorOrders();
    _monitorCartAndStock();
    _monitorPrescriptions();
    _monitorChat();
  }

  void stopMonitoring() {
    _cartSubscription?.cancel();
    _orderSubscription?.cancel();
    _prescriptionSubscription?.cancel();
    _chatSubscription?.cancel();
    for (var sub in _stockSubscriptions) {
      sub.cancel();
    }
    _stockSubscriptions.clear();
    _handledEvents.clear();
  }

  // --- A. MONITOR ORDERS (INSTANT & SINGLE ALERT) ---
  void _monitorOrders() {
    _orderSubscription = _db
        .collection('orders')
        .where('userId', isEqualTo: _uid)
        // FIX: includeMetadataChanges ensure instant local trigger
        .snapshots(includeMetadataChanges: true)
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            final data = change.doc.data() as Map<String, dynamic>;
            String orderId = data['orderId'] ?? change.doc.id;
            String status = data['status'] ?? 'Processing';

            // UNIQUE KEY (OrderID + Status combination)
            String eventKey = "ORDER_${orderId}_$status";

            // Step 1: Check Duplicate
            if (_handledEvents.contains(eventKey)) {
              continue;
            }

            bool shouldNotify = false;
            String title = "";
            String message = "";
            String type = "delivery";

            // Step 2: Handle Logic
            // Case 1: New Order Placed
            if (change.type == DocumentChangeType.added) {
              Timestamp? ts = data['timestamp'];

              // Agar timestamp null hai (Matlab abhi mobile se likha gaya hai -> Instant Notification)
              // Ya agar timestamp abhi 2 minute ke andar ka hai.
              bool isRecent =
                  ts == null ||
                  DateTime.now().difference(ts.toDate()).inSeconds < 120;

              if (isRecent && (status == 'Processing' || status == 'Pending')) {
                shouldNotify = true;
                title = "Order Confirmed! 🎉";
                message = "Order #$orderId placed successfully.";
                type = "confirmed";
              }
            }
            // Case 2: Status Update (Shipped/Delivered)
            else if (change.type == DocumentChangeType.modified) {
              if (status != 'Processing' && status != 'Pending') {
                shouldNotify = true;
                title = "Order Update 🚚";
                message = "Your order is now $status.";
              }
            }

            // Step 3: Send & Lock
            if (shouldNotify) {
              _sendNotification(title: title, message: message, type: type);
              _handledEvents.add(
                eventKey,
              ); // LOCK this event to prevent duplicates
            }
          }
        });
  }

  // --- B. MONITOR PRESCRIPTIONS ---
  void _monitorPrescriptions() {
    _prescriptionSubscription = _db
        .collection('users')
        .doc(_uid)
        .collection('prescriptions')
        .snapshots(includeMetadataChanges: true)
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            var data = change.doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'Pending';
            String docId = change.doc.id;

            String eventKey = "PRES_${docId}_$status";

            if (_handledEvents.contains(eventKey)) continue;

            bool shouldNotify = false;
            String title = "Prescription Update 📄";
            String message = "Your prescription status is now: $status";

            Timestamp? ts = data['timestamp'];
            bool isRecent =
                (ts == null) ||
                (DateTime.now().difference(ts.toDate()).inSeconds < 120);

            if (change.type == DocumentChangeType.modified) {
              shouldNotify = true;
            } else if (change.type == DocumentChangeType.added &&
                status != 'Pending' &&
                isRecent) {
              shouldNotify = true;
              title = "AI Analysis Complete 🤖";
              message = "Your prescription was automatically $status.";
            }

            if (shouldNotify) {
              _sendNotification(
                title: title,
                message: message,
                type: "prescription",
              );
              _handledEvents.add(eventKey);
            }
          }
        });
  }

  // to MONITOR CHAT that is in history
  void _monitorChat() {
    _chatSubscription = _db
        .collection('users')
        .doc(_uid)
        .collection('chat_history')
        .where('role', isEqualTo: 'bot')
        .limit(1)
        .snapshots(includeMetadataChanges: true)
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              String msgId = change.doc.id;
              String eventKey = "CHAT_$msgId";

              if (_handledEvents.contains(eventKey)) continue;

              Timestamp? ts = change.doc['timestamp'];
              bool isRecent =
                  (ts == null) ||
                  (DateTime.now().difference(ts.toDate()).inSeconds < 60);

              if (isRecent) {
                _sendNotification(
                  title: "New Message 💬",
                  message: "MediCare Assistant sent you a reply.",
                  type: "feature",
                );
                _handledEvents.add(eventKey);
              }
            }
          }
        });
  }

  //to monitor CART & STOCK together because they are related and we can optimize the listeners
  void _monitorCartAndStock() {
    _cartSubscription = _db
        .collection('users')
        .doc(_uid)
        .collection('cart')
        .snapshots()
        .listen((cartSnapshot) {
          for (var sub in _stockSubscriptions) {
            sub.cancel();
          }
          _stockSubscriptions.clear();

          for (var cartDoc in cartSnapshot.docs) {
            var data = cartDoc.data();
            String itemName = data['name'] ?? 'Unknown Item';
            Timestamp? addedAt = data['addedAt'];

            //if the item is more than 2 days old in the cart, then send Reminder Logic
            if (addedAt != null &&
                DateTime.now().difference(addedAt.toDate()).inDays >= 2) {
              String key = "CART_REMIND_$itemName";
              if (!_handledEvents.contains(key)) {
                _sendNotification(
                  title: "Forgot something? 🤔",
                  message: "$itemName is waiting in your cart!",
                  type: "reminder",
                );
                _handledEvents.add(key);
              }
            }

            //the Stock Logic where if items is less than 10 7 5 3 1
            var stockSub = _db
                .collection('medicines')
                .where('name', isEqualTo: itemName)
                .limit(1)
                .snapshots()
                .listen((medSnapshot) {
                  if (medSnapshot.docs.isNotEmpty) {
                    var medData = medSnapshot.docs.first.data();
                    int stock = medData['stock'] ?? 0;

                    if ([10, 7, 5, 3, 1].contains(stock)) {
                      String key = "STOCK_${itemName}_$stock";
                      if (!_handledEvents.contains(key)) {
                        _sendNotification(
                          title: "Stock Alert! 🔥",
                          message: "Only $stock left for $itemName",
                          type: "offer",
                        );
                        _handledEvents.add(key);
                      }
                    }
                  }
                });
            _stockSubscriptions.add(stockSub);
          }
        }, onError: (e) {});
  }

  //created HELPER to send & save the notification
  Future<void> _sendNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    if (_uid == null) return;

    // to shoe the local popup
    await _showLocalNotification(title, message);

    //Saving the history to Firestore History
    await _db.collection('notifications').add({
      'userId': _uid,
      'title': title,
      'message': message,
      'type': type,
      'isUnread': true,
      'timestamp': FieldValue.serverTimestamp(),
      'time': _formatCurrentTime(),
    });
  }

  Future<void> triggerManualNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    await _sendNotification(title: title, message: message, type: type);
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    int hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    String period = now.hour >= 12 ? "PM" : "AM";
    return "$hour:${now.minute.toString().padLeft(2, '0')} $period";
  }
}
