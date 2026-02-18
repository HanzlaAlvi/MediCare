import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;

  const AppSearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      //EdgeInsets: padding/margin deta h of 4 sides of a container.
      padding: const EdgeInsets.all(10),
      //TextField : Input field hai.
      child: TextField(
        //controller: Controls the text being edited.
        controller: controller,
        decoration: InputDecoration(
          fillColor: Colors.grey[10],
          filled: true,
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            borderSide: BorderSide(width: 1, color: Colors.white)
            ),
          ),
        ),
    );
  }
}
