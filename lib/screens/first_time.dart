// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jeezy/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:jeezy/main.dart';

class FirstTimeSetup extends StatefulWidget {
  @override
  State<FirstTimeSetup> createState() => _FirstTimeSetupState();
}

class _FirstTimeSetupState extends State<FirstTimeSetup> with TickerProviderStateMixin {
  String? selectedClass;
  String? selectedYear;
  String? selectedGoal;
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  late AnimationController _animationController;
  late AnimationController _progressAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _cardScaleAnimation;

  final List<Map<String, dynamic>> classes = [
    {'value': '11th', 'title': 'Class 11th', 'subtitle': 'Building foundation for JEE', 'icon': Icons.school_outlined, 'color': Color(0xFF4A90E2), 'gradient': [Color(0xFF4A90E2), Color(0xFF357ABD)]},
    {'value': '12th', 'title': 'Class 12th', 'subtitle': 'Final year preparation', 'icon': Icons.auto_awesome, 'color': Color(0xFF50C878), 'gradient': [Color(0xFF50C878), Color(0xFF3A9B5C)]},
    {'value': 'Dropper', 'title': 'Dropper', 'subtitle': 'Gap year focused prep', 'icon': Icons.refresh_rounded, 'color': Color(0xFFFF8C42), 'gradient': [Color(0xFFFF8C42), Color(0xFFE67E22)]},
  ];

  final List<String> years = List.generate(4, (index) {
    final year = DateTime.now().year + index;
    return year.toString();
  });

  final List<Map<String, dynamic>> goals = [
    {'value': 'JEE Main', 'title': 'JEE Main', 'subtitle': 'NIT, IIIT, State Engineering', 'icon': Icons.flag_outlined, 'color': Color(0xFF9B59B6), 'gradient': [Color(0xFF9B59B6), Color(0xFF8E44AD)]},
    {'value': 'JEE Advanced', 'title': 'JEE Advanced', 'subtitle': 'IIT & Top Engineering', 'icon': Icons.emoji_events_outlined, 'color': Color(0xFFF39C12), 'gradient': [Color(0xFFF39C12), Color(0xFFE67E22)]},
    {'value': 'Both', 'title': 'Both Exams', 'subtitle': 'Complete JEE preparation', 'icon': Icons.star_outline, 'color': Color(0xFFE74C3C), 'gradient': [Color(0xFFE74C3C), Color(0xFFC0392B)]},
  ];

