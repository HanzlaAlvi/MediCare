import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'upload_prescription_screen.dart';
import 'cart_screen.dart'; // Import Cart Screen for ordering

class PrescriptionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const PrescriptionDetailScreen({super.key, required this.data});

  // --- PDF GENERATOR ---
  Future<void> _generatePDF(BuildContext context) async {
    final pdf = pw.Document();

    // Extract medicines for PDF
    List medicines = data['extractedMedicines'] ?? [];

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text("Prescription Report")),
              pw.SizedBox(height: 20),
              pw.Text("ID: ${data['id']}"),
              pw.Text("Date: ${data['date']}"),
              pw.Divider(),
              pw.Text(
                "Status: ${data['status']}",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: data['status'] == 'Approved'
                      ? PdfColors.green
                      : PdfColors.red,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text("Doctor: ${data['doctor']}"),
              pw.SizedBox(height: 20),

              // Medicines List in PDF
              if (medicines.isNotEmpty) ...[
                pw.Text(
                  "Medicines Identified:",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                ...medicines.map(
                  (m) => pw.Bullet(
                    text:
                        "${m['name']} (${m['isAvailable'] ? 'Available' : 'Out of Stock'})",
                  ),
                ),
                pw.SizedBox(height: 20),
              ],

              pw.Text(
                "Pharmacist Comment:",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(data['comment']),
              pw.SizedBox(height: 20),
              pw.Text("Notes: ${data['note']}"),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status'];
    Color statusColor = Colors.orange;
    Color boxColor = Colors.orange.shade50;
    Color textColor = Colors.orange.shade800;

    if (status == 'Approved') {
      statusColor = Colors.green;
      boxColor = Colors.green.shade50;
      textColor = Colors.green.shade800;
    } else if (status == 'Rejected') {
      statusColor = Colors.redAccent;
      boxColor = Colors.red.shade50;
      textColor = Colors.red.shade800;
    }

    // --- CHECK MEDICINES ---
    List extractedMedicines = data['extractedMedicines'] ?? [];
    bool hasMedicines = extractedMedicines.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "My Prescription",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => const UploadPrescriptionScreen(),
              ),
            ),
            icon: const Icon(Icons.add, size: 30),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image Section
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.shade200),
              child: data['localPath'] != null
                  ? Image.file(
                      File(data['localPath']),
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(Icons.image),
                    )
                  : Image.network(
                      data['imageUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(Icons.image),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data['id'] ?? 'ID-123',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "Uploaded ${data['date']}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Download Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => _generatePDF(context),
                      icon: const Icon(
                        Icons.download,
                        color: Color(0xFF285D66),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        side: const BorderSide(color: Color(0xFF285D66)),
                      ),
                      label: const Text(
                        "Download PDF",
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF285D66),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Details
                  _buildDetailRow("Doctor's Name", data['doctor']),
                  _buildDetailRow("Status", status, color: statusColor),
                  _buildDetailRow("Note", data['note']),
                  const SizedBox(height: 20),

                  // --- NEW: DISPLAY EXTRACTED MEDICINES ---
                  if (hasMedicines) ...[
                    const Text(
                      "Identified Medicines:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: extractedMedicines.map<Widget>((med) {
                          bool isAvail = med['isAvailable'] ?? false;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  isAvail ? Icons.check_circle : Icons.cancel,
                                  color: isAvail ? Colors.green : Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    med['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  isAvail ? "In Stock" : "Unavailable",
                                  style: TextStyle(
                                    color: isAvail ? Colors.green : Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Comment Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: boxColor,
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status == 'Pending'
                              ? "Under Review"
                              : "Doctor's Comment (AI)",
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          data['comment'],
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- CONDITIONAL BUTTON: ONLY SHOW IF MEDICINES EXIST ---
                  if (status == 'Approved' && hasMedicines)
                    _buildActionButton(
                      "Order Medicines",
                      const Color(0xFF285D66),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (c) => const CartScreen()),
                        );
                      },
                    ),

                  if (status == 'Rejected') ...[
                    _buildActionButton(
                      "Upload New Prescription",
                      const Color(0xFF285D66),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const UploadPrescriptionScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                  ],

                  if (status != 'Approved')
                    _buildOutlinedButton("Contact Support", () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          side: const BorderSide(color: Colors.grey),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF285D66),
          ),
        ),
      ),
    );
  }
}
