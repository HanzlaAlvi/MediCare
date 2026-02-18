import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton Pattern
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

  // --- NEW: DUPLICATE PREVENTION ---
  // Order IDs aur unke last notification ka time store karenge
  final Map<String, DateTime> _processedOrders = {};

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // --- 1. INITIALIZE ---
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

  // --- 2. SHOW POP-UP ---
  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'medicare_channel_id',
          'Medi Care Updates',
          channelDescription: 'Real-time alerts',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          ticker: 'ticker',
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

  // --- 3. START LISTENERS ---
  void startMonitoring() {
    if (_uid == null) return;
    stopMonitoring(); // Purane listeners band karein taake double na hon

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
    _processedOrders.clear(); // Clear cache on stop
  }

  // --- A. MONITOR ORDERS (FIXED DOUBLE NOTIFICATION) ---
  void _monitorOrders() {
    _orderSubscription = _db
        .collection('orders')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            String orderId = change.doc['orderId'] ?? change.doc.id;

            // 1. New Order Placed
            if (change.type == DocumentChangeType.added) {
              Timestamp? ts = change.doc['timestamp'];
              bool isRecent = false;

              // Check time logic
              if (ts != null &&
                  DateTime.now().difference(ts.toDate()).inSeconds < 30) {
                isRecent = true;
              }
              if (ts == null) {
                isRecent = true;
              }

              if (isRecent) {
                // --- FIX: Prevent Duplicate ---
                if (_shouldSkipNotification(orderId)) return;

                _sendNotification(
                  title: "Order Confirmed! 🎉",
                  message: "Order #$orderId placed successfully.",
                  type: "confirmed",
                );
                _markAsProcessed(orderId);
              }
            }
            // 2. Order Status Modified
            else if (change.type == DocumentChangeType.modified) {
              String newStatus = change.doc['status'];

              // Status change hone par hi bhejo
              if (newStatus != 'Processing') {
                // Unique key for status change to allow different updates
                String updateKey = "$orderId-$newStatus";
                if (_shouldSkipNotification(updateKey)) return;

                _sendNotification(
                  title: "Order Update 🚚",
                  message: "Your order is now $newStatus.",
                  type: "delivery",
                );
                _markAsProcessed(updateKey);
              }
            }
          }
        });
  }

  // --- HELPER: DUPLICATE CHECKER ---
  bool _shouldSkipNotification(String id) {
    if (_processedOrders.containsKey(id)) {
      final lastTime = _processedOrders[id]!;
      // Agar 10 second ke andar same ID par notification gayi hai, to SKIP karo
      if (DateTime.now().difference(lastTime).inSeconds < 10) {
        return true;
      }
    }
    return false;
  }

  void _markAsProcessed(String id) {
    _processedOrders[id] = DateTime.now();
  }

  // --- B. MONITOR PRESCRIPTIONS ---
  void _monitorPrescriptions() {
    _prescriptionSubscription = _db
        .collection('users')
        .doc(_uid)
        .collection('prescriptions')
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            var data = change.doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'Pending';
            Timestamp? timestamp = data['timestamp'];
            String docId = change.doc.id; // Unique ID

            bool shouldNotify = false;
            String title = "Prescription Update 📄";
            String message = "";

            if (change.type == DocumentChangeType.modified) {
              shouldNotify = true;
              message = "Your prescription status is now: $status";
            } else if (change.type == DocumentChangeType.added) {
              bool isRecent = false;
              if (timestamp == null) {
                isRecent = true;
              } else {
                if (DateTime.now().difference(timestamp.toDate()).inSeconds <
                    30)
                  {isRecent = true;}
              }

              if (isRecent && status != 'Pending') {
                shouldNotify = true;
                title = "AI Analysis Complete 🤖";
                message = "Your prescription was automatically $status.";
              }
            }

            if (shouldNotify) {
              // --- FIX: Prevent Duplicate ---
              String key = "$docId-$status";
              if (_shouldSkipNotification(key)) return;

              _sendNotification(
                title: title,
                message: message,
                type: "prescription",
              );
              _markAsProcessed(key);
            }
          }
        });
  }

  // --- C. MONITOR CHAT ---
  void _monitorChat() {
    _chatSubscription = _db
        .collection('users')
        .doc(_uid)
        .collection('chat_history')
        .where('role', isEqualTo: 'bot')
        .limit(10)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              Timestamp? ts = change.doc['timestamp'];
              String msgId = change.doc.id;
              bool isRecent = false;

              if (ts == null) {
                isRecent = true;
              } else {
                if (DateTime.now().difference(ts.toDate()).inSeconds < 60) {
                  isRecent = true;
                }
              }

              if (isRecent) {
                if (_shouldSkipNotification(msgId)) return;

                _sendNotification(
                  title: "New Message 💬",
                  message: "MediCare Assistant sent you a reply.",
                  type: "feature",
                );
                _markAsProcessed(msgId);
              }
            }
          }
        });
  }

  // --- D. MONITOR CART & STOCK ---
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
            String itemName = cartDoc['name'];
            Timestamp? addedAt = cartDoc['addedAt'];

            if (addedAt != null) {
              if (DateTime.now().difference(addedAt.toDate()).inDays >= 2) {
                // Cart Reminder: Check Duplicate (Daily basis logic handled by map overwrite)
                if (!_shouldSkipNotification("cart-$itemName")) {
                  _sendNotification(
                    title: "Forgot something? 🤔",
                    message: "$itemName is waiting in your cart!",
                    type: "reminder",
                  );
                  _markAsProcessed("cart-$itemName");
                }
              }
            }

            var stockSub = _db
                .collection('medicines')
                .where('name', isEqualTo: itemName)
                .limit(1)
                .snapshots()
                .listen((medSnapshot) {
                  if (medSnapshot.docs.isNotEmpty) {
                    int stock = medSnapshot.docs.first.data()['stock'] ?? 0;
                    if ([10, 7, 5, 3, 1].contains(stock)) {
                      if (!_shouldSkipNotification("stock-$itemName-$stock")) {
                        _sendNotification(
                          title: "Stock Alert! 🔥",
                          message: "Only $stock left for $itemName",
                          type: "offer",
                        );
                        _markAsProcessed("stock-$itemName-$stock");
                      }
                    }
                  }
                });
            _stockSubscriptions.add(stockSub);
          }
        });
  }

  // --- HELPER: SEND & SAVE ---
  Future<void> _sendNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    if (_uid == null) return;
    await _showLocalNotification(title, message);
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
