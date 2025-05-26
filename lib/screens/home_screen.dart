import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jeezy/screens/bookmark_screen.dart';
import 'package:jeezy/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jeezy/screens/privacy_policy.dart';
import 'package:jeezy/screens/profile.dart';
import 'package:jeezy/main.dart';
import 'package:jeezy/screens/notes_screen.dart';
import 'package:jeezy/screens/progress_screen.dart';
import 'package:jeezy/screens/tests_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:jeezy/screens/feedback_screen.dart';
import 'package:jeezy/screens/ai_assistant.dart';

class HomePage extends StatefulWidget {
  final User user;
  HomePage({required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? userClass;
  String? jeeYear;
  String? displayName;
  int _currentIndex = 0;

  final List<Widget> _pages = [];


  @override
  void initState() {
    super.initState();
    displayName = widget.user.displayName ?? "User";
    loadUserInfo();

    _pages.addAll([
    HomeContent(),
    AIAssistantPage(),
  ]);
  }

  Future<Map<String, dynamic>> loadUserInfo() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await user.reload();
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      return {
        'display_name': data['display_name'] ?? user.displayName ?? "User",
        'user_class': data['user_class'] ?? "Not set",
        'jee_year': data['jee_year'] ?? "Not set",
      };
    }
  }
  return {
    'display_name': user?.displayName ?? "User",
    'user_class': "Not set",
    'jee_year': "Not set",
  };
}

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, child) {
        final isDark = currentThemeMode == ThemeMode.dark;
        final theme = Theme.of(context);

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            leading: Builder(
              builder: (context) {
                final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: CircleAvatar(
                      backgroundImage: photoUrl != null
                          ? NetworkImage(photoUrl)
                          : AssetImage("assets/images/default_user.png") as ImageProvider,
                    ),
                  ),
                );
              },
            ),
            title: FutureBuilder<Map<String, dynamic>>(
  future: loadUserInfo(),
  builder: (context, snapshot) {
    final name = snapshot.data?['display_name']?.split(' ').first ?? 'User';
    return Row(
      children: [
        Image.asset('assets/images/wave.png', width: 24),
        Text(
          "  Hey, $name",
          style: TextStyle(
            fontFamily: GoogleFonts.comicNeue().fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  },
),
          ),
          body: _pages[_currentIndex],
          drawer: _buildDrawer(context, isDark, theme),
          bottomNavigationBar: _buildBottomNavBar(isDark, theme),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark, ThemeData theme) {
    return Drawer(

      child: DefaultTextStyle(
        style: GoogleFonts.comicNeue(
        textStyle: theme.textTheme.bodyMedium,
      ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
        
            _buildProfileSection(context, isDark), // Profile Section
            const Divider(),
        
            _buildDarkModeToggle(isDark), // Dark Mode Toggle
            const Divider(),
        
            _buildDrawerNavigationItems(context, theme), // Navigation Items
            const Divider(),
        
        
          ListTile(
            leading: Icon(Icons.share, color: isDark ? Color(0xFFBDBDBD) : Color(0xFF1C1B1F),),
            title: Text("Share App", style: GoogleFonts.comicNeue(fontWeight: FontWeight.w700, fontSize: 18),),
            onTap: () async {
              final box = context.findRenderObject() as RenderBox?;
              Navigator.pop(context);
        
              // final result = 
              await SharePlus.instance.share(
                ShareParams(
                  text: '📱 Ace your JEE preparation with *Jeezy*! 🚀\n\n'
                  'Get access to high-quality notes, mock tests, and curated materials for both JEE Main & Advanced — all in one place.\n\n'
                  'Download now and supercharge your prep: https://github.com/bhavishy2801/jeezy\n\n',
                  subject: '🔥 Must-Have App for Every JEE Aspirant – Jeezy!',
                  title: 'Check out Jeezy – your ultimate JEE prep companion!',
                  sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
                ),
              );
        
              // final scaffoldMessenger = ScaffoldMessenger.of(context);
              // scaffoldMessenger.showSnackBar(
              //   SnackBar(
              //     content: Text('Share result: ${result.status.name}', style: TextStyle(color: Colors.white),),
              //     duration: const Duration(seconds: 2),
              //     backgroundColor: Color.fromARGB(255, 12, 20, 41),
              //   ),
              // );
            },
          ),
        
          ListTile(
            leading: Icon(Icons.feedback, color: isDark ? Color(0xFFBDBDBD) : Color(0xFF1C1B1F),),
            title: Text("Send Feedback", style: GoogleFonts.comicNeue(fontWeight: FontWeight.w700, fontSize: 18),),
            onTap: () {
              // Open mail app or feedback form link
              Navigator.pop(context);
              Navigator.push(
                context,
                PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => FeedbackPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.ease;
                  final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                  );
                },
                transitionDuration: Duration(milliseconds: 400),
                ),
              );
            },
          ),
        
          ListTile(
            leading: Icon(Icons.privacy_tip, color: isDark ? Color(0xFFBDBDBD) : Color(0xFF1C1B1F),),
            title: Text("Privacy Policy", style: GoogleFonts.comicNeue(fontWeight: FontWeight.w700, fontSize: 18),),
            onTap: () {
              // Navigate to privacy policy screen or open URL
              Navigator.pop(context);
              Navigator.push(
                context,
                PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => PrivacyPolicyPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.ease;
                  final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                  );
                },
                transitionDuration: Duration(milliseconds: 400),
                ),
              );
            },
          ),
        
        
          _buildSignOutButton(context, isDark), // Sign Out Button
        
          Expanded(child: Container()),  // pushes the text to bottom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Text(
              "Beta Version",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w700,
                fontFamily: GoogleFonts.comicNeue().fontFamily,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Made with ❤ by Bhavishy Agrawal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  // fontStyle: FontStyle.italic,
                  fontFamily: GoogleFonts.comicNeue().fontFamily,
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, bool isDark) {
  return FutureBuilder<Map<String, dynamic>>(
    future: loadUserInfo(),
    builder: (context, snapshot) {
      final data = snapshot.data ?? {};
      return GestureDetector(
        onTap: () async {
          Navigator.pop(context);
            await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => ValueListenableBuilder(
              valueListenable: themeNotifier,
              builder: (context, _, __) => ProfilePage(user: widget.user, isDark: isDark),
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.ease;
              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
              },
              transitionDuration: Duration(milliseconds: 400),
            ),
            );
            setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: widget.user.photoURL != null
                    ? NetworkImage(widget.user.photoURL!)
                    : AssetImage("assets/images/default_user.png") as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['display_name'] ?? "User",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("${data['user_class'] ?? 'Not set'} ◉ ${data['jee_year'] ?? 'Not set'}",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? const Color.fromARGB(255, 180, 180, 180) : Colors.black54)),
                    ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}


  Widget _buildDarkModeToggle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Dark Mode",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Switch(
            
            value: isDark,
            onChanged: (_) {
              setState(() {
                themeNotifier.toggleTheme();
              });
            },
            activeColor: Color.fromARGB(255, 242, 202, 249), // thumb color
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerNavigationItems(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        
        _buildDrawerItem(
          context,
          icon: Icons.note,
          title: "Notes",
            onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => NotesScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.ease;
                final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(
                position: animation.drive(tween),
                child: child,
                );
              },
              transitionDuration: Duration(milliseconds: 400),
              ),
            );
          },
        ),
        _buildDrawerItem(
          context,
          icon: Icons.assignment,
          title: "Tests",
            onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => TestsScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.ease;
                final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(
                position: animation.drive(tween),
                child: child,
                );
              },
              transitionDuration: Duration(milliseconds: 400),
              ),
            );
          },
        ),
        _buildDrawerItem(
                context,
                icon: Icons.support_agent,
                title: "Assistant",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => AIAssistantPage(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.ease;
                        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                      transitionDuration: Duration(milliseconds: 400),
                    ),
                  );
                },
              ),
        _buildDrawerItem(
          context,
          icon: Icons.bookmark,
          title: "My Bookmarks",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => BookmarksPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.ease;
                final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(
                position: animation.drive(tween),
                child: child,
                );
              },
              transitionDuration: Duration(milliseconds: 400),
              ),
            );
          },
        ),
        _buildDrawerItem(
          context,
          icon: Icons.track_changes,
          title: "My Progress",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => ProgressPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.ease;
                final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(
                position: animation.drive(tween),
                child: child,
                );
              },
              transitionDuration: Duration(milliseconds: 400),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDrawerItem(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold, fontSize: 18),),
      onTap: onTap,
    );
  }

  Widget _buildSignOutButton(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark
              ? const Color.fromARGB(25, 255, 255, 255)
              : const Color.fromARGB(160, 243, 235, 235),
        ),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        },
        icon: Icon(Icons.logout, color: isDark ? Color.fromARGB(255, 242, 202, 249) : Colors.black,),
        label: Text("Sign out", style: TextStyle(color: isDark ? Color.fromARGB(255, 242, 202, 249) : Colors.black, fontFamily: GoogleFonts.comicNeue().fontFamily, fontWeight: FontWeight.bold),),
      ),
    );
  }

  Widget _buildBottomNavBar(bool isDark, ThemeData theme) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) async {
          if (index == 0) {
            setState(() => _currentIndex = 0);
          } else if (index == 1) {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => NotesScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                transitionDuration: Duration(milliseconds: 300),
              ),
            );
          }
          else if (index == 2) {
              // Assistant page navigation
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => AIAssistantPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: Duration(milliseconds: 300),
                ),
              );
            }
          else if (index == 3) {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => TestsScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                transitionDuration: Duration(milliseconds: 300),
              ),
            );
          }
          else if (index == 4) {
            final updatedUser = await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => ValueListenableBuilder(
                  valueListenable: themeNotifier,
                  builder: (context, currentThemeMode, _) {
                    return ProfilePage(
                      user: widget.user,
                      isDark: currentThemeMode == ThemeMode.dark,
                    );
                  },
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                transitionDuration: Duration(milliseconds: 300),
              ),
            );

            if (updatedUser != null) {
              setState(() {});
            }
          }
        },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.note),
          label: 'Notes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.support_agent),
          label: 'Assistant',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Tests',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
