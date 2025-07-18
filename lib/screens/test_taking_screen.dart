// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_html/flutter_html.dart';
import 'dart:async';
import 'dart:math' as math;

class TestTakingScreen extends StatefulWidget {
  final Map<String, dynamic> test;
  final String testId;

  const TestTakingScreen({Key? key, required this.test, required this.testId}) : super(key: key);

  @override
  State<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends State<TestTakingScreen> with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  Map<int, String> _selectedAnswers = {};
  Map<int, List<String>> _selectedMultipleAnswers = {};
  Map<int, String> _numericalAnswers = {};
  
  List<Map<String, dynamic>> _questions = [];
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isTestCompleted = false;
  bool _isLoading = true;
  
  late AnimationController _questionAnimationController;
  late AnimationController _timerAnimationController;
  late Animation<double> _slideAnimation;
  late Animation<Color?> _timerColorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadQuestions();
    _startTimer();
  }

  void _initializeAnimations() {
    _questionAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _timerAnimationController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _questionAnimationController,
      curve: Curves.easeInOut,
    ));

    _timerColorAnimation = ColorTween(
      begin: Colors.green,
      end: Colors.red,
    ).animate(_timerAnimationController);

    _questionAnimationController.forward();
  }

  Future<void> _loadQuestions() async {
  try {
    setState(() => _isLoading = true);
    
    print('Loading questions for testId: ${widget.testId}');
    
    // FIXED: Check if test has pre-generated questions (for practice tests)
    if (widget.test['questions'] != null && widget.test['questions'] is List) {
      print('Using pre-generated questions from test data');
      final questionsData = widget.test['questions'] as List<dynamic>;
      _questions = questionsData.map((q) {
        if (q is Map<String, dynamic>) {
          return Map<String, dynamic>.from(q);
        }
        return q as Map<String, dynamic>;
      }).toList();
      
      print('Loaded ${_questions.length} pre-generated questions');
      
      // Debug: Print first question to verify data
      if (_questions.isNotEmpty) {
        print('First question: ${_questions[0]['questionText']}');
        print('Options: ${_questions[0]['options']}');
      }
      
      setState(() => _isLoading = false);
      return;
    }
    
    // Load questions for this test from Firestore
    final questionsSnapshot = await FirebaseFirestore.instance
        .collection('questions')
        .where('testId', isEqualTo: widget.testId)
        .get();

    print('Found ${questionsSnapshot.docs.length} questions in Firestore');

    if (questionsSnapshot.docs.isEmpty) {
      print('No questions found, generating sample questions');
      _questions = _generateSampleQuestions();
    } else {
      _questions = questionsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        print('Loaded question: ${data['questionText']?.substring(0, 50)}...');
        return data;
      }).toList();
    }

    // Shuffle questions for variety
    _questions.shuffle();
    
    // Limit questions based on test configuration
    final questionCount = widget.test['questionCount'] ?? _questions.length;
    if (_questions.length > questionCount) {
      _questions = _questions.take(questionCount).toList();
    }

    print('Final question count: ${_questions.length}');
    setState(() => _isLoading = false);
  } catch (e) {
    print('Error loading questions: $e');
    setState(() {
      _isLoading = false;
      _questions = _generateSampleQuestions();
    });
  }
}




  List<Map<String, dynamic>> _generateSampleQuestions() {
    // Generate sample questions for practice/demo
    return [
      {
        'id': 'sample_1',
        'questionText': 'What is the acceleration due to gravity on Earth?',
        'type': 'mcq',
        'subject': 'Physics',
        'difficulty': 'Easy',
        'marks': 4,
        'options': [
          {'id': 'A', 'text': '9.8 m/s²'},
          {'id': 'B', 'text': '10 m/s²'},
          {'id': 'C', 'text': '8.9 m/s²'},
          {'id': 'D', 'text': '11 m/s²'},
        ],
        'correctAnswer': 'A',
        'explanation': 'The standard acceleration due to gravity on Earth is approximately 9.8 m/s².',
      },
      {
        'id': 'sample_2',
        'questionText': 'Which of the following are noble gases? (Select all that apply)',
        'type': 'multiple',
        'subject': 'Chemistry',
        'difficulty': 'Medium',
        'marks': 4,
        'options': [
          {'id': 'A', 'text': 'Helium (He)'},
          {'id': 'B', 'text': 'Oxygen (O₂)'},
          {'id': 'C', 'text': 'Neon (Ne)'},
          {'id': 'D', 'text': 'Nitrogen (N₂)'},
        ],
        'correctAnswers': ['A', 'C'],
        'explanation': 'Noble gases include Helium (He) and Neon (Ne). Oxygen and Nitrogen are not noble gases.',
      },
      {
        'id': 'sample_3',
        'questionText': 'Find the derivative of f(x) = x³ + 2x² - 5x + 3 at x = 2',
        'type': 'numerical',
        'subject': 'Mathematics',
        'difficulty': 'Hard',
        'marks': 4,
        'numericalAnswer': 15,
        'tolerance': 0.1,
        'explanation': 'f\'(x) = 3x² + 4x - 5. At x = 2: f\'(2) = 3(4) + 4(2) - 5 = 12 + 8 - 5 = 15',
      },
    ];
  }

  void _startTimer() {
  final duration = widget.test['duration'] ?? 30; // Default 30 minutes
  _remainingSeconds = duration * 60;
  
  _timer = Timer.periodic(Duration(seconds: 1), (timer) {
    if (mounted) {
      setState(() {
        _remainingSeconds--;
        
        // Update timer animation based on remaining time
        final totalSeconds = (widget.test['duration'] ?? 30) * 60;
        final progress = 1.0 - (_remainingSeconds / totalSeconds);
        _timerAnimationController.value = progress;
        
        // Auto-submit when time runs out (no popup)
        if (_remainingSeconds <= 0) {
          _timer?.cancel();
          _autoSubmitTest(); // Call auto-submit instead
        }
      });
    }
  });
}

