// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jeezy/screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jeezy/screens/first_time.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:jeezy/main.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _otpFocus = FocusNode();

  String _verificationId = '';
  bool _isOtpDialogOpen = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isPhoneLoading = false;
  
  late AnimationController _animationController;
  late AnimationController _logoAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAlreadySignedIn();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _logoAnimationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));

    _logoRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    _animationController.forward();
    _logoAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    _animationController.dispose();
    _logoAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkAlreadySignedIn() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      print('User already signed in: ${user.uid}');
      await _navigateAfterLogin(user);
    } else {
      print('No user signed in yet.');
    }
  }

  Future<void> _handleGoogleAuth() async {
    if (_isGoogleLoading) return;
    
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null && mounted) {
        print('Google sign-in successful: ${user.uid}');
        _showSuccessSnackBar('Welcome, ${user.displayName ?? 'User'}!');
        await _navigateAfterLogin(user);
      }
    } catch (e) {
      print("Google Sign-In Error: $e");
      _showErrorSnackBar(_getErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  void _showPhoneInputDialog() {
    _phoneController.clear();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.phone_android,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Phone Login",
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Enter your phone number to receive a verification code",
                    style: GoogleFonts.comicNeue(),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.comicNeue(),
                    decoration: InputDecoration(
                      hintText: "+91XXXXXXXXXX",
                      hintStyle: GoogleFonts.comicNeue(),
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.comicNeue(),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isPhoneLoading ? null : () async {
                    final phoneNumber = _phoneController.text.trim();
                    if (phoneNumber.isEmpty) {
                      _showErrorSnackBar('Please enter a phone number');
                      return;
                    }
                    if (!phoneNumber.startsWith('+')) {
                      _showErrorSnackBar('Please include country code (e.g., +91)');
                      return;
                    }
                    
                    setDialogState(() {
                      _isPhoneLoading = true;
                    });
                    
                    Navigator.pop(context);
                    await _verifyPhoneNumber(phoneNumber);
                    
                    setDialogState(() {
                      _isPhoneLoading = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isPhoneLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          "Send OTP",
                          style: GoogleFonts.comicNeue(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _navigateAfterLogin(User user) async {
  print('Checking user profile completion for: ${user.uid}');

  try {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      print('User doc does not exist, creating...');
      await userDoc.set({
        'created_at': FieldValue.serverTimestamp(),
        'email': user.email,
        'display_name': user.displayName,
        'photo_url': user.photoURL,
      });
    }

    final updatedDoc = await userDoc.get();
    final data = updatedDoc.data();

    print('User data from Firestore: $data');

    if (data == null || !data.containsKey('user_class') || !data.containsKey('jee_year')) {
      print('User profile incomplete, going to FirstTimeSetup');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
            ThemeSwitchingArea(child: FirstTimeSetup()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 500),
        ),
      );
    } else {
      print('User profile complete, going to HomePage with preloaded data');
      if (!mounted) return;
      
      // Preload user data here too for consistency
      final preloadedData = {
        'display_name': data['display_name'] ?? user.displayName ?? "User",
        'user_class': data['user_class'] ?? "Not set",
        'jee_year': data['jee_year'] ?? "Not set",
        'goal': data['goal'] ?? "Not set",
      };
      
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
            ThemeSwitchingArea(
              child: HomePage(
                user: user,
                preloadedUserInfo: preloadedData, // Pass preloaded data
              ),
            ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 500),
        ),
      );
    }
  } catch (e) {
    print('Error in navigation: $e');
    _showErrorSnackBar('Navigation error occurred');
  }
}


  Future<void> _verifyPhoneNumber(String phoneNumber) async {
    setState(() {
      _isPhoneLoading = true;
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);
            final user = _auth.currentUser;
            if (user != null && mounted) {
              _showSuccessSnackBar('Phone verification successful!');
              await _navigateAfterLogin(user);
            }
          } catch (e) {
            _showErrorSnackBar('Auto-verification failed');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isPhoneLoading = false;
          });
          _showErrorSnackBar(_getErrorMessage(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isPhoneLoading = false;
          });
          _verificationId = verificationId;
          _showOtpDialog();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          setState(() {
            _isPhoneLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isPhoneLoading = false;
      });
      print("Phone verification error: $e");
      _showErrorSnackBar('Phone verification failed');
    }
  }

  void _showOtpDialog() {
    if (_isOtpDialogOpen) return;
    _isOtpDialogOpen = true;
    _otpController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.sms,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Enter OTP",
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Enter the 6-digit code sent to your phone",
                    style: GoogleFonts.comicNeue(),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _otpController,
                    focusNode: _otpFocus,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.comicNeue(
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: "000000",
                      hintStyle: GoogleFonts.comicNeue(),
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _isOtpDialogOpen = false;
                  },
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.comicNeue(),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await _verifyPhoneNumber(_phoneController.text.trim());
                  },
                  child: Text(
                    "Resend",
                    style: GoogleFonts.comicNeue(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    final smsCode = _otpController.text.trim();
                    if (smsCode.length != 6) {
                      _showErrorSnackBar('Please enter a valid 6-digit OTP');
                      return;
                    }

                    setDialogState(() {
                      _isLoading = true;
                    });

                    final credential = PhoneAuthProvider.credential(
                      verificationId: _verificationId,
                      smsCode: smsCode,
                    );

                    try {
                      await _auth.signInWithCredential(credential);
                      final user = _auth.currentUser;
                      if (user != null && mounted) {
                        Navigator.pop(context);
                        _isOtpDialogOpen = false;
                        _showSuccessSnackBar('Phone verification successful!');
                        await _navigateAfterLogin(user);
                      }
                    } catch (e) {
                      print("OTP Sign-in Error: $e");
                      _showErrorSnackBar(_getErrorMessage(e));
                    } finally {
                      setDialogState(() {
                        _isLoading = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          "Verify",
                          style: GoogleFonts.comicNeue(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _isOtpDialogOpen = false;
    });
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-phone-number':
          return 'Invalid phone number format';
        case 'too-many-requests':
          return 'Too many requests. Please try again later';
        case 'invalid-verification-code':
          return 'Invalid verification code';
        case 'session-expired':
          return 'Verification session expired';
        case 'network-request-failed':
          return 'Network error. Please check your connection';
        case 'user-disabled':
          return 'This account has been disabled';
        case 'operation-not-allowed':
          return 'Phone authentication is not enabled';
        default:
          return error.message ?? 'Authentication failed';
      }
    }
    return 'An unexpected error occurred';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.comicNeue(),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.comicNeue(),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThemeSwitchingArea(
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentThemeMode, child) {
          final isDark = currentThemeMode == ThemeMode.dark;
          
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Color(0xFF232526),
                        Color(0xFF1a1a2e),
                        Color(0xFF0f2027),
                        Color(0xFF2c5364),
                      ]
                    : [
                        Color(0xFF667eea),
                        Color(0xFF764ba2),
                        Color(0xFF6B73FF),
                        Color(0xFF000DFF),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animated Logo
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: RotationTransition(
                                turns: _logoRotationAnimation,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.2),
                                        Colors.white.withOpacity(0.1),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.school,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(height: 40),
                            
                            // Welcome Text
                            Text(
                              "Welcome to JEEzy",
                              style: GoogleFonts.comicNeue(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: Offset(2, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            SizedBox(height: 12),
                            
                            Text(
                              "Your ultimate JEE preparation companion",
                              style: GoogleFonts.comicNeue(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            SizedBox(height: 60),
                            
                            // Google Sign In Button
                            _buildSignInButton(
                              onPressed: _handleGoogleAuth,
                              icon: Icons.login,
                              label: "Continue with Google",
                              isLoading: _isGoogleLoading,
                              backgroundColor: Colors.white.withOpacity(0.15),
                              textColor: Colors.white,
                            ),
                            
                            SizedBox(height: 20),
                            
                            // Phone Sign In Button
                            _buildSignInButton(
                              onPressed: _showPhoneInputDialog,
                              icon: Icons.phone,
                              label: "Continue with Phone",
                              isLoading: _isPhoneLoading,
                              backgroundColor: Colors.white.withOpacity(0.15),
                              textColor: Colors.white,
                            ),
                            
                            SizedBox(height: 40),
                            
                            // Terms and Privacy
                            Text(
                              "By continuing, you agree to our Terms of Service and Privacy Policy",
                              style: GoogleFonts.comicNeue(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSignInButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isLoading,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Icon(icon, color: textColor, size: 24),
        label: Text(
          isLoading ? "Please wait..." : label,
          style: GoogleFonts.comicNeue(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
