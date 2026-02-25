import 'dart:convert'; // Base64 conversion ke liye
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'payment_success_screen.dart';

class TransactionProofScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;
  final Map<String, dynamic> selectedAddress;
  final String paymentMethod;

  const TransactionProofScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    required this.selectedAddress,
    required this.paymentMethod,
  });

  @override
  State<TransactionProofScreen> createState() => _TransactionProofScreenState();
}

class _TransactionProofScreenState extends State<TransactionProofScreen> {
  File? _image;
  bool _isUploading = false;
  final double _maxSizeMB = 2.0;

  // --- IMAGE PICKER ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Size control karne ke liye quality thori kam ki hai
    );

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      int sizeInBytes = await file.length();
      double sizeInMB = sizeInBytes / (1024 * 1024);

      if (sizeInMB > _maxSizeMB) {
        if (mounted) {
          _showErrorDialog(
            "File too large!",
            "Selected image is ${sizeInMB.toStringAsFixed(2)}MB. Please upload an image smaller than 2MB.",
          );
        }
      } else {
        setState(() => _image = file);
      }
    }
  }

  void _showErrorDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // --- SUBMIT ORDER LOGIC ---
  Future<void> _submitOrderWithProof() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload payment screenshot")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String orderId =
          "ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";
      final firestore = FirebaseFirestore.instance;

      // 1. Convert Image to Base64
      List<int> imageBytes = await _image!.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // 2. Transaction for Stock Update and Order Creation
      await firestore.runTransaction((transaction) async {
        // A. Stock Update Karein
        for (var item in widget.cartItems) {
          String itemName = item['name'];
          int qtyOrdered = item['qty'] ?? 1;

          QuerySnapshot medSearch = await firestore
              .collection('medicines')
              .where('name', isEqualTo: itemName)
              .limit(1)
              .get();

          if (medSearch.docs.isNotEmpty) {
            DocumentReference medRef = medSearch.docs.first.reference;
            DocumentSnapshot medDoc = await transaction.get(medRef);

            if (medDoc.exists) {
              int currentStock = int.tryParse(medDoc['stock'].toString()) ?? 0;
              transaction.update(medRef, {
                'stock': (currentStock - qtyOrdered).clamp(0, 999),
              });
            }
          }
        }

        // B. Order Document Create Karein
        DocumentReference orderRef = firestore
            .collection('orders')
            .doc(orderId);
        transaction.set(orderRef, {
          'orderId': orderId,
          'userId': userId,
          'items': widget.cartItems,
          'totalAmount': widget.totalAmount,
          'status': 'Pending Approval',
          'paymentMethod': widget.paymentMethod,
          'paymentScreenshot': base64Image, // DB mein photo save ho rhi hai
          'hasProof': true,
          'addressDetails': widget.selectedAddress,
          'deliveryAddress':
              "${widget.selectedAddress['street']}, ${widget.selectedAddress['city']}",
          'timestamp': FieldValue.serverTimestamp(),
          'date':
              "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
        });
      });

      // 3. Cart Khali Karein
      var cartSnaps = await firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();
      for (var doc in cartSnaps.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PaymentSuccessScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      _showErrorDialog("Error", e.toString());
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Upload Proof",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 50,
              color: Color(0xFF285D66),
            ),
            const SizedBox(height: 15),
            const Text(
              "Almost Done!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Please upload a screenshot of your payment transaction to confirm your order.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Image Upload Box
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF285D66).withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Select Screenshot",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "(Max 2MB)",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
              ),
            ),

            const Spacer(),

            if (_isUploading)
              const Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF285D66)),
                  SizedBox(height: 10),
                  Text(
                    "Uploading Proof...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submitOrderWithProof,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF285D66),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Submit Proof & Place Order",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
