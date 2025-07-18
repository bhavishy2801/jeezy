import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:jeezy/main.dart';
import 'package:jeezy/screens/question_review_screen.dart';
import 'package:share_plus/share_plus.dart';

class ResultsScreen extends StatefulWidget {
  final String? specificTestId;
  
  const ResultsScreen({Key? key, this.specificTestId}) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _selectedSubject = 'All';
  String _selectedTimeRange = 'All Time';
  bool _showOnlyPassed = false;
  
  final List<String> _subjects = ['All', 'Physics', 'Chemistry', 'Mathematics'];
  final List<String> _timeRanges = ['All Time', 'Last 7 Days', 'Last 30 Days', 'Last 3 Months'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
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
                  Icon(Icons.analytics, color: theme.colorScheme.primary, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Test Results',
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: () => _showFilterDialog(context, isDark, theme),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'export':
                        _exportResults();
                        break;
                      case 'analytics':
                        _showAdvancedAnalytics();
                        break;
                      case 'compare':
                        _showComparisonView();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.download, size: 20),
                          SizedBox(width: 8),
                          Text('Export Results'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'analytics',
                      child: Row(
                        children: [
                          Icon(Icons.insights, size: 20),
                          SizedBox(width: 8),
                          Text('Advanced Analytics'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'compare',
                      child: Row(
                        children: [
                          Icon(Icons.compare_arrows, size: 20),
                          SizedBox(width: 8),
                          Text('Compare Results'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: isDark ? Colors.white70 : Colors.grey.shade600,
                labelStyle: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'All Results'),
                  Tab(text: 'Performance'),
                  Tab(text: 'Analytics'),
                ],
              ),
            ),
            body: FadeTransition(
              opacity: _fadeAnimation,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllResultsTab(isDark, theme),
                  _buildPerformanceTab(isDark, theme),
                  _buildAnalyticsTab(isDark, theme),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllResultsTab(bool isDark, ThemeData theme) {
    return Column(
      children: [
        // Performance Overview Card
        _buildPerformanceOverview(isDark, theme),
        
        // Filter Chips
        _buildFilterChips(isDark, theme),
        
        // Results List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getFilteredResultsStream(),
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
                        style: GoogleFonts.comicNeue(),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState('Error loading results', snapshot.error.toString());
              }

              final results = snapshot.data?.docs ?? [];
              
              if (results.isEmpty) {
                return _buildEmptyResultsState(isDark, theme);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                  await Future.delayed(Duration(seconds: 1));
                },
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final resultData = results[index].data() as Map<String, dynamic>;
                    return _buildEnhancedResultCard(resultData, results[index].id, isDark, theme);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceOverview(bool isDark, ThemeData theme) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getPerformanceOverview(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        
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
                  Icon(Icons.trending_up, color: theme.colorScheme.primary),
                  SizedBox(width: 8),
                  Text(
                    'Performance Overview',
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
                    child: _buildOverviewStat(
                      'Tests Taken',
                      '${data['totalTests'] ?? 0}',
                      Icons.quiz,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildOverviewStat(
                      'Average Score',
                      '${(data['avgScore'] ?? 0.0).toStringAsFixed(1)}%',
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildOverviewStat(
                      'Best Score',
                      '${(data['bestScore'] ?? 0.0).toStringAsFixed(1)}%',
                      Icons.star,
                      Colors.amber,
                    ),
                  ),
                  Expanded(
                    child: _buildOverviewStat(
                      'Improvement',
                      '${(data['improvement'] ?? 0.0).toStringAsFixed(1)}%',
                      Icons.arrow_upward,
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

  Widget _buildOverviewStat(String title, String value, IconData icon, Color color) {
    return Column(
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
            fontSize: 10,
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
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with test info and score
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result['testTitle'] ?? 'Test Result',
                        style: GoogleFonts.comicNeue(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.subject, size: 16, color: Colors.grey.shade600),
                          SizedBox(width: 4),
                          Text(
                            result['subject'] ?? 'General',
                            style: GoogleFonts.comicNeue(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(width: 16),
                          Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                          SizedBox(width: 4),
                          Text(
                            _formatDate(result['completedAt']),
                            style: GoogleFonts.comicNeue(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Score breakdown
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
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
                  SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: isDark ? Colors.white24 : Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    minHeight: 8,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _buildScoreChip('Correct', '${result['correctAnswers'] ?? 0}', Colors.green),
                      SizedBox(width: 8),
                      _buildScoreChip('Wrong', '${result['incorrectAnswers'] ?? 0}', Colors.red),
                      SizedBox(width: 8),
                      _buildScoreChip('Skipped', '${result['unattempted'] ?? 0}', Colors.orange),
                      SizedBox(width: 8),
                      _buildScoreChip('Time', '${result['timeTaken'] ?? 0}/${result['duration'] ?? 0}m', Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
            
            // Subject-wise performance
            if (result['subjectWise'] != null) ...[
              SizedBox(height: 16),
              Text(
                'Subject Performance',
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              ...((result['subjectWise'] as Map<String, dynamic>).entries.map((entry) {
                final subjectData = entry.value as Map<String, dynamic>;
                final subjectPercentage = subjectData['percentage'] ?? 0.0;
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          entry.key,
                          style: GoogleFonts.comicNeue(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: subjectPercentage / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _getSubjectColor(entry.key),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '${subjectPercentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.comicNeue(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getSubjectColor(entry.key),
                        ),
                      ),
                    ],
                  ),
                );
              })),
            ],
            
            SizedBox(height: 20),
            
            // Action buttons with Question Review
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDetailedAnalysis(result, resultId),
                    icon: Icon(Icons.analytics, size: 18),
                    label: Text(
                      'Analysis',
                      style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _reviewTestQuestions(result, resultId),
                    icon: Icon(Icons.quiz, size: 18),
                    label: Text(
                      'Review',
                      style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareResult(result),
                    icon: Icon(Icons.share, size: 18),
                    label: Text(
                      'Share',
                      style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.secondary,
                      side: BorderSide(color: theme.colorScheme.secondary),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  // Add this method for question review
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

      final questionWiseResults = result['questionWiseResults'] as List<dynamic>? ?? [];
      
      if (questionWiseResults.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question details not available for this test'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      List<Map<String, dynamic>> questions = [];
      Map<String, dynamic> userAnswers = {};
      
      for (var qResult in questionWiseResults) {
        final questionData = qResult as Map<String, dynamic>;
        
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

      Navigator.pop(context);

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
      Navigator.pop(context);
      print('Error loading question review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading question review: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper methods
  Widget _buildScoreChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.comicNeue(
                fontSize: 10,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Physics': return Colors.blue;
      case 'Chemistry': return Colors.green;
      case 'Mathematics': return Colors.orange;
      default: return Colors.purple;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else {
        date = DateTime.parse(timestamp.toString());
      }
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  Stream<QuerySnapshot> _getFilteredResultsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.empty();

    Query query = FirebaseFirestore.instance
        .collection('test_results')
        .where('userId', isEqualTo: user.uid);

    if (_selectedSubject != 'All') {
      query = query.where('subject', isEqualTo: _selectedSubject);
    }

    return query.orderBy('completedAt', descending: true).snapshots();
  }

  Future<Map<String, dynamic>> _getPerformanceOverview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    try {
      final results = await FirebaseFirestore.instance
          .collection('test_results')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (results.docs.isEmpty) return {};

      double totalScore = 0;
      double bestScore = 0;
      double firstScore = 0;
      double lastScore = 0;

      for (int i = 0; i < results.docs.length; i++) {
        final data = results.docs[i].data();
        final percentage = data['percentage'] ?? 0.0;
        
        totalScore += percentage;
        bestScore = bestScore > percentage ? bestScore : percentage;
        
        if (i == 0) firstScore = percentage;
        if (i == results.docs.length - 1) lastScore = percentage;
      }

      final avgScore = totalScore / results.docs.length;
      final improvement = lastScore - firstScore;

      return {
        'totalTests': results.docs.length,
        'avgScore': avgScore,
        'bestScore': bestScore,
        'improvement': improvement,
      };
    } catch (e) {
      return {};
    }
  }

  // Placeholder methods for other tabs and features
  Widget _buildPerformanceTab(bool isDark, ThemeData theme) => Container();
  Widget _buildAnalyticsTab(bool isDark, ThemeData theme) => Container();
  Widget _buildFilterChips(bool isDark, ThemeData theme) => Container();
  Widget _buildEmptyResultsState(bool isDark, ThemeData theme) => Container();
  Widget _buildErrorState(String title, String message) => Container();
  
  void _showFilterDialog(BuildContext context, bool isDark, ThemeData theme) {}
  void _exportResults() {}
  void _showAdvancedAnalytics() {}
  void _showComparisonView() {}
  void _showDetailedAnalysis(Map<String, dynamic> result, String resultId) {}
  void _shareResult(Map<String, dynamic> result) {
    final testTitle = result['testTitle'] ?? 'Test';
    final percentage = result['percentage'] ?? 0.0;
    final shareText = 'I scored ${percentage.toStringAsFixed(1)}% in $testTitle on JEEzy! 🎉\n\nJoin me for JEE preparation!';
    
    Share.share(shareText);
  }
}
