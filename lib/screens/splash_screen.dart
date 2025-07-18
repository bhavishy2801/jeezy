// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api

import 'dart:math' as math;
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jeezy/screens/first_time.dart';
import 'package:jeezy/screens/login_screen.dart';
import 'package:jeezy/screens/home_screen.dart';
import 'package:jeezy/main.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Simplified Animation Controllers
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late AnimationController _textController;
  late AnimationController _pulseController;
  
  // Simplified Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _pulseAnimation;
  
  // Minimalistic particles
  List<MinimalParticle> particles = [];
  
  @override
  void initState() {
    super.initState();
    print('🚀 Minimalistic Splash Screen Started');
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _initializeAnimations();
    _initializeParticles();
    _startSequence();
  }

  void _initializeAnimations() {
    // Logo Animation (2 seconds)
    _logoController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Fade Animation (1.5 seconds)
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Text Animation (1 second)
    _textController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Pulse Animation (continuous)
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Logo Animations
    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    // Fade Animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Text Animations
    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    _textSlide = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    // Pulse Animation
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations with delays
    _fadeController.forward();
    
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) _logoController.forward();
    });
    
    Future.delayed(Duration(milliseconds: 800), () {
      if (mounted) _textController.forward();
    });
  }

  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < 20; i++) { // Reduced particles for minimalism
      particles.add(MinimalParticle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        speed: 0.0005 + random.nextDouble() * 0.001,
        size: 0.5 + random.nextDouble() * 1.5,
        opacity: 0.1 + random.nextDouble() * 0.3,
      ));
    }
  }

  Future<void> _startSequence() async {
    print('⏰ Starting splash sequence');
    
    // Wait for animations to complete
    await Future.delayed(Duration(milliseconds: 3000));
    
    if (!mounted) return;
    
    await _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
  print('🔍 Checking authentication and navigating');
  
  // Add haptic feedback
  HapticFeedback.lightImpact();
  
  // PRELOAD: Do all data loading here during splash
  User? user;
  Map<String, dynamic>? userInfo;
  bool needsFirstTimeSetup = false;
  
  try {
    user = FirebaseAuth.instance.currentUser;
    print('👤 Current user: ${user?.uid ?? 'null'}');
    
    // If user exists, preload their data and check profile completion
    if (user != null) {
      print('📊 Preloading user data during splash...');
      
      // Check if profile is complete
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) {
        // Create basic user document
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'created_at': FieldValue.serverTimestamp(),
          'email': user.email,
          'display_name': user.displayName,
          'photo_url': user.photoURL,
        });
        needsFirstTimeSetup = true;
      } else {
        final data = userDoc.data();
        if (data == null || !data.containsKey('user_class') || !data.containsKey('jee_year')) {
          needsFirstTimeSetup = true;
        } else {
          // Profile is complete, preload data
          userInfo = {
            'display_name': data['display_name'] ?? user.displayName ?? "User",
            'user_class': data['user_class'] ?? "Not set",
            'jee_year': data['jee_year'] ?? "Not set",
            'goal': data['goal'] ?? "Not set",
          };
        }
      }
      
      print('✅ User data preloaded successfully');
    }
  } catch (e) {
    print('❌ Error during preload: $e');
  }
  
  // Fade out animation
  await _fadeController.reverse();
  
  if (!mounted) return;
  
  // Navigate with preloaded data - NO LOADING SCREENS
  Navigator.of(context).pushAndRemoveUntil(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        if (user != null) {
          if (needsFirstTimeSetup) {
            print('✅ User needs first time setup');
            return ThemeSwitchingArea(child: FirstTimeSetup());
          } else {
            print('✅ User authenticated, going to HomePage with preloaded data');
            return ThemeSwitchingArea(
              child: HomePage(
                user: user, 
                preloadedUserInfo: userInfo, // Pass preloaded data
              ),
            );
          }
        } else {
          print('❌ No user, going to LoginPage');
          return LoginPage();
        }
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: Duration(milliseconds: 500),
    ),
    (route) => false,
  );
}


  // Add this method to preload user data during splash
Future<Map<String, dynamic>?> _preloadUserData(User user) async {
  try {
    await user.reload();
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    if (doc.exists) {
      final data = doc.data()!;
      return {
        'display_name': data['display_name'] ?? user.displayName ?? "User",
        'user_class': data['user_class'] ?? "Not set",
        'jee_year': data['jee_year'] ?? "Not set",
      };
    }
  } catch (e) {
    print('Error preloading user data: $e');
  }
  
  return {
    'display_name': user.displayName ?? "User",
    'user_class': "Not set",
    'jee_year': "Not set",
  };
}

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _logoController.dispose();
    _fadeController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0C1429), // Solid dark background
      body: Stack(
        children: [
          // Minimal Particle Background
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return CustomPaint(
                painter: MinimalParticlePainter(particles),
                size: Size.infinite,
              );
            },
          ),
          
          // Main Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Minimalistic Logo
                      _buildMinimalLogo(),
                      
                      SizedBox(height: 40),
                      
                      // Minimalistic Title
                      _buildMinimalTitle(),
                      
                      SizedBox(height: 60),
                      
                      // Simple Loading Indicator
                      _buildMinimalLoading(),
                      
                      SizedBox(height: 120),
                      
                      // Minimal Version Info
                      _buildMinimalVersionInfo(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoScale, _logoRotation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Transform.rotate(
            angle: _logoRotation.value * 0.1, // Subtle rotation
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF06292),
                    Color(0xFF9C27B0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFF06292).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.school,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinimalTitle() {
    return SlideTransition(
      position: _textSlide,
      child: FadeTransition(
        opacity: _textFade,
        child: Column(
          children: [
            Text(
              "JEEzy",
              style: GoogleFonts.comicNeue(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            
            SizedBox(height: 12),
            
            Text(
              "Your JEE preparation companion",
              style: GoogleFonts.comicNeue(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalLoading() {
    return FadeTransition(
      opacity: _textFade,
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(0xFFF06292),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalVersionInfo() {
    return FadeTransition(
      opacity: _textFade,
      child: Column(
        children: [
          Text(
            "Beta Version",
            style: GoogleFonts.comicNeue(
              fontSize: 12,
              color: Colors.white.withOpacity(0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
          
          SizedBox(height: 8),
          
          Text(
            "Made with ❤ by Bhavishy Agrawal",
            style: GoogleFonts.comicNeue(
              fontSize: 10,
              color: Colors.white.withOpacity(0.3),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// Minimal Particle class
class MinimalParticle {
  double x;
  double y;
  final double speed;
  final double size;
  final double opacity;

  MinimalParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });

  void update() {
    y -= speed;
    if (y < 0) {
      y = 1.0;
      x = math.Random().nextDouble();
    }
  }
}

// Minimal Particle Painter
class MinimalParticlePainter extends CustomPainter {
  final List<MinimalParticle> particles;

  MinimalParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final particle in particles) {
      particle.update();
      
      paint.color = Colors.white.withOpacity(particle.opacity);
      
      canvas.drawCircle(
        Offset(
          particle.x * size.width,
          particle.y * size.height,
        ),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