  final _formKey = GlobalKey<FormState>();
  bool _isDataSaved = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _progressAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));

    _cardScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    _pageController.dispose();
    _animationController.dispose();
    _progressAnimationController.dispose();
    _cardAnimationController.dispose();
    
    if (!_isDataSaved) {
      FirebaseAuth.instance.signOut();
    }
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            selectedClass = data['user_class'];
            selectedYear = data['jee_year'];
            selectedGoal = data['goal'];
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      HapticFeedback.lightImpact();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      HapticFeedback.lightImpact();
    }
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return selectedClass != null;
      case 2:
        return selectedYear != null;
      case 3:
        return selectedGoal != null;
      default:
        return false;
    }
  }

  Future<void> saveUserInfo() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user found');

      await user.updateDisplayName(_nameController.text.trim());
      await user.reload();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'display_name': _nameController.text.trim(),
        'user_class': selectedClass,
        'jee_year': selectedYear,
        'goal': selectedGoal,
        'profile_completed_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isProfileComplete', true);

      setState(() => _isDataSaved = true);
      
      _showSuccessDialog();
      
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error saving profile: ${e.toString()}');
    }
  }

  void _showSuccessDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF8F9FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 48,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Profile Completed!',
              style: GoogleFonts.comicNeue(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Welcome to JEEzy, ${_nameController.text.split(' ').first}!',
              style: GoogleFonts.comicNeue(
                fontSize: 16,
                color: Color(0xFF7F8C8D),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // DIRECT NAVIGATION - NO LOADING
                  Navigator.pushAndRemoveUntil(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => 
                          ThemeSwitchingArea(
                            child: HomePage(
                              user: FirebaseAuth.instance.currentUser!,
                              preloadedUserInfo: {
                                'display_name': _nameController.text.trim(),
                                'user_class': selectedClass,
                                'jee_year': selectedYear,
                                'goal': selectedGoal,
                              },
                            ),
                          ),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      transitionDuration: Duration(milliseconds: 800),
                    ),
                    (route) => false, // Remove all previous routes
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: Color(0xFF4CAF50).withOpacity(0.3),
                ),
                child: Text(
                  'Get Started',
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
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
                  ? [Color(0xFF0C1429), Color(0xFF1C2542), Color(0xFF2C3E50)]
                  : [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFF6B73FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: true, // ADDED: Handle keyboard properly
            body: SafeArea(
              child: _isLoading
                  ? _buildLoadingScreen()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: ClampingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: Column(
                                    children: [
                                      // Custom App Bar
                                      _buildCustomAppBar(),
                                      
                                      // Progress Indicator
                                      _buildEnhancedProgressIndicator(),
                                      
                                      // Page Content
                                      Expanded(
                                        child: Form(
                                          key: _formKey,
                                          child: Container(
                                            height: MediaQuery.of(context).size.height * 0.6, // UPDATED: Use MediaQuery
                                            child: PageView(
                                              controller: _pageController,
                                              onPageChanged: (page) {
                                                setState(() => _currentPage = page);
                                                _progressAnimationController.animateTo(
                                                  (page + 1) / 4,
                                                );
                                                HapticFeedback.lightImpact();
                                              },
                                              children: [
                                                _buildNamePage(),
                                                _buildClassPage(),
                                                _buildYearPage(),
                                                _buildGoalPage(),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // Navigation Buttons
                                      _buildEnhancedNavigationButtons(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          if (_currentPage > 0)
            GestureDetector(
              onTap: _previousPage,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: Text(
                "Complete Your Profile",
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          SizedBox(width: 44), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Setting up your profile...',
            style: GoogleFonts.comicNeue(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        children: [
          Row(
            children: List.generate(4, (index) {
              final isActive = index <= _currentPage;
              final isCompleted = index < _currentPage;
              
              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: isActive 
                                ? Colors.white 
                                : Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                      if (index < 3) SizedBox(width: 8),
                    ],
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepIndicator(0, 'Name', Icons.person_outline),
              _buildStepIndicator(1, 'Class', Icons.school_outlined),
              _buildStepIndicator(2, 'Year', Icons.calendar_today_outlined),
              _buildStepIndicator(3, 'Goal', Icons.flag_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = step <= _currentPage;
    final isCurrent = step == _currentPage;
    
    return Column(
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
            boxShadow: isCurrent ? [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ] : [],
          ),
          child: Icon(
            icon,
            color: isActive ? Color(0xFF4A90E2) : Colors.white,
            size: 20,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.comicNeue(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildNamePage() {
  return LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight - 40, // Account for padding
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(flex: 1),
                ScaleTransition(
                  scale: _cardScaleAnimation,
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  "What's your name?",
                  style: GoogleFonts.comicNeue(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  "We'll use this to personalize your JEE preparation journey",
                  style: GoogleFonts.comicNeue(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    style: GoogleFonts.comicNeue(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter your full name",
                      hintStyle: GoogleFonts.comicNeue(
                        color: Colors.white.withOpacity(0.6),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(24),
                      prefixIcon: Container(
                        margin: EdgeInsets.all(12),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? "Please enter your name"
                        : null,
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                Spacer(flex: 1),
                SizedBox(height: 20), // Minimum bottom spacing
              ],
            ),
          ),
        ),
      );
    },
  );
}


  Widget _buildClassPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        children: [
          SizedBox(height: 20),
          ScaleTransition(
            scale: _cardScaleAnimation,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Icon(
                Icons.school_outlined,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 32),
          Text(
            "What's your current class?",
            style: GoogleFonts.comicNeue(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            "This helps us customize your preparation plan",
            style: GoogleFonts.comicNeue(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 48),
          ...classes.map((classItem) => _buildEnhancedOptionCard(
            title: classItem['title'],
            subtitle: classItem['subtitle'],
            icon: classItem['icon'],
            gradient: classItem['gradient'],
            isSelected: selectedClass == classItem['value'],
            onTap: () {
              setState(() => selectedClass = classItem['value']);
              HapticFeedback.lightImpact();
            },
          )),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildYearPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        children: [
          SizedBox(height: 20),
          ScaleTransition(
            scale: _cardScaleAnimation,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 32),
          Text(
            "JEE appearing year?",
            style: GoogleFonts.comicNeue(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            "When are you planning to take the JEE exam?",
            style: GoogleFonts.comicNeue(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 48),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
            ),
            itemCount: years.length,
            itemBuilder: (context, index) {
              return _buildEnhancedYearChip(years[index]);
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGoalPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        children: [
          SizedBox(height: 20),
          ScaleTransition(
            scale: _cardScaleAnimation,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Icon(
                Icons.flag_outlined,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 32),
          Text(
            "What's your goal?",
            style: GoogleFonts.comicNeue(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            "Choose your target to get personalized guidance",
            style: GoogleFonts.comicNeue(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 48),
          ...goals.map((goal) => _buildEnhancedOptionCard(
            title: goal['title'],
            subtitle: goal['subtitle'],
            icon: goal['icon'],
            gradient: goal['gradient'],
            isSelected: selectedGoal == goal['value'],
            onTap: () {
              setState(() => selectedGoal = goal['value']);
              HapticFeedback.lightImpact();
            },
          )),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEnhancedOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: gradient)
                : LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05)
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ] : [],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon, 
                  color: Colors.white, 
                  size: 28,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.comicNeue(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.comicNeue(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedScale(
                scale: isSelected ? 1.0 : 0.0,
                duration: Duration(milliseconds: 200),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: gradient[0],
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedYearChip(String year) {
    final isSelected = selectedYear == year;
    return GestureDetector(
      onTap: () {
        setState(() => selectedYear = year);
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05)
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Color(0xFF4A90E2).withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ] : [],
        ),
        child: Center(
          child: Text(
            year,
            style: GoogleFonts.comicNeue(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: Container(
                height: 56,
                child: ElevatedButton(
                  onPressed: _previousPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_ios, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Previous',
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_currentPage > 0) SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              height: 56,
              child: ElevatedButton(
                onPressed: _canProceed()
                    ? (_currentPage == 3 ? saveUserInfo : _nextPage)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF4A90E2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: Colors.white.withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentPage == 3 ? 'Complete Setup' : 'Next',
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      _currentPage == 3 ? Icons.check : Icons.arrow_forward_ios,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
