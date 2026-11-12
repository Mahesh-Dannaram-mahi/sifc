// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sipora/main.dart';
import 'package:sipora/Home_page/home_page.dart';
import 'package:sipora/Login_page/widgets/login.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);

    // Wait for loading to complete
    await tester.pumpAndSettle();

    // Verify that either HomePage or SignupPage is shown
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
