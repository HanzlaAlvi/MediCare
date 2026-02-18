import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_address_screen.dart';
import 'payment_method_screen.dart';

class CheckOutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;

  const CheckOutScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  final TextEditingController _voucherController = TextEditingController();
  double _discountAmount = 0.0;
  bool _isVoucherApplied = false;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  // --- LOGIC: Apply Voucher & Deduct Points ---
  Future<void> _applyVoucher() async {
    String enteredCode = _voucherController.text.trim();
    if (enteredCode.isEmpty) return;

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      final doc = await userRef.get();

      if (doc.exists) {
        String myActualCode = doc.data()?['referralCode'] ?? "";
        int currentPoints = doc.data()?['points'] ?? 0;

        // 1. Check if Code matches user's own unique code
        if (enteredCode != myActualCode) {
          _showMsg("Invalid code! Please use your own reward code.");
          return;
        }

        // 2. Points Check (Must be at least 100)
        if (currentPoints < 100) {
          _showMsg(
            "Not applicable! You need minimum 100 points for 5% discount.",
          );
          return;
        }

        // 3. APPLY DISCOUNT & DEDUCT POINTS
        // Exact 100 points deduct honge discount ke liye
        await userRef.update({'points': currentPoints - 100});

        // Point History update
        await userRef.collection('point_history').add({
          'title': "Voucher Discount Applied",
          'points': "-100",
          'type': 'debit',
          'date': DateTime.now(),
        });

        setState(() {
          _discountAmount = widget.totalAmount * 0.05; // 5% Discount
          _isVoucherApplied = true;
        });

        _showMsg("Success! 5% discount applied and 100 points deducted.");
      }
    } catch (e) {
      _showMsg("Error applying voucher: $e");
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    double finalPayableAmount = widget.totalAmount - _discountAmount;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Check Out",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Shipping Address Section ---
            _buildSectionHeader(
              "Shipping Address",
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddAddressScreen(),
                ),
              ),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('addresses')
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddAddressScreen(),
                        ),
                      ),
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF285D66),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  );
                }
                var addr =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF285D66),
                        size: 28,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addr['fullName'] ?? 'Name',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              addr['email'] ?? 'Email',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "${addr['street']}, ${addr['city']}, ${addr['country']}",
                              style: const TextStyle(
                                color: Colors.grey,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            _buildSectionHeader("Order Summary", () => Navigator.pop(context)),
            const SizedBox(height: 10),
            ...widget.cartItems.map(
              (item) => _buildOrderItem(
                name: item['name'],
                brand: item['brand'],
                price: "Rs. ${item['price']}",
                qty: "x${item['qty']}",
                imageUrl: item['image'],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Voucher",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Serif',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: TextField(
                      controller: _voucherController,
                      enabled: !_isVoucherApplied,
                      decoration: InputDecoration(
                        hintText: _isVoucherApplied
                            ? "Voucher Applied"
                            : "Enter reward code...",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                        ),
                        filled: _isVoucherApplied,
                        fillColor: _isVoucherApplied
                            ? Colors.grey.shade100
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF285D66),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isVoucherApplied ? null : _applyVoucher,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE0F2F1), // Light Teal
                      foregroundColor: const Color(0xFF285D66), // Text Color
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _isVoucherApplied ? "Used" : "Use",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Pricing details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Subtotal:",
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
                Text(
                  "Rs.${widget.totalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (_isVoucherApplied)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Discount (5%):",
                      style: TextStyle(fontSize: 15, color: Colors.green),
                    ),
                    Text(
                      "-Rs.${_discountAmount.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Order total:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "Rs.${finalPayableAmount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF285D66),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentMethodScreen(
                  cartItems: widget.cartItems,
                  totalAmount: finalPayableAmount,
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF285D66),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              "Go to Payment",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Serif',
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title, VoidCallback onEdit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Serif',
          ),
        ),
        TextButton(
          onPressed: onEdit,
          style: TextButton.styleFrom(
            backgroundColor: Colors.teal.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            "Edit",
            style: TextStyle(color: Color(0xFF285D66), fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem({
    required String name,
    required String brand,
    required String price,
    required String qty,
    required String imageUrl,
  }) {
    bool isNetwork = imageUrl.toString().startsWith('http');
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
            ),
            child: isNetwork
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, o, s) => const Icon(Icons.error),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  brand,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  price,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF285D66),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Text(
            qty,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF285D66),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
