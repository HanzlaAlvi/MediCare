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

  Map<String, dynamic>? _selectedAddress;

  // --- NEW: Inline Feedback Variables ---
  String? _voucherFeedbackMessage;
  bool _isVoucherError = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _selectedAddress = snapshot.docs.first.data();
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading address: $e");
    }
  }

  // --- UPDATED LOGIC: Inline Feedback (No Snackbar) ---
  Future<void> _applyVoucher() async {
    // Reset status
    setState(() {
      _voucherFeedbackMessage = null;
      _isVoucherError = false;
    });

    String enteredCode = _voucherController.text.trim();
    if (enteredCode.isEmpty) {
      setState(() {
        _voucherFeedbackMessage = "Please enter a code";
        _isVoucherError = true;
      });
      return;
    }

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      final doc = await userRef.get();

      if (doc.exists) {
        String myActualCode = doc.data()?['referralCode'] ?? "";
        int currentPoints = doc.data()?['points'] ?? 0;

        // Check 1: Code Match
        if (enteredCode != myActualCode) {
          setState(() {
            _voucherFeedbackMessage = "Invalid Reward Code";
            _isVoucherError = true;
          });
          return;
        }

        // Check 2: Points Balance
        if (currentPoints < 100) {
          setState(() {
            _voucherFeedbackMessage = "Insufficient points (Min 100 needed)";
            _isVoucherError = true;
          });
          return;
        }

        // Apply
        await userRef.update({'points': currentPoints - 100});
        await userRef.collection('point_history').add({
          'title': "Voucher Discount Applied",
          'points': "-100",
          'type': 'debit',
          'date': DateTime.now(),
        });

        setState(() {
          _discountAmount = widget.totalAmount * 0.05;
          _isVoucherApplied = true;
          _voucherFeedbackMessage = "Success! 5% Discount Applied";
          _isVoucherError = false;
        });
      }
    } catch (e) {
      setState(() {
        _voucherFeedbackMessage = "Error: Something went wrong";
        _isVoucherError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double finalPayableAmount = widget.totalAmount - _discountAmount;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Checkout",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Address ---
            _buildSectionHeader(
              "Shipping Address",
              "Change",
              _showAddressSelectionDialog,
            ),
            const SizedBox(height: 10),
            _buildAddressCard(),

            const SizedBox(height: 25),

            // --- 2. Order Items ---
            const Text(
              "Order Items",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: _cardDecoration(),
              child: Column(
                children: widget.cartItems
                    .map((item) => _buildOrderItem(item))
                    .toList(),
              ),
            ),

            const SizedBox(height: 25),

            // --- 3. Payment Details Card (Voucher + Summary) ---
            const Text(
              "Payment Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  // Voucher Input Area
                  _buildVoucherRow(),

                  // Feedback Text (Inline)
                  if (_voucherFeedbackMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 5),
                      child: Row(
                        children: [
                          Icon(
                            _isVoucherError
                                ? Icons.error_outline
                                : Icons.check_circle,
                            size: 16,
                            color: _isVoucherError ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _voucherFeedbackMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isVoucherError
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),

                  // Pricing Breakdown
                  _buildPriceRow("Subtotal", widget.totalAmount),
                  const SizedBox(height: 10),
                  _buildPriceRow("Delivery Fee", 0, isFree: true),

                  // Discount Row (Only if applied)
                  if (_isVoucherApplied) ...[
                    const SizedBox(height: 10),
                    _buildPriceRow(
                      "Discount (5%)",
                      -_discountAmount,
                      isDiscount: true,
                    ),
                  ],

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Divider(thickness: 1.2),
                  ),

                  // Total Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Rs. ${finalPayableAmount.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF285D66),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(finalPayableAmount),
    );
  }

  // --- WIDGET HELPER METHODS ---

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    String actionLabel,
    VoidCallback onTap,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: Color(0xFF285D66),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard() {
    if (_selectedAddress == null) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAddressScreen()),
          ).then((_) => _loadDefaultAddress());
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade300,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.add_location_alt_outlined,
                size: 40,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 10),
              Text(
                "Add Shipping Address",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on, color: Color(0xFF285D66)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedAddress!['fullName'] ?? 'Name',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedAddress!['email'] ?? 'Email',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  "${_selectedAddress!['street']}, ${_selectedAddress!['city']}",
                  style: const TextStyle(height: 1.4, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                item['image'],
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) =>
                    const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Rs. ${item['price']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF285D66),
                  ),
                ),
              ],
            ),
          ),
          Text(
            "x${item['qty']}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherRow() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 45,
            child: TextField(
              controller: _voucherController,
              enabled: !_isVoucherApplied,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Enter Reward Code",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                filled: true,
                fillColor: _isVoucherApplied
                    ? Colors.grey.shade100
                    : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.confirmation_number_outlined,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 45,
          child: ElevatedButton(
            onPressed: _isVoucherApplied ? null : _applyVoucher,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF285D66),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: Text(_isVoucherApplied ? "Applied" : "Apply"),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isDiscount = false,
    bool isFree = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDiscount ? Colors.green : Colors.grey.shade600,
            fontSize: 15,
          ),
        ),
        Text(
          isFree
              ? "Free"
              : (isDiscount ? "-" : "") +
                    "Rs. ${amount.abs().toStringAsFixed(0)}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDiscount || isFree ? Colors.green : Colors.black,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(double finalAmount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              if (_selectedAddress == null) {
                // Show clean error on button press if address missing
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please select a delivery address"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentMethodScreen(
                    cartItems: widget.cartItems,
                    totalAmount: finalAmount,
                    selectedAddress: _selectedAddress!,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF285D66),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              "Continue to Payment",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- ADDRESS SELECTION SHEET ---
  void _showAddressSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true, // For better height control
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Select Address",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddAddressScreen(),
                        ),
                      ).then((_) => _loadDefaultAddress());
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      "Add New",
                      style: TextStyle(color: Color(0xFF285D66)),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('addresses')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("No addresses found. Add one!"),
                      );
                    }

                    var docs = snapshot.data!.docs;
                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        bool isSelected =
                            _selectedAddress != null &&
                            _selectedAddress!['street'] == data['street'];

                        return InkWell(
                          onTap: () {
                            setState(() => _selectedAddress = data);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE0F2F1)
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF285D66)
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: const Color(0xFF285D66),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['fullName'] ?? 'Name',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "${data['street']}, ${data['city']}",
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
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
              ),
            ],
          ),
        );
      },
    );
  }
}
