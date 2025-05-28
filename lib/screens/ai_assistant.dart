import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jeezy/services/gemini_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/chat_storage_service.dart';

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({Key? key}) : super(key: key);

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final _uuid = Uuid();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _listenToAuthChanges();
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
        });
        
        if (user != null) {
          _loadChatHistory();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await ChatStorageService.loadChatHistory();
      if (mounted) {
        setState(() {
          _messages = history;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading chat history: $e');
      if (mounted) {
        setState(() {
          _messages = [];
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save chat history')),
        );
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
        title: Text('Clear Chat', style: GoogleFonts.comicNeue(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to clear all messages for this account?', 
                     style: GoogleFonts.comicNeue()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.comicNeue()),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ChatStorageService.clearChatHistory();
                setState(() {
                  _messages.clear();
                });
                Navigator.pop(context);
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to clear chat history')),
                );
              }
            },
            child: Text('Clear', style: GoogleFonts.comicNeue()),
          ),
        ],
      ),
    );
  }

  bool _isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  Widget _parseBoldText(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    final parts = text.split('**');
    List<TextSpan> spans = [];

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      spans.add(TextSpan(
        text: part,
        style: TextStyle(
          fontWeight: i.isOdd ? FontWeight.bold : FontWeight.w500,
        ),
      ));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 17, 
          color: textColor, 
          fontFamily: GoogleFonts.comicNeue().fontFamily
        ),
        children: spans,
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (!_isUserLoggedIn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to use the AI assistant')),
      );
      return;
    }

    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

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
    });

    _scrollToBottom();

    final aiChatMessage = ChatMessage(
      id: _uuid.v4(),
      message: '',
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(aiChatMessage);
    });

    final int aiIndex = _messages.length - 1;
    String botMessage = '';

    try {
      final fullText = await GeminiService.getResponse(
        "$userMessage. Don't give me a very long answer. Give a concise answer.",
        chatHistory: _messages.sublist(0, _messages.length - 1),
      );

      for (int i = 0; i < fullText.length; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
        botMessage += fullText[i];
        if (mounted) {
          setState(() {
            _messages[aiIndex] = ChatMessage(
              id: aiChatMessage.id,
              message: botMessage,
              isUser: false,
              timestamp: aiChatMessage.timestamp,
            );
          });
          _scrollToBottom();
        }
      }

      await _saveChatHistory();
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages[aiIndex] = ChatMessage(
            id: aiChatMessage.id,
            message: 'Error: ${e.toString()}',
            isUser: false,
            timestamp: aiChatMessage.timestamp,
          );
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.isUser;
    final baseColor = Theme.of(context).colorScheme.primary;
    final blendColor = Theme.of(context).colorScheme.surface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            baseColor.withAlpha(isUser ? 50 : 25),
            blendColor.withAlpha(isUser ? 30 : 10),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            !isUser
                ? _parseBoldText(message.message)
                : Text(
                    "You: ${message.message}",
                    style: TextStyle(
                      fontSize: 17,
                      fontFamily: GoogleFonts.comicNeue().fontFamily,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
            SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                fontFamily: GoogleFonts.comicNeue().fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'JEEzy AI',
          style: GoogleFonts.comicNeue(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        actions: [
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Start a conversation with JEEzy AI!',
                          style: GoogleFonts.comicNeue(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessage(_messages[index]);
                    },
                  ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'JEEzy AI is thinking...',
                    style: GoogleFonts.comicNeue(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ask JEEzy AI...',
                      hintStyle: TextStyle(
                        fontFamily: GoogleFonts.comicNeue().fontFamily,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
