// feedback-screen.dart
// ignore_for_file: use_super_parameters, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:jeezy/main.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:math' as math;

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _feedbackFocus = FocusNode();
  final FocusNode _subjectFocus = FocusNode();
  
  String? _selectedCategory;
  String? _selectedPriority;
  int _selectedRating = 0;
  String _userEmail = "";
  bool _isLoading = false;
  bool _includeDeviceInfo = true;
  bool _allowFollowUp = true;
  bool _isAnonymous = false;
  List<File> _attachedImages = [];
  List<String> _selectedTags = [];
  
  late AnimationController _animationController;
  late AnimationController _submitController;
  late AnimationController _ratingController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _shakeAnimation;

  final List<Map<String, dynamic>> _categories = [
    {"name": "Bug Report", "icon": Icons.bug_report, "color": Colors.red, "description": "Report crashes, errors, or unexpected behavior"},
    {"name": "Feature Request", "icon": Icons.lightbulb, "color": Colors.blue, "description": "Suggest new features or improvements"},
    {"name": "General Feedback", "icon": Icons.feedback, "color": Colors.green, "description": "Share your overall experience"},
    {"name": "UI/UX Improvement", "icon": Icons.design_services, "color": Colors.purple, "description": "Suggest design or usability improvements"},
    {"name": "Performance Issue", "icon": Icons.speed, "color": Colors.orange, "description": "Report slow loading or lag issues"},
    {"name": "Content Issue", "icon": Icons.content_copy, "color": Colors.teal, "description": "Report incorrect or missing content"},
    {"name": "Accessibility", "icon": Icons.accessibility, "color": Colors.indigo, "description": "Suggest accessibility improvements"},
    {"name": "Security Concern", "icon": Icons.security, "color": Colors.deepOrange, "description": "Report security vulnerabilities"},
    {"name": "Other", "icon": Icons.help, "color": Colors.grey, "description": "Something else not covered above"}
  ];

  final List<Map<String, dynamic>> _priorities = [
    {"name": "Low", "color": Colors.green, "icon": Icons.low_priority},
    {"name": "Medium", "color": Colors.orange, "icon": Icons.remove},
    {"name": "High", "color": Colors.red, "icon": Icons.priority_high},
    {"name": "Critical", "color": Colors.deepPurple, "icon": Icons.warning}
  ];

  final List<String> _availableTags = [
  // Core Issues (Most Common)
  "Bug", "Crash", "Slow Performance", "Login Issue", "Loading Problem",
  
  // Platform Specific
  "Mobile", "Web", "Android", "iOS",
  
  // UI/UX (Very Common)
  "Dark Mode", "Light Mode", "Navigation", "UI Design", "Accessibility",
  
  // Features (JEE App Specific)
  "Questions", "Test", "Practice", "Results", "PDF Viewer", "Search",
  
  // Technical Issues
  "Sync Problem", "Offline Mode", "Network Error", "Payment Issue",
  
  // User Experience
  "Animation", "Notification", "Settings", "Tutorial",
  
  // Feedback Types
  "Feature Request", "Improvement", "Content Error", "General Feedback"
];


  final List<String> _ratingLabels = [
    "Terrible",
    "Poor", 
    "Fair",
    "Good",
    "Excellent"
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _initializeAnimations();
    _feedbackController.addListener(_onFeedbackChanged);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _submitController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _ratingController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: Duration(milliseconds: 500),
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
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _ratingController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _submitController,
      curve: Curves.easeInOut,
    ));
    
    _shakeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0.1, 0),
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _feedbackFocus.dispose();
    _subjectFocus.dispose();
    _animationController.dispose();
    _submitController.dispose();
    _ratingController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onFeedbackChanged() {
    setState(() {}); // Update character count
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (mounted) {
          setState(() {
            _userEmail = snapshot.data()?['email'] ?? user.email ?? "";
            _nameController.text = snapshot.data()?['display_name'] ?? user.displayName ?? "";
            _emailController.text = _userEmail;
          });
        }
      } catch (e) {
        print('Error loading user info: $e');
      }
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty && images.length <= 5) {
      setState(() {
        _attachedImages = images.map((xfile) => File(xfile.path)).toList();
      });
      _showSnackBar('${images.length} image(s) attached', Colors.green);
    } else if (images.length > 5) {
      _showSnackBar('Maximum 5 images allowed', Colors.orange);
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    
    for (File image in _attachedImages) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('feedback_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        await ref.putFile(image);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
    
    return imageUrls;
  }

  Future<void> _sendFeedback() async {
    if (!_formKey.currentState!.validate()) {
      _shakeController.forward().then((_) => _shakeController.reverse());
      _showSnackBar('Please fill in all required fields', Colors.red);
      return;
    }

    if (_selectedCategory == null) {
      _showSnackBar('Please select a feedback category', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _submitController.forward();

    try {
      // Upload images first
      List<String> imageUrls = [];
      if (_attachedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
      }
      
      // Save feedback to Firestore only (removed email sending)
      await _saveFeedbackToFirestore(imageUrls);
      
      _showSuccessAnimation();
      _showSnackBar('Feedback sent successfully! Thank you for helping us improve.', Colors.green);
      
      // Clear form after successful submission
      await Future.delayed(Duration(milliseconds: 1500));
      _clearForm();
      
    } catch (e) {
      _showSnackBar('Error sending feedback: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _submitController.reverse();
      }
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 1000),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 80,
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              Text(
                'Feedback Sent!',
                style: GoogleFonts.comicNeue(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Thank you for helping us improve JEEzy',
                style: GoogleFonts.comicNeue(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
    
    Future.delayed(Duration(milliseconds: 2000), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _saveFeedbackToFirestore(List<String> imageUrls) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final feedbackData = {
      'userId': _isAnonymous ? 'anonymous' : user.uid,
      'name': _isAnonymous ? 'Anonymous' : (_nameController.text.trim().isEmpty ? 'Anonymous' : _nameController.text.trim()),
      'email': _isAnonymous ? '' : _emailController.text.trim(),
      'subject': _subjectController.text.trim(),
      'category': _selectedCategory ?? 'General Feedback',
      'priority': _selectedPriority ?? 'Medium',
      'rating': _selectedRating,
      'feedback': _feedbackController.text.trim(),
      'tags': _selectedTags,
      'includeDeviceInfo': _includeDeviceInfo,
      'allowFollowUp': _allowFollowUp,
      'isAnonymous': _isAnonymous,
      'attachedImages': imageUrls,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'deviceInfo': _includeDeviceInfo ? await _getDeviceInfo() : null,
      'appVersion': '1.0.0',
      'platform': Theme.of(context).platform.toString(),
      'resolved': false,
      'adminNotes': '',
      'resolvedAt': null,
      'resolvedBy': null,
    };

    await FirebaseFirestore.instance.collection('feedback').add(feedbackData);
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    return {
      'platform': Theme.of(context).platform.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'locale': Localizations.localeOf(context).toString(),
      'brightness': Theme.of(context).brightness.toString(),
    };
  }

  void _clearForm() {
    _feedbackController.clear();
    _nameController.clear();
    _emailController.clear();
    _subjectController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedPriority = null;
      _selectedRating = 0;
      _selectedTags.clear();
      _attachedImages.clear();
      _includeDeviceInfo = true;
      _allowFollowUp = true;
      _isAnonymous = false;
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : 
              color == Colors.red ? Icons.error : Icons.info,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.comicNeue(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
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
        final theme = Theme.of(context);
        
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          resizeToAvoidBottomInset: true,
          body: SafeArea( // FIXED: Add SafeArea to prevent overflow
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(isDark, theme),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SlideTransition(
                        position: _shakeAnimation,
                        child: Padding( // FIXED: Use Padding instead of SingleChildScrollView
                          padding: EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildWelcomeCard(isDark, theme),
                                SizedBox(height: 24),
                                _buildRatingSection(isDark, theme),
                                SizedBox(height: 24),
                                _buildCategorySection(isDark, theme),
                                SizedBox(height: 24),
                                _buildPrioritySection(isDark, theme),
                                SizedBox(height: 24),
                                _buildSubjectSection(isDark, theme),
                                SizedBox(height: 24),
                                _buildUserInfoSection(isDark, theme),
                                SizedBox(height: 24),
                                _buildFeedbackSection(isDark, theme),
                                SizedBox(height: 24),
                                _buildTagsSection(isDark, theme),
                                SizedBox(height: 24),
                                _buildAttachmentSection(isDark, theme),
                                SizedBox(height: 24),
                                _buildOptionsSection(isDark, theme),
                                SizedBox(height: 32),
                                _buildSubmitButton(isDark, theme),
                                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 40), // FIXED: Dynamic bottom padding for keyboard
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildSliverAppBar(bool isDark, ThemeData theme) {
  return SliverAppBar(
    expandedHeight: 200,
    floating: false,
    pinned: true,
    elevation: 0,
    centerTitle: false, // Left align when collapsed
    backgroundColor: isDark ? Color(0xFFF06292) : theme.colorScheme.primary,
    // FIXED: Remove title from here to avoid double titles
    flexibleSpace: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double collapseRatio =
            (constraints.maxHeight - kToolbarHeight) / (200 - kToolbarHeight);
        
        // FIXED: Show title only in FlexibleSpaceBar to avoid duplication
        return FlexibleSpaceBar(
          centerTitle: collapseRatio > 0.5, // Center when expanded, left when collapsed
          title: Text(
            "Send Feedback",
            style: GoogleFonts.comicNeue(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark ? [
                  theme.colorScheme.primary.withBlue(150),
                  theme.colorScheme.secondary.withBlue(100),
                ] : [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary.withGreen(50),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 40),
                      Icon(
                        Icons.feedback,
                        color: Colors.white,
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'We Value Your Input',
                        style: GoogleFonts.comicNeue(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
    actions: [
      IconButton(
        icon: Icon(Icons.help_outline, color: Colors.white),
        onPressed: () => _showHelpDialog(context, isDark),
      ),
      IconButton(
        icon: Icon(Icons.history, color: Colors.white),
        onPressed: () => _showFeedbackHistory(context, isDark),
      ),
    ],
  );
}



  Widget _buildWelcomeCard(bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.favorite,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Help Us Improve JEEzy!',
                      style: GoogleFonts.comicNeue(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your feedback drives our innovation and helps create a better learning experience',
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
          SizedBox(height: 16),
          // Real-time stats
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('feedback').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Row(
                  children: [
                    _buildQuickStat('📊', 'Loading...', '...'),
                    SizedBox(width: 16),
                    _buildQuickStat('⚡', 'Loading...', '...'),
                    SizedBox(width: 16),
                    _buildQuickStat('🎯', 'Loading...', '...'),
                  ],
                );
              }
              
              final docs = snapshot.data!.docs;
              final totalFeedback = docs.length;
              final resolvedFeedback = docs.where((doc) => 
                (doc.data() as Map<String, dynamic>)['resolved'] == true
              ).length;
              final avgRating = docs.isEmpty ? 0.0 : docs
                  .map((doc) => (doc.data() as Map<String, dynamic>)['rating'] ?? 0)
                  .where((rating) => rating > 0)
                  .fold(0.0, (sum, rating) => sum + rating) / 
                  docs.where((doc) => (doc.data() as Map<String, dynamic>)['rating'] != null && 
                                     (doc.data() as Map<String, dynamic>)['rating'] > 0).length;
              
              final resolvedPercentage = totalFeedback > 0 ? ((resolvedFeedback / totalFeedback) * 100).toInt() : 0;
              
              return Row(
                children: [
                  _buildQuickStat('📊', 'Total Feedback', totalFeedback.toString()),
                  SizedBox(width: 16),
                  _buildQuickStat('⚡', 'Avg Response', '24h'),
                  SizedBox(width: 16),
                  _buildQuickStat('🎯', 'Resolved', '$resolvedPercentage%'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String emoji, String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 20)),
            SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.comicNeue(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildRatingSection(bool isDark, ThemeData theme) {
    return Container(
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
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.star_rate, color: Colors.amber),
              ),
              SizedBox(width: 12),
              Text(
                'Rate Your Experience',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = index + 1;
                  });
                  _ratingController.forward().then((_) => _ratingController.reverse());
                  HapticFeedback.lightImpact();
                },
                child: ScaleTransition(
                  scale: _selectedRating == index + 1 ? _scaleAnimation : 
                         Tween<double>(begin: 1.0, end: 1.0).animate(_ratingController),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: index < _selectedRating 
                          ? Colors.amber.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.star,
                      size: 32,
                      color: index < _selectedRating
                          ? Colors.amber
                          : (isDark ? Colors.white38 : Colors.grey.shade300),
                    ),
                  ),
                ),
              );
            }),
          ),
          if (_selectedRating > 0) ...[
            SizedBox(height: 12),
            Center(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(_selectedRating),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getRatingColor(_selectedRating).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _ratingLabels[_selectedRating - 1],
                    style: GoogleFonts.comicNeue(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _getRatingColor(_selectedRating),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.yellow.shade700;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green;
      default: return Colors.grey;
    }
  }

  Widget _buildCategorySection(bool isDark, ThemeData theme) {
    return Container(
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
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.category, color: theme.colorScheme.primary),
              ),
              SizedBox(width: 12),
              Text(
                'Feedback Category *',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Fixed grid with proper constraints
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
              final childAspectRatio = constraints.maxWidth > 600 ? 2.8 : 2.2;
              
              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category['name'];
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category['name'];
                      });
                      HapticFeedback.lightImpact();
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? category['color'].withOpacity(0.2)
                            : (isDark ? Colors.white12 : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? category['color']
                              : (isDark ? Colors.white24 : Colors.grey.shade300),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            category['icon'],
                            size: 18,
                            color: isSelected
                                ? category['color']
                                : (isDark ? Colors.white70 : Colors.grey.shade600),
                          ),
                          SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              category['name'],
                              style: GoogleFonts.comicNeue(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? category['color']
                                    : (isDark ? Colors.white70 : Colors.grey.shade700),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_selectedCategory != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _categories.firstWhere((c) => c['name'] == _selectedCategory)['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _categories.firstWhere((c) => c['name'] == _selectedCategory)['description'],
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrioritySection(bool isDark, ThemeData theme) {
    return Container(
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
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.flag, color: theme.colorScheme.primary),
              ),
              SizedBox(width: 12),
              Text(
                'Priority Level',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: _priorities.map((priority) {
              final isSelected = _selectedPriority == priority['name'];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPriority = priority['name'];
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? priority['color'].withOpacity(0.2)
                          : (isDark ? Colors.white12 : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? priority['color']
                            : (isDark ? Colors.white24 : Colors.grey.shade300),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          priority['icon'],
                          size: 20,
                          color: isSelected
                              ? priority['color']
                              : (isDark ? Colors.white70 : Colors.grey.shade600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          priority['name'],
                          style: GoogleFonts.comicNeue(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? priority['color']
                                : (isDark ? Colors.white70 : Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSection(bool isDark, ThemeData theme) {
    return Container(
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
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.subject, color: theme.colorScheme.primary),
              ),
              SizedBox(width: 12),
              Text(
                'Subject',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _subjectController,
            focusNode: _subjectFocus,
            style: GoogleFonts.comicNeue(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Brief summary of your feedback',
              hintStyle: GoogleFonts.comicNeue(),
              prefixIcon: Icon(Icons.title),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
            ),
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _nameFocus.requestFocus(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(bool isDark, ThemeData theme) {
    return Container(
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
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.person, color: theme.colorScheme.primary),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Contact Information',
                    style: GoogleFonts.comicNeue(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Anonymous',
                    style: GoogleFonts.comicNeue(fontSize: 12),
                  ),
                  Switch(
                    value: _isAnonymous,
                    onChanged: (value) {
                      setState(() {
                        _isAnonymous = value;
                        if (value) {
                          _nameController.clear();
                          _emailController.clear();
                          _allowFollowUp = false;
                        }
                      });
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
          if (!_isAnonymous) ...[
            SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              focusNode: _nameFocus,
              style: GoogleFonts.comicNeue(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Your Name (Optional)',
                labelStyle: GoogleFonts.comicNeue(),
                hintText: 'Enter your name',
                hintStyle: GoogleFonts.comicNeue(),
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _emailFocus.requestFocus(),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocus,
              style: GoogleFonts.comicNeue(fontSize: 16),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address (Optional)',
                labelStyle: GoogleFonts.comicNeue(),
                hintText: 'Enter your email',
                hintStyle: GoogleFonts.comicNeue(),
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _feedbackFocus.requestFocus(),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                }
                return null;
              },
            ),
          ] else ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.privacy_tip, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your feedback will be submitted anonymously. We won\'t be able to follow up with you.',
                      style: GoogleFonts.comicNeue(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(bool isDark, ThemeData theme) {
    final characterCount = _feedbackController.text.length;
    final maxCharacters = 1000;
    
    return Container(
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
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.message, color: theme.colorScheme.primary),
              ),
              SizedBox(width: 12),
              Text(
                'Your Feedback *',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _feedbackController,
            focusNode: _feedbackFocus,
            style: GoogleFonts.comicNeue(fontSize: 16),
            maxLines: 6,
            maxLength: maxCharacters,
            decoration: InputDecoration(
              hintText: 'Tell us about your experience, suggestions, or report any issues...\n\nBe as detailed as possible to help us understand and address your feedback effectively.',
              hintStyle: GoogleFonts.comicNeue(
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
              errorStyle: GoogleFonts.comicNeue(fontSize: 13),
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Feedback is required";
              }
              if (value.trim().length < 10) {
                return "Please provide more detailed feedback (at least 10 characters)";
              }
              return null;
            },
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Characters: $characterCount/$maxCharacters',
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  color: characterCount > maxCharacters * 0.8 
                      ? Colors.orange 
                      : (isDark ? Colors.white54 : Colors.grey.shade600),
                ),
              ),
              if (characterCount >= 50)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Good detail!',
                    style: GoogleFonts.comicNeue(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(bool isDark, ThemeData theme) {
    return Container(
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
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.label, color: theme.colorScheme.primary),
              ),
              SizedBox(width: 12),
              Text(
                'Tags (Optional)',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Select relevant tags to help us categorize your feedback',
            style: GoogleFonts.comicNeue(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTags.remove(tag);
                    } else {
                      _selectedTags.add(tag);
                    }
                  });
                  HapticFeedback.lightImpact();
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.2)
                        : (isDark ? Colors.white12 : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark ? Colors.white24 : Colors.grey.shade300),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.comicNeue(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark ? Colors.white70 : Colors.grey.shade700),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedTags.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              'Selected: ${_selectedTags.join(', ')}',
              style: GoogleFonts.comicNeue(
                fontSize: 12,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentSection(bool isDark, ThemeData theme) {
    return Container(
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
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.attach_file, color: theme.colorScheme.primary),
              ),
              SizedBox(width: 12),
              Text(
                'Attachments (Optional)',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Add screenshots or images to help explain your feedback (Max 5 images)',
            style: GoogleFonts.comicNeue(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.primary.withOpacity(0.05),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap to select images',
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'PNG, JPG up to 10MB each',
                    style: GoogleFonts.comicNeue(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_attachedImages.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              'Attached Images (${_attachedImages.length})',
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 8),
            Container(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _attachedImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _attachedImages[index],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _attachedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionsSection(bool isDark, ThemeData theme) {
    return Container(
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
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.settings, color: theme.colorScheme.primary),
              ),
              SizedBox(width: 12),
              Text(
                'Additional Options',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              'Include Device Information',
              style: GoogleFonts.comicNeue(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Help us debug issues by including basic device info',
              style: GoogleFonts.comicNeue(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
            value: _includeDeviceInfo,
            onChanged: (value) {
              setState(() {
                _includeDeviceInfo = value;
              });
            },
            activeColor: theme.colorScheme.primary,
          ),
          if (!_isAnonymous)
            SwitchListTile(
              title: Text(
                'Allow Follow-up Contact',
                style: GoogleFonts.comicNeue(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'We may contact you for clarification or updates',
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
              value: _allowFollowUp,
              onChanged: (value) {
                setState(() {
                  _allowFollowUp = value;
                });
              },
              activeColor: theme.colorScheme.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isDark, ThemeData theme) {
    return RotationTransition(
      turns: _rotationAnimation,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _sendFeedback,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: _isLoading ? 0 : 4,
          ),
          child: _isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Sending Feedback...',
                      style: GoogleFonts.comicNeue(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Send Feedback',
                      style: GoogleFonts.comicNeue(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showFeedbackHistory(BuildContext context, bool isDark) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        constraints: BoxConstraints(
          maxWidth: 600, // Maximum width for larger screens
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          minHeight: 300, // Minimum height
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // FIXED: Prevent column from taking full height
          children: [
            // FIXED: Header with proper padding and constraints
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
                  SizedBox(width: 8),
                  Expanded( // FIXED: Wrap text in Expanded to prevent overflow
                    child: Text(
                      'Your Feedback History',
                      style: GoogleFonts.comicNeue(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis, // FIXED: Handle text overflow
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // FIXED: Expanded ListView with proper constraints
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('feedback')
                    .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                    .orderBy('timestamp', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading feedback history...',
                            style: GoogleFonts.comicNeue(fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.red),
                            SizedBox(height: 16),
                            Text(
                              'Error loading feedback history',
                              style: GoogleFonts.comicNeue(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Flexible( // FIXED: Use Flexible for error text
                              child: Text(
                                snapshot.error.toString(),
                                style: GoogleFonts.comicNeue(
                                  fontSize: 12, 
                                  color: Colors.grey
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 3,
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Close'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.feedback_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No feedback history yet',
                              style: GoogleFonts.comicNeue(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Your submitted feedback will appear here',
                              style: GoogleFonts.comicNeue(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  // FIXED: Proper ListView with constraints
                  return ListView.builder(
                    padding: EdgeInsets.all(16), // FIXED: Add padding to ListView
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final feedback = doc.data() as Map<String, dynamic>;
                      final timestamp = feedback['timestamp'] as Timestamp?;
                      final date = timestamp?.toDate() ?? DateTime.now();
                      final isResolved = feedback['resolved'] == true;
                      
                      return Container( // FIXED: Wrap in Container for better control
                        margin: EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // FIXED: Status row with proper constraints
                                Row(
                                  children: [
                                    Flexible( // FIXED: Use Flexible instead of fixed containers
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(feedback['category']).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          feedback['category'] ?? 'General',
                                          style: GoogleFonts.comicNeue(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _getCategoryColor(feedback['category']),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Flexible( // FIXED: Use Flexible for status
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isResolved ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isResolved ? Icons.check_circle : Icons.pending,
                                              size: 12,
                                              color: isResolved ? Colors.green : Colors.orange,
                                            ),
                                            SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                isResolved ? 'Resolved' : 'Pending',
                                                style: GoogleFonts.comicNeue(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isResolved ? Colors.green : Colors.orange,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Spacer(),
                                    Flexible( // FIXED: Use Flexible for priority
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getPriorityColor(feedback['priority']).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          feedback['priority'] ?? 'Medium',
                                          style: GoogleFonts.comicNeue(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _getPriorityColor(feedback['priority']),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                // FIXED: Subject with proper overflow handling
                                Text(
                                  feedback['subject'] ?? 'No subject',
                                  style: GoogleFonts.comicNeue(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2, // FIXED: Allow 2 lines for subject
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                // FIXED: Feedback content with proper constraints
                                Text(
                                  feedback['feedback'] ?? '',
                                  style: GoogleFonts.comicNeue(fontSize: 14),
                                  maxLines: 3, // FIXED: Allow 3 lines for content
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // FIXED: Admin notes with proper constraints
                                if (feedback['adminNotes'] != null && feedback['adminNotes'].isNotEmpty) ...[
                                  SizedBox(height: 8),
                                  Container(
                                    width: double.infinity, // FIXED: Ensure container takes full width
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Admin Response:',
                                          style: GoogleFonts.comicNeue(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          feedback['adminNotes'],
                                          style: GoogleFonts.comicNeue(
                                            fontSize: 12,
                                            color: Colors.blue.shade700,
                                          ),
                                          maxLines: 3, // FIXED: Limit admin notes lines
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                SizedBox(height: 8),
                                // FIXED: Bottom row with proper constraints
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Expanded( // FIXED: Use Expanded for date
                                      child: Text(
                                        _formatDate(date),
                                        style: GoogleFonts.comicNeue(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (feedback['rating'] != null && feedback['rating'] > 0) ...[
                                      SizedBox(width: 8),
                                      // FIXED: Rating stars with proper constraints
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: List.generate(
                                          math.min(5, feedback['rating'] as int), // FIXED: Ensure max 5 stars
                                          (starIndex) {
                                            return Icon(
                                              Icons.star,
                                              size: 16,
                                              color: starIndex < feedback['rating']
                                                  ? Colors.amber
                                                  : Colors.grey.shade300,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Color _getCategoryColor(String? category) {
    final categoryData = _categories.firstWhere(
      (c) => c['name'] == category,
      orElse: () => _categories.last,
    );
    return categoryData['color'] as Color;
  }

  Color _getPriorityColor(String? priority) {
    final priorityData = _priorities.firstWhere(
      (p) => p['name'] == priority,
      orElse: () => _priorities[1], // Default to Medium
    );
    return priorityData['color'] as Color;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showHelpDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Text(
              'Feedback Help',
              style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to provide effective feedback:',
                style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              _buildHelpItem('🐛', 'Bug Reports', 'Describe what happened, what you expected, and steps to reproduce'),
              _buildHelpItem('💡', 'Feature Requests', 'Explain the feature and how it would help you'),
              _buildHelpItem('🎨', 'UI/UX Issues', 'Include screenshots and describe the problem'),
              _buildHelpItem('⚡', 'Performance', 'Mention device model and specific slow areas'),
              _buildHelpItem('🔒', 'Security', 'Report vulnerabilities responsibly'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: The more specific you are, the better we can help!',
                        style: GoogleFonts.comicNeue(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it!',
              style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String emoji, String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
