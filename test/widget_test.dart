//yimport 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart'; // Import GetX
import 'package:medi_care/main.dart';
//import 'package:medi_care/auth_controller.dart'; // Import Controller

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // FIX: Initialize the AuthController Mock or just let GetX handle dependency injection
    // Since we are just testing if the app builds, we can just pump the widget.
    // Ensure GetX doesn't throw errors for missing controllers in tests:
    Get.testMode = true;

    // Build our app and trigger a frame.
    // We invoke MyApp() without arguments now.
    await tester.pumpWidget(const MyApp());

    // Verify that the GetMaterialApp is present.
    expect(find.byType(GetMaterialApp), findsOneWidget);
  });
}
