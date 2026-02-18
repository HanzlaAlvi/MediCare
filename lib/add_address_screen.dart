import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddAddressScreen extends StatefulWidget {
  final String? docId; // Edit ke liye document ID
  final Map<String, dynamic>? existingData; // Pehle se majood data

  // Constructor ko parameters ke sath define kiya gaya hai
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

  @override
  void initState() {
    super.initState();
    // Agar Edit mode hai (existingData null nahi hai), toh data fields mein bhar dein
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and Street are required")),
      );
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
        // Naya address save karein
        await addressRef.add(data);
      } else {
        // Purana address update karein
        await addressRef.doc(widget.docId).update(data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.docId == null ? "Address saved!" : "Address updated!",
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
        title: Text(
          widget.docId == null ? "Add Address" : "Edit Address",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: _isSaving
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF285D66)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInputField("Full Name", _nameController),
                  const SizedBox(height: 15),
                  _buildInputField("Email", _emailController),
                  const SizedBox(height: 15),
                  _buildInputField("Country", _countryController),
                  const SizedBox(height: 15),
                  _buildInputField("City", _cityController),
                  const SizedBox(height: 15),
                  _buildInputField("Street", _streetController),
                  const SizedBox(height: 15),
                  _buildInputField("Description", _descController, maxLines: 3),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _processAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF285D66),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        widget.docId == null
                            ? "Save Address"
                            : "Update Address",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
          ),
        ),
      ],
    );
  }
}
