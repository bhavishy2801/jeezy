import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_html/flutter_html.dart';

class QuestionReviewScreen extends StatefulWidget {
  final Map<String, dynamic> testResult;
  final List<Map<String, dynamic>> questions;
  final Map<String, dynamic> userAnswers;

  const QuestionReviewScreen({
    Key? key,
    required this.testResult,
    required this.questions,
    required this.userAnswers,
  }) : super(key: key);

  @override
  State<QuestionReviewScreen> createState() => _QuestionReviewScreenState();
}

class _QuestionReviewScreenState extends State<QuestionReviewScreen> {
  int _currentQuestionIndex = 0;
  PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text(
          'Question Review',
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => _showQuestionNavigator(),
            icon: Icon(Icons.grid_view),
            tooltip: 'Question Navigator',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(theme),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.questions.length,
              onPageChanged: (index) {
                setState(() {
                  _currentQuestionIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildQuestionReview(index, theme, isDark);
              },
            ),
          ),
          _buildNavigationButtons(theme),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${widget.questions.length}',
                style: GoogleFonts.comicNeue(fontWeight: FontWeight.w600),
              ),
              _buildQuestionStatusChip(),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.questions.length,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionStatusChip() {
    final question = widget.questions[_currentQuestionIndex];
    final questionId = question['id'];
    final userAnswer = widget.userAnswers[questionId];
    final correctAnswer = question['correctAnswer'];
    
    bool isCorrect = false;
    bool isAttempted = userAnswer != null;
    Color statusColor = Colors.grey;
    String statusText = 'Not Attempted';
    
    if (isAttempted) {
      if (question['type'] == 'multiple') {
        final correctAnswers = List<String>.from(question['correctAnswers'] ?? []);
        final userAnswersList = List<String>.from(userAnswer ?? []);
        isCorrect = correctAnswers.length == userAnswersList.length &&
                   correctAnswers.every((answer) => userAnswersList.contains(answer));
      } else {
        isCorrect = userAnswer.toString() == correctAnswer.toString();
      }
      
      statusColor = isCorrect ? Colors.green : Colors.red;
      statusText = isCorrect ? 'Correct' : 'Incorrect';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Text(
        statusText,
        style: GoogleFonts.comicNeue(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildQuestionReview(int index, ThemeData theme, bool isDark) {
    final question = widget.questions[index];
    final questionId = question['id'];
    final userAnswer = widget.userAnswers[questionId];
    final correctAnswer = question['correctAnswer'];
    final explanation = question['explanation'] ?? 'No explanation available';

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1C2542) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey.shade200,
              ),
            ),
            child: Row(
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
                        '${question['difficulty']} • ${question['marks']} marks',
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

          SizedBox(height: 20),

          // Question Text
          Container(
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
              data: question['questionText'] ?? 'Question text not available',
              style: {
                "body": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(16),
                  fontWeight: FontWeight.w600,
                  lineHeight: LineHeight(1.5),
                  fontFamily: GoogleFonts.comicNeue().fontFamily,
                ),
              },
            ),
          ),

          SizedBox(height: 24),

          // Options Review
          if (question['type'] == 'mcq' || question['type'] == 'multiple')
            _buildOptionsReview(question, userAnswer, correctAnswer, theme, isDark),

          if (question['type'] == 'numerical')
            _buildNumericalReview(question, userAnswer, correctAnswer, theme, isDark),

          SizedBox(height: 24),

          // Explanation
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
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Explanation',
                      style: GoogleFonts.comicNeue(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Html(
                  data: explanation,
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(14),
                      fontFamily: GoogleFonts.comicNeue().fontFamily,
                    ),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // In question_review_screen.dart, update the _buildOptionsReview method:

Widget _buildOptionsReview(Map<String, dynamic> question, dynamic userAnswer, 
                         String correctAnswer, ThemeData theme, bool isDark) {
  final options = question['options'] as List<dynamic>? ?? [];
  final isMultiple = question['type'] == 'multiple';
  
  // FIXED: Proper type handling for correctAnswers
  List<String> correctAnswers;
  if (isMultiple) {
    final correctAnswersData = question['correctAnswers'];
    if (correctAnswersData is List) {
      correctAnswers = correctAnswersData.map((e) => e.toString()).toList();
    } else if (correctAnswersData is String) {
      correctAnswers = [correctAnswersData];
    } else {
      correctAnswers = [];
    }
  } else {
    correctAnswers = [correctAnswer];
  }
  
  // FIXED: Proper type handling for userAnswers
  List<String> userAnswers;
  if (isMultiple) {
    if (userAnswer is List) {
      userAnswers = userAnswer.map((e) => e.toString()).toList();
    } else if (userAnswer is String && userAnswer.isNotEmpty) {
      userAnswers = [userAnswer];
    } else {
      userAnswers = [];
    }
  } else {
    userAnswers = userAnswer != null ? [userAnswer.toString()] : [];
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Options Review',
        style: GoogleFonts.comicNeue(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 12),
      ...options.map<Widget>((option) {
        final optionId = option['id']?.toString() ?? '';
        final optionText = option['text']?.toString() ?? '';
        final isCorrectOption = correctAnswers.contains(optionId);
        final isUserSelected = userAnswers.contains(optionId);
        
        Color borderColor = Colors.grey.shade300;
        Color backgroundColor = Colors.transparent;
        
        if (isCorrectOption && isUserSelected) {
          borderColor = Colors.green;
          backgroundColor = Colors.green.withOpacity(0.1);
        } else if (isCorrectOption) {
          borderColor = Colors.green;
          backgroundColor = Colors.green.withOpacity(0.05);
        } else if (isUserSelected) {
          borderColor = Colors.red;
          backgroundColor = Colors.red.withOpacity(0.1);
        }

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: isMultiple ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: isMultiple ? BorderRadius.circular(4) : null,
                  color: isCorrectOption ? Colors.green : 
                         (isUserSelected ? Colors.red : Colors.transparent),
                  border: Border.all(
                    color: isCorrectOption ? Colors.green : 
                           (isUserSelected ? Colors.red : Colors.grey),
                    width: 2,
                  ),
                ),
                child: isCorrectOption || isUserSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
              SizedBox(width: 12),
              Text(
                optionId,
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isCorrectOption ? Colors.green : 
                         (isUserSelected ? Colors.red : null),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  optionText,
                  style: GoogleFonts.comicNeue(
                    fontSize: 14,
                    fontWeight: (isCorrectOption || isUserSelected) ? 
                               FontWeight.w600 : FontWeight.normal,
                    color: isCorrectOption ? Colors.green : 
                           (isUserSelected ? Colors.red : null),
                  ),
                ),
              ),
              if (isCorrectOption)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Correct',
                    style: GoogleFonts.comicNeue(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (isUserSelected && !isCorrectOption)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Your Answer',
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
      }).toList(),
    ],
  );
}


