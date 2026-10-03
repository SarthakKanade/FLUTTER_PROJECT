import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fittrail/main.dart';
import 'package:fittrail/widgets/calorie_ring.dart';
import 'package:fittrail/widgets/date_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('FitTrailApp loads Daily Summary dashboard and adapts to mobile screen', (WidgetTester tester) async {
    // Set mobile dimensions (390 x 844) matching PRD Figma specifications
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: FitTrailApp(),
      ),
    );

    // Initial pump and settle
    await tester.pumpAndSettle();

    // Verify Title and Navigation elements
    expect(find.text('FitTrail'), findsOneWidget);
    expect(find.byType(DateHeader), findsOneWidget);
    expect(find.byType(CalorieRing), findsOneWidget);

    // Verify Mobile NavigationBar destinations
    expect(find.text('Summary'), findsWidgets);
    expect(find.text('Log Meal'), findsWidgets);
    expect(find.text('Log Workout'), findsWidgets);
  });

  testWidgets('FitTrailApp adapts to tablet/wide screen with NavigationRail', (WidgetTester tester) async {
    // Set tablet dimensions (800 x 600)
    tester.view.physicalSize = const Size(800 * 2, 600 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: FitTrailApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Meal'), findsOneWidget);
    expect(find.text('Workout'), findsOneWidget);
  });
}
