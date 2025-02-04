import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:secuprime_mobile/config/api_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const String _storageKey = 'chat_history';
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _loadChatHistory().then((_) {
      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }
    });
  }

  void _initializeGemini() {
    _model =
        GenerativeModel(model: 'gemini-pro', apiKey: ApiConfig.geminiApiKey);
    _chat = _model.startChat(history: [
      Content.text(
        'You are SecuPrime, an AI password security expert assistant. Your role is to:'
        '\n1. Educate users about password security best practices'
        '\n2. Help users understand common password vulnerabilities'
        '\n3. Provide practical advice for creating and managing secure passwords'
        '\n4. Explain password-related concepts in simple terms'
        '\n5. Guide users in protecting their digital accounts'
        '\nKeep responses concise, practical, and easy to understand. Always maintain a helpful and professional tone.',
      ),
      Content.text(
        'I understand my role as SecuPrime. I will provide expert guidance on password security, focusing on practical advice and clear explanations to help users protect their digital accounts.',
      ),
    ]);
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        const ChatMessage(
          text:
              "Hello! I'm SecuPrime, your password security assistant. I can help you with:\n"
              "• Creating strong passwords\n"
              "• Understanding password security best practices\n"
              "• Protecting your online accounts\n"
              "• Managing passwords securely\n\n"
              "What would you like to learn about?",
          isUser: false,
        ),
      );
    });
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_storageKey);
      if (history != null) {
        setState(() {
          _messages.addAll(
            history.map((message) {
              final map = json.decode(message) as Map<String, dynamic>;
              return ChatMessage(
                text: map['text'] as String,
                isUser: map['isUser'] as bool,
              );
            }),
          );
        });
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = _messages.map((message) {
        return json.encode({
          'text': message.text,
          'isUser': message.isUser,
        });
      }).toList();
      await prefs.setStringList(_storageKey, history);
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
      ));
      _isLoading = true;
    });

    await _saveChatHistory();
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(text));

      if (response.text == null) {
        throw Exception('Empty response from API');
      }

      final responseText = response.text;
      setState(() {
        _messages.add(ChatMessage(
          text: responseText!,
          isUser: false,
        ));
        _isLoading = false;
      });

      await _saveChatHistory();
      _scrollToBottom();
    } catch (e) {
      print('Error in chat response: $e');
      debugPrint('API Key: ${ApiConfig.geminiApiKey}');
      setState(() {
        _messages.add(ChatMessage(
          text: "Error: ${e.toString()}",
          isUser: false,
        ));
        _isLoading = false;
      });
      await _saveChatHistory();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      setState(() {
        _messages.clear();
        _addWelcomeMessage();
      });
    } catch (e) {
      print('Error clearing chat history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191647),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191647),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SecuPrime',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            Text(
              'Password Security Assistant',
              style: TextStyle(
                color: Color(0xFF8E8EF3),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF242761),
                  title: const Text(
                    'Clear Chat History',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Are you sure you want to clear all chat history?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFF8E8EF3)),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _clearChatHistory();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Color(0xFF8E8EF3)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF191647),
                      const Color(0xFF191647),
                    ],
                  ),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            color: Color(0xFF8E8EF3),
                          ),
                        ),
                      );
                    }
                    return _messages[index];
                  },
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF242761),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ask about password security...',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2E3270),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: _handleSubmitted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  MaterialButton(
                    onPressed: () => _handleSubmitted(_textController.text),
                    color: const Color(0xFF8E8EF3),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                    elevation: 2,
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF8E8EF3),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.security,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color:
                    isUser ? const Color(0xFF8E8EF3) : const Color(0xFF242761),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF242761),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
