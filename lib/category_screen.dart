import 'package:flutter/material.dart';
import 'category_products_screen.dart'; 

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {'name': 'Painkiller', 'icon': Icons.medication, 'color': Colors.greenAccent},
      {'name': 'Antibiotics', 'icon': Icons.healing, 'color': Colors.orangeAccent},
      {'name': 'Vitamins', 'icon': Icons.wb_sunny, 'color': Colors.yellowAccent},
      {'name': 'FirstAids', 'icon': Icons.medical_services, 'color': Colors.redAccent},
      {'name': 'Diabetic care', 'icon': Icons.bloodtype, 'color': Colors.pinkAccent},
      {'name': 'Heart Health', 'icon': Icons.favorite, 'color': Colors.red},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF285D66),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text("Categories", style: TextStyle(fontWeight: FontWeight.bold)),
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back_ios),
        //   onPressed: () {
        //     // FIX: Added Pop functionality
        //     Navigator.pop(context); 
        //   },
        // ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              // child: TextField(
              //   decoration: InputDecoration(
              //     hintText: 'Search ...',
              //     prefixIcon: const Icon(Icons.search, color: Colors.grey),
              //     filled: true,
              //     fillColor: Colors.white,
              //     contentPadding: const EdgeInsets.symmetric(vertical: 15),
              //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              //   ),
              // ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                // Wrap in GestureDetector for Navigation
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryProductsScreen(
                          categoryName: categories[index]['name'],
                        ),
                      ),
                    );
                  },
                  child: _buildCategoryCard(categories[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF285D66),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 5))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: Icon(item['icon'], size: 40, color: item['color']),
          ),
          const SizedBox(height: 15),
          Text(
            item['name'],
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}