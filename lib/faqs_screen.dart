import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        title: const Text(
          "FAQ's",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.edit_square),
        //     onPressed: () => Navigator.pop(context),
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactOption(
              title: "How do I upload a prescription?",
              answer:
                  "You can upload a prescription by clicking the camera icon on the signup page or through the prescription upload section in your profile.",
            ),
            const SizedBox(height: 15),

            _buildContactOption(
              title: "Do you deliver prescription medicines?",
              answer:
                  "Yes, we deliver prescription medicines provided you upload a valid prescription from a certified doctor.",
            ),
            const SizedBox(height: 15),

            _buildContactOption(
              title: "How long does delivery take?",
              answer:
                  "Standard delivery takes 24-48 hours depending on your location.",
            ),
            const SizedBox(height: 15),
            _buildContactOption(
              title: "Can I cancel my order?",
              answer:
                  "Yes, you can cancel your order within 30 minutes of placing it from the 'My Orders' section.",
            ),
            const SizedBox(height: 15),
            _buildContactOption(
              title: "What payment methods do you accept?",
              answer:
                  "We accept Credit/Debit cards, JazzCash, EasyPaisa, and Cash on Delivery.",
            ),

            GestureDetector(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                // decoration: BoxDecoration(
                //   color: Colors.grey.shade100,
                //   borderRadius: BorderRadius.circular(15),
                //   boxShadow: const [
                //     BoxShadow(
                //       color: Colors.black12,
                //       blurRadius: 3,
                //       offset: Offset(0, 2),
                //     ),
                //   ],
                // ),
                // child: Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,

                //   children: const [
                //     Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                //   ],
                // ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption({required String title, required String answer}) {
    return GestureDetector(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ExpansionTile(
          shape: Border.all(color: Colors.transparent),
          collapsedShape: Border.all(color: Colors.transparent),

          backgroundColor: Colors.grey[100],
          collapsedBackgroundColor: Colors.grey[100],
          tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          childrenPadding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
          // title: Row(
          //   children: [
          //     Container(
          //       padding: const EdgeInsets.all(5),
          //       decoration: BoxDecoration(shape: BoxShape.circle),
          // ),
          // const ExpansionTile(
          //   title: Text("How do I upload a prescription?"),
          //   children: [
          //     Padding(
          //       padding: EdgeInsets.all(16),
          //       child: Text(
          //         "You can upload a prescription by clicking the camera icon on the signup page or through the prescription upload section in your profile.",
          //       ),
          //     ),
          //   ],
          // ),
          //const SizedBox(width: 10),
          title: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          children: [
            Text(
              answer,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ),
        //const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}
