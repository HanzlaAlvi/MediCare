import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final Color themeColor = const Color(0xFF285D66);

  // Selection track karne ke liye Set
  Set<String> selectedDocIds = {};
  bool isFirstLoad = true;

  double parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is num) return price.toDouble();
    String p = price.toString().toLowerCase();
    p = p.replaceAll('rs.', '').replaceAll('rs', '').replaceAll('pkr', '');
    p = p.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(p) ?? 0.0;
  }

  int parseQty(dynamic qty) {
    if (qty == null) return 1;
    if (qty is int) return qty;
    return int.tryParse(qty.toString()) ?? 1;
  }

  void _updateQuantity(String docId, int currentQty, int change) {
    int newQty = currentQty + change;
    if (newQty > 0) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(docId)
          .update({'qty': newQty});
    }
  }

  void _removeItem(String docId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(docId)
        .delete();
    setState(() {
      selectedDocIds.remove(docId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Shopping Cart",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('cart')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: themeColor));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final cartDocs = snapshot.data!.docs;

          // Logic: First load par sab items ko select karlo
          if (isFirstLoad) {
            for (var doc in cartDocs) {
              selectedDocIds.add(doc.id);
            }
            isFirstLoad = false;
          }

          double subtotal = 0.0;
          List<Map<String, dynamic>> selectedItems = [];

          for (var doc in cartDocs) {
            var data = doc.data() as Map<String, dynamic>;
            if (selectedDocIds.contains(doc.id)) {
              subtotal += (parsePrice(data['price']) * parseQty(data['qty']));
              selectedItems.add(data);
            }
          }

          double salesTax = subtotal > 0 ? 200.0 : 0.0;
          double orderTotal = subtotal + salesTax;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: cartDocs.length,
                  itemBuilder: (context, index) {
                    var data = cartDocs[index].data() as Map<String, dynamic>;
                    String docId = cartDocs[index].id;
                    return _buildCartCard(data, docId);
                  },
                ),
              ),
              _buildBottomSection(
                subtotal,
                salesTax,
                orderTotal,
                selectedItems,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartCard(Map<String, dynamic> item, String docId) {
    int qty = parseQty(item['qty']);
    double unitPrice = parsePrice(item['price']);
    String imagePath = item['image'].toString();
    bool isSelected = selectedDocIds.contains(docId);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Selection Checkbox
          Checkbox(
            activeColor: themeColor,
            value: isSelected,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  selectedDocIds.add(docId);
                } else {
                  selectedDocIds.remove(docId);
                }
              });
            },
          ),

          // 2. Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imagePath.startsWith('http')
                  ? Image.network(imagePath, fit: BoxFit.contain)
                  : Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (c, o, s) => Icon(
                        Icons.medication,
                        color: themeColor.withValues(alpha: 0.5),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // 3. Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['name'] ?? 'Product',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 4. Delete Icon (Top Right of Info Section)
                    GestureDetector(
                      onTap: () => _removeItem(docId),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                Text(
                  item['brand'] ?? '',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 12),
                // 5. Horizontal Row for Price and Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Rs. ${unitPrice.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: themeColor,
                      ),
                    ),
                    // Horizontal Counter
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          _qtyBtn(
                            Icons.remove,
                            () => _updateQuantity(docId, qty, -1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "$qty",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _qtyBtn(
                            Icons.add,
                            () => _updateQuantity(docId, qty, 1),
                            isAdd: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, {bool isAdd = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isAdd ? themeColor : Colors.transparent,
        ),
        child: Icon(icon, size: 16, color: isAdd ? Colors.white : themeColor),
      ),
    );
  }

  Widget _buildBottomSection(
    double sub,
    double tax,
    double total,
    List<Map<String, dynamic>> selectedItems,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
      ),
      child: Column(
        children: [
          _summaryRow(
            "Selected Items Subtotal",
            "Rs. ${sub.toStringAsFixed(0)}",
          ),
          _summaryRow("Sales Tax", "Rs. ${tax.toStringAsFixed(0)}"),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Amount",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "Rs. ${total.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: themeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: selectedItems.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => CheckOutScreen(
                            cartItems: selectedItems,
                            totalAmount: total,
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: Text(
                selectedItems.isEmpty
                    ? "Select items"
                    : "Checkout (${selectedItems.length})",
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
    );
  }

  Widget _summaryRow(String title, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: themeColor.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 15),
          const Text(
            "Cart is empty",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
