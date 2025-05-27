import 'package:flutter/material.dart';
// import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jeezy/services/gemini_service.dart';

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({Key? key}) : super(key: key);

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

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
        style: TextStyle(fontSize: 17, color: textColor, fontFamily: GoogleFonts.comicNeue().fontFamily),
        children: spans,
      ),
    );
  }

  Future<void> _sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'You', 'text': userMessage});
      _controller.clear();
      _isLoading = true;
    });

    final int aiIndex = _messages.length;
    String botMessage = '';

    setState(() {
      _messages.add({'sender': 'JEEzy AI', 'text': ''});
    });

    try {
      final fullText = await GeminiService.getResponse("$userMessage. Dont' give me a very long answer. Give a concise answer.");

      for (int i = 0; i < fullText.length; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
        botMessage += fullText[i];
        setState(() {
          _messages[aiIndex] = {'sender': 'JEEzy AI', 'text': botMessage};
        });
      }
    } catch (e) {
      setState(() {
        _messages[aiIndex] = {'sender': 'JEEzy AI', 'text': 'Error: ${e.toString()}'};
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildMessage(Map<String, String> message) {
    final isUser = message['sender'] == 'You';
    final baseColor = Theme.of(context).colorScheme.primary;
    final blendColor = Theme.of(context).colorScheme.surface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            baseColor.withAlpha(isUser ? 50 : 25),
            blendColor.withAlpha(isUser ? 30 : 10),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: message['sender'] == 'JEEzy AI'
            ? _parseBoldText(message['text'] ?? '')
            : Text(
                "${message['sender']}: ${message['text']}",
                style: TextStyle(fontSize: 17, fontFamily: GoogleFonts.comicNeue().fontFamily, fontWeight: FontWeight.w900),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('JEEzy AI', style: GoogleFonts.comicNeue(fontSize: 24, fontWeight: FontWeight.w600),),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(),
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
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
