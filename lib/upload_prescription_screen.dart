import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'prescription_detail_screen.dart';

class UploadPrescriptionScreen extends StatefulWidget {
  const UploadPrescriptionScreen({super.key});

  @override
  State<UploadPrescriptionScreen> createState() =>
      _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _doctorController = TextEditingController();

  // Replace with your valid API Key
  final String _apiKey = 'AIzaSyCWacvI3ZFJwt_YdPcHZijAI33jmU9LAP8';

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF285D66)),
              title: const Text('Pick from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF285D66)),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW: CHECK DB AVAILABILITY ---
  Future<List<Map<String, dynamic>>> _checkMedicineAvailability(List<String> medNames) async {
    List<Map<String, dynamic>> results = [];
    final db = FirebaseFirestore.instance;

    for (String medName in medNames) {
      String cleanName = medName.trim();
      if (cleanName.isEmpty) continue;

      // Check Database (Assumes 'name' field exists in 'medicines')
      // Note: This is case-sensitive. Ideally, store lowercase names in DB for searching.
      final querySnapshot = await db
          .collection('medicines')
          .where('name', isEqualTo: cleanName) 
          .limit(1)
          .get();

      bool isAvailable = false;
      if (querySnapshot.docs.isNotEmpty) {
        int stock = querySnapshot.docs.first['stock'] ?? 0;
        if (stock > 0) isAvailable = true;
      }

      results.add({
        'name': cleanName,
        'isAvailable': isAvailable,
      });
    }
    return results;
  }

  Future<void> _submitPrescription() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload a prescription image first!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // --- 1. GEMINI AI ANALYSIS ---
      final model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: _apiKey,
      );
      final imageBytes = await _selectedImage!.readAsBytes();

      // Updated Prompt to extract Medicines List
      final prompt = TextPart(
        "Act as a strict Senior Doctor. Analyze this image.\n"
        "1. STATUS: Check if it's a valid prescription. Set 'Approved' or 'Rejected'.\n"
        "2. DOCTOR: Extract Doctor Name.\n"
        "3. MEDICINES: Extract list of medicine names ONLY (comma separated).\n"
        "4. COMMENT: Write a short summary.\n\n"
        "Output format: Status: [Value] | Doctor: [Name] | Medicines: [Med1, Med2, Med3] | Comment: [Text] and proper medicines name enlist them",
        
      );

      final content = [
        Content.multi([prompt, DataPart('image/jpeg', imageBytes)]),
      ];
      final response = await model.generateContent(content);

      // --- 2. PARSING RESPONSE ---
      String status = "Pending";
      String doctor = "Unknown Doctor";
      String comment = "Uploaded for review.";
      List<String> extractedMeds = [];

      if (response.text != null) {
        final text = response.text!;
        final parts = text.split("|");

        for (var part in parts) {
          part = part.trim();
          if (part.startsWith("Status:")) {
            status = part.replaceAll("Status:", "").trim();
          } else if (part.startsWith("Doctor:")) {
            doctor = part.replaceAll("Doctor:", "").trim();
          } else if (part.startsWith("Medicines:")) {
            // Extract CSV list
            String medString = part.replaceAll("Medicines:", "").trim();
            // Remove brackets if Gemini adds them [ ]
            medString = medString.replaceAll('[', '').replaceAll(']', ''); 
            extractedMeds = medString.split(',').map((e) => e.trim()).toList();
          } else if (part.startsWith("Comment:")) {
            comment = part.replaceAll("Comment:", "").trim();
          }
        }
      }

      if (_doctorController.text.isNotEmpty) {
        doctor = _doctorController.text;
      }

      // --- 3. CHECK AVAILABILITY IN FIRESTORE ---
      List<Map<String, dynamic>> finalMedicineData = await _checkMedicineAvailability(extractedMeds);

      // Append availability info to comment for better UX
      int availableCount = finalMedicineData.where((m) => m['isAvailable'] == true).length;
      comment += "\n\nFound ${extractedMeds.length} medicines. $availableCount are available in stock.";

      // --- 4. SAVE TO FIREBASE ---
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('prescriptions')
            .doc();

        final prescriptionData = {
          'id': docRef.id,
          'status': status,
          'doctor': doctor,
          'comment': comment,
          'extractedMedicines': finalMedicineData, // Saving detailed list
          'note': _notesController.text,
          'date': "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
          'timestamp': FieldValue.serverTimestamp(),
          'localPath': _selectedImage!.path,
          'imageUrl': 'https://via.placeholder.com/400?text=Prescription',
        };

        await docRef.set(prescriptionData);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PrescriptionDetailScreen(data: prescriptionData),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        title: const Text("Upload Prescription", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.grey.shade50,
                  image: _selectedImage != null
                      ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                      : null,
                ),
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.upload_file, size: 50, color: Color(0xFF285D66)),
                          SizedBox(height: 10),
                          Text("Upload prescription image", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("Supported formats: JPG, PNG", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 25),
            const Text("Doctor's Name", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            TextField(
              controller: _doctorController,
              decoration: InputDecoration(
                hintText: "Optional (AI will detect)",
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Additional Notes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Add any Description...",
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                border: Border.all(color: const Color(0xFFB2DFDB)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Important Guidelines", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00695C))),
                  SizedBox(height: 10),
                  _GuidelineItem(text: "Ensure prescription is clearly visible"),
                  _GuidelineItem(text: "All doctor details must be visible"),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPrescription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF285D66),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Prescription", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidelineItem extends StatelessWidget {
  final String text;
  const _GuidelineItem({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF004D40)))),
        ],
      ),
    );
  }
}