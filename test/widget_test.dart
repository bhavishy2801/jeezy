import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeezy/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFirebaseApp extends Fake implements FirebaseApp {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App builds without crashing', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'light',
      'isProfileComplete': true,
    });

    setupFirebaseMocks();
    await Firebase.initializeApp();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
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

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
void setupFirebaseMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
}