  Widget _buildNumericalReview(Map<String, dynamic> question, dynamic userAnswer, 
                             dynamic correctAnswer, ThemeData theme, bool isDark) {
    final userAnswerStr = userAnswer?.toString() ?? 'Not Attempted';
    final correctAnswerStr = correctAnswer?.toString() ?? 'N/A';
    final tolerance = question['tolerance'] ?? 0.1;
    final unit = question['answerUnit'] ?? '';
    
    bool isCorrect = false;
    if (userAnswer != null && correctAnswer != null) {
      final userNum = double.tryParse(userAnswerStr);
      final correctNum = double.tryParse(correctAnswerStr);
      if (userNum != null && correctNum != null) {
        isCorrect = (userNum - correctNum).abs() <= tolerance;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Numerical Answer Review',
          style: GoogleFonts.comicNeue(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        
        // Your Answer
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: userAnswer != null 
                ? (isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1))
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: userAnswer != null 
                  ? (isCorrect ? Colors.green : Colors.red)
                  : Colors.grey,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                userAnswer != null 
                    ? (isCorrect ? Icons.check_circle : Icons.cancel)
                    : Icons.remove_circle,
                color: userAnswer != null 
                    ? (isCorrect ? Colors.green : Colors.red)
                    : Colors.grey,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Answer',
                      style: GoogleFonts.comicNeue(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '$userAnswerStr $unit',
                      style: GoogleFonts.comicNeue(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: userAnswer != null 
                            ? (isCorrect ? Colors.green : Colors.red)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 12),
        
        // Correct Answer
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correct Answer',
                      style: GoogleFonts.comicNeue(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '$correctAnswerStr $unit',
                      style: GoogleFonts.comicNeue(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        if (tolerance > 0) ...[
          SizedBox(height: 8),
          Text(
            'Tolerance: ±$tolerance',
            style: GoogleFonts.comicNeue(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: Icon(Icons.arrow_back),
                label: Text(
                  'Previous',
                  style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          
          if (_currentQuestionIndex > 0) SizedBox(width: 12),
          
          if (_currentQuestionIndex < widget.questions.length - 1)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: Icon(Icons.arrow_forward),
                label: Text(
                  'Next',
                  style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          
          if (_currentQuestionIndex == widget.questions.length - 1)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.check),
                label: Text(
                  'Finish Review',
                  style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
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
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: widget.questions.length,
            itemBuilder: (context, index) {
              final question = widget.questions[index];
              final questionId = question['id'];
              final userAnswer = widget.userAnswers[questionId];
              final correctAnswer = question['correctAnswer'];
              
              Color backgroundColor;
              Color textColor;
              bool isCorrect = false;
              bool isAttempted = userAnswer != null;
              
              if (isAttempted) {
                if (question['type'] == 'multiple') {
                  final correctAnswers = List<String>.from(question['correctAnswers'] ?? []);
                  final userAnswersList = List<String>.from(userAnswer ?? []);
                  isCorrect = correctAnswers.length == userAnswersList.length &&
                             correctAnswers.every((answer) => userAnswersList.contains(answer));
                } else {
                  isCorrect = userAnswer.toString() == correctAnswer.toString();
                }
                
                backgroundColor = isCorrect ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2);
                textColor = isCorrect ? Colors.green : Colors.red;
              } else {
                backgroundColor = Colors.grey.withOpacity(0.2);
                textColor = Colors.grey.shade700;
              }
              
              if (index == _currentQuestionIndex) {
                backgroundColor = Colors.blue;
                textColor = Colors.white;
              }
              
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _pageController.animateToPage(
                    index,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: index == _currentQuestionIndex ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${index + 1}',
                          style: GoogleFonts.comicNeue(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                        if (isAttempted && index != _currentQuestionIndex)
                          Icon(
                            isCorrect ? Icons.check : Icons.close,
                            size: 12,
                            color: textColor,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
}
