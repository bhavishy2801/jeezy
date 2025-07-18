// tests_screen.dart

// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:jeezy/main.dart';
import 'package:jeezy/screens/test_taking_screen.dart';
import 'package:jeezy/screens/results_screen.dart';
import 'package:jeezy/screens/question_review_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Add your Gemini API key (replace with your actual key)
const String GEMINI_API_KEY = 'AIzaSyByUBK5p67vekpjEmZppC7KjB1f64MHX9Q';

class TestsScreen extends StatefulWidget {
  const TestsScreen({Key? key}) : super(key: key);

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> with TickerProviderStateMixin {
  int _selectedTabIndex = 0;
  String _selectedSubject = 'All';
  String _selectedDifficulty = 'All';
  String _selectedType = 'All';
  String _searchQuery = '';
  
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabScaleAnimation;

  final List<String> _subjects = ['All', 'Physics', 'Chemistry', 'Mathematics'];
  final List<String> _difficulties = ['All', 'Easy', 'Medium', 'Hard'];
  final List<String> _testTypes = ['All', 'Mock Test', 'Practice Test', 'Chapter Test', 'Full Syllabus', 'Previous Year'];

  bool _testReminders = true;
  bool _hapticFeedback = true;
  bool _soundEffects = false;
  String _defaultDifficulty = 'Medium';
  
  // AI Question Generation Methods
Future<List<Map<String, dynamic>>> _generateQuestionsWithAI({
  required String subject,
  required String difficulty,
  required int count,
  String? specificTopic,
}) async {
  print('🚀 Starting AI generation for $count $subject questions...');
  
  try {
    final prompt = _buildOptimizedQuestionPrompt(subject, difficulty, count, specificTopic);
    
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$GEMINI_API_KEY'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [{
          'parts': [{
            'text': prompt
          }]
        }],
        'generationConfig': {
          'temperature': 0.8,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 2048,
        }
      }),
    ).timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final generatedText = data['candidates'][0]['parts'][0]['text'];
      print('✅ AI response received: ${generatedText.substring(0, math.min(200, generatedText.length))}...');
      
      var aiQuestions = _parseGeneratedQuestions(generatedText, subject, difficulty);
      
      if (aiQuestions.isNotEmpty) {
        print('✅ Successfully parsed ${aiQuestions.length} AI questions');
        return aiQuestions.take(count).toList();
      } else {
        print('⚠️ Failed to parse AI questions, using realistic fallback');
        return _getRealisticFallbackQuestions(subject, difficulty, count);
      }
    } else {
      print('❌ AI API error: ${response.statusCode}');
      return _getRealisticFallbackQuestions(subject, difficulty, count);
    }
  } catch (e) {
    print('❌ AI generation failed: $e');
    return _getRealisticFallbackQuestions(subject, difficulty, count);
  }
}


String _buildOptimizedQuestionPrompt(String subject, String difficulty, int count, String? specificTopic) {
  String topicText = specificTopic != null ? " focusing on $specificTopic" : "";
  
  return """
Generate $count multiple choice questions for JEE $subject$topicText.
Difficulty: $difficulty

IMPORTANT: Return ONLY a valid JSON array. No extra text before or after.

Format:
[
  {
    "questionText": "Question here",
    "options": [
      {"id": "A", "text": "Option A"},
      {"id": "B", "text": "Option B"},
      {"id": "C", "text": "Option C"},
      {"id": "D", "text": "Option D"}
    ],
    "correctAnswer": "A",
    "explanation": "Brief explanation"
  }
]

Generate exactly $count questions in this format.
""";
}



String _generateQuestionHash(String questionText) {
  return questionText.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
}

List<Map<String, dynamic>> _parseGeneratedQuestions(String generatedText, String subject, String difficulty) {
  try {
    // Clean the text to extract JSON
    String cleanText = generatedText.trim();
    
    // Find JSON array boundaries
    int startIndex = cleanText.indexOf('[');
    int endIndex = cleanText.lastIndexOf(']');
    
    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      String jsonString = cleanText.substring(startIndex, endIndex + 1);
      print('Extracted JSON: ${jsonString.substring(0, math.min(100, jsonString.length))}...');
      
      final List<dynamic> questionsJson = jsonDecode(jsonString);
      
      return questionsJson.map((q) {
        final question = q as Map<String, dynamic>;
        return {
          'id': 'ai_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}',
          'questionText': question['questionText'] ?? 'Generated question',
          'subject': subject,
          'difficulty': difficulty,
          'marks': 4,
          'type': 'mcq',
          'options': question['options'] ?? [
            {'id': 'A', 'text': 'Option A'},
            {'id': 'B', 'text': 'Option B'},
            {'id': 'C', 'text': 'Option C'},
            {'id': 'D', 'text': 'Option D'},
          ],
          'correctAnswer': question['correctAnswer'] ?? 'A',
          'explanation': question['explanation'] ?? 'AI-generated explanation',
          'negativeMarking': 1.0,
          'partialMarking': 0.0,
        };
      }).toList();
    } else {
      print('❌ No valid JSON array found in response');
      return [];
    }
  } catch (e) {
    print('❌ Error parsing JSON: $e');
    return [];
  }
}



List<Map<String, dynamic>> _getRealisticFallbackQuestions(String subject, String difficulty, int count) {
  Map<String, List<Map<String, dynamic>>> questionBank = {
    'Physics': [
      {
        'questionText': 'A ball is thrown vertically upward with an initial velocity of 20 m/s. What is the maximum height reached? (g = 10 m/s²)',
        'options': [
          {'id': 'A', 'text': '10 m'},
          {'id': 'B', 'text': '20 m'},
          {'id': 'C', 'text': '30 m'},
          {'id': 'D', 'text': '40 m'},
        ],
        'correctAnswer': 'B',
        'explanation': 'Using v² = u² + 2as, at maximum height v = 0, u = 20 m/s, a = -g = -10 m/s². So 0 = 400 - 20h, h = 20 m.',
      },
      {
        'questionText': 'The SI unit of electric field intensity is:',
        'options': [
          {'id': 'A', 'text': 'N/C'},
          {'id': 'B', 'text': 'V/m'},
          {'id': 'C', 'text': 'Both A and B'},
          {'id': 'D', 'text': 'J/C'},
        ],
        'correctAnswer': 'C',
        'explanation': 'Electric field intensity can be expressed as force per unit charge (N/C) or voltage per unit distance (V/m). Both are equivalent.',
      },
    ],
    'Chemistry': [
      {
        'questionText': 'Which of the following is the most electronegative element?',
        'options': [
          {'id': 'A', 'text': 'Oxygen'},
          {'id': 'B', 'text': 'Fluorine'},
          {'id': 'C', 'text': 'Nitrogen'},
          {'id': 'D', 'text': 'Chlorine'},
        ],
        'correctAnswer': 'B',
        'explanation': 'Fluorine is the most electronegative element with an electronegativity value of 4.0 on the Pauling scale.',
      },
      {
        'questionText': 'The molecular formula of benzene is:',
        'options': [
          {'id': 'A', 'text': 'C₆H₆'},
          {'id': 'B', 'text': 'C₆H₁₂'},
          {'id': 'C', 'text': 'C₆H₁₄'},
          {'id': 'D', 'text': 'C₆H₁₀'},
        ],
        'correctAnswer': 'A',
        'explanation': 'Benzene has the molecular formula C₆H₆ with a ring structure containing alternating double bonds.',
      },
    ],
    'Mathematics': [
      {
        'questionText': 'What is the derivative of sin(x) with respect to x?',
        'options': [
          {'id': 'A', 'text': 'cos(x)'},
          {'id': 'B', 'text': '-cos(x)'},
          {'id': 'C', 'text': 'sin(x)'},
          {'id': 'D', 'text': '-sin(x)'},
        ],
        'correctAnswer': 'A',
        'explanation': 'The derivative of sin(x) with respect to x is cos(x). This is a fundamental trigonometric derivative.',
      },
      {
        'questionText': 'If log₁₀(x) = 2, then x equals:',
        'options': [
          {'id': 'A', 'text': '10'},
          {'id': 'B', 'text': '20'},
          {'id': 'C', 'text': '100'},
          {'id': 'D', 'text': '1000'},
        ],
        'correctAnswer': 'C',
        'explanation': 'If log₁₀(x) = 2, then x = 10² = 100.',
      },
    ],
  };

  List<Map<String, dynamic>> subjectQuestions = questionBank[subject] ?? questionBank['Physics']!;
  List<Map<String, dynamic>> selectedQuestions = [];
  
  for (int i = 0; i < count && i < subjectQuestions.length; i++) {
    Map<String, dynamic> baseQuestion = subjectQuestions[i % subjectQuestions.length];
    selectedQuestions.add({
      'id': 'fallback_${DateTime.now().millisecondsSinceEpoch}_$i',
      'questionText': baseQuestion['questionText'],
      'subject': subject,
      'difficulty': difficulty,
      'type': 'mcq',
      'marks': 4,
      'options': baseQuestion['options'],
      'correctAnswer': baseQuestion['correctAnswer'],
      'explanation': baseQuestion['explanation'],
      'negativeMarking': 1.0,
      'partialMarking': 0.0,
    });
  }
  
  return selectedQuestions;
}



  // Services
  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
    _initializeNotifications();
    _initializeAudio();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
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

    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    _fabAnimationController.forward();
  }

  Future<void> _loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _testReminders = prefs.getBool('test_reminders') ?? true;
    _hapticFeedback = prefs.getBool('haptic_feedback') ?? true;
    _soundEffects = prefs.getBool('sound_effects') ?? false;
    _defaultDifficulty = prefs.getString('default_difficulty') ?? 'Medium';
  });
}

Future<void> _initializeNotifications() async {
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  
  await _flutterLocalNotificationsPlugin?.initialize(initializationSettings);
}

Future<void> _initializeAudio() async {
  _audioPlayer = AudioPlayer();
}

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  // Enhanced haptic feedback method
void _performHapticFeedback() {
  if (_hapticFeedback) {
    HapticFeedback.lightImpact();
  }
}

// Sound effects method
Future<void> _playSoundEffect(String soundType) async {
  if (_soundEffects && _audioPlayer != null) {
    try {
      switch (soundType) {
        case 'button_tap':
          await _audioPlayer!.play(AssetSource('sounds/button_tap.mp3'));
          break;
        case 'success':
          await _audioPlayer!.play(AssetSource('sounds/success.mp3'));
          break;
        case 'error':
          await _audioPlayer!.play(AssetSource('sounds/error.mp3'));
          break;
      }
    } catch (e) {
      print('Error playing sound: $e');
    }
  }
}

