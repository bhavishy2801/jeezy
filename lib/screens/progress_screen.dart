// ignore_for_file: use_super_parameters, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:jeezy/main.dart';
import 'package:jeezy/screens/notes_screen.dart';
import 'package:jeezy/screens/tests_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({Key? key}) : super(key: key);

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Sample data - replace with Firebase data
  final List<Map<String, dynamic>> testScores = [
    {"test": "Physics Mock 1", "score": 75, "date": "2025-01-15", "subject": "Physics", "maxScore": 100},
    {"test": "Chemistry Test 2", "score": 82, "date": "2025-02-10", "subject": "Chemistry", "maxScore": 100},
    {"test": "Math Practice 3", "score": 90, "date": "2025-03-05", "subject": "Mathematics", "maxScore": 100},
    {"test": "Physics Mock 2", "score": 85, "date": "2025-04-01", "subject": "Physics", "maxScore": 100},
    {"test": "Full Mock Test", "score": 88, "date": "2025-05-20", "subject": "All", "maxScore": 100}
  ];

  final List<Map<String, dynamic>> timeSpent = [
    {"date": "2025-01-15", "minutes": 120, "subject": "Physics"},
    {"date": "2025-02-10", "minutes": 150, "subject": "Chemistry"},
    {"date": "2025-03-05", "minutes": 180, "subject": "Mathematics"},
    {"date": "2025-04-01", "minutes": 160, "subject": "Physics"},
    {"date": "2025-05-20", "minutes": 200, "subject": "All"}
  ];

  final Map<String, int> subjectStats = {
    "Physics": 85,
    "Chemistry": 78,
    "Mathematics": 92,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
                  Expanded(
                    child: Text(
                      'My Progress',
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
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    _animationController.reset();
                    _animationController.forward();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.analytics),
                  onPressed: () => _showDetailedAnalytics(context, isDark),
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: isDark ? Colors.white70 : Colors.grey.shade600,
                labelStyle: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text('Overview'),
                  )),
                  Tab(child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text('Test Scores'),
                  )),
                  Tab(child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text('Study Time'),
                  )),
                  Tab(child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text('Analytics'),
                  )),
                ],
                tabAlignment: TabAlignment.start,
              ),
            ),
            body: FadeTransition(
              opacity: _fadeAnimation,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(isDark, theme),
                  _buildTestScoresTab(isDark, theme),
                  _buildStudyTimeTab(isDark, theme),
                  _buildAnalyticsTab(isDark, theme),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          _buildStatsCards(isDark, theme),
          
          SizedBox(height: 24),
          
          // Recent Performance
          _buildRecentPerformance(isDark, theme),
          
          SizedBox(height: 24),
          
          // Subject Breakdown
          _buildSubjectBreakdown(isDark, theme),
          
          SizedBox(height: 24),
          
          // Quick Actions
          _buildQuickActions(isDark, theme),
          
          SizedBox(height: 20), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isDark, ThemeData theme) {
    final totalTests = testScores.length;
    final avgScore = testScores.fold<double>(0, (sum, test) => sum + test['score']) / totalTests;
    final totalStudyTime = timeSpent.fold<int>(0, (sum, time) => sum + time['minutes'] as int);
    final bestScore = testScores.map((test) => test['score']).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Overview',
          style: GoogleFonts.comicNeue(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            double cardWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _buildStatCard(
                    'Total Tests',
                    totalTests.toString(),
                    Icons.quiz,
                    Colors.blue,
                    isDark,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildStatCard(
                    'Average Score',
                    '${avgScore.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.green,
                    isDark,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildStatCard(
                    'Study Hours',
                    '${(totalStudyTime / 60).toStringAsFixed(1)}h',
                    Icons.access_time,
                    Colors.orange,
                    isDark,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildStatCard(
                    'Best Score',
                    '$bestScore%',
                    Icons.star,
                    Colors.purple,
                    isDark,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
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
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          FittedBox(
            child: Text(
              value,
              style: GoogleFonts.comicNeue(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.comicNeue(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPerformance(bool isDark, ThemeData theme) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: theme.colorScheme.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recent Performance',
                  style: GoogleFonts.comicNeue(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 10,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= testScores.length) return Container();
                        return Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'T${index + 1}',
                            style: GoogleFonts.comicNeue(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: GoogleFonts.comicNeue(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                  ),
                ),
                minX: 0,
                maxX: (testScores.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      testScores.length,
                      (index) => FlSpot(index.toDouble(), testScores[index]['score'].toDouble()),
                    ),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: theme.colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.3),
                          theme.colorScheme.primary.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectBreakdown(bool isDark, ThemeData theme) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: theme.colorScheme.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Subject Performance',
                  style: GoogleFonts.comicNeue(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...subjectStats.entries.map((entry) => _buildSubjectProgress(
            entry.key,
            entry.value,
            _getSubjectColor(entry.key),
            isDark,
          )),
        ],
      ),
    );
  }

  Widget _buildSubjectProgress(String subject, int score, Color color, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subject,
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$score%',
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: isDark ? Colors.white24 : Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.comicNeue(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Take Test',
                    Icons.quiz,
                    theme.colorScheme.primary,
                    () {
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
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Study Notes',
                    Icons.book,
                    Colors.green,
                    () {
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
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestScoresTab(bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Scores Over Time',
            style: GoogleFonts.comicNeue(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= testScores.length) return Container();
                        return Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            testScores[index]['test'].toString().split(' ').last,
                            style: GoogleFonts.comicNeue(fontSize: 12),
                          ),
                        );
                      },
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, interval: 10),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                minX: 0,
                maxX: (testScores.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      testScores.length,
                      (index) => FlSpot(index.toDouble(), testScores[index]['score'].toDouble()),
                    ),
                    isCurved: true,
                    barWidth: 4,
                    color: theme.colorScheme.primary,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildTestScoresList(isDark, theme),
        ],
      ),
    );
  }

  Widget _buildTestScoresList(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Tests',
          style: GoogleFonts.comicNeue(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        ...testScores.map((test) => Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1C2542) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getSubjectColor(test['subject']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getSubjectIcon(test['subject']),
                  color: _getSubjectColor(test['subject']),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test['test'],
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(DateTime.parse(test['date'])),
                      style: GoogleFonts.comicNeue(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getScoreColor(test['score']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${test['score']}%',
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(test['score']),
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildStudyTimeTab(bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Study Time Analysis',
            style: GoogleFonts.comicNeue(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= timeSpent.length) return Container();
                        return Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('MM/dd').format(DateTime.parse(timeSpent[index]['date'])),
                            style: GoogleFonts.comicNeue(fontSize: 12),
                          ),
                        );
                      },
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}m',
                          style: GoogleFonts.comicNeue(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                barGroups: List.generate(timeSpent.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: timeSpent[index]['minutes'].toDouble(),
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Analytics',
            style: GoogleFonts.comicNeue(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          // Performance Trends
          _buildPerformanceTrends(isDark, theme),
          
          SizedBox(height: 24),
          
          // Subject Distribution
          _buildSubjectDistribution(isDark, theme),
          
          SizedBox(height: 24),
          
          // Recommendations
          _buildRecommendations(isDark, theme),
          
          SizedBox(height: 20), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildPerformanceTrends(bool isDark, ThemeData theme) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Trends',
            style: GoogleFonts.comicNeue(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Improving in Mathematics (+12%)',
                  style: GoogleFonts.comicNeue(color: Colors.green),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.trending_down, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Need focus on Chemistry (-5%)',
                  style: GoogleFonts.comicNeue(color: Colors.orange),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectDistribution(bool isDark, ThemeData theme) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject Distribution',
            style: GoogleFonts.comicNeue(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: 35,
                    title: 'Physics\n35%',
                    color: Colors.blue,
                    radius: 60,
                    titleStyle: GoogleFonts.comicNeue(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 30,
                    title: 'Chemistry\n30%',
                    color: Colors.green,
                    radius: 60,
                    titleStyle: GoogleFonts.comicNeue(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 35,
                    title: 'Math\n35%',
                    color: Colors.orange,
                    radius: 60,
                    titleStyle: GoogleFonts.comicNeue(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(bool isDark, ThemeData theme) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recommendations',
                  style: GoogleFonts.comicNeue(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildRecommendationItem(
            'Focus on Chemistry concepts',
            'Your chemistry scores need improvement. Spend 30 more minutes daily.',
            Icons.science,
            Colors.green,
          ),
          _buildRecommendationItem(
            'Maintain Math momentum',
            'Great progress in Mathematics! Keep practicing daily.',
            Icons.calculate,
            Colors.blue,
          ),
          _buildRecommendationItem(
            'Take more mock tests',
            'Increase test frequency to 3 times per week.',
            Icons.quiz,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(width: 12),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailedAnalytics(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Detailed Analytics',
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Coming soon! Advanced analytics with AI insights.'),
              SizedBox(height: 16),
              Icon(Icons.analytics, size: 64, color: Colors.blue),
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

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.orange;
    return Colors.red;
  }
}
