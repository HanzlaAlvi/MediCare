import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'category_screen.dart';
import 'product_details_screen.dart';
import 'order_screen.dart';
import 'profile_screen.dart';
import 'notification_service.dart';
import 'viewall_screen.dart';
// Import Widgets File
import 'home_widgets.dart';

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
    NotificationService().startMonitoring();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
  final TextEditingController _searchController = TextEditingController();

  String searchQuery = "";
  String selectedCategory = "All";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    // 1. GestureDetector to handle Focus (Unfocus keyboard on tap outside)
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        // Custom App Bar from Widgets file
        appBar: HomeAppBar(
          searchController: _searchController,
          searchQuery: searchQuery,
          onSearchChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase();
            });
          },
          onClearSearch: () {
            _searchController.clear();
            setState(() => searchQuery = "");
          },
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- STATIC SECTION (Does NOT reload on category change) ---
            const PromoBanner(),

            // Category Chips
            CategorySelector(
              selectedCategory: selectedCategory,
              onCategorySelected: (category) {
                setState(() {
                  selectedCategory = category;
                });
              },
            ),

            // Popular Title Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                      MaterialPageRoute(builder: (c) => const ViewAllScreen()),
                    ),
                    child: const Text(
                      "See All",
                      style: TextStyle(color: Color(0xFF285D66)),
                    ),
                  ),
                ],
              ),
            ),

            // --- DYNAMIC SECTION (StreamBuilder wrapped in Expanded) ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('medicines')
                    .snapshots(),
                builder: (context, snapshot) {
                  // Loading
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Filter Logic (Client Side)
                  var allDocs = snapshot.hasData ? snapshot.data!.docs : [];

                  var filteredDocs = allDocs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String name = data['name'].toString().toLowerCase();
                    String category = data['category'] ?? "All";

                    bool matchesSearch = name.contains(searchQuery);
                    bool matchesCategory =
                        (selectedCategory == "All") ||
                        (category == selectedCategory);

                    return matchesSearch && matchesCategory;
                  }).toList();

                  // Empty State Handling (Shown BELOW popular title)
                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 50,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "No items found in $selectedCategory",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  // Grid View
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                          // Unfocus before navigation
                          FocusScope.of(context).unfocus();

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
                                ingredients:
                                    data['ingredients'] ?? "See package",
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
                          color: Color(
                            int.parse(data['color'] ?? "0xFFF3E5F5"),
                          ),
                          imageUrl: firstImage,
                          onCartTap: () => _addToCart({
                            'name': data['name'],
                            'brand': data['brand'],
                            'price': data['price'],
                            'image': firstImage,
                          }),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