// Test reminder notification
Future<void> _scheduleTestReminder(String testTitle, DateTime testTime) async {
  if (!_testReminders || _flutterLocalNotificationsPlugin == null) return;
  
  try {
    // Initialize timezone data
    tz.initializeTimeZones();
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'test_reminders',
      'Test Reminders',
      channelDescription: 'Notifications for upcoming tests',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    // Schedule notification 30 minutes before test
    final reminderTime = testTime.subtract(Duration(minutes: 30));
    
    if (reminderTime.isAfter(DateTime.now())) {
      await _flutterLocalNotificationsPlugin!.zonedSchedule(
        testTitle.hashCode,
        'Test Reminder',
        '$testTitle starts in 30 minutes!',
        tz.TZDateTime.from(reminderTime, tz.local),
        platformChannelSpecifics,
        // FIXED: Use the correct parameter names for the new API
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  } catch (e) {
    print('Error scheduling reminder: $e');
  }
}

// Updated settings dialog with proper implementation
void _showTestSettings(BuildContext context, bool isDark, ThemeData theme) {
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(
          'Test Settings',
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              SwitchListTile(
                title: Text('Test Reminders'),
                subtitle: Text('Get notified about upcoming tests'),
                value: _testReminders,
                onChanged: (value) {
                  setDialogState(() {
                    _testReminders = value;
                  });
                  _performHapticFeedback();
                },
              ),
              
              Divider(),
              
              Text(
                'User Experience',
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              SwitchListTile(
                title: Text('Haptic Feedback'),
                subtitle: Text('Vibration on button taps'),
                value: _hapticFeedback,
                onChanged: (value) {
                  setDialogState(() {
                    _hapticFeedback = value;
                  });
                  if (value) HapticFeedback.lightImpact();
                },
              ),
              SwitchListTile(
                title: Text('Sound Effects'),
                subtitle: Text('Audio feedback for actions'),
                value: _soundEffects,
                onChanged: (value) {
                  setDialogState(() {
                    _soundEffects = value;
                  });
                  _performHapticFeedback();
                  if (value) _playSoundEffect('button_tap');
                },
              ),
              
              Divider(),
              
              Text(
                'Default Preferences',
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              ListTile(
                title: Text('Default Difficulty'),
                subtitle: Text('Preferred difficulty for practice'),
                trailing: DropdownButton<String>(
                  value: _defaultDifficulty,
                  items: ['Easy', 'Medium', 'Hard'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setDialogState(() {
                      _defaultDifficulty = newValue!;
                    });
                    _performHapticFeedback();
                  },
                ),
              ),
              
              Divider(),
              
              Text(
                'Data & Privacy',
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              ListTile(
                title: Text('Clear Test History'),
                subtitle: Text('Remove all test results'),
                trailing: Icon(Icons.delete_outline, color: Colors.red),
                onTap: () {
                  _performHapticFeedback();
                  _showClearHistoryDialog(context);
                },
              ),
              ListTile(
                title: Text('Export Data'),
                subtitle: Text('Download your test data'),
                trailing: Icon(Icons.download),
                onTap: () {
                  _performHapticFeedback();
                  _exportUserData();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _performHapticFeedback();
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              _performHapticFeedback();
              await _playSoundEffect('success');
              await _saveTestSettings();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Settings saved successfully!')),
              );
            },
            child: Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _saveTestSettings() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('test_reminders', _testReminders);
    await prefs.setBool('haptic_feedback', _hapticFeedback);
    await prefs.setBool('sound_effects', _soundEffects);
    await prefs.setString('default_difficulty', _defaultDifficulty);
    
    // Update state
    setState(() {});
    
    print('Settings saved: Reminders: $_testReminders, Haptic: $_hapticFeedback, Sound: $_soundEffects, Difficulty: $_defaultDifficulty');
  } catch (e) {
    print('Error saving settings: $e');
  }
}

  // FIXED: Better error handling and query structure
  Stream<QuerySnapshot> _getTestsStream() {
  try {
    Query query = FirebaseFirestore.instance.collection('tests');
    
    // Always start with published tests
    query = query.where('status', isEqualTo: 'published');
    
    // Apply filters carefully to avoid compound index issues
    if (_selectedSubject != 'All') {
      query = query.where('subject', isEqualTo: _selectedSubject);
    }
    if (_selectedDifficulty != 'All') {
      query = query.where('difficulty', isEqualTo: _selectedDifficulty);
    }
    if (_selectedType != 'All') {
      query = query.where('type', isEqualTo: _selectedType);
    }
    
    // Use createdAt for ordering (make sure this field exists)
    query = query.orderBy('createdAt', descending: true);
    
    return query.snapshots();
  } catch (e) {
    print('Error in _getTestsStream: $e');
    // Fallback to basic query
    return FirebaseFirestore.instance
        .collection('tests')
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}

  // Fetch user's test results
  Stream<QuerySnapshot> _getUserResultsStream() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.empty();
  
  try {
    return FirebaseFirestore.instance
        .collection('test_results')
        .where('userId', isEqualTo: user.uid)
        .orderBy('completedAt', descending: true)
        .snapshots();
  } catch (e) {
    print('Error in getUserResultsStream: $e');
    // Return a stream that emits an empty query snapshot
    return Stream.value(
      FirebaseFirestore.instance.collection('test_results').limit(0).get()
    ).asyncMap((snapshot) => snapshot);
  }
}

  // Fetch live tests
  Stream<QuerySnapshot> _getLiveTestsStream() {
  try {
    // First try the simple query without ordering to avoid index issues
    return FirebaseFirestore.instance
        .collection('tests')
        .where('status', isEqualTo: 'published')
        .where('isLive', isEqualTo: true)
        .snapshots();
  } catch (e) {
    print('Error in _getLiveTestsStream: $e');
    // If that fails, try even simpler query
    return FirebaseFirestore.instance
        .collection('tests')
        .where('isLive', isEqualTo: true)
        .snapshots();
  }
}




  // Fetch analytics data
  Future<Map<String, dynamic>> _getAnalyticsData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    try {
      // Get published tests only (visible to students)
      final publishedTestsSnapshot = await FirebaseFirestore.instance
          .collection('tests')
          .where('status', isEqualTo: 'published')  // Only published tests
          .get();

      // Get user's test statistics
      final resultsSnapshot = await FirebaseFirestore.instance
          .collection('test_results')
          .where('userId', isEqualTo: user.uid)
          .get();

      int totalTests = publishedTestsSnapshot.docs.length;
      int completedTests = resultsSnapshot.docs.length;
      double avgScore = 0.0;
      double avgAccuracy = 0.0;
      int totalQuestionsSolved = 0;
      int currentStreak = 0;

      if (completedTests > 0) {
        double totalScore = 0.0;
        double totalAccuracy = 0.0;
        
        for (var doc in resultsSnapshot.docs) {
          final data = doc.data();
          totalScore += (data['percentage'] ?? 0.0);
          totalAccuracy += (data['accuracy'] ?? 0.0);
          totalQuestionsSolved += (data['correctAnswers'] ?? 0) + (data['incorrectAnswers'] ?? 0) as int;
        }
        
        avgScore = totalScore / completedTests;
        avgAccuracy = totalAccuracy / completedTests;
        
        // Calculate streak (simplified)
        currentStreak = await _calculateStreak(user.uid);
      }

      return {
        'totalTests': totalTests,
        'completedTests': completedTests,
        'avgScore': avgScore,
        'avgAccuracy': avgAccuracy,
        'totalQuestionsSolved': totalQuestionsSolved,
        'currentStreak': currentStreak,
      };
    } catch (e) {
      print('Error fetching analytics: $e');
      return {};
    }
  }

  Future<int> _calculateStreak(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      int streak = 0;
      
      for (int i = 0; i < 30; i++) {
        final checkDate = today.subtract(Duration(days: i));
        final nextDay = checkDate.add(Duration(days: 1));
        
        final snapshot = await FirebaseFirestore.instance
            .collection('test_results')
            .where('userId', isEqualTo: userId)
            .where('completedAt', isGreaterThanOrEqualTo: checkDate)
            .where('completedAt', isLessThan: nextDay)
            .limit(1)
            .get();
        
        if (snapshot.docs.isNotEmpty) {
          streak++;
        } else {
          break;
        }
      }
      
      return streak;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeSwitchingArea(
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentThemeMode, child) {
          final isDark = currentThemeMode == ThemeMode.dark;
          final theme = Theme.of(context);

          return DefaultTabController(
            length: 5,
            child: Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
                elevation: 0,
                backgroundColor: theme.appBarTheme.backgroundColor,
                title: Row(
                  children: [
                    Icon(
                      Icons.quiz,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Practice',
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
                    icon: Icon(Icons.search),
                    onPressed: () => _showSearchDialog(context, isDark, theme),
                  ),
                  IconButton(
                    icon: Icon(Icons.leaderboard),
                    onPressed: () => _showLeaderboard(context, isDark, theme),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'filter':
                          _showAdvancedFilterDialog(context, isDark, theme);
                          break;
                        case 'analytics':
                          _showAnalytics(context, isDark, theme);
                          break;
                        case 'settings':
                          _showTestSettings(context, isDark, theme);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'filter',
                        child: Row(
                          children: [
                            Icon(Icons.filter_list, size: 20),
                            SizedBox(width: 8),
                            Text('Advanced Filters'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'analytics',
                        child: Row(
                          children: [
                            Icon(Icons.analytics, size: 20),
                            SizedBox(width: 8),
                            Text('Performance Analytics'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings, size: 20),
                            SizedBox(width: 8),
                            Text('Test Settings'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                // Update the TabBar to include attempted tests
                bottom: TabBar(
                  indicatorColor: theme.colorScheme.primary,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: isDark ? Colors.white70 : Colors.grey.shade600,
                  labelStyle: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'All Tests'),
                    Tab(text: 'My Results'),
                    Tab(text: 'Attempted'), // Add this new tab
                    Tab(text: 'Live Tests'),
                    Tab(text: 'Practice'),
                  ],
                  tabAlignment: TabAlignment.start,
                ),
              ),
                // Update TabBarView
                body: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: TabBarView(
                      children: [
                        _buildAllTestsTab(isDark, theme),
                        _buildMyResultsTab(isDark, theme),
                        _buildAttemptedTestsTab(isDark, theme), // Add this new tab
                        _buildLiveTestsTab(isDark, theme),
                        _buildPracticeTab(isDark, theme),
                      ],
                    ),
                  ),
                ),
              floatingActionButton: ScaleTransition(
                scale: _fabScaleAnimation,
                child: FloatingActionButton.extended(
                  onPressed: () => _showCreateTestDialog(context, isDark, theme),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  icon: Icon(Icons.add),
                  label: Text(
                    'Create Test',
                    style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllTestsTab(bool isDark, ThemeData theme) {
    return Column(
      children: [
        // Enhanced Filter Chips
        _buildEnhancedFilterChips(isDark, theme),
        
        // Stats Cards with Real Data
        _buildRealTimeStatsCards(isDark, theme),
        
        // Tests List from Firestore with Enhanced Error Handling
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getTestsStream(),
            builder: (context, snapshot) {
              // Enhanced error handling
              if (snapshot.hasError) {
                print('StreamBuilder error: ${snapshot.error}');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Error loading tests',
                        style: GoogleFonts.comicNeue(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Error: ${snapshot.error.toString()}',
                          style: GoogleFonts.comicNeue(
                            color: isDark ? Colors.white70 : Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            // Reset filters to reduce query complexity
                            _selectedSubject = 'All';
                            _selectedDifficulty = 'All';
                            _selectedType = 'All';
                          });
                        },
                        icon: Icon(Icons.refresh),
                        label: Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: theme.colorScheme.primary),
                      SizedBox(height: 16),
                      Text(
                        'Loading tests...',
                        style: GoogleFonts.comicNeue(
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Check if snapshot has data
              if (!snapshot.hasData || snapshot.data == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                      SizedBox(height: 16),
                      Text(
                        'No data available',
                        style: GoogleFonts.comicNeue(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please check your internet connection',
                        style: GoogleFonts.comicNeue(
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final tests = snapshot.data!.docs;
              final filteredTests = _filterTestsBySearch(tests);

              if (filteredTests.isEmpty) {
                return _buildEmptyState(isDark, theme);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                  await Future.delayed(Duration(seconds: 1));
                },
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredTests.length,
                  itemBuilder: (context, index) {
                    final testDoc = filteredTests[index];
                    final testData = testDoc.data() as Map<String, dynamic>;
                    return _buildEnhancedTestCard(testData, testDoc.id, isDark, theme, index);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<QueryDocumentSnapshot> _filterTestsBySearch(List<QueryDocumentSnapshot> tests) {
    if (_searchQuery.isEmpty) return tests;
    
    return tests.where((test) {
      final data = test.data() as Map<String, dynamic>;
      final title = (data['title'] ?? '').toString().toLowerCase();
      final description = (data['description'] ?? '').toString().toLowerCase();
      final subject = (data['subject'] ?? '').toString().toLowerCase();
      final tags = (data['tags'] as List<dynamic>?)?.join(' ').toLowerCase() ?? '';
      
      final searchLower = _searchQuery.toLowerCase();
      return title.contains(searchLower) ||
             description.contains(searchLower) ||
             subject.contains(searchLower) ||
             tags.contains(searchLower);
    }).toList();
  }

  Widget _buildRealTimeStatsCards(bool isDark, ThemeData theme) {
  return FutureBuilder<Map<String, dynamic>>(
    future: _getAnalyticsData(),
    builder: (context, snapshot) {
      final data = snapshot.data ?? {};
      final totalTests = data['totalTests'] ?? 0;
      final completedTests = data['completedTests'] ?? 0;
      final avgScore = data['avgScore'] ?? 0.0;
      
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: _buildStatCard(
                      'Total Tests',
                      '$totalTests',
                      Icons.quiz,
                      Colors.blue,
                      isDark,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 1000),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: _buildStatCard(
                      'Completed',
                      '$completedTests',
                      Icons.check_circle,
                      Colors.green,
                      isDark,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 1200),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: _buildStatCard(
                      'Avg Score',
                      '${avgScore.toStringAsFixed(1)}%',
                      Icons.trending_up,
                      Colors.orange,
                      isDark,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: FutureBuilder<int>(
                future: _getLiveTestsCount(),
                builder: (context, snapshot) {
                  final liveTests = snapshot.data ?? 0;
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 1400),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: _buildStatCard(
                          'Live Tests',
                          '$liveTests',
                          Icons.live_tv,
                          Colors.red,
                          isDark,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

// Add this new method
Future<int> _getLiveTestsCount() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('tests')
        .where('status', isEqualTo: 'published')
        .where('isLive', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  } catch (e) {
    print('Error getting live tests count: $e');
    return 0;
  }
}


  Widget _buildEnhancedFilterChips(bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Subject Filter
            ..._subjects.map((subject) => Padding(
              padding: EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  subject,
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.w600,
                    color: _selectedSubject == subject
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
                selected: _selectedSubject == subject,
                onSelected: (selected) {
                  setState(() {
                    _selectedSubject = subject;
                  });
                  _performHapticFeedback(); // Add this line
                  HapticFeedback.lightImpact();
                },
                backgroundColor: isDark ? Color(0xFF1C2542) : Colors.grey.shade200,
                selectedColor: theme.colorScheme.primary,
                checkmarkColor: Colors.white,
              ),
            )),
            
            SizedBox(width: 8),
            
            // Difficulty Filter
            ..._difficulties.map((difficulty) => Padding(
              padding: EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  difficulty,
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.w600,
                    color: _selectedDifficulty == difficulty
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
                selected: _selectedDifficulty == difficulty,
                onSelected: (selected) {
                  setState(() {
                    _selectedDifficulty = difficulty;
                  });
                  _performHapticFeedback(); // Add this line
                  HapticFeedback.lightImpact();
                },
                backgroundColor: isDark ? Color(0xFF1C2542) : Colors.grey.shade200,
                selectedColor: theme.colorScheme.secondary,
                checkmarkColor: Colors.white,
              ),
            )),
            
            SizedBox(width: 8),
            
            // Type Filter
            ..._testTypes.map((type) => Padding(
              padding: EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  type,
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.w600,
                    color: _selectedType == type
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
                selected: _selectedType == type,
                onSelected: (selected) {
                  setState(() {
                    _selectedType = type;
                  });
                  _performHapticFeedback(); // Add this line
                  HapticFeedback.lightImpact();
                },
                backgroundColor: isDark ? Color(0xFF1C2542) : Colors.grey.shade200,
                selectedColor: Colors.orange,
                checkmarkColor: Colors.white,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(12),
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
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 6),
          FittedBox(
            child: Text(
              value,
              style: GoogleFonts.comicNeue(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.comicNeue(
              fontSize: 10,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTestCard(Map<String, dynamic> test, String testId, bool isDark, ThemeData theme, int index) {
  return TweenAnimationBuilder<double>(
    duration: Duration(milliseconds: 300 + (index * 100)),
    tween: Tween(begin: 0.0, end: 1.0),
    builder: (context, value, child) {
      return Transform.translate(
        offset: Offset(0, 50 * (1 - value)),
        child: Opacity(
          opacity: value,
          child: Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1C2542) : Colors.white,
              borderRadius: BorderRadius.circular(16),
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
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Header with Live Indicator
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getSubjectColor(test['subject'] ?? 'All').withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getSubjectIcon(test['subject'] ?? 'All'),
                          color: _getSubjectColor(test['subject'] ?? 'All'),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    test['title'] ?? 'Untitled Test',
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (test['isLive'] == true)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.circle, size: 6, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          'LIVE',
                                          style: GoogleFonts.comicNeue(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (test['isPremium'] == true)
                                  Container(
                                    margin: EdgeInsets.only(left: 8),
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.amber, Colors.orange],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'PRO',
                                      style: GoogleFonts.comicNeue(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              test['description'] ?? 'No description available',
                              style: GoogleFonts.comicNeue(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Enhanced Test Info
                  Row(
                    children: [
                      _buildInfoChip(Icons.timer, '${test['duration'] ?? 0} min', Colors.blue),
                      SizedBox(width: 8),
                      _buildInfoChip(Icons.quiz, '${test['questionCount'] ?? 0} Qs', Colors.green),
                      SizedBox(width: 8),
                      _buildInfoChip(Icons.star, '${test['rating'] ?? 0.0}', Colors.amber),
                      SizedBox(width: 8),
                      _buildInfoChip(Icons.people, '${test['attempts'] ?? 0}', Colors.purple),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Difficulty and Pass Percentage
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(test['difficulty'] ?? 'Medium').withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          test['difficulty'] ?? 'Medium',
                          style: GoogleFonts.comicNeue(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getDifficultyColor(test['difficulty'] ?? 'Medium'),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      if (test['defaultNegativeMarking'] != null && test['defaultNegativeMarking'] > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Negative: -${test['defaultNegativeMarking']}',
                            style: GoogleFonts.comicNeue(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      Spacer(),
                      Text(
                        'Pass: ${test['passPercentage'] ?? 33}%',
                        style: GoogleFonts.comicNeue(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Tags
                  if (test['tags'] != null && (test['tags'] as List).isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: (test['tags'] as List<dynamic>).take(3).map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            tag.toString(),
                            style: GoogleFonts.comicNeue(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  
                  SizedBox(height: 16),
                  
                  // Enhanced Action Buttons with Attempt Check
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: FutureBuilder<bool>(
                          future: _hasUserAttemptedTest(testId),
                          builder: (context, snapshot) {
                            final hasAttempted = snapshot.data ?? false;
                            final canRetake = test['allowRetake'] ?? true;
                            final isDisabled = hasAttempted && !canRetake;
                            
                            return ElevatedButton.icon(
                              onPressed: isDisabled ? null : () {
                                _performHapticFeedback();
                                _playSoundEffect('button_tap');
                                _startTest(test, testId);
                              },
                              icon: Icon(
                                isDisabled ? Icons.block : Icons.play_arrow, 
                                size: 18
                              ),
                              label: Text(
                                isDisabled 
                                    ? 'Already Attempted' 
                                    : (test['isLive'] == true ? 'Join Live' : 'Start Test'),
                                style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDisabled 
                                    ? Colors.grey 
                                    : (test['isLive'] == true ? Colors.red : theme.colorScheme.primary),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showEnhancedTestDetails(test, testId, isDark, theme),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            side: BorderSide(color: theme.colorScheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Details',
                                style: GoogleFonts.comicNeue(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _shareTest(test),
                        icon: Icon(Icons.share, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                          foregroundColor: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

  Future<bool> _hasUserAttemptedTest(String testId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  
  try {
    final result = await FirebaseFirestore.instance
        .collection('test_results')
        .where('userId', isEqualTo: user.uid)
        .where('testId', isEqualTo: testId)
        .limit(1)
        .get();
    
    return result.docs.isNotEmpty;
  } catch (e) {
    return false;
  }
}

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.comicNeue(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyResultsTab(bool isDark, ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getUserResultsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: theme.colorScheme.primary),
                SizedBox(height: 16),
                Text(
                  'Loading results...',
                  style: GoogleFonts.comicNeue(
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error loading results',
                  style: GoogleFonts.comicNeue(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        final results = snapshot.data?.docs ?? [];
        
        if (results.isEmpty) {
          return _buildEmptyResults(isDark, theme);
        }

        return Column(
          children: [
            // Performance Summary Card
            _buildPerformanceSummary(results, isDark, theme),
            
            // Results List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final resultData = results[index].data() as Map<String, dynamic>;
                  return _buildEnhancedResultCard(resultData, results[index].id, isDark, theme);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPerformanceSummary(List<QueryDocumentSnapshot> results, bool isDark, ThemeData theme) {
    if (results.isEmpty) return Container();

    double totalScore = 0;
    double totalAccuracy = 0;
    int totalTests = results.length;

    for (var result in results) {
      final data = result.data() as Map<String, dynamic>;
      totalScore += (data['percentage'] ?? 0.0);
      totalAccuracy += (data['accuracy'] ?? 0.0);
    }

    final avgScore = totalScore / totalTests;
    final avgAccuracy = totalAccuracy / totalTests;

    return Container(
      margin: EdgeInsets.all(16),
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
              Icon(Icons.analytics, color: theme.colorScheme.primary),
              SizedBox(width: 8),
              Text(
                'Performance Summary',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Tests Taken', '$totalTests', Icons.quiz),
              ),
              Expanded(
                child: _buildSummaryItem('Avg Score', '${avgScore.toStringAsFixed(1)}%', Icons.trending_up),
              ),
              Expanded(
                child: _buildSummaryItem('Accuracy', '${avgAccuracy.toStringAsFixed(1)}%', Icons.track_changes),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.comicNeue(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.comicNeue(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEnhancedResultCard(Map<String, dynamic> result, String resultId, bool isDark, ThemeData theme) {
  final percentage = result['percentage'] ?? 0.0;
  final scoreColor = percentage >= 80 ? Colors.green : 
                    percentage >= 60 ? Colors.orange : Colors.red;

  return Container(
    margin: EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: isDark ? Color(0xFF1C2542) : Colors.white,
      borderRadius: BorderRadius.circular(16),
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
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result['testTitle'] ?? 'Test Result',
                  style: GoogleFonts.comicNeue(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Score Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Score: ${result['score'] ?? 0}/${result['maxScore'] ?? 100}',
                    style: GoogleFonts.comicNeue(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Rank: #${result['rank'] ?? 'N/A'}',
                    style: GoogleFonts.comicNeue(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: isDark ? Colors.white24 : Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                minHeight: 6,
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Detailed Stats
          Row(
            children: [
              _buildResultInfo('Correct', '${result['correctAnswers'] ?? 0}', Colors.green),
              _buildResultInfo('Wrong', '${result['incorrectAnswers'] ?? 0}', Colors.red),
              _buildResultInfo('Skipped', '${result['unattempted'] ?? 0}', Colors.orange),
              _buildResultInfo('Time', '${result['timeTaken'] ?? 0}/${result['duration'] ?? 0} min', Colors.blue),
            ],
          ),
          
          // Subject-wise breakdown if available
          if (result['subjectWise'] != null) ...[
            SizedBox(height: 16),
            Text(
              'Subject-wise Performance',
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            ...((result['subjectWise'] as Map<String, dynamic>).entries.map((entry) {
              final subjectData = entry.value as Map<String, dynamic>;
              final subjectPercentage = subjectData['percentage'] ?? 0.0;
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        entry.key,
                        style: GoogleFonts.comicNeue(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: subjectPercentage / 100,
                        backgroundColor: isDark ? Colors.white24 : Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getSubjectColor(entry.key),
                        ),
                        minHeight: 4,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${subjectPercentage.toStringAsFixed(0)}%',
                      style: GoogleFonts.comicNeue(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            })),
          ],
          
          SizedBox(height: 16),
          
          // FIXED: Better button layout to prevent text cutting
          Column(
            children: [
              // First row of buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _viewDetailedAnalysis(result, resultId),
                      icon: Icon(Icons.analytics, size: 16),
                      label: Text(
                        'Analysis',
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _reviewTestQuestions(result, resultId),
                      icon: Icon(Icons.quiz, size: 16),
                      label: Text(
                        'Review',
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              // Second row for share button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _shareResult(result),
                  icon: Icon(Icons.share, size: 16),
                  label: Text(
                    'Share Result',
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}


  Widget _buildResultInfo(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.comicNeue(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.comicNeue(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTestsTab(bool isDark, ThemeData theme) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('tests')
        .where('status', isEqualTo: 'published')
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              SizedBox(height: 16),
              Text(
                'Loading live tests...',
                style: GoogleFonts.comicNeue(
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }

      if (snapshot.hasError) {
        print('Live tests error: ${snapshot.error}');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error loading live tests',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please check your internet connection',
                style: GoogleFonts.comicNeue(
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => setState(() {}),
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }

      // Filter live tests on client side
      final allTests = snapshot.data?.docs ?? [];
      final liveTests = allTests.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isLive'] == true;
      }).toList();
      
      print('Total tests: ${allTests.length}, Live tests: ${liveTests.length}');
      
      if (liveTests.isEmpty) {
        return _buildNoLiveTests(isDark, theme);
      }

      return Column(
        children: [
          // Live Tests Header
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.live_tv, color: Colors.red),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Tests Available (${liveTests.length})',
                        style: GoogleFonts.comicNeue(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Join live tests with real-time rankings',
                        style: GoogleFonts.comicNeue(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
                await Future.delayed(Duration(seconds: 1));
              },
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: liveTests.length,
                itemBuilder: (context, index) {
                  final testData = liveTests[index].data() as Map<String, dynamic>;
                  return _buildLiveTestCard(testData, liveTests[index].id, isDark, theme);
                },
              ),
            ),
          ),
        ],
      );
    },
  );
}


  Widget _buildLiveTestCard(Map<String, dynamic> test, String testId, bool isDark, ThemeData theme) {
    final startTime = (test['startTime'] as Timestamp?)?.toDate() ?? DateTime.now();
    final isStartingSoon = startTime.isAfter(DateTime.now());
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.1),
            Colors.orange.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 6, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: GoogleFonts.comicNeue(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                if (isStartingSoon)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Starting Soon',
                      style: GoogleFonts.comicNeue(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: 12),
            
            Text(
              test['title'] ?? 'Live Test',
              style: GoogleFonts.comicNeue(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 8),
            
            Text(
              test['description'] ?? 'Join this live test session',
              style: GoogleFonts.comicNeue(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
            
            SizedBox(height: 16),
            
            Row(
              children: [
                _buildInfoChip(Icons.timer, '${test['duration'] ?? 0} min', Colors.blue),
                SizedBox(width: 8),
                _buildInfoChip(Icons.quiz, '${test['questionCount'] ?? 0} Qs', Colors.green),
                SizedBox(width: 8),
                _buildInfoChip(Icons.people, '${test['participants'] ?? 0} joined', Colors.purple),
              ],
            ),
            
            SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _joinLiveTest(test, testId),
                icon: Icon(Icons.play_arrow),
                label: Text(
                  isStartingSoon ? 'Join When Live' : 'Join Live Test',
                  style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttemptedTestsTab(bool isDark, ThemeData theme) {
  final user = FirebaseAuth.instance.currentUser;
  
  if (user == null) {
    return Center(
      child: Text(
        'Please login to view attempted tests',
        style: GoogleFonts.comicNeue(fontSize: 16),
      ),
    );
  }

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('test_results')
        .where('userId', isEqualTo: user.uid)
        .orderBy('completedAt', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(
          child: Text('Error loading attempted tests'),
        );
      }

      final attemptedResults = snapshot.data?.docs ?? [];
      
      if (attemptedResults.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No attempted tests yet',
                style: GoogleFonts.comicNeue(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Take some tests to see them here',
                style: GoogleFonts.comicNeue(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      // Get unique test IDs
      Set<String> attemptedTestIds = attemptedResults
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['testId'] as String)
          .toSet();

      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _getAttemptedTestsDetails(attemptedTestIds.toList()),
        builder: (context, testSnapshot) {
          if (testSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final attemptedTests = testSnapshot.data ?? [];

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: attemptedTests.length,
            itemBuilder: (context, index) {
              final test = attemptedTests[index];
              return _buildAttemptedTestCard(test, isDark, theme);
            },
          );
        },
      );
    },
  );
}

Future<List<Map<String, dynamic>>> _getAttemptedTestsDetails(List<String> testIds) async {
  List<Map<String, dynamic>> tests = [];
  
  for (String testId in testIds) {
    try {
      final testDoc = await FirebaseFirestore.instance
          .collection('tests')
          .doc(testId)
          .get();
      
      if (testDoc.exists) {
        final testData = testDoc.data()!;
        testData['id'] = testId;
        tests.add(testData);
      }
    } catch (e) {
      print('Error fetching test $testId: $e');
    }
  }
  
  return tests;
}

Widget _buildAttemptedTestCard(Map<String, dynamic> test, bool isDark, ThemeData theme) {
  return Container(
    margin: EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: isDark ? Color(0xFF1C2542) : Colors.white,
      borderRadius: BorderRadius.circular(16),
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
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test['title'] ?? 'Test',
                      style: GoogleFonts.comicNeue(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${test['subject']} • ${test['difficulty']}',
                      style: GoogleFonts.comicNeue(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ATTEMPTED',
                  style: GoogleFonts.comicNeue(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // FIXED: Better button layout to prevent text cutting
          Column(
            children: [
              // First row - Retake button (full width)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: test['allowRetake'] == true 
                      ? () => _startTest(test, test['id'])
                      : null,
                  icon: Icon(
                    test['allowRetake'] == true ? Icons.refresh : Icons.block,
                    size: 16,
                  ),
                  label: Text(
                    test['allowRetake'] == true ? 'Retake Test' : 'Retake Not Allowed',
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: test['allowRetake'] == true 
                        ? theme.colorScheme.primary 
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 8),
              
              // Second row - Analysis and Review buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewDetailedAnalysis(test, test['id']),
                      icon: Icon(Icons.analytics, size: 16),
                      label: Text(
                        'Analysis',
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(color: theme.colorScheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reviewQuestions(test['id']),
                      icon: Icon(Icons.quiz, size: 16),
                      label: Text(
                        'Review',
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

    


// Add this method to handle question review
void _reviewQuestions(String testId) async {
  try {
    // Get test result
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final resultSnapshot = await FirebaseFirestore.instance
        .collection('test_results')
        .where('userId', isEqualTo: user.uid)
        .where('testId', isEqualTo: testId)
        .orderBy('completedAt', descending: true)
        .limit(1)
        .get();

    if (resultSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test result not found')),
      );
      return;
    }

    final testResult = resultSnapshot.docs.first.data();
    
    // Get questions and user answers from the result
    final questionWiseResults = testResult['questionWiseResults'] as List<dynamic>? ?? [];
    
    if (questionWiseResults.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Question details not available for this test')),
      );
      return;
    }

    // Convert to the format needed for review screen
    List<Map<String, dynamic>> questions = [];
    Map<String, dynamic> userAnswers = {};
    
    for (var qResult in questionWiseResults) {
      final questionData = qResult as Map<String, dynamic>;
      questions.add(questionData);
      userAnswers[questionData['id']] = questionData['userAnswer'];
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionReviewScreen(
          testResult: testResult,
          questions: questions,
          userAnswers: userAnswers,
        ),
      ),
    );
  } catch (e) {
    print('Error loading question review: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading question review')),
    );
  }
}


void _viewTestResults(String testId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ResultsScreen(),
    ),
  );
}


  Widget _buildPracticeTab(bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Practice Modes Header
          Text(
            'Practice Modes',
            style: GoogleFonts.comicNeue(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: 16),
          
          // Quick Practice Cards
          _buildPracticeCard(
            'Quick Practice',
            'Solve 10 random questions',
            Icons.flash_on,
            Colors.orange,
            () => _startQuickPractice(),
            isDark,
            theme,
          ),
          
          SizedBox(height: 12),
          
          _buildPracticeCard(
            'Subject Practice',
            'Practice specific subjects',
            Icons.book,
            Colors.blue,
            () => _showSubjectPractice(context, isDark, theme),
            isDark,
            theme,
          ),
          
          SizedBox(height: 12),
          
          _buildPracticeCard(
            'Weak Areas',
            'Focus on your weak topics',
            Icons.trending_down,
            Colors.red,
            () => _showWeakAreas(context, isDark, theme),
            isDark,
            theme,
          ),
          
          SizedBox(height: 12),
          
          _buildPracticeCard(
            'Daily Challenge',
            'Complete today\'s challenge',
            Icons.emoji_events,
            Colors.purple,
            () => _startDailyChallenge(),
            isDark,
            theme,
          ),
          
          SizedBox(height: 24),
          
          // Practice Statistics from Firebase
          _buildRealTimePracticeStats(isDark, theme),
        ],
      ),
    );
  }

  Widget _buildPracticeCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isDark,
    ThemeData theme,
  ) {
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
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                                        style: GoogleFonts.comicNeue(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.comicNeue(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimePracticeStats(bool isDark, ThemeData theme) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getAnalyticsData(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        
        return Container(
          padding: EdgeInsets.all(16),
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
              Text(
                'Your Practice Stats',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Questions Solved',
                      '${data['totalQuestionsSolved'] ?? 0}',
                      Icons.quiz,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Current Streak',
                      '${data['currentStreak'] ?? 0} days',
                      Icons.local_fire_department,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Avg Accuracy',
                      '${(data['avgAccuracy'] ?? 0.0).toStringAsFixed(1)}%',
                      Icons.track_changes,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Tests Completed',
                      '${data['completedTests'] ?? 0}',
                      Icons.check_circle,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.comicNeue(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.comicNeue(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 24),
          Text(
            'No tests found',
            style: GoogleFonts.comicNeue(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Try adjusting your filters or check back later for new tests',
              style: GoogleFonts.comicNeue(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedSubject = 'All';
                _selectedDifficulty = 'All';
                _selectedType = 'All';
                _searchQuery = '';
              });
            },
            icon: Icon(Icons.refresh),
            label: Text(
              'Clear Filters',
              style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults(bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 24),
          Text(
            'No test results yet',
            style: GoogleFonts.comicNeue(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Take some tests to see your results and track your progress',
              style: GoogleFonts.comicNeue(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedTabIndex = 0; // Switch to All Tests tab
              });
            },
            icon: Icon(Icons.quiz),
            label: Text(
              'Take a Test',
              style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoLiveTests(bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.live_tv_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 24),
          Text(
            'No live tests available',
            style: GoogleFonts.comicNeue(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Live tests will appear here when scheduled. Check back later or take practice tests',
              style: GoogleFonts.comicNeue(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedTabIndex = 0; // Switch to All Tests tab
              });
            },
            icon: Icon(Icons.quiz),
            label: Text(
              'Browse Tests',
              style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Start test method with proper navigation
  void _startTest(Map<String, dynamic> test, String testId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please login to take tests'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    return;
  }

  // Check if retakes are allowed
  if (test['allowRetake'] == false) {
    // Check if user has already taken this test
    final existingResult = await FirebaseFirestore.instance
        .collection('test_results')
        .where('userId', isEqualTo: user.uid)
        .where('testId', isEqualTo: testId)
        .limit(1)
        .get();
    
    if (existingResult.docs.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Test Already Taken',
            style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'You have already taken this test and retakes are not allowed.',
            style: GoogleFonts.comicNeue(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('View Results'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
  }

  // Check if test is premium and user has access
  if (test['isPremium'] == true) {
    _showPremiumDialog(context, test);
    return;
  }

  // Navigate to test taking screen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TestTakingScreen(
        test: test,
        testId: testId,
      ),
    ),
  );
}


  void _showPremiumDialog(BuildContext context, Map<String, dynamic> test) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              'Premium Test',
              style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This is a premium test. Upgrade to access premium content and features.',
              style: GoogleFonts.comicNeue(),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Premium Features:',
                    style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Detailed explanations\n• Advanced analytics\n• Unlimited attempts\n• Priority support',
                    style: GoogleFonts.comicNeue(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showUpgradeDialog(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: Text('Upgrade Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Upgrade to Premium',
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Premium features will be available soon. Stay tuned for updates!',
          style: GoogleFonts.comicNeue(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _joinLiveTest(Map<String, dynamic> test, String testId) {
    // For now, treat live tests the same as regular tests
    _startTest(test, testId);
  }

  void _showSearchDialog(BuildContext context, bool isDark, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Search Tests',
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter test name, subject, or keywords...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value;
            });
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAdvancedFilterDialog(BuildContext context, bool isDark, ThemeData theme) {
  // Create local state variables for the dialog
  String localSelectedSubject = _selectedSubject;
  String localSelectedDifficulty = _selectedDifficulty;
  String localSelectedType = _selectedType;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(
          'Advanced Filters',
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Subject', style: GoogleFonts.comicNeue(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _subjects.map((subject) {
                  return FilterChip(
                    label: Text(subject),
                    selected: localSelectedSubject == subject,
                    selectedColor: theme.colorScheme.primary,
                    checkmarkColor: Colors.white,
                    onSelected: (selected) {
                      setDialogState(() {
                        localSelectedSubject = subject;
                      });
                      _performHapticFeedback(); // Add this line
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
              Text('Difficulty', style: GoogleFonts.comicNeue(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _difficulties.map((difficulty) {
                  return FilterChip(
                    label: Text(difficulty),
                    selected: localSelectedDifficulty == difficulty,
                    selectedColor: theme.colorScheme.secondary,
                    checkmarkColor: Colors.white,
                    onSelected: (selected) {
                      setDialogState(() {
                        localSelectedDifficulty = difficulty;
                      });
                      _performHapticFeedback(); // Add this line
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
              Text('Type', style: GoogleFonts.comicNeue(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _testTypes.map((type) {
                  return FilterChip(
                    label: Text(type),
                    selected: localSelectedType == type,
                    selectedColor: Colors.orange,
                    checkmarkColor: Colors.white,
                    onSelected: (selected) {
                      setDialogState(() {
                        localSelectedType = type;
                      });
                      _performHapticFeedback(); // Add this line
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedSubject = 'All';
                _selectedDifficulty = 'All';
                _selectedType = 'All';
              });
              Navigator.pop(context);
            },
            child: Text('Clear All'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedSubject = localSelectedSubject;
                _selectedDifficulty = localSelectedDifficulty;
                _selectedType = localSelectedType;
              });
              Navigator.pop(context);
            },
            child: Text('Apply'),
          ),
        ],
      ),
    ),
  );
}


  void _showAnalytics(BuildContext context, bool isDark, ThemeData theme) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(child: CircularProgressIndicator()),
  );

  _getDetailedAnalyticsData().then((analyticsData) {
    Navigator.pop(context);
    _showAnalyticsDialog(context, analyticsData, isDark, theme);
  }).catchError((error) {
    Navigator.pop(context);
    _showErrorDialog(context, 'Analytics Error', 'Could not load analytics data.');
  });
}

Future<Map<String, dynamic>> _getDetailedAnalyticsData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return {};

  try {
    // Get user's test results
    final resultsSnapshot = await FirebaseFirestore.instance
        .collection('test_results')
        .where('userId', isEqualTo: user.uid)
        .get();

    if (resultsSnapshot.docs.isEmpty) {
      return {'hasData': false};
    }

    // Calculate comprehensive analytics
    List<Map<String, dynamic>> results = resultsSnapshot.docs
        .map((doc) => doc.data())
        .toList();

    // Basic stats
    int totalTests = results.length;
    double totalScore = 0;
    double totalAccuracy = 0;
    int totalQuestions = 0;
    int totalCorrect = 0;
    int totalIncorrect = 0;
    int totalSkipped = 0;

    // Subject-wise performance
    Map<String, List<double>> subjectPerformance = {};
    Map<String, int> subjectTestCounts = {};

    // Difficulty-wise performance
    Map<String, List<double>> difficultyPerformance = {};

    // Time-based performance (last 30 days)
    List<Map<String, dynamic>> recentTests = [];
    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));

    for (var result in results) {
      totalScore += result['percentage'] ?? 0.0;
      totalAccuracy += result['accuracy'] ?? 0.0;
      totalQuestions += (result['totalQuestions'] ?? 0) as int;
      totalCorrect += (result['correctAnswers'] ?? 0) as int;
      totalIncorrect += (result['incorrectAnswers'] ?? 0) as int;
      totalSkipped += (result['unattempted'] ?? 0) as int;

      // Subject analysis
      String subject = result['subject'] ?? 'General';
      if (!subjectPerformance.containsKey(subject)) {
        subjectPerformance[subject] = [];
        subjectTestCounts[subject] = 0;
      }
      subjectPerformance[subject]!.add(result['percentage'] ?? 0.0);
      subjectTestCounts[subject] = subjectTestCounts[subject]! + 1;

      // Difficulty analysis
      String difficulty = result['difficulty'] ?? 'Medium';
      if (!difficultyPerformance.containsKey(difficulty)) {
        difficultyPerformance[difficulty] = [];
      }
      difficultyPerformance[difficulty]!.add(result['percentage'] ?? 0.0);

      // Recent tests
      final completedAt = result['completedAt'];
      if (completedAt != null) {
        DateTime testDate;
        if (completedAt is Timestamp) {
          testDate = completedAt.toDate();
        } else {
          testDate = DateTime.parse(completedAt.toString());
        }
        
        if (testDate.isAfter(thirtyDaysAgo)) {
          recentTests.add({
            'date': testDate,
            'percentage': result['percentage'] ?? 0.0,
            'title': result['testTitle'] ?? 'Test',
          });
        }
      }
    }

    // Calculate averages
    double avgScore = totalScore / totalTests;
    double avgAccuracy = totalAccuracy / totalTests;

    // Subject averages
    Map<String, double> subjectAverages = {};
    subjectPerformance.forEach((subject, scores) {
      subjectAverages[subject] = scores.reduce((a, b) => a + b) / scores.length;
    });

    // Difficulty averages
    Map<String, double> difficultyAverages = {};
    difficultyPerformance.forEach((difficulty, scores) {
      difficultyAverages[difficulty] = scores.reduce((a, b) => a + b) / scores.length;
    });

    // Sort recent tests
    recentTests.sort((a, b) => b['date'].compareTo(a['date']));

    // Find strengths and weaknesses
    var sortedSubjects = subjectAverages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String strongestSubject = sortedSubjects.isNotEmpty ? sortedSubjects.first.key : 'None';
    String weakestSubject = sortedSubjects.isNotEmpty ? sortedSubjects.last.key : 'None';

    return {
      'hasData': true,
      'totalTests': totalTests,
      'avgScore': avgScore,
      'avgAccuracy': avgAccuracy,
      'totalQuestions': totalQuestions,
      'totalCorrect': totalCorrect,
      'totalIncorrect': totalIncorrect,
      'totalSkipped': totalSkipped,
      'subjectAverages': subjectAverages,
      'subjectTestCounts': subjectTestCounts,
      'difficultyAverages': difficultyAverages,
      'recentTests': recentTests.take(10).toList(),
      'strongestSubject': strongestSubject,
      'weakestSubject': weakestSubject,
    };
  } catch (e) {
    print('Error in analytics: $e');
    return {'hasData': false, 'error': e.toString()};
  }
}

void _showAnalyticsDialog(BuildContext context, Map<String, dynamic> data, bool isDark, ThemeData theme) {
  if (data['hasData'] != true) {
    _showNoDataDialog(context, 'No test data available for analysis');
    return;
  }

  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: theme.colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Performance Analytics',
                  style: GoogleFonts.comicNeue(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnalyticsCard(
                            'Tests Taken',
                            '${data['totalTests']}',
                            Icons.quiz,
                            Colors.blue,
                            isDark,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildAnalyticsCard(
                            'Avg Score',
                            '${data['avgScore'].toStringAsFixed(1)}%',
                            Icons.trending_up,
                            Colors.green,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnalyticsCard(
                            'Questions Solved',
                            '${data['totalQuestions']}',
                            Icons.help,
                            Colors.orange,
                            isDark,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildAnalyticsCard(
                            'Accuracy',
                            '${data['avgAccuracy'].toStringAsFixed(1)}%',
                            Icons.track_changes,
                            Colors.purple,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Strengths & Weaknesses
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFF1C2542) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Strengths & Areas for Improvement',
                            style: GoogleFonts.comicNeue(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.star, color: Colors.green),
                                      SizedBox(height: 4),
                                      Text(
                                        'Strongest',
                                        style: GoogleFonts.comicNeue(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        data['strongestSubject'],
                                        style: GoogleFonts.comicNeue(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.trending_down, color: Colors.red),
                                      SizedBox(height: 4),
                                      Text(
                                        'Needs Work',
                                        style: GoogleFonts.comicNeue(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      Text(
                                        data['weakestSubject'],
                                        style: GoogleFonts.comicNeue(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Subject Performance
                    Text(
                      'Subject-wise Performance',
                      style: GoogleFonts.comicNeue(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    ...(data['subjectAverages'] as Map<String, double>).entries.map((entry) {
                      final subject = entry.key;
                      final average = entry.value;
                      final testCount = data['subjectTestCounts'][subject] ?? 0;
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xFF1C2542) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? Colors.white24 : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getSubjectIcon(subject),
                              color: _getSubjectColor(subject),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subject,
                                    style: GoogleFonts.comicNeue(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '$testCount tests',
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${average.toStringAsFixed(1)}%',
                                  style: GoogleFonts.comicNeue(
                                    fontWeight: FontWeight.bold,
                                    color: _getSubjectColor(subject),
                                  ),
                                ),
                                Container(
                                  width: 60,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: average / 100,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _getSubjectColor(subject),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color, bool isDark) {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? Color(0xFF1C2542) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: color.withOpacity(0.3),
      ),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.comicNeue(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.comicNeue(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

void _showClearHistoryDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Clear Test History',
        style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
      ),
      content: Text(
        'This will permanently delete all your test results. This action cannot be undone.',
        style: GoogleFonts.comicNeue(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            // Implement clear history
            await _clearTestHistory();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('Clear History', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

Future<void> _clearTestHistory() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final results = await FirebaseFirestore.instance
        .collection('test_results')
        .where('userId', isEqualTo: user.uid)
        .get();

    for (var doc in results.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Test history cleared successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error clearing history: $e')),
    );
  }
}

void _exportUserData() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get user's test results
    final results = await FirebaseFirestore.instance
        .collection('test_results')
        .where('userId', isEqualTo: user.uid)
        .get();

    final exportData = {
      'exportDate': DateTime.now().toIso8601String(),
      'userId': user.uid,
      'email': user.email,
      'testResults': results.docs.map((doc) => doc.data()).toList(),
    };

    // For now, just show success message
    // In a real app, you'd generate and download a file
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data export feature will be available soon')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error exporting data: $e')),
    );
  }
}


  void _showLeaderboard(BuildContext context, bool isDark, ThemeData theme) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(child: CircularProgressIndicator()),
  );

  try {
    // Get test results with better error handling
    final resultsSnapshot = await FirebaseFirestore.instance
        .collection('test_results')
        .limit(100)
        .get();

    if (resultsSnapshot.docs.isEmpty) {
      Navigator.pop(context);
      _showNoDataDialog(context, 'No test results available yet');
      return;
    }

    // Group by user and calculate average
    Map<String, Map<String, dynamic>> userStats = {};
    
    for (var doc in resultsSnapshot.docs) {
      final data = doc.data();
      final userId = data['userId'];
      
      if (userId == null) continue;
      
      if (!userStats.containsKey(userId)) {
        userStats[userId] = {
          'totalScore': 0.0,
          'testCount': 0,
          'bestScore': 0.0,
          'userId': userId,
          'name': 'Loading...',
          'email': '',
        };
      }
      
      userStats[userId]!['totalScore'] += (data['percentage'] ?? 0.0);
      userStats[userId]!['testCount']++;
      userStats[userId]!['bestScore'] = math.max(
        userStats[userId]!['bestScore'], 
        data['percentage'] ?? 0.0
      );
    }

    // Calculate averages and sort
    List<Map<String, dynamic>> leaderboard = userStats.values.map((stats) {
      stats['averageScore'] = stats['totalScore'] / stats['testCount'];
      return stats;
    }).toList();

    leaderboard.sort((a, b) => b['averageScore'].compareTo(a['averageScore']));
    leaderboard = leaderboard.take(10).toList();

    // Get user details from multiple possible fields
    // Get user details from multiple possible fields
for (var entry in leaderboard) {
  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(entry['userId'])
        .get();
    
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      // Try multiple possible name fields in order of preference
      String userName = userData['fullName'] ?? 
                       userData['name'] ?? 
                       userData['displayName'] ?? 
                       userData['display_name'] ??
                       userData['firstName'] ??
                       userData['username'] ??
                       '';
      
      // If still no name found, try email prefix
      if (userName.isEmpty) {
        final email = userData['email'] ?? '';
        if (email.isNotEmpty) {
          userName = email.split('@')[0]; // Use email prefix as name
        } else {
          userName = 'User ${entry['userId'].substring(0, 6)}';
        }
      }
      
      entry['name'] = userName;
      entry['email'] = userData['email'] ?? '';
    } else {
      // If user document doesn't exist, create a readable name
      entry['name'] = 'Anonymous User';
    }
  } catch (e) {
    print('Could not fetch user ${entry['userId']}: $e');
    entry['name'] = 'Anonymous User';
  }
}

    Navigator.pop(context);
    _showLeaderboardDialog(context, leaderboard, isDark, theme);

  } catch (e) {
    Navigator.pop(context);
    print('Leaderboard error: $e');
    _showErrorDialog(context, 'Error loading leaderboard', 'Please try again later.');
  }
}


void _showLeaderboardDialog(BuildContext context, List<Map<String, dynamic>> leaderboard, bool isDark, ThemeData theme) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.leaderboard, color: Colors.amber),
          SizedBox(width: 8),
          Text(
            'Leaderboard',
            style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        height: 400,
        child: leaderboard.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No rankings available yet',
                      style: GoogleFonts.comicNeue(fontSize: 16),
                    ),
                    Text(
                      'Take some tests to see rankings!',
                      style: GoogleFonts.comicNeue(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: leaderboard.length,
                itemBuilder: (context, index) {
                  final entry = leaderboard[index];
                  final rank = index + 1;
                  
                  Color rankColor = rank == 1 ? Colors.amber :
                                  rank == 2 ? Colors.grey.shade400 :
                                  rank == 3 ? Colors.brown.shade400 :
                                  Colors.blue;
                  
                  IconData rankIcon = rank == 1 ? Icons.emoji_events :
                                     rank == 2 ? Icons.military_tech :
                                     rank == 3 ? Icons.workspace_premium :
                                     Icons.person;

                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: rank <= 3 ? rankColor.withOpacity(0.1) : null,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: rank <= 3 ? rankColor.withOpacity(0.3) : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: rankColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: rank <= 3
                                ? Icon(rankIcon, color: Colors.white, size: 20)
                                : Text(
                                    '$rank',
                                    style: GoogleFonts.comicNeue(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry['name'],
                                style: GoogleFonts.comicNeue(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${entry['testCount']} tests',
                                style: GoogleFonts.comicNeue(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${entry['averageScore'].toStringAsFixed(1)}%',
                              style: GoogleFonts.comicNeue(
                                fontWeight: FontWeight.bold,
                                color: rankColor,
                              ),
                            ),
                            Text(
                              'Best: ${entry['bestScore'].toStringAsFixed(1)}%',
                              style: GoogleFonts.comicNeue(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    ),
  );
}

void _showNoDataDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('No Data'),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}


  void _showCreateTestDialog(BuildContext context, bool isDark, ThemeData theme) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Create Custom Test',
        style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.quiz, color: Colors.blue),
            title: Text('Quick Test'),
            subtitle: Text('Create a test with random questions'),
            onTap: () {
              Navigator.pop(context);
              _showQuickTestCreator(context, isDark, theme);
            },
          ),
          ListTile(
            leading: Icon(Icons.book, color: Colors.green),
            title: Text('Subject Test'),
            subtitle: Text('Create a subject-specific test'),
            onTap: () {
              Navigator.pop(context);
              _showSubjectTestCreator(context, isDark, theme);
            },
          ),
          ListTile(
            leading: Icon(Icons.star, color: Colors.amber),
            title: Text('Custom Test'),
            subtitle: Text('Advanced test creation (Premium)'),
            onTap: () {
              Navigator.pop(context);
              _showPremiumDialog(context, {});
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
      ],
    ),
  );
}

void _showQuickTestCreator(BuildContext context, bool isDark, ThemeData theme) {
  int questionCount = 10;
  String difficulty = 'Medium';
  int duration = 15;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(
          'Create Quick Test',
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Number of Questions'),
            Slider(
              value: questionCount.toDouble(),
              min: 5,
              max: 25,
              divisions: 4,
              label: '$questionCount questions',
              onChanged: (value) {
                setDialogState(() {
                  questionCount = value.round();
                  duration = questionCount * 2; // 2 minutes per question
                });
              },
            ),
            SizedBox(height: 16),
            Text('Difficulty'),
            DropdownButton<String>(
              value: difficulty,
              isExpanded: true,
              items: ['Easy', 'Medium', 'Hard'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setDialogState(() {
                  difficulty = newValue!;
                });
              },
            ),
            SizedBox(height: 16),
            Text('Duration: $duration minutes'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createQuickTest(questionCount, difficulty, duration);
            },
            child: Text('Create Test'),
          ),
        ],
      ),
    ),
  );
}

void _createQuickTest(int questionCount, String difficulty, int duration) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(child: CircularProgressIndicator()),
  );

  try {
    // Get random questions based on difficulty
    final questionsQuery = await FirebaseFirestore.instance
        .collection('questions')
        .where('difficulty', isEqualTo: difficulty)
        .limit(questionCount * 2)
        .get();

    List<Map<String, dynamic>> questions = questionsQuery.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    questions.shuffle();
    if (questions.length > questionCount) {
      questions = questions.take(questionCount).toList();
    }

    Navigator.pop(context);

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No questions available for selected difficulty')),
      );
      return;
    }

    final customTest = {
      'title': 'Custom Test - $difficulty',
      'description': 'Custom created test with $questionCount questions',
      'subject': 'Mixed',
      'difficulty': difficulty,
      'duration': duration,
      'questionCount': questions.length,
      'maxScore': questions.length * 4,
      'type': 'Custom Test',
      'isLive': false,
      'isPremium': false,
      'questions': questions,
    };
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestTakingScreen(
          test: customTest,
          testId: 'custom_test_${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    );
  } catch (e) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error creating test: $e')),
    );
  }
}

void _showSubjectTestCreator(BuildContext context, bool isDark, ThemeData theme) {
  String selectedSubject = 'Physics';
  int questionCount = 15;
  String difficulty = 'Medium';

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(
          'Create Subject Test',
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Subject'),
            DropdownButton<String>(
              value: selectedSubject,
              isExpanded: true,
              items: ['Physics', 'Chemistry', 'Mathematics'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Icon(_getSubjectIcon(value), color: _getSubjectColor(value)),
                      SizedBox(width: 8),
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setDialogState(() {
                  selectedSubject = newValue!;
                });
              },
            ),
            SizedBox(height: 16),
            Text('Number of Questions: $questionCount'),
            Slider(
              value: questionCount.toDouble(),
              min: 5,
              max: 30,
              divisions: 5,
              onChanged: (value) {
                setDialogState(() {
                  questionCount = value.round();
                });
              },
            ),
            SizedBox(height: 16),
            Text('Difficulty'),
            DropdownButton<String>(
              value: difficulty,
              isExpanded: true,
              items: ['Easy', 'Medium', 'Hard'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setDialogState(() {
                  difficulty = newValue!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createSubjectTest(selectedSubject, questionCount, difficulty);
            },
            child: Text('Create Test'),
          ),
        ],
      ),
    ),
  );
}

void _createSubjectTest(String subject, int questionCount, String difficulty) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(child: CircularProgressIndicator()),
  );

  try {
    final questionsQuery = await FirebaseFirestore.instance
        .collection('questions')
        .where('subject', isEqualTo: subject)
        .where('difficulty', isEqualTo: difficulty)
        .limit(questionCount * 2)
        .get();

    List<Map<String, dynamic>> questions = questionsQuery.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    questions.shuffle();
    if (questions.length > questionCount) {
      questions = questions.take(questionCount).toList();
    }

    Navigator.pop(context);

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No $difficulty questions available for $subject')),
      );
      return;
    }

    final subjectTest = {
      'title': '$subject Test - $difficulty',
      'description': 'Custom $subject test with $questionCount questions',
      'subject': subject,
      'difficulty': difficulty,
      'duration': questionCount * 2,
      'questionCount': questions.length,
      'maxScore': questions.length * 4,
      'type': 'Subject Test',
      'isLive': false,
      'isPremium': false,
      'questions': questions,
    };
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestTakingScreen(
          test: subjectTest,
          testId: 'subject_test_${subject.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    );
  } catch (e) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error creating $subject test: $e')),
    );
  }
}

  void _showEnhancedTestDetails(Map<String, dynamic> test, String testId, bool isDark, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1C2542) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Test Header
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getSubjectColor(test['subject'] ?? 'All').withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getSubjectIcon(test['subject'] ?? 'All'),
                              color: _getSubjectColor(test['subject'] ?? 'All'),
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  test['title'] ?? 'Test Details',
                                  style: GoogleFonts.comicNeue(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  test['subject'] ?? 'General',
                                  style: GoogleFonts.comicNeue(
                                    fontSize: 14,
                                    color: _getSubjectColor(test['subject'] ?? 'All'),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Description
                      if (test['description'] != null) ...[
                        Text(
                          'Description',
                          style: GoogleFonts.comicNeue(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          test['description'],
                          style: GoogleFonts.comicNeue(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                      
                      // Test Details Grid
                      Text(
                        'Test Information',
                        style: GoogleFonts.comicNeue(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('Duration', '${test['duration'] ?? 0} minutes'),
                            _buildDetailRow('Questions', '${test['questionCount'] ?? 0}'),
                            _buildDetailRow('Max Score', '${test['maxScore'] ?? 0} marks'),
                            _buildDetailRow('Difficulty', test['difficulty'] ?? 'Medium'),
                            _buildDetailRow('Type', test['type'] ?? 'Practice Test'),
                            _buildDetailRow('Pass Percentage', '${test['passPercentage'] ?? 33}%'),
                            if (test['defaultNegativeMarking'] != null && test['defaultNegativeMarking'] > 0)
                            _buildDetailRow(
                              'Default Negative Marking',
                              '-${test['defaultNegativeMarking']} per wrong answer',
                            ),
                            if (test['defaultPartialMarking'] != null && test['defaultPartialMarking'] > 0)
                            _buildDetailRow(
                              'Default Partial Marking',
                              '+${test['defaultPartialMarking']} per partially correct',
                            ),
                            if (test['allowPerQuestionMarking'] == true)
                            _buildDetailRow(
                              'Per-Question Marking',
                              'Individual questions may have different marking',
                            ),
                            if (test['negativeMarking'] == true && test['defaultNegativeMarking'] == null)
                            _buildDetailRow(
                              'Negative Marking',
                              'Yes (varies per question)',
                            ),
                            if (test['questions'] is List && (test['questions'] as List).isNotEmpty)
                            ...[
                              SizedBox(height: 12),
                              Text(
                                'Marking Scheme (per question):',
                                style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              ...((test['questions'] as List).map((q) {
                                final qn = q['number'] ?? (test['questions'] as List).indexOf(q) + 1;
                                final marks = q['marks'] ?? '';
                                final neg = q['negativeMarking'] ?? test['negativeMarking'] ?? '';
                                final partial = q['partialMarking'] ?? test['partialMarking'] ?? '';
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    'Q$qn: +$marks, -$neg${partial != '' ? ', Partial: $partial' : ''}',
                                    style: GoogleFonts.comicNeue(fontSize: 12),
                                  ),
                                );
                              })),
                            ],
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Instructions
Text(
  'Instructions',
  style: GoogleFonts.comicNeue(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
),
SizedBox(height: 8),
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.blue.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.blue.withOpacity(0.3)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildInstructionItem('• Read all questions carefully before answering'),
      _buildInstructionItem('• You can navigate between questions using the navigation buttons'),
      _buildInstructionItem('• Your progress is automatically saved'),
      _buildInstructionItem('• Submit the test when you are done'),
      if (test['negativeMarking'] == true)
        _buildInstructionItem(
          '• Be careful with negative marking for wrong answers',
          isWarning: true,
        ),
    ],
  ),
),
                      
                      SizedBox(height: 30),
                      
                      // Start Test Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _startTest(test, testId);
                          },
                          icon: Icon(Icons.play_arrow, size: 20),
                          label: Text(
                            'Start Test',
                            style: GoogleFonts.comicNeue(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text, {bool isWarning = false}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 2),
    child: Text(
      text,
      style: GoogleFonts.comicNeue(
        fontSize: 12,
        color: isWarning ? Colors.red : null,
        fontWeight: isWarning ? FontWeight.w600 : null,
      ),
    ),
  );
}


  Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.comicNeue(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    ),
  );
}

  void _shareTest(Map<String, dynamic> test) {
    final testTitle = test['title'] ?? 'Test';
    final testSubject = test['subject'] ?? 'General';
    final shareText = 'Check out this $testSubject test: $testTitle\n\nJoin me on JEEzy for JEE preparation!';
    
    Share.share(shareText);
  }

  void _shareResult(Map<String, dynamic> result) {
    final testTitle = result['testTitle'] ?? 'Test';
    final percentage = result['percentage'] ?? 0.0;
    final shareText = 'I scored ${percentage.toStringAsFixed(1)}% in $testTitle on JEEzy! 🎉\n\nJoin me for JEE preparation!';
    
    Share.share(shareText);
  }

  void _viewDetailedAnalysis(Map<String, dynamic> result, String resultId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(),
      ),
    );
  }

// Add this method to handle question review from results
void _reviewTestQuestions(Map<String, dynamic> result, String resultId) async {
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading questions...',
              style: GoogleFonts.comicNeue(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    // Get questions and user answers from the result
    final questionWiseResults = result['questionWiseResults'] as List<dynamic>? ?? [];
    
    if (questionWiseResults.isEmpty) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Question details not available for this test'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Convert to the format needed for review screen
    List<Map<String, dynamic>> questions = [];
    Map<String, dynamic> userAnswers = {};
    
    for (var qResult in questionWiseResults) {
      final questionData = qResult as Map<String, dynamic>;
      
      // Ensure all required fields are present
      Map<String, dynamic> formattedQuestion = {
        'id': questionData['id'] ?? 'unknown_${questions.length}',
        'questionText': questionData['questionText'] ?? 'Question text not available',
        'subject': questionData['subject'] ?? 'General',
        'difficulty': questionData['difficulty'] ?? 'Medium',
        'marks': questionData['marks'] ?? 4,
        'type': questionData['questionType'] ?? 'mcq',
        'options': questionData['options'] ?? [
          {'id': 'A', 'text': 'Option A'},
          {'id': 'B', 'text': 'Option B'},
          {'id': 'C', 'text': 'Option C'},
          {'id': 'D', 'text': 'Option D'},
        ],
        'correctAnswer': questionData['correctAnswer'] ?? 'A',
        'correctAnswers': questionData['correctAnswers'] ?? [],
        'explanation': questionData['explanation'] ?? 'No explanation available',
        'negativeMarking': questionData['negativeMarking'] ?? 0,
        'partialMarking': questionData['partialMarking'] ?? 0,
      };
      
      questions.add(formattedQuestion);
      userAnswers[formattedQuestion['id']] = questionData['userAnswer'];
    }

    Navigator.pop(context); // Close loading dialog

    // Navigate to question review screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionReviewScreen(
          testResult: result,
          questions: questions,
          userAnswers: userAnswers,
        ),
      ),
    );
  } catch (e) {
    Navigator.pop(context); // Close loading dialog if still open
    print('Error loading question review: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error loading question review: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Add this method to clear the cache periodically
void _clearQuestionCache() {
  _generatedQuestionHashes.clear();
  _questionCache.clear();
  print('Question cache cleared');
}

List<Map<String, dynamic>> _getUniqueRealisticFallbackQuestions(String subject, String difficulty, int count) {
  Map<String, List<Map<String, dynamic>>> questionBank = {
    'Physics': [
      {
        'questionText': 'A ball is thrown vertically upward with an initial velocity of 20 m/s. What is the maximum height reached? (g = 10 m/s²)',
        'options': [
          {'id': 'A', 'text': '10 m'},
          {'id': 'B', 'text': '20 m'},
          {'id': 'C', 'text': '30 m'},
          {'id': 'D', 'text': '40 m'},
        ],
        'correctAnswer': 'B',
        'explanation': 'Using v² = u² + 2as, at maximum height v = 0, u = 20 m/s, a = -g = -10 m/s². So 0 = 400 - 20h, h = 20 m.',
        'topic': 'Kinematics',
      },
      {
        'questionText': 'A car accelerates from rest at 2 m/s² for 10 seconds. What distance does it cover?',
        'options': [
          {'id': 'A', 'text': '50 m'},
          {'id': 'B', 'text': '100 m'},
          {'id': 'C', 'text': '200 m'},
          {'id': 'D', 'text': '400 m'},
        ],
        'correctAnswer': 'B',
        'explanation': 'Using s = ut + ½at², where u = 0, a = 2 m/s², t = 10s. So s = 0 + ½(2)(10)² = 100 m.',
        'topic': 'Motion',
      },
      {
        'questionText': 'The SI unit of electric field intensity is:',
        'options': [
          {'id': 'A', 'text': 'N/C'},
          {'id': 'B', 'text': 'V/m'},
          {'id': 'C', 'text': 'Both A and B'},
          {'id': 'D', 'text': 'J/C'},
        ],
        'correctAnswer': 'C',
        'explanation': 'Electric field intensity can be expressed as force per unit charge (N/C) or voltage per unit distance (V/m). Both are equivalent.',
        'topic': 'Electrostatics',
      },
      {
        'questionText': 'A spring with spring constant k = 100 N/m is compressed by 0.1 m. What is the potential energy stored?',
        'options': [
          {'id': 'A', 'text': '0.5 J'},
          {'id': 'B', 'text': '1.0 J'},
          {'id': 'C', 'text': '5.0 J'},
          {'id': 'D', 'text': '10 J'},
        ],
        'correctAnswer': 'A',
        'explanation': 'Potential energy in spring = ½kx² = ½(100)(0.1)² = ½(100)(0.01) = 0.5 J.',
        'topic': 'Energy',
      },
      {
        'questionText': 'What is the frequency of a wave with wavelength 2 m and speed 10 m/s?',
        'options': [
          {'id': 'A', 'text': '5 Hz'},
          {'id': 'B', 'text': '10 Hz'},
          {'id': 'C', 'text': '20 Hz'},
          {'id': 'D', 'text': '0.2 Hz'},
        ],
        'correctAnswer': 'A',
        'explanation': 'Using v = fλ, where v = 10 m/s, λ = 2 m. So f = v/λ = 10/2 = 5 Hz.',
        'topic': 'Waves',
      },
    ],
    'Chemistry': [
      {
        'questionText': 'Which of the following is the most electronegative element?',
        'options': [
          {'id': 'A', 'text': 'Oxygen'},
          {'id': 'B', 'text': 'Fluorine'},
          {'id': 'C', 'text': 'Nitrogen'},
          {'id': 'D', 'text': 'Chlorine'},
        ],
        'correctAnswer': 'B',
        'explanation': 'Fluorine is the most electronegative element with an electronegativity value of 4.0 on the Pauling scale.',
        'topic': 'Periodic Properties',
      },
      {
        'questionText': 'What is the hybridization of carbon in methane (CH₄)?',
        'options': [
          {'id': 'A', 'text': 'sp'},
          {'id': 'B', 'text': 'sp²'},
          {'id': 'C', 'text': 'sp³'},
          {'id': 'D', 'text': 'sp³d'},
        ],
        'correctAnswer': 'C',
        'explanation': 'In methane, carbon forms four sigma bonds with hydrogen atoms, requiring sp³ hybridization.',
        'topic': 'Chemical Bonding',
      },
      {
        'questionText': 'The molecular formula of benzene is:',
        'options': [
          {'id': 'A', 'text': 'C₆H₆'},
          {'id': 'B', 'text': 'C₆H₁₂'},
          {'id': 'C', 'text': 'C₆H₁₄'},
          {'id': 'D', 'text': 'C₆H₁₀'},
        ],
        'correctAnswer': 'A',
        'explanation': 'Benzene has the molecular formula C₆H₆ with a ring structure containing alternating double bonds.',
        'topic': 'Organic Chemistry',
      },
      {
        'questionText': 'Which gas is evolved when zinc reacts with dilute hydrochloric acid?',
        'options': [
          {'id': 'A', 'text': 'Oxygen'},
          {'id': 'B', 'text': 'Hydrogen'},
          {'id': 'C', 'text': 'Chlorine'},
          {'id': 'D', 'text': 'Carbon dioxide'},
        ],
        'correctAnswer': 'B',
        'explanation': 'Zn + 2HCl → ZnCl₂ + H₂. Hydrogen gas is evolved when zinc reacts with dilute HCl.',
        'topic': 'Acids and Bases',
      },
      {
        'questionText': 'What is the pH of a neutral solution at 25°C?',
        'options': [
          {'id': 'A', 'text': '0'},
          {'id': 'B', 'text': '7'},
          {'id': 'C', 'text': '14'},
          {'id': 'D', 'text': '1'},
        ],
        'correctAnswer': 'B',
        'explanation': 'At 25°C, pure water has a pH of 7, which is considered neutral.',
        'topic': 'pH and Solutions',
      },
    ],
    'Mathematics': [
      {
        'questionText': 'What is the derivative of sin(x) with respect to x?',
        'options': [
          {'id': 'A', 'text': 'cos(x)'},
          {'id': 'B', 'text': '-cos(x)'},
          {'id': 'C', 'text': 'sin(x)'},
          {'id': 'D', 'text': '-sin(x)'},
        ],
        'correctAnswer': 'A',
        'explanation': 'The derivative of sin(x) with respect to x is cos(x). This is a fundamental trigonometric derivative.',
        'topic': 'Calculus',
      },
      {
        'questionText': 'If log₁₀(x) = 2, then x equals:',
        'options': [
          {'id': 'A', 'text': '10'},
          {'id': 'B', 'text': '20'},
          {'id': 'C', 'text': '100'},
          {'id': 'D', 'text': '1000'},
        ],
        'correctAnswer': 'C',
        'explanation': 'If log₁₀(x) = 2, then x = 10² = 100.',
        'topic': 'Logarithms',
      },
      {
        'questionText': 'The sum of first n natural numbers is:',
        'options': [
          {'id': 'A', 'text': 'n(n+1)'},
          {'id': 'B', 'text': 'n(n+1)/2'},
          {'id': 'C', 'text': 'n(n-1)/2'},
          {'id': 'D', 'text': 'n²'},
        ],
        'correctAnswer': 'B',
        'explanation': 'The sum of first n natural numbers is given by the formula n(n+1)/2.',
        'topic': 'Sequences and Series',
      },
      {
        'questionText': 'What is the value of sin(90°)?',
        'options': [
          {'id': 'A', 'text': '0'},
          {'id': 'B', 'text': '1'},
          {'id': 'C', 'text': '√2/2'},
          {'id': 'D', 'text': '√3/2'},
        ],
        'correctAnswer': 'B',
        'explanation': 'sin(90°) = 1. This is a fundamental trigonometric value.',
        'topic': 'Trigonometry',
      },
      {
        'questionText': 'What is the integral of x² dx?',
        'options': [
          {'id': 'A', 'text': 'x³ + C'},
          {'id': 'B', 'text': 'x³/3 + C'},
          {'id': 'C', 'text': '2x + C'},
          {'id': 'D', 'text': '3x² + C'},
        ],
        'correctAnswer': 'B',
        'explanation': 'The integral of x² is x³/3 + C, where C is the constant of integration.',
        'topic': 'Integration',
      },
    ],
  };

  List<Map<String, dynamic>> subjectQuestions = questionBank[subject] ?? questionBank['Physics']!;
  List<Map<String, dynamic>> selectedQuestions = [];
  
  // Filter out already used questions
  var availableQuestions = subjectQuestions.where((q) {
    String questionHash = _generateQuestionHash(q['questionText']);
    return !_generatedQuestionHashes.contains(questionHash);
  }).toList();
  
  // Shuffle to get random selection
  availableQuestions.shuffle();
  
  for (int i = 0; i < count && i < availableQuestions.length; i++) {
    Map<String, dynamic> baseQuestion = availableQuestions[i];
    Map<String, dynamic> question = {
      'id': 'fallback_${DateTime.now().millisecondsSinceEpoch}_$i',
      'questionText': baseQuestion['questionText'],
      'subject': subject,
      'difficulty': difficulty,
      'type': 'mcq',
      'marks': 4,
      'options': baseQuestion['options'],
      'correctAnswer': baseQuestion['correctAnswer'],
      'explanation': baseQuestion['explanation'],
      'topic': baseQuestion['topic'],
      'negativeMarking': 1.0,
      'partialMarking': 0.0,
    };
    
    selectedQuestions.add(question);
    _generatedQuestionHashes.add(_generateQuestionHash(question['questionText']));
  }
  
  return selectedQuestions;
}


// Updated Practice Methods - Using Database Questions
// Updated Practice Methods - Using Database Questions
void _startQuickPractice() async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading practice questions...', style: GoogleFonts.comicNeue()),
        ],
      ),
    ),
  );

  try {
    List<Map<String, dynamic>> allQuestions = [];
    
    // Get Physics questions (4 questions)
    final physicsQuery = await FirebaseFirestore.instance
        .collection('practice_questions')
        .where('subject', isEqualTo: 'Physics')
        .get();
    
    // Get Chemistry questions (3 questions)
    final chemistryQuery = await FirebaseFirestore.instance
        .collection('practice_questions')
        .where('subject', isEqualTo: 'Chemistry')
        .get();
    
    // Get Mathematics questions (3 questions)
    final mathsQuery = await FirebaseFirestore.instance
        .collection('practice_questions')
        .where('subject', isEqualTo: 'Mathematics')
        .get();

    // Collect and shuffle questions from each subject
    List<Map<String, dynamic>> physicsQuestions = physicsQuery.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    physicsQuestions.shuffle();
    
    List<Map<String, dynamic>> chemistryQuestions = chemistryQuery.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    chemistryQuestions.shuffle();
    
    List<Map<String, dynamic>> mathsQuestions = mathsQuery.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    mathsQuestions.shuffle();

    // Take required number of questions from each subject
    allQuestions.addAll(physicsQuestions.take(4));
    allQuestions.addAll(chemistryQuestions.take(3));
    allQuestions.addAll(mathsQuestions.take(3));

    Navigator.pop(context);

    if (allQuestions.length < 5) {
      _showErrorDialog(context, 'Insufficient Questions', 
          'Not enough practice questions available. Please add more questions from the admin panel.');
      return;
    }

    // Final shuffle for random order
    allQuestions.shuffle();

    final quickTest = {
      'title': 'Quick Practice - ${allQuestions.length} Questions',
      'description': 'Mixed questions from Physics, Chemistry, and Mathematics',
      'subject': 'All',
      'difficulty': 'Mixed',
      'duration': 20,
      'questionCount': allQuestions.length,
      'maxScore': allQuestions.length * 4,
      'type': 'Quick Practice',
      'isLive': false,
      'isPremium': false,
      'questions': allQuestions,
    };
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestTakingScreen(
          test: quickTest,
          testId: 'quick_practice_${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    );
  } catch (e) {
    Navigator.pop(context);
    print('Quick practice error: $e');
    _showErrorDialog(context, 'Error', 'Could not load practice questions. Please try again.');
  }
}

void _showErrorDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold)),
      content: Text(message, style: GoogleFonts.comicNeue()),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}


void _startSubjectPractice(String subject, int questionCount) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading $subject questions...', style: GoogleFonts.comicNeue()),
        ],
      ),
    ),
  );

  try {
    final questionsQuery = await FirebaseFirestore.instance
        .collection('practice_questions')
        .where('subject', isEqualTo: subject)
        .get();

    List<Map<String, dynamic>> questions = questionsQuery.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    questions.shuffle();
    if (questions.length > questionCount) {
      questions = questions.take(questionCount).toList();
    }

    Navigator.pop(context);

    if (questions.isEmpty) {
      _showErrorDialog(context, 'No Questions Available', 
          'No $subject practice questions are available. Please add questions from the admin panel.');
      return;
    }

    final subjectTest = {
      'title': '$subject Practice - ${questions.length} Questions',
      'description': 'Practice questions from $subject',
      'subject': subject,
      'difficulty': 'Mixed',
      'duration': questions.length * 2,
      'questionCount': questions.length,
      'maxScore': questions.length * 4,
      'type': 'Subject Practice',
      'isLive': false,
      'isPremium': false,
      'questions': questions,
    };
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestTakingScreen(
          test: subjectTest,
          testId: 'subject_practice_${subject.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    );
  } catch (e) {
    Navigator.pop(context);
    print('Subject practice error: $e');
    _showErrorDialog(context, 'Error', 'Could not load $subject questions. Please try again.');
  }
}

void _startDailyChallenge() async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading daily challenge...', style: GoogleFonts.comicNeue()),
        ],
      ),
    ),
  );

  try {
    List<Map<String, dynamic>> challengeQuestions = [];
    
    // Get one question from each subject
    for (String subject in ['Physics', 'Chemistry', 'Mathematics']) {
      final subjectQuery = await FirebaseFirestore.instance
          .collection('practice_questions')
          .where('subject', isEqualTo: subject)
          .get();
      
      if (subjectQuery.docs.isNotEmpty) {
        final questions = subjectQuery.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        
        questions.shuffle();
        challengeQuestions.add(questions.first);
      }
    }

    Navigator.pop(context);

    if (challengeQuestions.isEmpty) {
      _showErrorDialog(context, 'No Challenge Available', 
          'Daily challenge questions are not available. Please add questions from the admin panel.');
      return;
    }

    final challengeTest = {
      'title': 'Daily Challenge - ${DateTime.now().day}/${DateTime.now().month}',
      'description': 'Today\'s challenge: ${challengeQuestions.length} questions from different subjects',
      'subject': 'All',
      'difficulty': 'Mixed',
      'duration': 15,
      'questionCount': challengeQuestions.length,
      'maxScore': challengeQuestions.length * 4,
      'type': 'Daily Challenge',
      'isLive': false,
      'isPremium': false,
      'questions': challengeQuestions,
    };
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestTakingScreen(
          test: challengeTest,
          testId: 'daily_challenge_${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    );
  } catch (e) {
    Navigator.pop(context);
    print('Daily challenge error: $e');
    _showErrorDialog(context, 'Error', 'Could not load daily challenge. Please try again.');
  }
}

void _startWeakAreaPractice(String subject) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading $subject practice...', style: GoogleFonts.comicNeue()),
        ],
      ),
    ),
  );

  try {
    final questionsQuery = await FirebaseFirestore.instance
        .collection('practice_questions')
        .where('subject', isEqualTo: subject)
        .get();

    List<Map<String, dynamic>> questions = questionsQuery.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    questions.shuffle();
    if (questions.length > 10) {
      questions = questions.take(10).toList();
    }

    Navigator.pop(context);

    if (questions.isEmpty) {
      _showErrorDialog(context, 'No Questions Available', 
          'No $subject practice questions available for weak area practice.');
      return;
    }

    final weakAreaTest = {
      'title': 'Weak Area Practice - $subject',
      'description': 'Targeted practice questions for $subject',
      'subject': subject,
      'difficulty': 'Mixed',
      'duration': 20,
      'questionCount': questions.length,
      'maxScore': questions.length * 4,
      'type': 'Weak Area Practice',
      'isLive': false,
      'isPremium': false,
      'questions': questions,
    };
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestTakingScreen(
          test: weakAreaTest,
          testId: 'weak_area_${subject.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    );
  } catch (e) {
    Navigator.pop(context);
    print('Weak area practice error: $e');
    _showErrorDialog(context, 'Error', 'Could not load practice questions. Please try again.');
  }
}

void _showSubjectPractice(BuildContext context, bool isDark, ThemeData theme) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Subject Practice',
        style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _subjects.where((s) => s != 'All').map((subject) {
          return ListTile(
            leading: Icon(_getSubjectIcon(subject), color: _getSubjectColor(subject)),
            title: Text(subject),
            onTap: () {
              Navigator.pop(context);
              _showQuestionCountDialog(subject);
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
      ],
    ),
  );
}

static final Set<String> _generatedQuestionHashes = <String>{};
static final Map<String, List<Map<String, dynamic>>> _questionCache = {};

void _showQuestionCountDialog(String subject) {
  int questionCount = 10;
  
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(
          '$subject Practice',
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How many questions would you like to practice?'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [5, 10, 15, 20].map((count) {
                return ChoiceChip(
                  label: Text('$count'),
                  selected: questionCount == count,
                  onSelected: (selected) {
                    setDialogState(() {
                      questionCount = count;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startSubjectPractice(subject, questionCount);
            },
            child: Text('Start Practice'),
          ),
        ],
      ),
    ),
  );
}

void _showWeakAreas(BuildContext context, bool isDark, ThemeData theme) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(child: CircularProgressIndicator()),
  );

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login to view weak areas')),
      );
      return;
    }

    // Analyze user's performance
    final resultsSnapshot = await FirebaseFirestore.instance
        .collection('test_results')
        .where('userId', isEqualTo: user.uid)
        .get();

    Map<String, double> subjectPerformance = {};
    Map<String, int> subjectAttempts = {};

    for (var doc in resultsSnapshot.docs) {
      final data = doc.data();
      final subjectWise = data['subjectWise'] as Map<String, dynamic>? ?? {};
      
      subjectWise.forEach((subject, subjectData) {
        final percentage = (subjectData['percentage'] ?? 0.0).toDouble();
        subjectPerformance[subject] = (subjectPerformance[subject] ?? 0.0) + percentage;
        subjectAttempts[subject] = (subjectAttempts[subject] ?? 0) + 1;
      });
    }

    // Calculate average performance
    Map<String, double> avgPerformance = {};
    subjectPerformance.forEach((subject, total) {
      avgPerformance[subject] = total / (subjectAttempts[subject] ?? 1);
    });

    // Find weakest subjects (below 60%)
    List<String> weakSubjects = avgPerformance.entries
        .where((entry) => entry.value < 60.0)
        .map((entry) => entry.key)
        .toList();

    Navigator.pop(context);

    if (weakSubjects.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Great Performance!',
            style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'You\'re performing well in all subjects! Keep up the good work.',
            style: GoogleFonts.comicNeue(),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Continue'),
            ),
          ],
        ),
      );
      return;
    }

    // Show weak areas dialog with AI-generated practice
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Your Weak Areas',
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Based on your performance, you need improvement in:',
              style: GoogleFonts.comicNeue(),
            ),
            SizedBox(height: 16),
            ...weakSubjects.map((subject) {
              final performance = avgPerformance[subject] ?? 0.0;
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(_getSubjectIcon(subject), color: _getSubjectColor(subject)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Average: ${performance.toStringAsFixed(1)}%',
                            style: GoogleFonts.comicNeue(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _startWeakAreaPractice(subject);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getSubjectColor(subject),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Practice'),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later'),
          ),
        ],
      ),
    );
  } catch (e) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error analyzing weak areas: $e')),
    );
  }
}


  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Physics':
        return Colors.blue;
      case 'Chemistry':
        return Colors.green;
      case 'Mathematics':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject) {
      case 'Physics':
        return Icons.science;
      case 'Chemistry':
        return Icons.biotech;
      case 'Mathematics':
        return Icons.calculate;
      default:
        return Icons.quiz;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
