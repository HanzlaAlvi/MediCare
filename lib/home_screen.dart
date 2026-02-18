import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'category_screen.dart';
import 'product_details_screen.dart';
import 'order_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import 'cart_screen.dart';
import 'viewall_screen.dart';
import 'notification_service.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const HomeTab(),
    const CategoriesScreen(),
    const OrdersScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // --- START MONITORING NOTIFICATIONS ---
    NotificationService().startMonitoring();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- UPDATED DATABASE PUSH (Includes Stock for Testing) ---
  Future<void> pushMedicinesData() async {
    final CollectionReference medicines = FirebaseFirestore.instance.collection(
      'medicines',
    );

    List<Map<String, dynamic>> finalData = [
      {
        'name': 'Xinc B 100mg',
        'brand': 'PharmaPro',
        'price': 'Rs. 780',
        'rating': '4.8',
        'color': '0xFFE8EAF6',
        'category': 'Vitamins',
        'stock': 15, // Test Stock added
        'description': 'Xinc B supports immune health...',
        'mfgDate': '10-01-2024',
        'expiryDate': '10-01-2027',
        'images': ['assets/xinc-b-1.webp'],
        'ingredients': 'Zinc Sulfate (100mg)...',
        'sideEffects': 'Mild nausea...',
        'safetyAdvice': 'Take with a full meal.',
      },
    ];

    for (var med in finalData) {
      await medicines.add(med);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Data Uploaded with Stock!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF285D66),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category_outlined),
              label: 'Categories',
            ),
            
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  String searchQuery = "";
  String selectedCategory = "All";

  Future<void> _addToCart(Map<String, dynamic> product) async {
    try {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart');
      final doc = await cartRef.doc(product['name']).get();

      if (doc.exists) {
        int currentQty = doc.data()?['qty'] ?? 1;
        await cartRef.doc(product['name']).update({'qty': currentQty + 1});
      } else {
        await cartRef.doc(product['name']).set({
          'name': product['name'],
          'brand': product['brand'],
          'price': product['price'],
          'image': product['image'],
          'qty': 1,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${product['name']} added to cart!"),
            backgroundColor: const Color(0xFF285D66),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Cart Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _buildSearchBar(),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('cart')
                .snapshots(),
            builder: (context, snapshot) {
              int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Badge(
                label: Text("$count"),
                isLabelVisible: count > 0,
                backgroundColor: Colors.redAccent,
                child: IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const CartScreen()),
                  ),
                  icon: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFF285D66),
                  ),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const NotificationScreen()),
            ),
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFF285D66),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No medicines found"));
          }

          var filteredDocs = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String name = data['name'].toString().toLowerCase();
            bool matchesSearch = name.contains(searchQuery);
            String category = data['category'] ?? "All";
            bool matchesCategory =
                (selectedCategory == "All") || (category == selectedCategory);
            return matchesSearch && matchesCategory;
          }).toList();

          if (filteredDocs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No items match your search"),
              ),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBanner(),
                _buildCategoryChips(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Popular Medicines",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => const ViewAllScreen(),
                          ),
                        ),
                        child: const Text(
                          "See All",
                          style: TextStyle(color: Color(0xFF285D66)),
                        ),
                      ),
                    ],
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    List<String> images = List<String>.from(
                      data['images'] ?? [],
                    );
                    String firstImage = images.isNotEmpty ? images[0] : "";

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailsScreen(
                              name: data['name'] ?? 'N/A',
                              price: data['price'] ?? '0',
                              brand: data['brand'] ?? 'Unknown',
                              images: images,
                              description: data['description'] ?? "",
                              mfgDate: data['mfgDate'] ?? 'N/A',
                              expiryDate: data['expiryDate'] ?? 'N/A',
                              ingredients: data['ingredients'] ?? "See package",
                              sideEffects:
                                  data['sideEffects'] ?? "Consult doctor",
                              safetyAdvice:
                                  data['safetyAdvice'] ??
                                  "Keep away from children",
                            ),
                          ),
                        );
                      },
                      child: MedicineCard(
                        name: data['name'] ?? 'N/A',
                        brand: data['brand'] ?? 'Unknown',
                        price: data['price'] ?? '0',
                        rating: data['rating'] ?? '0.0',
                        color: Color(int.parse(data['color'] ?? "0xFFF3E5F5")),
                        imageUrl: firstImage,
                        onCartTap: () {
                          _addToCart({
                            'name': data['name'],
                            'brand': data['brand'],
                            'price': data['price'],
                            'image': firstImage,
                          });
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
        decoration: const InputDecoration(
          hintText: 'Search medicines...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF285D66), Color(0xFF4DB6AC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF285D66).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 20,
            top: 35,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Get 5% OFF",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "On getting 100 points",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            bottom: 0,
            child: Icon(
              Icons.local_pharmacy,
              size: 100,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['All', 'Tablets', 'Syrup', 'Painkiller', 'Vitamins'];
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedCategory == categories[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = categories[index];
              });
            },
            child: CategoryChip(
              label: categories[index],
              icon: _getCategoryIcon(categories[index]),
              isSelected: isSelected,
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String label) {
    switch (label) {
      case 'Tablets':
        return Icons.medication;
      case 'Syrup':
        return Icons.local_drink;
      case 'PainKiller':
        return Icons.healing;
      case 'Vitamins':
        return Icons.bolt;
      default:
        return Icons.grid_view;
    }
  }
}

// --- COMPONENTS (Inside same file to make it work easily) ---

class MedicineCard extends StatelessWidget {
  final String name, brand, price, rating, imageUrl;
  final Color color;
  final VoidCallback onCartTap;

  const MedicineCard({
    super.key,
    required this.name,
    required this.brand,
    required this.price,
    required this.rating,
    required this.color,
    required this.imageUrl,
    required this.onCartTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isNetwork = imageUrl.startsWith('http');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Hero(
                tag: name,
                child: isNetwork
                    ? Image.network(imageUrl, fit: BoxFit.contain)
                    : Image.asset(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            ),
                      ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        brand.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF285D66),
                        ),
                      ),
                      InkWell(
                        onTap: onCartTap,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF285D66),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF285D66) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isSelected ? Colors.transparent : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
