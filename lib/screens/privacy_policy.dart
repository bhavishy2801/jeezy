// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:jeezy/main.dart';
import 'dart:async';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> 
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  int _expandedSection = -1;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Debouncer for search
  Timer? _debouncer;
  String _debouncedSearchQuery = '';
  
  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late AnimationController _searchAnimationController;
  late AnimationController _sectionAnimationController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _searchAnimation;
  late Animation<double> _searchBarSlideAnimation;
  
  // Search focus node
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  final List<Map<String, dynamic>> _sections = [
    {
      'title': '1. Information We Collect',
      'icon': Icons.info_outline,
      'color': Colors.blue,
      'content': [
        {
          'subtitle': 'Personal Information',
          'text': 'We collect your name, email, class, board, and JEE appearing year during signup or profile editing to personalize your experience and provide targeted study recommendations.'
        },
        {
          'subtitle': 'Academic Data',
          'text': 'Your test scores, practice session data, subject preferences, and study patterns are collected to generate personalized analytics and improvement suggestions.'
        },
        {
          'subtitle': 'AI Mentor Interactions',
          'text': 'Your questions, responses, and interactions with our AI features are processed securely to generate personalized preparation strategies and study plans.'
        },
        {
          'subtitle': 'Device & Usage Analytics',
          'text': 'We collect anonymized device information, app usage patterns, and performance metrics to optimize the app experience and fix technical issues.'
        },
        {
          'subtitle': 'Study Materials Access',
          'text': 'Information about which study materials you access, download, or bookmark is collected to recommend relevant content and track your progress.'
        }
      ]
    },
    {
      'title': '2. How We Use Your Information',
      'icon': Icons.settings_applications,
      'color': Colors.green,
      'content': [
        {
          'subtitle': 'Personalized Learning Experience',
          'text': 'To customize your app experience, provide relevant study recommendations, and create adaptive learning paths based on your performance and preferences.'
        },
        {
          'subtitle': 'AI-Powered Study Assistant',
          'text': 'To power our AI Mentor functionality, generate intelligent study assistance, and provide personalized doubt resolution and concept explanations.'
        },
        {
          'subtitle': 'Progress Tracking & Analytics',
          'text': 'To track your study progress, generate detailed performance analytics, identify weak areas, and suggest improvement strategies.'
        },
        {
          'subtitle': 'Content Recommendation',
          'text': 'To recommend relevant study materials, practice tests, and learning resources based on your academic profile and study patterns.'
        },
        {
          'subtitle': 'Cross-Device Synchronization',
          'text': 'To store and sync your data securely across devices using Firebase Firestore, ensuring seamless access to your study materials and progress.'
        }
      ]
    },
    {
      'title': '3. Data Sharing and Storage',
      'icon': Icons.cloud_outlined,
      'color': Colors.orange,
      'content': [
        {
          'subtitle': 'No Third-Party Selling',
          'text': 'We never sell or share your personal data with third-party advertisers, marketing companies, or unauthorized entities. Your data is exclusively used to improve your learning experience.'
        },
        {
          'subtitle': 'Secure Cloud Storage',
          'text': 'Your data is securely stored using Google Firebase services with industry-standard AES-256 encryption and multi-factor authentication protection.'
        },
        {
          'subtitle': 'Educational Partners',
          'text': 'Anonymized, aggregated data may be shared with educational institutions and research organizations to improve JEE preparation methodologies and curriculum development.'
        },
        {
          'subtitle': 'Global Data Centers',
          'text': 'Your data is stored in secure Google Cloud servers with global redundancy, automatic backups, and 99.9% uptime guarantee for reliable access.'
        },
        {
          'subtitle': 'AI Model Training',
          'text': 'Anonymized study patterns and question-answer data may be used to improve our AI models, ensuring better doubt resolution and personalized recommendations.'
        }
      ]
    },
    {
      'title': '4. Data Security & Protection',
      'icon': Icons.security,
      'color': Colors.red,
      'content': [
        {
          'subtitle': 'End-to-End Encryption',
          'text': 'We use industry-standard AES-256 encryption for data transmission and storage, ensuring your information remains secure during transfer and at rest.'
        },
        {
          'subtitle': 'Multi-Factor Authentication',
          'text': 'Secure authentication via Firebase with optional 2FA ensures only authorized access to your account and study data.'
        },
        {
          'subtitle': 'Access Control & Monitoring',
          'text': 'Your data is only accessible to authorized services and personnel on a need-to-know basis, with comprehensive audit logs and real-time monitoring.'
        },
        {
          'subtitle': 'Regular Security Audits',
          'text': 'We conduct quarterly security audits, penetration testing, and vulnerability assessments to maintain the highest security standards.'
        },
        {
          'subtitle': 'Data Breach Response',
          'text': 'In the unlikely event of a data breach, we have a comprehensive response plan and will notify affected users within 72 hours as required by law.'
        }
      ]
    },
    {
      'title': '5. Your Rights and Control',
      'icon': Icons.account_circle_outlined,
      'color': Colors.purple,
      'content': [
        {
          'subtitle': 'Complete Data Control',
          'text': 'You can view, update, export, or permanently delete your profile data anytime from within the app settings with immediate effect.'
        },
        {
          'subtitle': 'Feature Opt-out Options',
          'text': 'You can selectively disable features like AI Mentor, analytics tracking, or personalized recommendations while maintaining core app functionality.'
        },
        {
          'subtitle': 'Account Deletion Rights',
          'text': 'You have the right to permanently delete your account and all associated data, which will be completely removed from our servers within 30 days.'
        },
        {
          'subtitle': 'Data Portability',
          'text': 'You can request a complete copy of your data in JSON or CSV format, including study history, test scores, and AI interaction logs.'
        },
        {
          'subtitle': 'Consent Management',
          'text': 'You can withdraw or modify your consent for specific data processing activities at any time through the privacy settings in the app.'
        }
      ]
    },
    {
      'title': '6. Cookies and Tracking',
      'icon': Icons.track_changes,
      'color': Colors.teal,
      'content': [
        {
          'subtitle': 'Essential Cookies Only',
          'text': 'We use only essential cookies for authentication, session management, and core app functionality. No advertising or tracking cookies are used.'
        },
        {
          'subtitle': 'Anonymous Analytics',
          'text': 'Anonymous usage analytics help us understand user behavior patterns and improve the app experience without identifying individual users.'
        },
        {
          'subtitle': 'Local Preferences Storage',
          'text': 'We store your app preferences, theme settings, and customization choices locally on your device to enhance your user experience.'
        },
        {
          'subtitle': 'Performance Monitoring',
          'text': 'We collect anonymous performance metrics to identify and fix technical issues, ensuring optimal app performance for all users.'
        }
      ]
    },
    {
      'title': '7. Student Privacy Protection',
      'icon': Icons.child_care,
      'color': Colors.pink,
      'content': [
        {
          'subtitle': 'Age-Appropriate Design',
          'text': 'Our app is designed specifically for JEE aspirants (typically 16-19 years) with age-appropriate content and enhanced privacy protections for younger users.'
        },
        {
          'subtitle': 'Parental Consent Framework',
          'text': 'Users under 18 are encouraged to have parental consent, and we provide clear information to parents about data collection and usage practices.'
        },
        {
          'subtitle': 'Educational Data Protection',
          'text': 'We comply with educational privacy laws and take extra care to protect student academic data, ensuring it\'s used solely for educational purposes.'
        },
        {
          'subtitle': 'No Targeted Advertising',
          'text': 'We never show targeted advertisements to students or use their data for commercial purposes beyond improving the educational experience.'
        }
      ]
    },
    {
      'title': '8. AI and Machine Learning',
      'icon': Icons.psychology,
      'color': Colors.deepOrange,
      'content': [
        {
          'subtitle': 'AI Model Transparency',
          'text': 'Our AI Mentor uses advanced natural language processing to provide study assistance. All AI responses are generated based on educational content and your study patterns.'
        },
        {
          'subtitle': 'Algorithmic Fairness',
          'text': 'We ensure our recommendation algorithms are fair and unbiased, providing equal opportunities for all students regardless of background or performance level.'
        },
        {
          'subtitle': 'Human Oversight',
          'text': 'All AI-generated content and recommendations are subject to human review and educational expert validation to ensure accuracy and appropriateness.'
        },
        {
          'subtitle': 'Continuous Improvement',
          'text': 'We continuously improve our AI models using anonymized data to provide better study assistance while maintaining strict privacy standards.'
        }
      ]
    },
    {
      'title': '9. Policy Updates and Changes',
      'icon': Icons.update,
      'color': const Color.fromARGB(255, 136, 154, 255),
      'content': [
        {
          'subtitle': 'Regular Policy Reviews',
          'text': 'We review and update this policy quarterly to reflect changes in our practices, new features, or evolving privacy regulations.'
        },
        {
          'subtitle': 'User Notification System',
          'text': 'Users will be notified of significant changes through in-app notifications, email alerts, and prominent notices on the app dashboard.'
        },
        {
          'subtitle': 'Granular Consent Updates',
          'text': 'For material changes affecting data usage, we will seek renewed consent and provide clear explanations of what has changed and why.'
        },
        {
          'subtitle': 'Version History',
          'text': 'We maintain a complete history of policy versions, allowing users to review previous versions and understand how our practices have evolved.'
        }
      ]
    }
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _setupSearchListener();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _searchAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _sectionAnimationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _searchAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _searchBarSlideAnimation = Tween<double>(
      begin: -100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showScrollToTop) {
        setState(() => _showScrollToTop = true);
        _fabAnimationController.forward();
      } else if (_scrollController.offset <= 300 && _showScrollToTop) {
        setState(() => _showScrollToTop = false);
        _fabAnimationController.reverse();
      }
    });
  }

  void _setupSearchListener() {
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    _fabAnimationController.dispose();
    _searchAnimationController.dispose();
    _sectionAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debouncer?.cancel();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
    );
    HapticFeedback.lightImpact();
  }

  void _toggleSearch() {
    if (_searchAnimation.value == 0) {
      _searchAnimationController.forward();
      Future.delayed(Duration(milliseconds: 200), () {
        _searchFocusNode.requestFocus();
      });
    } else {
      _searchAnimationController.reverse();
      _searchController.clear();
      _searchFocusNode.unfocus();
      setState(() {
        _searchQuery = '';
        _debouncedSearchQuery = '';
      });
    }
    HapticFeedback.lightImpact();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });

    // Debounce search to improve performance
    if (_debouncer?.isActive ?? false) _debouncer!.cancel();
    _debouncer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _debouncedSearchQuery = value;
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _debouncedSearchQuery = '';
    });
    HapticFeedback.lightImpact();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredSections() {
    if (_debouncedSearchQuery.isEmpty) return _sections;
    
    return _sections.where((section) {
      final titleMatch = section['title'].toLowerCase().contains(_debouncedSearchQuery.toLowerCase());
      final contentMatch = (section['content'] as List).any((item) =>
        item['subtitle'].toLowerCase().contains(_debouncedSearchQuery.toLowerCase()) ||
        item['text'].toLowerCase().contains(_debouncedSearchQuery.toLowerCase())
      );
      
      return titleMatch || contentMatch;
    }).toList();
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
            appBar: AppBar(
              elevation: 0,
              backgroundColor: theme.appBarTheme.backgroundColor,
              title: Row(
                children: [
                  Icon(
                    Icons.privacy_tip,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Privacy Policy",
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: theme.appBarTheme.titleTextStyle?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    child: Icon(
                      _searchAnimation.value > 0.5 ? Icons.close : Icons.search,
                      key: ValueKey(_searchAnimation.value > 0.5),
                    ),
                  ),
                  onPressed: _toggleSearch,
                  tooltip: _searchAnimation.value > 0.5 ? 'Close Search' : 'Search Policy',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    HapticFeedback.selectionClick();
                    switch (value) {
                      case 'expand_all':
                        setState(() => _expandedSection = -2);
                        break;
                      case 'collapse_all':
                        setState(() => _expandedSection = -1);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'expand_all',
                      child: Row(
                        children: [
                          Icon(Icons.expand_more, size: 20),
                          SizedBox(width: 8),
                          Text('Expand All'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'collapse_all',
                      child: Row(
                        children: [
                          Icon(Icons.expand_less, size: 20),
                          SizedBox(width: 8),
                          Text('Collapse All'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Enhanced Search Bar
                    AnimatedBuilder(
                      animation: _searchAnimation,
                      builder: (context, child) {
                        return SizeTransition(
                          sizeFactor: _searchAnimation,
                          child: Transform.translate(
                            offset: Offset(0, _searchBarSlideAnimation.value),
                            child: Container(
                              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                              decoration: BoxDecoration(
                                color: isDark ? Color(0xFF1C2542) : Colors.grey.shade50,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _isSearchFocused 
                                            ? theme.colorScheme.primary
                                            : (isDark ? Colors.white24 : Colors.grey.shade300),
                                        width: _isSearchFocused ? 2 : 1,
                                      ),
                                      boxShadow: _isSearchFocused ? [
                                        BoxShadow(
                                          color: theme.colorScheme.primary.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ] : [],
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      focusNode: _searchFocusNode,
                                      onChanged: _onSearchChanged,
                                      style: GoogleFonts.comicNeue(fontSize: 16),
                                      decoration: InputDecoration(
                                        hintText: 'Search privacy policy sections...',
                                        hintStyle: GoogleFonts.comicNeue(
                                          color: isDark ? Colors.white54 : Colors.grey.shade500,
                                        ),
                                        prefixIcon: AnimatedContainer(
                                          duration: Duration(milliseconds: 200),
                                          child: Icon(
                                            Icons.search,
                                            color: _isSearchFocused 
                                                ? theme.colorScheme.primary
                                                : (isDark ? Colors.white54 : Colors.grey.shade500),
                                          ),
                                        ),
                                        suffixIcon: _searchQuery.isNotEmpty
                                            ? IconButton(
                                                icon: Icon(
                                                  Icons.clear,
                                                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                                                ),
                                                onPressed: _clearSearch,
                                                tooltip: 'Clear search',
                                              )
                                            : null,
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        filled: true,
                                        fillColor: isDark ? Color(0xFF2A3441) : Colors.white,
                                      ),
                                    ),
                                  ),
                                  
                                  // Search suggestions/results count
                                  if (_searchQuery.isNotEmpty) ...[
                                    SizedBox(height: 8),
                                    AnimatedOpacity(
                                      opacity: _searchQuery.isNotEmpty ? 1.0 : 0.0,
                                      duration: Duration(milliseconds: 200),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: theme.colorScheme.primary.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.search_outlined,
                                              size: 16,
                                              color: theme.colorScheme.primary,
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Found ${_getFilteredSections().length} section${_getFilteredSections().length != 1 ? 's' : ''} matching "$_searchQuery"',
                                                style: GoogleFonts.comicNeue(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: theme.colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                            if (_searchQuery.isNotEmpty)
                                              GestureDetector(
                                                onTap: _clearSearch,
                                                child: Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: theme.colorScheme.primary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16),
                        child: DefaultTextStyle(
                          style: GoogleFonts.comicNeue(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Section
                              _buildHeader(isDark, theme),
                              
                              SizedBox(height: 32),
                              
                              // Introduction
                              _buildIntroduction(isDark, theme),
                              
                              SizedBox(height: 32),
                              
                              // Sections with improved animations
                              ..._getFilteredSections().asMap().entries.map((entry) {
                                final index = entry.key;
                                final section = entry.value;
                                return _buildSection(section, index, isDark, theme);
                              }),
                              
                              SizedBox(height: 32),
                              
                              // Data Rights Summary
                              _buildDataRightsSummary(isDark, theme),
                              
                              SizedBox(height: 32),
                              
                              // Footer
                              _buildFooter(isDark, theme),
                              
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: _showScrollToTop
                ? ScaleTransition(
                    scale: _fabScaleAnimation,
                    child: FloatingActionButton(
                      onPressed: _scrollToTop,
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(Icons.keyboard_arrow_up, color: Colors.white),
                      tooltip: 'Scroll to top',
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.15),
            theme.colorScheme.secondary.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.shield,
                  color: theme.colorScheme.primary,
                  size: 30,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Privacy Policy for JEEzy",
                      style: GoogleFonts.comicNeue(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Last Updated: June 11, 2025",
                      style: GoogleFonts.comicNeue(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntroduction(bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C2542) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
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
              Icon(Icons.info, color: theme.colorScheme.primary, size: 24),
              SizedBox(width: 12),
              Text(
                "Introduction",
                style: GoogleFonts.comicNeue(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            "Welcome to JEEzy! Your privacy and academic data security are our top priorities. This comprehensive Privacy Policy explains how we collect, use, protect, and respect your information when you use our JEE preparation app. We are committed to transparency, giving you complete control over your data, and ensuring your study journey remains private and secure.",
            style: GoogleFonts.comicNeue(
              fontSize: 16,
              height: 1.7,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(Map<String, dynamic> section, int index, bool isDark, ThemeData theme) {
    final isExpanded = _expandedSection == index || _expandedSection == -2;
    
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C2542) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: section['color'].withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedSection = isExpanded ? -1 : index;
              });
              HapticFeedback.lightImpact();
            },
            child: Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: section['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      section['icon'],
                      color: section['color'],
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      section['title'],
                      style: GoogleFonts.comicNeue(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: section['color'],
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: section['color'],
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Fixed animation container for section content
          ClipRect(
            child: AnimatedAlign(
              duration: Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              heightFactor: isExpanded ? 1.0 : 0.0,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: section['content'].map<Widget>((item) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: section['color'].withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: section['color'].withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: section['color'],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item['subtitle'],
                                  style: GoogleFonts.comicNeue(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: section['color'],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            item['text'],
                            style: GoogleFonts.comicNeue(
                              fontSize: 14,
                              height: 1.6,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRightsSummary(bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text(
                "Your Data Rights Summary",
                style: GoogleFonts.comicNeue(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 36),
          _buildRightItem(Icons.visibility, "View", "Access all your data anytime", Colors.blue),
          SizedBox(height: 16),
          _buildRightItem(Icons.edit, "Update", "Modify your information easily", Colors.orange),
          SizedBox(height: 16),
          _buildRightItem(Icons.download, "Export", "Download your data in multiple formats", Colors.purple),
          SizedBox(height: 16),
          _buildRightItem(Icons.delete_forever, "Delete", "Permanently remove your account and data", Colors.red),
          SizedBox(height: 16),
          _buildRightItem(Icons.block, "Opt-out", "Disable specific features or tracking", Colors.teal),
        ],
      ),
    );
  }

  Widget _buildRightItem(IconData icon, String title, String description, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.comicNeue(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.comicNeue(
                    fontSize: 14,
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

  Widget _buildFooter(bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.15),
            theme.colorScheme.secondary.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.verified_user,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: 20),
          Text(
            "Your Trust, Our Commitment",
            style: GoogleFonts.comicNeue(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            "By using JEEzy, you agree to the collection and use of your information in accordance with this policy. We are committed to protecting your privacy and providing a safe, secure learning environment for your JEE preparation journey.",
            style: GoogleFonts.comicNeue(
              fontSize: 16,
              height: 1.7,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
