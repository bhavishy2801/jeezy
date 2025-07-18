// ignore_for_file: avoid_print, prefer_const_constructors_in_immutables, deprecated_member_use

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jeezy/screens/splash_screen.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Initializing Firebase...');
  await Firebase.initializeApp();

  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    print("✅ Auth persistence enabled successfully");
  } catch (e) {
    print("❌ Error setting persistence: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  String? themeString = prefs.getString('theme_mode');
  ThemeMode initialTheme = themeString == 'dark' ? ThemeMode.dark : ThemeMode.light;

  themeNotifier = ThemeNotifier(prefs, initialTheme);

  print('🎬 Starting app');
  runApp(MyApp(initialTheme: initialTheme));
}

class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  final SharedPreferences prefs;
  static const _key = 'theme_mode';

  ThemeNotifier(this.prefs, ThemeMode initialTheme) : super(initialTheme);

  Future<void> toggleTheme() async {
    value = value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await prefs.setString(_key, value == ThemeMode.light ? 'light' : 'dark');
    print('🎨 Theme toggled to: ${value == ThemeMode.light ? 'light' : 'dark'}');
  }

  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Color.fromARGB(255, 255, 255, 255),
    appBarTheme: const AppBarTheme(
      elevation: 0,
    ),
    primarySwatch: Colors.blue,
    pageTransitionsTheme: PageTransitionsTheme(builders: {
      TargetPlatform.android: NoTransitionsBuilder(),
      TargetPlatform.iOS: NoTransitionsBuilder(),
    }),
  );

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color.fromARGB(255, 12, 20, 41),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1C2542),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color.fromARGB(255, 12, 20, 41),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFF06292),
      secondary: Color(0xFF9C27B0),
      background: Color.fromARGB(255, 12, 20, 41),
      surface: Color(0xFF1C2542),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white70,
      onBackground: Colors.white,
      onError: Colors.redAccent,
      brightness: Brightness.dark,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
    ),
    primarySwatch: Colors.deepPurple,
    pageTransitionsTheme: PageTransitionsTheme(builders: {
      TargetPlatform.android: NoTransitionsBuilder(),
      TargetPlatform.iOS: NoTransitionsBuilder(),
    }),
  );

  ThemeData get currentTheme => value == ThemeMode.light ? lightTheme : darkTheme;
}

late ThemeNotifier themeNotifier;

class MyApp extends StatelessWidget {
  final ThemeMode initialTheme;
  MyApp({required this.initialTheme, super.key});

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building MyApp');
    
    // SIMPLIFIED: Remove nested builders that cause loading issues
    return ThemeProvider(
      initTheme: themeNotifier.currentTheme,
      builder: (context, theme) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, themeMode, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'JEEzy App',
              theme: themeNotifier.currentTheme, // Use current theme directly
              home: SplashScreen(), // Always start with splash
            );
          },
        );
      },
    );
  }
}
