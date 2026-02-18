// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'searchbar.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   //constructor
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(home: BottomNavigationBarExample());
//   }
// }

// class BottomNavigationBarExample extends StatefulWidget {
//   const BottomNavigationBarExample({super.key});

//   @override
//   State<BottomNavigationBarExample> createState() {
//     return _BottomNavigationBarExampleState();
//   }
// }

// class _BottomNavigationBarExampleState
//     extends State<BottomNavigationBarExample> {
//   TextEditingController searchController = TextEditingController();
//   int _selectedIndex = 0;
//   static const TextStyle optionStyle = TextStyle(
//     fontSize: 30,
//     fontWeight: FontWeight.bold,
//   );
//   static const List<Widget> _widgetOptions = <Widget>[
//     Text('Home Page', style: optionStyle),
//     Text('One Page', style: optionStyle),
//     Text('two Page', style: optionStyle),
//   ];

//   void onTapItems(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Whatsapp"),
//         titleTextStyle: TextStyle(
//           color: Color.fromARGB(255, 60, 145, 130),
//           fontSize: 25,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       body: Column(
//         children: [
//           // 🔍 Imported Search Bar
//           AppSearchBar(controller: searchController),

//           // 📄 Page Content
//           Expanded(
//             child: Center(child: _widgetOptions.elementAt(_selectedIndex)),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.business),
//             label: 'Business',
//           ),
//           BottomNavigationBarItem(icon: Icon(Icons.school), label: 'School'),
//         ],
//         currentIndex: _selectedIndex,
//         selectedItemColor: const Color.fromARGB(255, 8, 210, 41),
//         onTap: onTapItems,
//       ),
//     );
//   }
// }
