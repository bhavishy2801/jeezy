import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:jeezy/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jeezy/screens/loading_decider.dart';
// import 'package:flutter_gemini/flutter_gemini.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // await Gemini.init(apiKey: 'API_KEY');

  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    print("Auth persistence enabled successfully");
  } catch (e) {
    print("Error setting persistence: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  String? themeString = prefs.getString('theme_mode');
  ThemeMode initialTheme = themeString == 'dark' ? ThemeMode.dark : ThemeMode.light;

  themeNotifier = ThemeNotifier(prefs, initialTheme);

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
  }
}

late ThemeNotifier themeNotifier;

class MyApp extends StatelessWidget {
  final ThemeMode initialTheme;
  MyApp({required this.initialTheme, super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'JEEzy App',
          themeMode: currentTheme,
          theme: ThemeData(
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
          ),
          darkTheme: ThemeData(
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
              primary: Color.fromARGB(255, 242, 202, 249),
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
          ),
          home: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasData) {
                    return LoadingDecider();
                  } else {
                    return LoginPage();
                  }
                },
              ),
        );
      },
    );
  }
}