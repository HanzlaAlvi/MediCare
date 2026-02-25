import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // 📦 Storage import
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart'; // 📦 Image Picker import
import 'dart:io';
import 'dart:math';

class AddEditMedicineScreen extends StatefulWidget {
  final Map<String, dynamic>? medicineData;
  final String? docId;

  const AddEditMedicineScreen({super.key, this.medicineData, this.docId});

  @override
  State<AddEditMedicineScreen> createState() => _AddEditMedicineScreenState();
}

class _AddEditMedicineScreenState extends State<AddEditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nameC = TextEditingController();
  final brandC = TextEditingController();
  final priceC = TextEditingController();
  final stockC = TextEditingController();
  final descriptionC = TextEditingController();
  final ingredientsC = TextEditingController();
  final safetyC = TextEditingController();
  final sideEffectsC = TextEditingController();
  final mfgDateC = TextEditingController();
  final expiryDateC = TextEditingController();
  final imageUrlC = TextEditingController();

  String selectedCategory = 'Tablets';
  final List<String> categories = [
    'Tablets',
    'Syrup',
    'Painkiller',
    'Vitamins',
  ];

  File? _pickedImage; // Local file holder
  bool _isEditing = false;
  bool _isLoading = false;
  bool _useUrl = true;

  @override
  void initState() {
    super.initState();
    if (widget.medicineData != null) {
      _isEditing = true;
      final d = widget.medicineData!;
      nameC.text = d['name'] ?? '';
      brandC.text = d['brand'] ?? '';
      selectedCategory = d['category'] ?? 'Tablets';
      priceC.text = d['price']?.toString().replaceAll("Rs. ", "") ?? '';
      stockC.text = d['stock']?.toString() ?? '0';
      descriptionC.text = d['description'] ?? '';
      ingredientsC.text = d['ingredients'] ?? '';
      safetyC.text = d['safetyAdvice'] ?? '';
      sideEffectsC.text = d['sideEffects'] ?? '';
      mfgDateC.text = d['mfgDate'] ?? '';
      expiryDateC.text = d['expiryDate'] ?? '';
      imageUrlC.text = (d['images'] as List?)?.first ?? '';
    }
  }

  // --- 📸 IMAGE PICKER LOGIC ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
        _useUrl = false;
        imageUrlC.text = "Local Image Selected"; // Placeholder text
      });
    }
  }

  // --- ☁️ FIREBASE STORAGE UPLOAD ---
  Future<String?> _uploadToStorage() async {
    if (_pickedImage == null) return imageUrlC.text.trim();

    try {
      String fileName =
          'medicines/${DateTime.now().millisecondsSinceEpoch}.png';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(_pickedImage!);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      Get.snackbar("Upload Error", "Failed to upload image to storage.");
      return null;
    }
  }

  // --- 📅 DATE PICKER ---
  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF285D66)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }

  String _getRandomPastelColor() {
    List<String> pastelColors = [
      "0xFFE0F2F1",
      "0xFFF3E5F5",
      "0xFFFFF9C4",
      "0xFFE1F5FE",
      "0xFFFBE9E7",
      "0xFFF1F8E9",
    ];
    return pastelColors[Random().nextInt(pastelColors.length)];
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Pehle image upload hogi (agar new select ki hai)
    String? finalImageUrl = await _uploadToStorage();

    if (finalImageUrl == null || finalImageUrl.isEmpty) {
      setState(() => _isLoading = false);
      Get.snackbar(
        "Image Required",
        "Please provide a URL or upload an image.",
      );
      return;
    }

    final Map<String, dynamic> data = {
      'name': nameC.text.trim(),
      'brand': brandC.text.trim(),
      'category': selectedCategory,
      'price': "Rs. ${priceC.text.trim()}",
      'stock': int.tryParse(stockC.text.trim()) ?? 0,
      'description': descriptionC.text.trim(),
      'ingredients': ingredientsC.text.trim(),
      'safetyAdvice': safetyC.text.trim(),
      'sideEffects': sideEffectsC.text.trim(),
      'mfgDate': mfgDateC.text.trim(),
      'expiryDate': expiryDateC.text.trim(),
      'color': _isEditing
          ? widget.medicineData!['color']
          : _getRandomPastelColor(),
      'rating': _isEditing ? widget.medicineData!['rating'] : "5.0",
      'images': [finalImageUrl],
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      if (_isEditing) {
        await FirebaseFirestore.instance
            .collection('medicines')
            .doc(widget.docId)
            .update(data);
      } else {
        await FirebaseFirestore.instance.collection('medicines').add(data);
      }
      Get.back();
      Get.snackbar(
        "Success",
        "Inventory Updated",
        backgroundColor: Colors.white,
        colorText: const Color(0xFF285D66),
      );
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        title: Text(
          _isEditing ? "Edit Medicine" : "Add Medicine",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF285D66)),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildImageUploadSection(),
                    const SizedBox(height: 20),
                    _buildCard("Product Information", [
                      _buildTextField(nameC, "Medicine Name"),
                      _buildTextField(brandC, "Brand (GSK, Pfizer, etc.)"),
                      _buildDropdown(),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              priceC,
                              "Price",
                              isNum: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              stockC,
                              "Stock Qty",
                              isNum: true,
                            ),
                          ),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildCard("Medical Details", [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(mfgDateC, "Mfg. Date"),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDateField(expiryDateC, "Expiry Date"),
                          ),
                        ],
                      ),
                      _buildTextField(ingredientsC, "Ingredients"),
                      _buildTextField(descriptionC, "Description", maxLines: 3),
                      _buildTextField(safetyC, "Safety Advice"),
                      _buildTextField(sideEffectsC, "Side Effects"),
                    ]),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _saveMedicine,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF285D66),
                        minimumSize: const Size(double.infinity, 58),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isEditing ? "UPDATE MEDICINE" : "POST TO STORE",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _choiceButton(
                "Network URL",
                _useUrl,
                () => setState(() => _useUrl = true),
              ),
              const SizedBox(width: 10),
              _choiceButton(
                "Upload Photo",
                !_useUrl,
                () => setState(() => _useUrl = false),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _useUrl
              ? _buildTextField(imageUrlC, "Paste Image URL")
              : GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF285D66).withValues(alpha: 0.2),
                      ),
                      image: _pickedImage != null
                          ? DecorationImage(
                              image: FileImage(_pickedImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _pickedImage == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: Color(0xFF285D66),
                                size: 30,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Tap to Select from Gallery",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _choiceButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF285D66) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF285D66)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF285D66),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF285D66),
            ),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNum = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (v) => v!.isEmpty ? "Required" : null,
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectDate(context, controller),
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(
            Icons.calendar_month,
            color: Color(0xFF285D66),
            size: 18,
          ),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (v) => v!.isEmpty ? "Select" : null,
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: selectedCategory,
        decoration: InputDecoration(
          labelText: "Category",
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        items: categories
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => setState(() => selectedCategory = v!),
      ),
    );
  }
}
