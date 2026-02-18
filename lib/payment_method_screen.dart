import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'payment_success_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;

  const PaymentMethodScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  int _selectedOption = 0;
  bool _isLoading = false;

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'name': 'Easy Paisa',
      'subtitle': 'Checked Automatically',
      'logo': Icons.account_balance_wallet,
      'color': Colors.green,
      'isWallet': true,
    },
    {
      'name': 'Jazz Cash',
      'subtitle': 'Checked Automatically',
      'logo': Icons.account_balance_wallet,
      'color': Colors.red,
      'isWallet': true,
    },
    {
      'name': 'Pay Fast',
      'subtitle': 'Checked Automatically',
      'logo': Icons.payment,
      'color': Colors.redAccent,
      'isWallet': true,
    },
    {
      'name': 'Cash on Delivery (COD)',
      'subtitle': '',
      'logo': Icons.money,
      'color': Colors.teal,
      'isWallet': false,
    },
  ];

  // --- SAFE PARSER ---
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<void> _processOrder() async {
    setState(() => _isLoading = true);
    String userId = FirebaseAuth.instance.currentUser!.uid;
    String orderId =
        "ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";

    final firestore = FirebaseFirestore.instance;

    try {
      await firestore.runTransaction((transaction) async {
        // Temp list to store updates so we don't write during the read loop
        List<Map<String, dynamic>> stockUpdates = [];

        // --- PHASE 1: READ ALL DATA FIRST ---
        for (var item in widget.cartItems) {
          String itemName = item['name'];
          int qtyOrdered = _parseInt(item['qty']);
          if (qtyOrdered <= 0) qtyOrdered = 1;

          // Search for the medicine document (Query is outside transaction, getting doc is inside)
          QuerySnapshot medSnapshot = await firestore
              .collection('medicines')
              .where('name', isEqualTo: itemName)
              .limit(1)
              .get();

          if (medSnapshot.docs.isNotEmpty) {
            DocumentReference medRef = medSnapshot.docs.first.reference;

            // TRANSACTIONAL READ
            DocumentSnapshot medDoc = await transaction.get(medRef);

            if (medDoc.exists) {
              var data = medDoc.data() as Map<String, dynamic>;
              int currentStock = _parseInt(data['stock']);
              int newStock = currentStock - qtyOrdered;
              if (newStock < 0) newStock = 0;

              // Store this update for Phase 2
              stockUpdates.add({'ref': medRef, 'newStock': newStock});
            }
          }
        }

        // --- PHASE 2: WRITE ALL DATA ---

        // 1. Update Stocks
        for (var update in stockUpdates) {
          transaction.update(update['ref'] as DocumentReference, {
            'stock': update['newStock'],
          });
        }

        // 2. Create Order
        DocumentReference orderRef = firestore.collection('orders').doc();
        transaction.set(orderRef, {
          'orderId': orderId,
          'userId': userId,
          'items': widget.cartItems,
          'total': widget.totalAmount,
          'status': 'Processing',
          'statusColor': 0xFF8BC34A,
          'paymentMethod': paymentMethods[_selectedOption]['name'],
          'date': DateTime.now().toString().split(' ')[0],
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      // --- AFTER TRANSACTION SUCCESS ---

      // 3. Delete Cart (Safe to do outside transaction)
      var cartColl = firestore
          .collection('users')
          .doc(userId)
          .collection('cart');
      var snaps = await cartColl.get();
      for (var doc in snaps.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PaymentSuccessScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Order Failed: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          "Payment",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Choose Method",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(paymentMethods.length, (index) {
                    final method = paymentMethods[index];
                    final isSelected = _selectedOption == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedOption = index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(15),
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFF285D66),
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              method['logo'],
                              color: method['color'],
                              size: 30,
                            ),
                            const SizedBox(width: 15),
                            Text(
                              method['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF285D66),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _processOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF285D66),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        "Confirm Payment",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
