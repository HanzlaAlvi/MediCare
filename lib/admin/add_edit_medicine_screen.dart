import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // Base64 encoding/decoding ke liye zaroori hai
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
    'Drops',
  ];

  File? _pickedImage;
  String _base64Image = ""; // 🛡️ Base64 string save karne ke liye
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

      // 🛡️ SMART IMAGE LOADER FOR EDIT SCREEN (CRASH PROOF)
      if (d['images'] != null && (d['images'] as List).isNotEmpty) {
        String existingImage = d['images'][0].toString().trim(); // Clean spaces

        if (existingImage.startsWith('http') || existingImage.contains('assets/')) {
          imageUrlC.text = existingImage;
          _useUrl = true;
        } else {
          // Agar Base64 hai toh usko securely load karein
          String cleanBase64 = existingImage;
          if (cleanBase64.contains(',')) {
            cleanBase64 = cleanBase64.split(',').last;
          }
          cleanBase64 = cleanBase64.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
          
          if (cleanBase64.length % 4 != 0) {
            cleanBase64 += '=' * (4 - (cleanBase64.length % 4));
          }

          _base64Image = cleanBase64;
          _useUrl = false;
        }
      }
    }
  }

  // --- 📸 IMAGE PICKER LOGIC (Convert to Base64) ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Image quality 50% ki hai taake size chota rahay
    );

    if (image != null) {
      File imgFile = File(image.path);
      List<int> imageBytes = await imgFile.readAsBytes();
      String base64String = base64Encode(imageBytes);

      setState(() {
        _pickedImage = imgFile;
        _base64Image = base64String;
        _useUrl = false;
        imageUrlC.text = "Image Selected from Gallery";
      });
    }
  }

  // --- 📂 SAVE TO MEDICINES COLLECTION ---
  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if any image is selected
    if (_useUrl && imageUrlC.text.trim().isEmpty) {
      Get.snackbar(
        "Error",
        "Please provide an image URL/Asset or select a photo.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }
    if (!_useUrl && _base64Image.isEmpty) {
      Get.snackbar(
        "Error",
        "Please select a photo from gallery.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    // Final Image decide karo (URL ya Base64)
    String finalImageUrl = _useUrl ? imageUrlC.text.trim() : _base64Image;

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
      'images': [finalImageUrl], 
      'timestamp': FieldValue.serverTimestamp(),
      'color': _isEditing
          ? (widget.medicineData?['color'] ?? _getRandomPastelColor())
          : _getRandomPastelColor(),
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
        "Medicine saved successfully!",
        backgroundColor: const Color(0xFF285D66),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Firestore error: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
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

  // 🛡️ SAFE IMAGE PROVIDER LOGIC
  ImageProvider? _getPreviewImage() {
    if (_pickedImage != null) {
      return FileImage(_pickedImage!);
    }
    if (_base64Image.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(_base64Image));
      } catch (e) {
        return null;
      }
    }
    return null;
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
    ImageProvider? previewImage = _getPreviewImage();

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
                "URL / Asset",
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
              ? _buildTextField(imageUrlC, "Paste Image URL or Asset Path")
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
                      image: previewImage != null
                          ? DecorationImage(
                              image: previewImage,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: previewImage == null
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