import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddAddressScreen extends StatefulWidget {
  final String? docId; // Edit ke liye document ID
  final Map<String, dynamic>? existingData; // Pehle se majood data

  const AddAddressScreen({super.key, this.docId, this.existingData});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  bool _isSaving = false;
  final Color themeColor = const Color(0xFF285D66);

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _nameController.text = widget.existingData!['fullName'] ?? '';
      _emailController.text = widget.existingData!['email'] ?? '';
      _countryController.text = widget.existingData!['country'] ?? '';
      _cityController.text = widget.existingData!['city'] ?? '';
      _streetController.text = widget.existingData!['street'] ?? '';
      _descController.text = widget.existingData!['description'] ?? '';
    }
  }

  Future<void> _processAddress() async {
    if (_nameController.text.isEmpty || _streetController.text.isEmpty) {
      _showCustomSnackBar("Name and Street are required", isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;
      final addressRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('addresses');

      Map<String, dynamic> data = {
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'country': _countryController.text.trim(),
        'city': _cityController.text.trim(),
        'street': _streetController.text.trim(),
        'description': _descController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (widget.docId == null) {
        await addressRef.add(data);
      } else {
        await addressRef.doc(widget.docId).update(data);
      }

      if (!mounted) return;
      _showCustomSnackBar(
        widget.docId == null ? "Address saved successfully!" : "Address updated successfully!",
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showCustomSnackBar("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showCustomSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
        elevation: 5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), 
      appBar: AppBar(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Text(
          widget.docId == null ? "Add Address" : "Edit Address",
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
      ),
      body: _isSaving
          ? Center(
              child: CircularProgressIndicator(color: themeColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_location_alt_outlined,
                      size: 50,
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Shipping Details",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Enter your delivery address carefully",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                  const SizedBox(height: 35),

                  _buildInputField("Full Name", _nameController, Icons.person_outline),
                  const SizedBox(height: 20),
                  
                  _buildInputField("Email Address", _emailController, Icons.email_outlined),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField("Country", _countryController, Icons.public),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildInputField("City", _cityController, Icons.location_city),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  _buildInputField("Street Address", _streetController, Icons.map_outlined),
                  const SizedBox(height: 20),
                  
                  _buildInputField(
                    "Delivery Instructions (Optional)", 
                    _descController, 
                    Icons.description_outlined, 
                    maxLines: 3,
                  ),
                  
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _processAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        shadowColor: themeColor.withValues(alpha: 0.5),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        widget.docId == null ? "SAVE ADDRESS" : "UPDATE ADDRESS",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // 🛡️ FIX: Height limit constraint issue solved here
  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            decoration: InputDecoration(
              // 🛡️ Icon ko prefixIcon ki bajaye directly define kiya hai taake height issue na aye
              prefixIcon: Icon(icon, color: themeColor, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              hintText: "Enter $label",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}