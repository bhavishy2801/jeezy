// ignore_for_file: use_super_parameters, avoid_print, use_build_context_synchronously, deprecated_member_use

// ai_assistant.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jeezy/services/gemini_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:jeezy/main.dart';
import '../models/chat_message.dart';
import '../services/chat_storage_service.dart';
import 'dart:async';

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({Key? key}) : super(key: key);

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> 
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  final _uuid = Uuid();
  String? _currentUserId;
  
  // Animation controllers
  late AnimationController _typingAnimationController;
  late AnimationController _messageAnimationController;
  late Animation<double> _typingAnimation;
  
  // Quick suggestions
  final List<String> _quickSuggestions = [
    "Explain this physics concept",
    "Help me solve this math problem",
    "What is the formula for...",
    "Give me chemistry notes on...",
    "Practice questions for JEE",
    "Study tips for preparation",
  ];
  
  bool _showSuggestions = true;
  String _currentStreamingMessage = '';
  int _currentStreamingIndex = -1;
  
  // For cancellation functionality
  StreamSubscription? _responseSubscription;
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeChat();
    _listenToAuthChanges();
    _setupScrollListener();
  }

  void _initializeAnimations() {
    _typingAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _messageAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.offset > 100) {
        setState(() {
          _showSuggestions = false;
        });
      }
    });
  }

  void _initializeChat() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      _loadChatHistory();
    }
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user?.uid != _currentUserId) {
        setState(() {
          _messages.clear();
          _currentUserId = user?.uid;
          _showSuggestions = true;
        });
        
        if (user != null) {
          _loadChatHistory();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimationController.dispose();
    _messageAnimationController.dispose();
    _responseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await ChatStorageService.loadChatHistory();
      if (mounted) {
        setState(() {
          _messages = history;
          _showSuggestions = history.isEmpty;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading chat history: $e');
      if (mounted) {
        setState(() {
          _messages = [];
          _showSuggestions = true;
        });
      }
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      await ChatStorageService.saveChatHistory(_messages);
    } catch (e) {
      print('Error saving chat history: $e');
      if (mounted) {
        _showSnackBar('Failed to save chat history', Colors.orange);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChat() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_sweep, color: Colors.red),
            SizedBox(width: 8),
            Text('Clear Chat', style: GoogleFonts.comicNeue(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          'Are you sure you want to clear all messages? This action cannot be undone.',
          style: GoogleFonts.comicNeue(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.comicNeue()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ChatStorageService.clearChatHistory();
                setState(() {
                  _messages.clear();
                  _showSuggestions = true;
                });
                Navigator.pop(context);
                _showSnackBar('Chat cleared successfully', Colors.green);
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar('Failed to clear chat history', Colors.red);
              }
            },
            child: Text(
              'Clear',
              style: GoogleFonts.comicNeue(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  bool _isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  Widget _buildWelcomeScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AI Avatar with animation
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.smart_toy,
                size: 60,
                color: Colors.white,
              ),
            ),
            
            SizedBox(height: 24),
            
            // Welcome text
            Text(
              'Welcome to JEEzy AI! 🚀',
              style: GoogleFonts.comicNeue(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 12),
            
            Text(
              'Your intelligent study companion for JEE preparation',
              style: GoogleFonts.comicNeue(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 32),
            
            // Quick suggestions
            if (_showSuggestions) _buildQuickSuggestions(),
            
            SizedBox(height: 24),
            
            // Features showcase
            _buildFeatureShowcase(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Suggestions:',
          style: GoogleFonts.comicNeue(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickSuggestions.map((suggestion) {
            return GestureDetector(
              onTap: () => _sendSuggestion(suggestion),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  suggestion,
                  style: GoogleFonts.comicNeue(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFeatureShowcase(bool isDark) {
    final features = [
      {'icon': Icons.calculate, 'title': 'Math Solutions', 'desc': 'Step-by-step problem solving'},
      {'icon': Icons.science, 'title': 'Physics Help', 'desc': 'Concept explanations & formulas'},
      {'icon': Icons.biotech, 'title': 'Chemistry Guide', 'desc': 'Reactions & molecular structures'},
      {'icon': Icons.quiz, 'title': 'Practice Tests', 'desc': 'Mock questions & answers'},
    ];

    return Column(
      children: [
        Text(
          'What I can help you with:',
          style: GoogleFonts.comicNeue(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
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
                children: [
                  Icon(
                    feature['icon'] as IconData,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    feature['title'] as String,
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    feature['desc'] as String,
                    style: GoogleFonts.comicNeue(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _sendSuggestion(String suggestion) {
    _controller.text = suggestion;
    _sendMessage();
  }

  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _typingAnimation,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'JEEzy AI is thinking',
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _parseBoldText(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    // Enhanced markdown parsing
    final parts = text.split(RegExp(r'(\*\*.*?\*\*|\*.*?\*|`.*?`)'));
    List<TextSpan> spans = [];

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      
      if (part.startsWith('**') && part.endsWith('**')) {
        // Bold text
        spans.add(TextSpan(
          text: part.substring(2, part.length - 2),
          style: TextStyle(fontWeight: FontWeight.bold),
        ));
      } else if (part.startsWith('*') && part.endsWith('*')) {
        // Italic text
        spans.add(TextSpan(
          text: part.substring(1, part.length - 1),
          style: TextStyle(fontStyle: FontStyle.italic),
        ));
      } else if (part.startsWith('`') && part.endsWith('`')) {
        // Code text
        spans.add(TextSpan(
          text: part.substring(1, part.length - 1),
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ));
      } else {
        spans.add(TextSpan(text: part));
      }
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 16,
          color: textColor,
          fontFamily: GoogleFonts.comicNeue().fontFamily,
          height: 1.4,
        ),
        children: spans,
      ),
    );
  }

  // Stop generation function
  void _stopGeneration() {
    setState(() {
      _isCancelled = true;
      _isLoading = false;
      _isTyping = false;
    });
    
    _responseSubscription?.cancel();
    _typingAnimationController.stop();
    
    if (_currentStreamingIndex != -1 && _currentStreamingIndex < _messages.length) {
      setState(() {
        _messages[_currentStreamingIndex] = ChatMessage(
          id: _messages[_currentStreamingIndex].id,
          message: _currentStreamingMessage.isEmpty 
              ? 'Response generation was stopped.' 
              : _currentStreamingMessage + '\n\n[Response stopped by user]',
          isUser: false,
          timestamp: _messages[_currentStreamingIndex].timestamp,
        );
        _currentStreamingIndex = -1;
      });
      _saveChatHistory();
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
      content: Text('Response generation stopped'),
      backgroundColor: Colors.orange,
      duration: Duration(milliseconds: 1200),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (!_isUserLoggedIn()) {
      _showSnackBar('Please log in to use the AI assistant', Colors.orange);
      return;
    }

    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    // Reset cancellation flag
    _isCancelled = false;

    // Hide suggestions after first message
    setState(() {
      _showSuggestions = false;
    });

    final userChatMessage = ChatMessage(
      id: _uuid.v4(),
      message: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userChatMessage);
      _controller.clear();
      _isLoading = true;
      _isTyping = true;
    });

    _typingAnimationController.repeat();
    _scrollToBottom();

    final aiChatMessage = ChatMessage(
      id: _uuid.v4(),
      message: '',
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(aiChatMessage);
      _currentStreamingIndex = _messages.length - 1;
    });

    try {
      // Create a stream for the response
      final responseStream = GeminiService.getResponseStreamSimulated(
        "$userMessage. Please provide a clear, concise answer, not long, suitable for JEE preparation, and do not mention these clear, concise things in your response.",
        chatHistory: _messages.sublist(0, _messages.length - 1),
      );

      _typingAnimationController.stop();
      setState(() {
        _isTyping = false;
      });

      // Listen to the stream
      _currentStreamingMessage = '';
      _responseSubscription = responseStream.listen(
        (chunk) {
          if (!_isCancelled && mounted) {
            _currentStreamingMessage += chunk;
            setState(() {
              _messages[_currentStreamingIndex] = ChatMessage(
                id: aiChatMessage.id,
                message: _currentStreamingMessage,
                isUser: false,
                timestamp: aiChatMessage.timestamp,
              );
            });
            _scrollToBottom();
          }
        },
        onDone: () async {
          if (!_isCancelled && mounted) {
            setState(() {
              _isLoading = false;
              _currentStreamingIndex = -1;
            });
            await _saveChatHistory();
          }
        },
        onError: (error) {
          if (!_isCancelled && mounted) {
            setState(() {
              _isTyping = false;
              _isLoading = false;
              _messages[_currentStreamingIndex] = ChatMessage(
                id: aiChatMessage.id,
                message: 'Sorry, I encountered an error. Please try again.',
                isUser: false,
                timestamp: aiChatMessage.timestamp,
              );
              _currentStreamingIndex = -1;
            });
            _showSnackBar('Error: ${error.toString()}', Colors.red);
          }
        },
      );

    } catch (e) {
      _typingAnimationController.stop();
      if (!_isCancelled && mounted) {
        setState(() {
          _isTyping = false;
          _isLoading = false;
          _messages[_currentStreamingIndex] = ChatMessage(
            id: aiChatMessage.id,
            message: 'Sorry, I encountered an error. Please try again.',
            isUser: false,
            timestamp: aiChatMessage.timestamp,
          );
          _currentStreamingIndex = -1;
        });
        _showSnackBar('Error: ${e.toString()}', Colors.red);
      }
    }
  }

  Widget _buildMessage(ChatMessage message, int index) {
    final isUser = message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(150),
                      child: Icon(Icons.smart_toy, size: 18, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                  ],
                  
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Theme.of(context).colorScheme.primary.withAlpha(60)
                            : (isDark ? Color(0xFF1C2542) : Colors.grey.shade100),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isUser)
                            Text(
                              message.message,
                              style: GoogleFonts.comicNeue(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              softWrap: true,
                            )
                          else
                            _parseBoldText(message.message),
                          
                          SizedBox(height: 6),
                          
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(message.timestamp),
                                style: GoogleFonts.comicNeue(
                                  fontSize: 11,
                                  color: isUser
                                      ? Colors.white70
                                      : (isDark ? Colors.white54 : Colors.grey.shade600),
                                ),
                              ),
                              
                              if (!isUser && message.message.isNotEmpty) ...[
                                SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _copyToClipboard(message.message),
                                  child: Icon(
                                    Icons.copy,
                                    size: 14,
                                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  if (isUser) ...[
                    SizedBox(width: 8),
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
                          ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                          : AssetImage("assets/images/default_user.png") as ImageProvider,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Copied to clipboard', Colors.green);
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInputArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: 120, // Limit height to prevent overflow
                ),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF1C2542) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: null,
                  minLines: 1,
                  style: GoogleFonts.comicNeue(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Ask JEEzy AI anything...',
                    hintStyle: GoogleFonts.comicNeue(
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    prefixIcon: Icon(
                      Icons.chat_bubble_outline,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(width: 12),
            
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _isLoading ? Colors.red : Theme.of(context).colorScheme.primary,
                    _isLoading ? Colors.red.shade700 : Theme.of(context).colorScheme.secondary,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isLoading ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  _isLoading ? Icons.stop : Icons.send,
                  color: Colors.white,
                ),
                onPressed: _isLoading ? _stopGeneration : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUserLoggedIn()) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'JEEzy AI',
            style: GoogleFonts.comicNeue(fontSize: 24, fontWeight: FontWeight.w600),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              SizedBox(height: 16),
              Text(
                'Please log in to use JEEzy AI',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ThemeSwitchingArea(
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentThemeMode, child) {
          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'JEEzy AI',
                      style: GoogleFonts.comicNeue(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                if (_messages.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () {
                      setState(() {
                        _showSuggestions = true;
                      });
                      _scrollToBottom();
                    },
                    tooltip: 'Show Suggestions',
                  ),
                IconButton(
                  icon: Icon(Icons.clear_all),
                  onPressed: _clearChat,
                  tooltip: 'Clear Chat',
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? _buildWelcomeScreen()
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _messages.length + (_isTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_isTyping && index == _messages.length) {
                              return _buildTypingIndicator();
                            }
                            return _buildMessage(_messages[index], index);
                          },
                        ),
                ),
                _buildInputArea(),
              ],
            ),
          );
        },
      ),
    );
  }
}
