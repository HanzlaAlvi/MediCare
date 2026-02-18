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
  bool isEditMode = false;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  // --- FIXED PRICE PARSER ---
  double parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is num) return price.toDouble();

    String p = price.toString().toLowerCase();

    // 1. Pehle "rs." ya "rs" ko specifically remove karein
    p = p.replaceAll('rs.', '').replaceAll('rs', '').replaceAll('pkr', '');

    // 2. Ab baqi kachra (spaces waghera) saaf karein, sirf numbers aur dot chorein
    p = p.replaceAll(RegExp(r'[^0-9.]'), '');

    return double.tryParse(p) ?? 0.0;
  }

  int parseQty(dynamic qty) {
    if (qty == null) return 1;
    if (qty is int) return qty;
    if (qty is double) return qty.toInt();
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
          "My Cart",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => isEditMode = !isEditMode),
            child: Text(
              isEditMode ? "Done" : "Edit",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('cart')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Cart is Empty"));
          }

          final cartDocs = snapshot.data!.docs;

          double subtotal = 0.0;

          for (var doc in cartDocs) {
            var data = doc.data() as Map<String, dynamic>;

            double price = parsePrice(data['price']);
            int qty = parseQty(data['qty']);

            // Ab ye console mein sahi 780 print karega
            debugPrint(
              "Item: ${data['name']} | Cleaned Price: $price | Qty: $qty | Total: ${price * qty}",
            );

            subtotal += (price * qty);
          }

          double salesTax = 200.0;
          double orderTotal = subtotal + salesTax;

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: cartDocs.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 30, color: Colors.transparent),
                  itemBuilder: (context, index) {
                    var data = cartDocs[index].data() as Map<String, dynamic>;
                    return _buildCartItem(data, cartDocs[index].id);
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      "Item(s) total:",
                      "Rs.${subtotal.toStringAsFixed(0)}",
                    ),

                    _buildSummaryRow(
                      "Subtotal:",
                      "Rs.${subtotal.toStringAsFixed(0)}",
                    ),

                    const SizedBox(height: 5),
                    const Divider(),
                    const SizedBox(height: 5),

                    _buildSummaryRow(
                      "Shipping:",
                      "FREE",
                      valueColor: Colors.green,
                    ),

                    _buildSummaryRow(
                      "Sales tax:",
                      "Rs.${salesTax.toStringAsFixed(0)}",
                    ),

                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 10),

                    _buildSummaryRow(
                      "Order total:",
                      "Rs.${orderTotal.toStringAsFixed(0)}",
                      isTotal: true,
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          List<Map<String, dynamic>> items = cartDocs
                              .map((e) => e.data() as Map<String, dynamic>)
                              .toList();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckOutScreen(
                                cartItems: items,
                                totalAmount: orderTotal,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF285D66),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          "Checkout",
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
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, String docId) {
    bool isNetwork = item['image'].toString().startsWith('http');

    int qty = parseQty(item['qty']);
    double unitPrice = parsePrice(item['price']);

    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: isNetwork
              ? Image.network(item['image'], fit: BoxFit.cover)
              : Image.asset(
                  item['image'],
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
                item['name'] ?? 'Product',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item['brand'] ?? '',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Rs. ${unitPrice.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: Color(0xFF285D66),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (!isEditMode)
                    Row(
                      children: [
                        _buildQtyBtn(
                          Icons.remove,
                          () => _updateQuantity(docId, qty, -1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "$qty",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildQtyBtn(
                          Icons.add,
                          () => _updateQuantity(docId, qty, 1),
                          isAdd: true,
                        ),
                      ],
                    )
                  else
                    InkWell(
                      onTap: () => _removeItem(docId),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, {bool isAdd = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isAdd ? const Color(0xFF285D66) : Colors.white,
          border: Border.all(color: const Color(0xFF285D66)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isAdd ? Colors.white : const Color(0xFF285D66),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 15,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 15,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
