import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeezy/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock Firebase for testing
class MockFirebaseApp extends Fake implements FirebaseApp {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'light',
      'isProfileComplete': true,
    });

    // Mock Firebase
    setupFirebaseMocks();
    await Firebase.initializeApp();

    // Build our app and trigger a frame
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            // Initialize SharedPreferences and theme notifier
            return FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final prefs = snapshot.data!;
                  themeNotifier = ThemeNotifier(prefs, ThemeMode.light);
                  return MyApp(initialTheme: ThemeMode.light);
                }
                return CircularProgressIndicator();
              },
            );
          },
        ),
      ),
    );

    // Wait for all async operations to complete
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

// Setup Firebase mocks
void setupFirebaseMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
}