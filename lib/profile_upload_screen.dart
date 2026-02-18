// import 'dart:convert'; // Base64 encoding ke liye lazmi hai
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'home_screen.dart';
// import 'components.dart';

// class ProfileUploadScreen extends StatefulWidget {
//   const ProfileUploadScreen({super.key});

//   @override
//   State<ProfileUploadScreen> createState() => _ProfileUploadScreenState();
// }

// class _ProfileUploadScreenState extends State<ProfileUploadScreen> {
//   String? _base64String; 
//   bool _isUploading = false;


//   Future<void> _pickAndConvertImage() async {
//     final pickedFile = await ImagePicker().pickImage(
//       source: ImageSource.gallery,
//     );

//     if (pickedFile != null) {
//       final bytes = await File(pickedFile.path).readAsBytes();
//       setState(() {
//         _base64String = base64Encode(bytes);
//       });
//     }
//   }

//   Future<void> _uploadAndContinue() async {
//     if (_base64String == null) {
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => const HomeScreen()),
//         (route) => false,
//       );
//       return;
//     }

//     setState(() => _isUploading = true);

//     try {
//       User? user = FirebaseAuth.instance.currentUser;

//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user!.uid)
//           .update({'profilePic': _base64String});

//       if (!mounted) return;
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => const HomeScreen()),
//         (route) => false,
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error: $e")));
//     } finally {
//       if (mounted) setState(() => _isUploading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFADDDE6),
//       body: Stack(
//         children: [
//           const BackgroundCurve(),
//           Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text(
//                   'Sign up',
//                   style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 50),
//                 GestureDetector(
//                   onTap: _pickAndConvertImage,
//                   child: CircleAvatar(
//                     radius: 90,
//                     backgroundColor: Colors.white,
//                     backgroundImage: _base64String != null
//                         ? MemoryImage(base64Decode(_base64String!))
//                         : null,
//                     child: _base64String == null
//                         ? const Icon(
//                             Icons.camera_alt,
//                             size: 50,
//                             color: Colors.grey,
//                           )
//                         : null,
//                   ),
//                 ),
//                 const SizedBox(height: 40),
//                 _isUploading
//                     ? const CircularProgressIndicator()
//                     : Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 40),
//                         child: MyButton(
//                           text: _base64String == null
//                               ? 'Skip'
//                               : 'Save & Finish',
//                           onPressed: _uploadAndContinue,
//                         ),
//                       ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
