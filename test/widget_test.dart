import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bus_staff_scanner/main.dart';

void main() {
  testWidgets('shows staff splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());

    expect(find.byIcon(Icons.directions_bus), findsOneWidget);
    expect(find.text('Bus Staff'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Staff Login'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
  });
}
