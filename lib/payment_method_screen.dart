import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'payment_success_screen.dart';
import 'transaction_proof_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;
  final Map<String, dynamic> selectedAddress;

  const PaymentMethodScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    required this.selectedAddress,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  int _selectedOption = 3; // Default to COD
  bool _isLoading = false;

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'name': 'Easy Paisa',
      'logo': Icons.account_balance_wallet,
      'color': Colors.green,
    },
    {
      'name': 'Jazz Cash',
      'logo': Icons.account_balance_wallet,
      'color': Colors.red,
    },
    {'name': 'Pay Fast', 'logo': Icons.payment, 'color': Colors.redAccent},
    {
      'name': 'Cash on Delivery (COD)',
      'logo': Icons.money,
      'color': Colors.teal,
    },
  ];

  void _handlePaymentSelection() {
    if (_selectedOption == 3) {
      _processDirectOrder();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionProofScreen(
            cartItems: widget.cartItems,
            totalAmount: widget.totalAmount,
            selectedAddress: widget.selectedAddress,
            paymentMethod: paymentMethods[_selectedOption]['name'],
          ),
        ),
      );
    }
  }

  Future<void> _processDirectOrder() async {
    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(
      context,
    ); // Store reference before async

    String userId = FirebaseAuth.instance.currentUser!.uid;
    String orderId =
        "ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";

    try {
      // 1. Order Place Karein
      await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'userId': userId,
        'items': widget.cartItems,
        'totalAmount': widget.totalAmount,
        'status': 'Pending',
        'paymentMethod': 'Cash on Delivery (COD)',
        'addressDetails': widget.selectedAddress,
        'deliveryAddress':
            "${widget.selectedAddress['street']}, ${widget.selectedAddress['city']}",
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Cart Clear Karein
      var snaps = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in snaps.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // 3. ASYNC GAP GUARD: Check karein ke widget abhi bhi mounted hai
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PaymentSuccessScreen()),
        (route) => false,
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // build method remains the same as your original code
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
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF285D66)),
            )
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
                      onPressed: _handlePaymentSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF285D66),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        _selectedOption == 3
                            ? "Confirm Order"
                            : "Continue to Proof",
                        style: const TextStyle(
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