// Add this new method for auto-submit
Future<void> _autoSubmitTest() async {
  if (!mounted || _isTestCompleted) return;
  
  print('Time up! Auto-submitting test...');
  await _calculateAndSaveResults();
  
  if (mounted) {
    setState(() {
      _isTestCompleted = true;
    });
  }
}

  @override
  void dispose() {
    _timer?.cancel();
    _questionAnimationController.dispose();
    _timerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              SizedBox(height: 16),
              Text(
                'Loading test questions...',
                style: GoogleFonts.comicNeue(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isTestCompleted) {
      return _buildResultScreen(theme, isDark);
    }

    return WillPopScope(
  onWillPop: () async {
    return await _showExitConfirmation();
  },
  child: Scaffold(
    backgroundColor: theme.scaffoldBackgroundColor,
    appBar: _buildAppBar(theme, isDark),
    body: Column(
      children: [
        _buildProgressBar(theme),
        _buildTimerBar(theme),
        Expanded(
          child: _buildQuestionContent(theme, isDark),
        ),
        _buildNavigationButtons(theme),
      ],
    ),
  ),
);
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: theme.appBarTheme.backgroundColor,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.test['title'] ?? 'Test',
            style: GoogleFonts.comicNeue(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${widget.test['subject']} • ${widget.test['difficulty']}',
            style: GoogleFonts.comicNeue(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
      actions: [
  IconButton(
    onPressed: () => _showQuestionNavigator(),
    icon: Icon(Icons.grid_view),
    tooltip: 'Question Navigator',
  ),
  IconButton(
    onPressed: () => _showInstructions(),
    icon: Icon(Icons.help_outline),
  ),
  IconButton(
    onPressed: () async {
      final shouldExit = await _showExitConfirmation();
      // The exit logic is already handled in _showExitConfirmation
    },
    icon: Icon(Icons.close),
    tooltip: 'Exit Test',
  ),
],
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    final progress = _questions.isEmpty ? 0.0 : (_currentQuestionIndex + 1) / _questions.length;
    
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                style: GoogleFonts.comicNeue(fontWeight: FontWeight.w600),
              ),
              Text(
                '${(_questions.length - _currentQuestionIndex - 1)} remaining',
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBar(ThemeData theme) {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final isLowTime = _remainingSeconds < 300; // Less than 5 minutes
    
    return AnimatedBuilder(
      animation: _timerColorAnimation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isLowTime ? Colors.red.withOpacity(0.1) : Colors.transparent,
          child: Row(
            children: [
              Icon(
                Icons.timer,
                color: isLowTime ? Colors.red : _timerColorAnimation.value,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isLowTime ? Colors.red : _timerColorAnimation.value,
                ),
              ),
              Spacer(),
              if (isLowTime)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'TIME RUNNING OUT!',
                    style: GoogleFonts.comicNeue(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestionContent(ThemeData theme, bool isDark) {
  if (_questions.isEmpty) {
    return Center(
      child: Text(
        'No questions available',
        style: GoogleFonts.comicNeue(fontSize: 16),
      ),
    );
  }

  final question = _questions[_currentQuestionIndex];
  
  return SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestionHeader(question, theme, isDark),
        SizedBox(height: 20),
        _buildQuestionText(question, theme),
        SizedBox(height: 24),
        _buildAnswerOptions(question, theme, isDark),
      ],
    ),
  );
}

  Widget _buildQuestionHeader(Map<String, dynamic> question, ThemeData theme, bool isDark) {

    final marks = question['marks'] ?? widget.test['defaultMarks'] ?? 4;
    final negativeMarking = question['negativeMarking'] ?? widget.test['defaultNegativeMarking'] ?? 0;
    final partialMarking = question['partialMarking'] ?? widget.test['defaultPartialMarking'] ?? 0;

    return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? Color(0xFF1C2542) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? Colors.white24 : Colors.grey.shade200,
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getSubjectColor(question['subject']).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getSubjectIcon(question['subject']),
                color: _getSubjectColor(question['subject']),
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question['subject'] ?? 'General',
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${question['difficulty']} • ${question['type'].toUpperCase()}',
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
        
        SizedBox(height: 12),
        
        // Marking Information
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Positive marks
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+$marks',
                  style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              
              if (negativeMarking > 0) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-$negativeMarking',
                    style: GoogleFonts.comicNeue(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
              
              if (partialMarking > 0) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Partial: +$partialMarking',
                    style: GoogleFonts.comicNeue(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
              
              Spacer(),
              
              Text(
                'Marks',
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  }

  Widget _buildQuestionText(Map<String, dynamic> question, ThemeData theme) {
  final questionText = question['questionText'] ?? 'Question text not available';
  
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: theme.colorScheme.primary.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: theme.colorScheme.primary.withOpacity(0.2),
      ),
    ),
    child: Html(
      data: questionText,
      style: {
        "body": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(16),
          fontWeight: FontWeight.w600,
          lineHeight: LineHeight(1.5),
          fontFamily: GoogleFonts.comicNeue().fontFamily,
        ),
        "p": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        "sup": Style(
          fontSize: FontSize(12),
          verticalAlign: VerticalAlign.sup,
        ),
        "sub": Style(
          fontSize: FontSize(12),
          verticalAlign: VerticalAlign.sub,
        ),
        "strong": Style(
          fontWeight: FontWeight.bold,
        ),
        "em": Style(
          fontStyle: FontStyle.italic,
        ),
        "u": Style(
          textDecoration: TextDecoration.underline,
        ),
        "h1": Style(
          fontSize: FontSize(20),
          fontWeight: FontWeight.bold,
          margin: Margins.only(bottom: 8),
        ),
        "h2": Style(
          fontSize: FontSize(18),
          fontWeight: FontWeight.bold,
          margin: Margins.only(bottom: 6),
        ),
        "h3": Style(
          fontSize: FontSize(16),
          fontWeight: FontWeight.bold,
          margin: Margins.only(bottom: 4),
        ),
      },
    ),
  );
}


  Widget _buildAnswerOptions(Map<String, dynamic> question, ThemeData theme, bool isDark) {
    final questionType = question['type'] ?? 'mcq';
    
    switch (questionType) {
      case 'mcq':
        return _buildMCQOptions(question, theme, isDark);
      case 'multiple':
        return _buildMultipleChoiceOptions(question, theme, isDark);
      case 'numerical':
        return _buildNumericalInput(question, theme, isDark);
      default:
        return _buildMCQOptions(question, theme, isDark);
    }
  }

  Widget _buildMCQOptions(Map<String, dynamic> question, ThemeData theme, bool isDark) {
  final options = question['options'] as List<dynamic>? ?? [];
  
  return Column(
    children: options.map<Widget>((option) {
      final optionId = option['id'];
      final optionText = option['text'];
      final isSelected = _selectedAnswers[_currentQuestionIndex] == optionId;
      
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedAnswers[_currentQuestionIndex] = optionId;
          });
          HapticFeedback.lightImpact();
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.colorScheme.primary.withOpacity(0.1)
                : (isDark ? Color(0xFF1C2542) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.white24 : Colors.grey.shade200),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : Colors.grey,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              SizedBox(width: 12),
              Text(
                optionId,
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Html(
                  data: optionText,
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(14),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? theme.colorScheme.primary : null,
                      fontFamily: GoogleFonts.comicNeue().fontFamily,
                    ),
                    "p": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                    ),
                    "sup": Style(
                      fontSize: FontSize(10),
                      verticalAlign: VerticalAlign.sup,
                    ),
                    "sub": Style(
                      fontSize: FontSize(10),
                      verticalAlign: VerticalAlign.sub,
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
}


  Widget _buildMultipleChoiceOptions(Map<String, dynamic> question, ThemeData theme, bool isDark) {
  final options = question['options'] as List<dynamic>? ?? [];
  final selectedOptions = _selectedMultipleAnswers[_currentQuestionIndex] ?? [];
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Select all correct answers',
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 16),
      ...options.map<Widget>((option) {
        final optionId = option['id'];
        final optionText = option['text'];
        final isSelected = selectedOptions.contains(optionId);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              if (!_selectedMultipleAnswers.containsKey(_currentQuestionIndex)) {
                _selectedMultipleAnswers[_currentQuestionIndex] = [];
              }
              
              if (isSelected) {
                _selectedMultipleAnswers[_currentQuestionIndex]!.remove(optionId);
              } else {
                _selectedMultipleAnswers[_currentQuestionIndex]!.add(optionId);
              }
            });
            HapticFeedback.lightImpact();
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? theme.colorScheme.secondary.withOpacity(0.1)
                  : (isDark ? Color(0xFF1C2542) : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? theme.colorScheme.secondary
                    : (isDark ? Colors.white24 : Colors.grey.shade200),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isSelected ? theme.colorScheme.secondary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.secondary : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                SizedBox(width: 12),
                Text(
                  optionId,
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isSelected ? theme.colorScheme.secondary : null,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Html(
                    data: optionText,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(14),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? theme.colorScheme.secondary : null,
                        fontFamily: GoogleFonts.comicNeue().fontFamily,
                      ),
                      "p": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                      "sup": Style(
                        fontSize: FontSize(10),
                        verticalAlign: VerticalAlign.sup,
                      ),
                      "sub": Style(
                        fontSize: FontSize(10),
                        verticalAlign: VerticalAlign.sub,
                      ),
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ],
  );
}


  Widget _buildNumericalInput(Map<String, dynamic> question, ThemeData theme, bool isDark) {
  // Use a more reliable approach for text controllers
  final String currentValue = _numericalAnswers[_currentQuestionIndex] ?? '';
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calculate, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Enter your numerical answer',
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 16),
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C2542) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Answer:',
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 12),
            TextFormField(
              key: ValueKey('numerical_${_currentQuestionIndex}'),
              initialValue: currentValue,
              keyboardType: TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                // Allow numbers, decimal point, and minus sign
                FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*')),
              ],
              style: GoogleFonts.comicNeue(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Enter numerical value',
                hintStyle: GoogleFonts.comicNeue(
                  color: Colors.grey.shade500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                // Immediate update without setState to avoid rebuilding
                _numericalAnswers[_currentQuestionIndex] = value;
              },
              // Enable better keyboard handling
              textInputAction: TextInputAction.done,
              autofocus: false,
            ),
            if (question['answerUnit'] != null) ...[
              SizedBox(height: 8),
              Text(
                'Unit: ${question['answerUnit']}',
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

  Widget _buildNavigationButtons(ThemeData theme) {
  final isLastQuestion = _currentQuestionIndex == _questions.length - 1;
  
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.scaffoldBackgroundColor,
      border: Border(
        top: BorderSide(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
    ),
    child: Column(
      children: [
        // Question status indicator
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.grid_view, size: 16, color: theme.colorScheme.primary),
              SizedBox(width: 4),
              Text(
                'Answered: ${_getAnsweredCount()}/${_questions.length}',
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: _showQuestionNavigator,
                child: Text(
                  'View All',
                  style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 12),
        
        // Navigation buttons - REMOVED GREYED OUT CONDITION
        Row(
          children: [
            if (_currentQuestionIndex > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _previousQuestion, // Always enabled
                  icon: Icon(Icons.arrow_back),
                  label: Text(
                    'Previous',
                    style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            
            if (_currentQuestionIndex > 0) SizedBox(width: 12),
            
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: isLastQuestion ? _submitTest : _nextQuestion, // Always enabled
                icon: Icon(isLastQuestion ? Icons.check : Icons.arrow_forward),
                label: Text(
                  isLastQuestion ? 'Submit Test' : 'Next',
                  style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastQuestion ? Colors.green : theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


int _getAnsweredCount() {
  int count = 0;
  for (int i = 0; i < _questions.length; i++) {
    if (_isQuestionAnswered(i)) {
      count++;
    }
  }
  return count;
}


  bool _hasAnsweredCurrentQuestion() {
    final question = _questions[_currentQuestionIndex];
    final questionType = question['type'] ?? 'mcq';
    
    switch (questionType) {
      case 'mcq':
        return _selectedAnswers.containsKey(_currentQuestionIndex);
      case 'multiple':
        return _selectedMultipleAnswers.containsKey(_currentQuestionIndex) &&
               _selectedMultipleAnswers[_currentQuestionIndex]!.isNotEmpty;
      case 'numerical':
        return _numericalAnswers.containsKey(_currentQuestionIndex) &&
               _numericalAnswers[_currentQuestionIndex]!.isNotEmpty;
      default:
        return false;
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _questionAnimationController.reset();
      setState(() {
        _currentQuestionIndex++;
      });
      _questionAnimationController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _questionAnimationController.reset();
      setState(() {
        _currentQuestionIndex--;
      });
      _questionAnimationController.forward();
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _submitTest() async {
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Submit Test',
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to submit your test? You cannot change your answers after submission.',
          style: GoogleFonts.comicNeue(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldSubmit == true) {
      _timer?.cancel();
      await _calculateAndSaveResults();
      setState(() {
        _isTestCompleted = true;
      });
    }
  }

  Future<void> _calculateAndSaveResults() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  _debugMarkingDetails();

  int correctAnswers = 0;
  int incorrectAnswers = 0;
  int unattempted = 0;
  double totalMarks = 0;
  double scoredMarks = 0;
  Map<String, dynamic> subjectWise = {};
  
  // Store detailed question-wise results for debugging
  List<Map<String, dynamic>> questionWiseResults = [];

  for (int i = 0; i < _questions.length; i++) {
    final question = _questions[i];
    final questionType = question['type'] ?? 'mcq';
    
    // FIXED: Use per-question marking values first, then fall back to test defaults
    final marks = (question['marks'] ?? widget.test['defaultMarks'] ?? 4).toDouble();
    final negativeMarking = (question['negativeMarking'] ?? widget.test['defaultNegativeMarking'] ?? 0).toDouble();
    final partialMarking = (question['partialMarking'] ?? widget.test['defaultPartialMarking'] ?? 0).toDouble();
    
    final subject = question['subject'] ?? 'General';
    
    bool isCorrect = false;
    bool isPartiallyCorrect = false;
    bool isAttempted = false;
    String userAnswer = '';
    String correctAnswer = '';

    // Initialize subject tracking
    if (!subjectWise.containsKey(subject)) {
      subjectWise[subject] = {
        'correct': 0,
        'incorrect': 0,
        'unattempted': 0,
        'totalQuestions': 0,
        'totalMarks': 0.0,
        'scoredMarks': 0.0,
      };
    }
    
    subjectWise[subject]['totalQuestions']++;
    subjectWise[subject]['totalMarks'] += marks;

    switch (questionType) {
      case 'mcq':
        if (_selectedAnswers.containsKey(i)) {
          isAttempted = true;
          userAnswer = _selectedAnswers[i]!;
          correctAnswer = question['correctAnswer'] ?? '';
          isCorrect = userAnswer == correctAnswer;
        }
        break;
      case 'multiple':
        if (_selectedMultipleAnswers.containsKey(i) && _selectedMultipleAnswers[i]!.isNotEmpty) {
          isAttempted = true;
          final correctAnswersList = List<String>.from(question['correctAnswers'] ?? []);
          final userAnswers = _selectedMultipleAnswers[i]!;
          userAnswer = userAnswers.join(', ');
          correctAnswer = correctAnswersList.join(', ');
          
          // Check for full correctness
          isCorrect = correctAnswersList.length == userAnswers.length &&
                     correctAnswersList.every((answer) => userAnswers.contains(answer));
          
          // Check for partial correctness (if partial marking is enabled)
          if (!isCorrect && partialMarking > 0) {
            final correctCount = userAnswers.where((answer) => correctAnswersList.contains(answer)).length;
            isPartiallyCorrect = correctCount > 0 && correctCount < correctAnswersList.length;
          }
        }
        break;
      case 'numerical':
        if (_numericalAnswers.containsKey(i) && _numericalAnswers[i]!.isNotEmpty) {
          isAttempted = true;
          userAnswer = _numericalAnswers[i]!;
          final correctAnswerNum = question['numericalAnswer'];
          correctAnswer = correctAnswerNum?.toString() ?? '';
          final tolerance = question['tolerance'] ?? 0.1;
          
          final userNum = double.tryParse(userAnswer);
          if (userNum != null && correctAnswerNum != null) {
            isCorrect = (userNum - correctAnswerNum).abs() <= tolerance;
          }
        }
        break;
    }

    totalMarks += marks;
    double questionScore = 0;

    if (isAttempted) {
      if (isCorrect) {
        correctAnswers++;
        questionScore = marks;
        scoredMarks += marks;
        subjectWise[subject]['correct']++;
        subjectWise[subject]['scoredMarks'] += marks;
      } else if (isPartiallyCorrect) {
        // Award partial marks
        questionScore = partialMarking;
        scoredMarks += partialMarking;
        subjectWise[subject]['scoredMarks'] += partialMarking;
        incorrectAnswers++; // Still count as incorrect for statistics
        subjectWise[subject]['incorrect']++;
      } else {
        incorrectAnswers++;
        // FIXED: Apply per-question negative marking
        questionScore = -negativeMarking;
        scoredMarks -= negativeMarking;
        subjectWise[subject]['incorrect']++;
      }
    } else {
      unattempted++;
      questionScore = 0;
      subjectWise[subject]['unattempted']++;
    }

            // Store question-wise result for detailed analysis
        questionWiseResults.add({
          'questionNumber': i + 1,
          'id': question['id'], // Add this line
          'questionText': question['questionText'], // Add this line
          'options': question['options'], // Add this line
          'correctAnswer': question['correctAnswer'], // Add this line
          'correctAnswers': question['correctAnswers'], // Add this line for multiple choice
          'explanation': question['explanation'], // Add this line
          'questionType': questionType,
          'subject': subject,
          'difficulty': question['difficulty'], // Add this line
          'marks': marks,
          'negativeMarking': negativeMarking,
          'partialMarking': partialMarking,
          'userAnswer': userAnswer,
          'isCorrect': isCorrect,
          'isPartiallyCorrect': isPartiallyCorrect,
          'isAttempted': isAttempted,
          'scoreAwarded': questionScore,
        });
  }

  // Ensure scored marks doesn't go below 0
  scoredMarks = math.max(0, scoredMarks);

  // Calculate percentages for each subject
  subjectWise.forEach((subject, data) {
    data['percentage'] = data['totalMarks'] > 0 
        ? (data['scoredMarks'] / data['totalMarks']) * 100 
        : 0.0;
  });

  final percentage = totalMarks > 0 ? (scoredMarks / totalMarks) * 100 : 0.0;
  final accuracy = (correctAnswers + incorrectAnswers) > 0 
      ? (correctAnswers / (correctAnswers + incorrectAnswers)) * 100 
      : 0.0;

  final testDuration = widget.test['duration'] ?? 30;
  final timeTaken = testDuration - (_remainingSeconds / 60);

  // Save result to Firestore with detailed marking information
  try {
    await FirebaseFirestore.instance.collection('test_results').add({
      'userId': user.uid,
      'testId': widget.testId,
      'testTitle': widget.test['title'],
      'subject': widget.test['subject'],
      'difficulty': widget.test['difficulty'],
      'score': scoredMarks.round(),
      'maxScore': totalMarks.round(),
      'percentage': percentage,
      'accuracy': accuracy,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'unattempted': unattempted,
      'totalQuestions': _questions.length,
      'timeTaken': timeTaken.round(),
      'duration': testDuration,
      'subjectWise': subjectWise,
      
      // FIXED: Store detailed question-wise results
      'questionWiseResults': questionWiseResults,
      
      'markingDetails': {
        'hasPerQuestionMarking': widget.test['allowPerQuestionMarking'] ?? false,
        'defaultNegativeMarking': widget.test['defaultNegativeMarking'] ?? 0,
        'defaultPartialMarking': widget.test['defaultPartialMarking'] ?? 0,
        'usedPerQuestionMarking': questionWiseResults.any((q) => 
          q['negativeMarking'] != (widget.test['defaultNegativeMarking'] ?? 0) ||
          q['partialMarking'] != (widget.test['defaultPartialMarking'] ?? 0)
        ),
      },
      'completedAt': FieldValue.serverTimestamp(),
      'completed': true,
    });

    // Debug logging
    print('🔍 Result Calculation Debug:');
    print('Total Questions: ${_questions.length}');
    print('Correct: $correctAnswers, Incorrect: $incorrectAnswers, Unattempted: $unattempted');
    print('Total Marks: $totalMarks, Scored Marks: $scoredMarks');
    print('Percentage: ${percentage.toStringAsFixed(2)}%');
    
    // Log per-question marking usage
    for (var qResult in questionWiseResults) {
      if (qResult['negativeMarking'] > 0 && !qResult['isCorrect'] && qResult['isAttempted']) {
        print('Q${qResult['questionNumber']}: Applied -${qResult['negativeMarking']} negative marking');
      }
    }

    // Update user's overall statistics
    await _updateUserStats(user.uid, percentage, correctAnswers + incorrectAnswers + unattempted);
    
  } catch (e) {
    print('Error saving test result: $e');
  }
}



  Future<void> _updateUserStats(String userId, double percentage, int questionsAttempted) async {
    try {
      final userStatsRef = FirebaseFirestore.instance.collection('user_stats').doc(userId);
      final userStatsDoc = await userStatsRef.get();
      
      if (userStatsDoc.exists) {
        final currentStats = userStatsDoc.data()!;
        final currentTotal = currentStats['totalScore'] ?? 0.0;
        final currentTests = currentStats['testsCompleted'] ?? 0;
        final currentQuestions = currentStats['questionsAttempted'] ?? 0;
        
        await userStatsRef.update({
          'totalScore': currentTotal + percentage,
          'testsCompleted': currentTests + 1,
          'questionsAttempted': currentQuestions + questionsAttempted,
          'averageScore': (currentTotal + percentage) / (currentTests + 1),
          'lastTestDate': FieldValue.serverTimestamp(),
        });
      } else {
        await userStatsRef.set({
          'totalScore': percentage,
          'testsCompleted': 1,
          'questionsAttempted': questionsAttempted,
          'averageScore': percentage,
          'lastTestDate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }

  Widget _buildResultScreen(ThemeData theme, bool isDark) {
    // Calculate results
    int correctAnswers = 0;
    int incorrectAnswers = 0;
    int unattempted = 0;
    double totalMarks = 0;
    double scoredMarks = 0;

    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final questionType = question['type'] ?? 'mcq';
      final marks = (question['marks'] ?? 4).toDouble();
      
      bool isCorrect = false;
      bool isAttempted = false;

      switch (questionType) {
        case 'mcq':
          if (_selectedAnswers.containsKey(i)) {
            isAttempted = true;
            isCorrect = _selectedAnswers[i] == question['correctAnswer'];
          }
          break;
        case 'multiple':
          if (_selectedMultipleAnswers.containsKey(i) && _selectedMultipleAnswers[i]!.isNotEmpty) {
            isAttempted = true;
            final correctAnswersList = List<String>.from(question['correctAnswers'] ?? []);
            final userAnswers = _selectedMultipleAnswers[i]!;
            isCorrect = correctAnswersList.length == userAnswers.length &&
                       correctAnswersList.every((answer) => userAnswers.contains(answer));
          }
          break;
        case 'numerical':
          if (_numericalAnswers.containsKey(i) && _numericalAnswers[i]!.isNotEmpty) {
            isAttempted = true;
            final userAnswer = double.tryParse(_numericalAnswers[i]!);
            final correctAnswer = question['numericalAnswer'];
            final tolerance = question['tolerance'] ?? 0.1;
            
            if (userAnswer != null && correctAnswer != null) {
              isCorrect = (userAnswer - correctAnswer).abs() <= tolerance;
            }
          }
          break;
      }

      totalMarks += marks;

      if (isAttempted) {
        if (isCorrect) {
          correctAnswers++;
          scoredMarks += marks;
        } else {
          incorrectAnswers++;
          if (widget.test['negativeMarking'] == true) {
            scoredMarks -= marks * 0.25;
          }
        }
      } else {
        unattempted++;
      }
    }

    final percentage = totalMarks > 0 ? (scoredMarks / totalMarks) * 100 : 0.0;
    final accuracy = (correctAnswers + incorrectAnswers) > 0 
        ? (correctAnswers / (correctAnswers + incorrectAnswers)) * 100 
        : 0.0;

    final testDuration = widget.test['duration'] ?? 30;
    final timeTaken = testDuration - (_remainingSeconds / 60);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text(
          'Test Results',
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Result Header
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: percentage >= 60 
                      ? [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.2)]
                      : [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: percentage >= 60 ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    percentage >= 60 ? Icons.celebration : Icons.sentiment_dissatisfied,
                    size: 64,
                    color: percentage >= 60 ? Colors.green : Colors.red,
                  ),
                  SizedBox(height: 16),
                  Text(
                    percentage >= 60 ? 'Congratulations!' : 'Keep Practicing!',
                    style: GoogleFonts.comicNeue(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: percentage >= 60 ? Colors.green : Colors.red,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.test['title'] ?? 'Test Completed',
                    style: GoogleFonts.comicNeue(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Score Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1C2542) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${scoredMarks.round()}',
                        style: GoogleFonts.comicNeue(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: percentage >= 60 ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        ' / ${totalMarks.round()}',
                        style: GoogleFonts.comicNeue(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: GoogleFonts.comicNeue(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: percentage >= 60 ? Colors.green : Colors.red,
                    ),
                  ),
                  SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage >= 60 ? Colors.green : Colors.red,
                    ),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Statistics Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Correct', '$correctAnswers', Colors.green, Icons.check_circle),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Wrong', '$incorrectAnswers', Colors.red, Icons.cancel),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Skipped', '$unattempted', Colors.orange, Icons.remove_circle),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Accuracy', '${accuracy.toStringAsFixed(1)}%', Colors.blue, Icons.track_changes),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Time', '${timeTaken.round()} min', Colors.purple, Icons.timer),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.home),
                    label: Text(
                      'Back to Tests',
                      style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.comicNeue(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.comicNeue(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _debugMarkingDetails() {
  print('🔍 Marking Details Debug:');
  print('Test Default Negative Marking: ${widget.test['defaultNegativeMarking']}');
  print('Test Default Partial Marking: ${widget.test['defaultPartialMarking']}');
  print('Allow Per-Question Marking: ${widget.test['allowPerQuestionMarking']}');
  
  for (int i = 0; i < _questions.length; i++) {
    final question = _questions[i];
    final questionMarks = question['marks'] ?? widget.test['defaultMarks'] ?? 4;
    final questionNegative = question['negativeMarking'] ?? widget.test['defaultNegativeMarking'] ?? 0;
    final questionPartial = question['partialMarking'] ?? widget.test['defaultPartialMarking'] ?? 0;
    
    print('Q${i+1}: +$questionMarks, -$questionNegative, Partial: +$questionPartial');
  }
}

  void _showInstructions() {
  // Get instructions from test data or use default
  final testInstructions = widget.test['instructions'] as List<dynamic>? ?? [];
  final hasCustomInstructions = testInstructions.isNotEmpty;
  final defaultNegative = widget.test['defaultNegativeMarking'] ?? 0;
  final defaultPartial = widget.test['defaultPartialMarking'] ?? 0;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Test Instructions',
        style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Marking Scheme Section
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marking Scheme:',
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (defaultNegative > 0)
                    Text('• Negative marking: -$defaultNegative for wrong answers'),
                  if (defaultPartial > 0)
                    Text('• Partial marking: +$defaultPartial for partially correct answers'),
                  if (widget.test['allowPerQuestionMarking'] == true)
                    Text('• Some questions may have different marking'),
                  if (defaultNegative == 0)
                    Text('• No negative marking'),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            if (hasCustomInstructions) ...[
              // Show custom instructions from admin
              Text(
                'Test-specific Instructions:',
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 8),
              ...testInstructions.map((instruction) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${instruction.toString()}',
                  style: GoogleFonts.comicNeue(fontSize: 13),
                ),
              )),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
            ],
            
            // General instructions
            Text(
              hasCustomInstructions ? 'General Instructions:' : 'Instructions:',
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: hasCustomInstructions ? Colors.grey.shade700 : Colors.blue,
              ),
            ),
            SizedBox(height: 8),
            Text('• Answer all questions to the best of your ability'),
            Text('• Use the navigation buttons to move between questions'),
            Text('• Your progress is automatically saved'),
            Text('• Submit the test when you\'re done'),
            Text('• Time remaining is shown at the top'),
            Text('• Use the question navigator to jump to any question'),
          ],
        ),
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


  void _showQuestionNavigator() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Question Navigator',
        style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
      ),
      content: Container(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Text(
              'Tap on any question number to navigate',
              style: GoogleFonts.comicNeue(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final questionNumber = index + 1;
                  final isCurrentQuestion = index == _currentQuestionIndex;
                  final isAnswered = _isQuestionAnswered(index);
                  
                  Color backgroundColor;
                  Color textColor;
                  
                  if (isCurrentQuestion) {
                    backgroundColor = Colors.blue;
                    textColor = Colors.white;
                  } else if (isAnswered) {
                    backgroundColor = Colors.green.withOpacity(0.2);
                    textColor = Colors.green;
                  } else {
                    backgroundColor = Colors.grey.withOpacity(0.2);
                    textColor = Colors.grey.shade700;
                  }
                  
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToQuestion(index);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrentQuestion ? Colors.blue : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$questionNumber',
                              style: GoogleFonts.comicNeue(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                            if (isAnswered && !isCurrentQuestion)
                              Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.green,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Current', Colors.blue, Colors.white),
                _buildLegendItem('Answered', Colors.green.withOpacity(0.2), Colors.green),
                _buildLegendItem('Not Answered', Colors.grey.withOpacity(0.2), Colors.grey.shade700),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    ),
  );
}

Widget _buildLegendItem(String label, Color backgroundColor, Color textColor) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      SizedBox(width: 4),
      Text(
        label,
        style: GoogleFonts.comicNeue(fontSize: 10),
      ),
    ],
  );
}

bool _isQuestionAnswered(int questionIndex) {
  final question = _questions[questionIndex];
  final questionType = question['type'] ?? 'mcq';
  
  switch (questionType) {
    case 'mcq':
      return _selectedAnswers.containsKey(questionIndex);
    case 'multiple':
      return _selectedMultipleAnswers.containsKey(questionIndex) &&
             _selectedMultipleAnswers[questionIndex]!.isNotEmpty;
    case 'numerical':
      return _numericalAnswers.containsKey(questionIndex) &&
             _numericalAnswers[questionIndex]!.isNotEmpty;
    default:
      return false;
  }
}

void _navigateToQuestion(int questionIndex) {
  if (questionIndex >= 0 && questionIndex < _questions.length) {
    _questionAnimationController.reset();
    setState(() {
      _currentQuestionIndex = questionIndex;
    });
    _questionAnimationController.forward();
    HapticFeedback.lightImpact();
  }
}


  Future<bool> _showExitConfirmation() async {
  final shouldExit = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(
        'Exit Test',
        style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
      ),
      content: Text(
        'Are you sure you want to exit? Your test will be automatically submitted.',
        style: GoogleFonts.comicNeue(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Continue Test'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('Exit & Submit', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  if (shouldExit == true) {
    _timer?.cancel();
    // Auto-submit the test when exiting
    await _calculateAndSaveResults();
    Navigator.of(context).pop();
    return true;
  }
  return false;
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
}
