// ignore_for_file: prefer_const_constructors_in_immutables, use_key_in_widget_constructors, use_build_context_synchronously, deprecated_member_use

import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jeezy/screens/bookmark_screen.dart';
import 'package:jeezy/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jeezy/screens/privacy_policy.dart';
import 'package:jeezy/screens/splash_screen.dart';
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
  final Map<String, dynamic>? preloadedUserInfo; // Add this parameter
  HomePage({
    required this.user, 
    this.preloadedUserInfo, // Optional preloaded data
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? userClass;
  String? jeeYear;
  String? displayName;
  int _currentIndex = 0;

  // Add these variables to preload data
  Map<String, dynamic> userInfo = {};
  bool isUserInfoLoaded = true;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    displayName = widget.user.displayName ?? "User";
    
    print('🏠 HomePage initState - Theme: ${themeNotifier.value}');

     // Use preloaded data if available
    if (widget.preloadedUserInfo != null) {
      userInfo = widget.preloadedUserInfo!;
      print('✅ Using preloaded user info');
    } else {
      // Fallback to default data (no loading state)
      userInfo = {
        'display_name': widget.user.displayName ?? "User",
        'user_class': "Not set",
        'jee_year': "Not set",
      };
      print('⚠️ Using fallback user info');
    }

    _pages.addAll([
      HomeContent(),
      AIAssistantPage(),
    ]);
  }

  @override
Widget build(BuildContext context) {
  return ThemeSwitchingArea(
    child: ValueListenableBuilder<ThemeMode>(
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
            title: Row(
              children: [
                Image.asset('assets/images/wave.png', width: 24),
                Text(
                  "  Hey, ${(isUserInfoLoaded ? userInfo['display_name'] : widget.user.displayName ?? 'User').split(' ').first}",
                  style: TextStyle(
                    fontFamily: GoogleFonts.comicNeue().fontFamily,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          body: _pages[_currentIndex],
          drawer: _buildDrawer(context, isDark, theme),
          bottomNavigationBar: _buildBottomNavBar(isDark, theme),
        );
      },
    ),
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
            _buildProfileSection(context, isDark),
            const Divider(),
            _buildDarkModeToggle(isDark),
            const Divider(),
            _buildDrawerNavigationItems(context, theme),
            const Divider(),
            ListTile(
              leading: Icon(Icons.share, color: isDark ? Color(0xFFBDBDBD) : Color(0xFF1C1B1F)),
              title: Text("Share App", style: GoogleFonts.comicNeue(fontWeight: FontWeight.w700, fontSize: 18)),
              onTap: () async {
                final box = context.findRenderObject() as RenderBox?;
                Navigator.pop(context);
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
              },
            ),
            ListTile(
              leading: Icon(Icons.feedback, color: isDark ? Color(0xFFBDBDBD) : Color(0xFF1C1B1F)),
              title: Text("Send Feedback", style: GoogleFonts.comicNeue(fontWeight: FontWeight.w700, fontSize: 18)),
              onTap: () {
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
              leading: Icon(Icons.privacy_tip, color: isDark ? Color(0xFFBDBDBD) : Color(0xFF1C1B1F)),
              title: Text("Privacy Policy", style: GoogleFonts.comicNeue(fontWeight: FontWeight.w700, fontSize: 18)),
              onTap: () {
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
            _buildSignOutButton(context, isDark),
            Expanded(child: Container()),
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
    final data = isUserInfoLoaded ? userInfo : {
      'display_name': widget.user.displayName ?? "User",
      'user_class': "Not set",
      'jee_year': "Not set",
    };
    
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
        
        // Refresh user info after returning from profile
        // _preloadUserInfo();
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
        ThemeSwitcher(
          clipper: const ThemeSwitcherCircleClipper(),
          builder: (context) {
            return Switch(
              value: isDark,
              onChanged: (value) async {
                print('🎨 Theme switch pressed: $value');
                
                // Get the render box for animation position
                final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                final Offset? offset = renderBox?.localToGlobal(Offset.zero);
                
                // Determine new theme
                final newTheme = isDark ? themeNotifier.lightTheme : themeNotifier.darkTheme;
                
                print('🎨 Switching to theme: ${isDark ? 'light' : 'dark'}');
                
                // Perform animated theme switch
                ThemeSwitcher.of(context).changeTheme(
                  theme: newTheme,
                  isReversed: false,
                  offset: offset ?? Offset(200, 200),
                );
                
                // Update theme notifier after a small delay to ensure animation starts
                await Future.delayed(Duration(milliseconds: 50));
                await themeNotifier.toggleTheme();
                
                print('✅ Theme switch completed');
              },
              activeColor: Color(0xFFF06292),
              activeTrackColor: Color(0xFFF06292).withOpacity(0.3),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.withOpacity(0.3),
            );
          },
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
          icon: Icons.school,
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
      title: Text(title, style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold, fontSize: 18)),
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
        icon: Icon(Icons.logout, color: isDark ? Color(0xFFF06292) : Colors.black),
        label: Text("Sign out", style: TextStyle(color: isDark ? Color(0xFFF06292) : Colors.black, fontFamily: GoogleFonts.comicNeue().fontFamily, fontWeight: FontWeight.bold)),
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
        } else if (index == 2) {
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
        } else if (index == 3) {
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
        } else if (index == 4) {
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
      unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: GoogleFonts.comicNeue().fontFamily),
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontFamily: GoogleFonts.comicNeue().fontFamily),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school),
          label: 'Study Hub',
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

// Enhanced HomeContent widget with actual content
class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1C2542) : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome to JEEzy! 🚀",
                  style: GoogleFonts.comicNeue(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Your ultimate JEE preparation companion",
                  style: GoogleFonts.comicNeue(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Quick Actions Grid
          Text(
            "Quick Actions",
            style: GoogleFonts.comicNeue(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildQuickActionCard(
                context,
                icon: Icons.school,
                title: "Study Notes",
                subtitle: "Access quality notes",
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotesScreen()),
                  );
                },
              ),
              _buildQuickActionCard(
                context,
                icon: Icons.assignment,
                title: "Practice Tests",
                subtitle: "Take mock tests",
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TestsScreen()),
                  );
                },
              ),
              _buildQuickActionCard(
                context,
                icon: Icons.support_agent,
                title: "AI Assistant",
                subtitle: "Get instant help",
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AIAssistantPage()),
                  );
                },
              ),
              _buildQuickActionCard(
                context,
                icon: Icons.track_changes,
                title: "Progress",
                subtitle: "Track your growth",
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProgressPage()),
                  );
                },
              ),
            ],
          ),
          
          SizedBox(height: 24),
          
          // Recent Activity Section
          Text(
            "Today's Goal",
            style: GoogleFonts.comicNeue(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1C2542) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 48,
                  color: Colors.amber,
                ),
                SizedBox(height: 12),
                Text(
                  "Keep up the great work!",
                  style: GoogleFonts.comicNeue(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Complete 3 practice questions today",
                  style: GoogleFonts.comicNeue(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C2542) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.comicNeue(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.comicNeue(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
