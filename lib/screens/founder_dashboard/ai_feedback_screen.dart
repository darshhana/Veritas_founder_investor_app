import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';

class AIFeedbackScreen extends StatefulWidget {
  @override
  _AIFeedbackScreenState createState() => _AIFeedbackScreenState();
}

class _AIFeedbackScreenState extends State<AIFeedbackScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  String? _recommendations;
  List<Map<String, dynamic>> _chatHistory = [];

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _getRecommendations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('🤖 AI FEEDBACK: Requesting recommendations for ${user.email}');
      final response = await _apiService.getAIRecommendations(user.email!);
      
      print('🤖 AI FEEDBACK: Response success: ${response['success']}');
      print('🤖 AI FEEDBACK: Response data: ${response['data']}');
      print('🤖 AI FEEDBACK: Response data type: ${response['data'].runtimeType}');
      
      if (response['success']) {
        // Format recommendations and clean markdown
        String formattedRecs = _formatRecommendations(response['data']);
        formattedRecs = _cleanMarkdown(formattedRecs);
        print('🤖 AI FEEDBACK: Formatted recommendations: $formattedRecs');
        
        setState(() {
          _recommendations = formattedRecs;
          _isLoading = false;
        });
      } else {
        throw Exception(response['error'] ?? 'Failed to get recommendations');
      }
    } catch (e, stackTrace) {
      print('❌ AI FEEDBACK ERROR: $e');
      print('❌ STACK TRACE: $stackTrace');
      setState(() {
        _isLoading = false;
      });
      
      // Show user-friendly error message
      String userFriendlyMsg = 'Failed to get recommendations.';
      final errorStr = e.toString().toLowerCase();
      
      if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
        userFriendlyMsg = 'Request timed out. The AI is processing your request but it\'s taking longer than expected. Please try again in a moment.';
      } else if (errorStr.contains('network') || errorStr.contains('connection')) {
        userFriendlyMsg = 'Network error. Please check your connection and try again.';
      } else if (errorStr.contains('failed')) {
        userFriendlyMsg = 'Failed to get recommendations. Please try again.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFriendlyMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _getRecommendations(),
          ),
        ),
      );
    }
  }

  Future<void> _askQuestion() async {
    if (_questionController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final question = _questionController.text.trim();
    _questionController.clear();

    print('💬 AI QUESTION: User asking: $question');

    // Add user question to chat
    setState(() {
      _chatHistory.add({
        'type': 'user',
        'message': question,
        'timestamp': DateTime.now(),
      });
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _apiService.askAIQuestion(
        founderEmail: user.email!,
        question: question,
      );

      print('💬 AI QUESTION: Response success: ${response['success']}');
      print('💬 AI QUESTION: Response data: ${response['data']}');
      print('💬 AI QUESTION: Response data type: ${response['data'].runtimeType}');

      if (response['success']) {
        String answer = '';
        final data = response['data'];
        
        print('💬 AI QUESTION: Raw data type: ${data.runtimeType}');
        print('💬 AI QUESTION: Raw data: $data');
        
        // Handle different response formats
        if (data is Map<String, dynamic>) {
          // Try to extract answer from various possible fields
          answer = data['answer']?.toString() ?? 
                   data['response']?.toString() ?? 
                   data['message']?.toString() ?? 
                   data['text']?.toString() ?? 
                   data['content']?.toString() ?? 
                   '';
          
          // If answer is still empty, check if it's nested
          if (answer.isEmpty && data.containsKey('data')) {
            final nestedData = data['data'];
            if (nestedData is Map) {
              answer = nestedData['answer']?.toString() ?? 
                       nestedData['response']?.toString() ?? 
                       nestedData['message']?.toString() ?? 
                       '';
            } else if (nestedData is String) {
              answer = nestedData;
            }
          }
          
          // If still empty and data looks like a JSON string, try parsing
          if (answer.isEmpty && data.length == 1) {
            final firstValue = data.values.first;
            if (firstValue is String && firstValue.trim().startsWith('{')) {
              try {
                final parsed = jsonDecode(firstValue) as Map<String, dynamic>;
                answer = parsed['answer']?.toString() ?? 
                        parsed['response']?.toString() ?? 
                        parsed['message']?.toString() ?? 
                        '';
              } catch (e) {
                print('⚠️  Could not parse nested JSON: $e');
              }
            } else if (firstValue is String) {
              answer = firstValue;
            }
          }
        } else if (data is String) {
          // Try to parse if it's a JSON string
          if (data.trim().startsWith('{')) {
            try {
              final parsed = jsonDecode(data) as Map<String, dynamic>;
              answer = parsed['answer']?.toString() ?? 
                      parsed['response']?.toString() ?? 
                      parsed['message']?.toString() ?? 
                      parsed['text']?.toString() ?? 
                      '';
            } catch (e) {
              // If parsing fails, use the string as-is
              answer = data;
            }
          } else {
            answer = data;
          }
        } else {
          // Try to convert to string and check if it's JSON
          final dataStr = data.toString();
          if (dataStr.trim().startsWith('{')) {
            try {
              final parsed = jsonDecode(dataStr) as Map<String, dynamic>;
              answer = parsed['answer']?.toString() ?? 
                      parsed['response']?.toString() ?? 
                      parsed['message']?.toString() ?? 
                      '';
            } catch (e) {
              answer = dataStr;
            }
          } else {
            answer = dataStr;
          }
        }
        
        // Remove any JSON structure artifacts if answer still contains them
        if (answer.contains('"answer"') || answer.contains('"question"')) {
          // Try to extract just the answer value from JSON-like string
          final answerMatch = RegExp(r'"answer"\s*:\s*"([^"]+)"').firstMatch(answer);
          if (answerMatch != null) {
            answer = answerMatch.group(1) ?? answer;
          }
        }
        
        // If still empty, try to extract from response map
        if (answer.isEmpty) {
          answer = response['message']?.toString() ?? 
                   response['text']?.toString() ?? 
                   '';
        }
        
        if (answer.isEmpty) {
          answer = 'Response received but no answer text found.';
        }
        
        // Format the answer to remove markdown and JSON formatting
        answer = _formatAnswer(answer);
        
        print('💬 AI QUESTION: Final extracted answer: $answer');
        
        setState(() {
          _chatHistory.add({
            'type': 'ai',
            'message': answer,
            'timestamp': DateTime.now(),
          });
          _isLoading = false;
        });
      } else {
        final errorMsg = response['error']?.toString() ?? 'Failed to get answer';
        throw Exception(errorMsg);
      }
    } catch (e, stackTrace) {
      print('❌ AI QUESTION ERROR: $e');
      print('❌ STACK TRACE: $stackTrace');
      
      String errorMsg = 'Error: $e';
      final errorStr = e.toString().toLowerCase();
      
      if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
        errorMsg = 'Request timed out. The AI is processing your question but it\'s taking longer than expected. Please try again.';
      } else if (errorStr.contains('network') || errorStr.contains('connection')) {
        errorMsg = 'Network error. Please check your connection and try again.';
      } else if (errorStr.contains('failed')) {
        errorMsg = 'Failed to get answer. Please try again.';
      }
      
      setState(() {
        _chatHistory.add({
          'type': 'error',
          'message': errorMsg,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatRecommendations(dynamic data) {
    if (data is Map) {
      // Check if this is an error response
      if (data['recommendations'] is List) {
        final recs = data['recommendations'] as List;
        StringBuffer buffer = StringBuffer();
        
        for (var rec in recs) {
          if (rec is Map) {
            // Check if it's an error recommendation
            if (rec['category'] == 'Error') {
              buffer.writeln('⚠️  ${_cleanMarkdown(rec['title']?.toString() ?? 'Error')}');
              buffer.writeln(_cleanMarkdown(rec['description']?.toString() ?? 'An error occurred'));
              buffer.writeln();
            } else {
              buffer.writeln('📌 ${_cleanMarkdown(rec['category']?.toString() ?? 'General')}');
              buffer.writeln('Priority: ${rec['priority']?.toString() ?? 'Medium'}');
              buffer.writeln(_cleanMarkdown(rec['title']?.toString() ?? ''));
              buffer.writeln(_cleanMarkdown(rec['description']?.toString() ?? ''));
              if (rec['action_items'] is List) {
                buffer.writeln('\nAction Items:');
                for (var action in rec['action_items']) {
                  buffer.writeln('  • ${_cleanMarkdown(action.toString())}');
                }
              }
              buffer.writeln();
            }
          }
        }
        
        return buffer.toString().trim();
      }
      
      // Generic map formatting
      StringBuffer buffer = StringBuffer();
      data.forEach((key, value) {
        buffer.writeln('$key:');
        if (value is List) {
          for (var item in value) {
            buffer.writeln('  • ${_cleanMarkdown(item.toString())}');
          }
        } else {
          buffer.writeln('  ${_cleanMarkdown(value.toString())}');
        }
        buffer.writeln();
      });
      return buffer.toString();
    }
    return _cleanMarkdown(data.toString());
  }

  String _cleanMarkdown(String text) {
    if (text.isEmpty) return text;
    
    // Remove markdown formatting using replaceAllMapped to avoid $1 appearing in output
    // Remove bold **text** and __text__
    text = text.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (match) => match.group(1) ?? '');
    text = text.replaceAllMapped(RegExp(r'__(.+?)__'), (match) => match.group(1) ?? '');
    
    // Remove italic *text* and _text_ (single asterisks/underscores, not double)
    text = text.replaceAllMapped(RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)'), (match) => match.group(1) ?? '');
    text = text.replaceAllMapped(RegExp(r'(?<!_)_(?!_)(.+?)(?<!_)_(?!_)'), (match) => match.group(1) ?? '');
    
    // Remove headers # ## ###
    text = text.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    
    // Remove links [text](url) but keep text
    text = text.replaceAllMapped(RegExp(r'\[(.+?)\]\(.+?\)'), (match) => match.group(1) ?? '');
    
    // Remove inline code `code`
    text = text.replaceAllMapped(RegExp(r'`(.+?)`'), (match) => match.group(1) ?? '');
    
    // Remove code blocks ```code```
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    
    // Remove bullet points markdown (- * +)
    text = text.replaceAll(RegExp(r'^[\s]*[-*+]\s+', multiLine: true), '');
    
    // Remove numbered lists (1. 2. etc.)
    text = text.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');
    
    // Clean up multiple newlines (more than 2 consecutive)
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    // Clean up extra spaces (more than 1 consecutive)
    text = text.replaceAll(RegExp(r' {2,}'), ' ');
    
    // Remove any remaining markdown artifacts
    text = text.trim();
    
    return text;
  }

  String _formatAnswer(String answer) {
    // Clean markdown from the answer
    return _cleanMarkdown(answer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Feedback'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _chatHistory.clear();
                _recommendations = null;
              });
            },
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: Column(
        children: [
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _getRecommendations,
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('Get Recommendations'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Recommendations Display
          if (_recommendations != null)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF4A90E2)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'AI Recommendations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _recommendations!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Chat History
          Expanded(
            child: _chatHistory.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _chatHistory.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _chatHistory.length) {
                        return _buildLoadingIndicator();
                      }
                      return _buildChatBubble(_chatHistory[index]);
                    },
                  ),
          ),

          // Input Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'Ask about your pitch deck...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _askQuestion(),
                    enabled: !_isLoading,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF4A90E2),
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isLoading ? null : _askQuestion,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Ask me anything about your pitch!',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'I can provide feedback, answer questions, and help improve your pitch deck.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.smart_toy, color: Color(0xFF4A90E2)),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Thinking...',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> chat) {
    final isUser = chat['type'] == 'user';
    final isError = chat['type'] == 'error';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor:
                  isError ? Colors.red.shade200 : Colors.grey.shade200,
              child: Icon(
                isError ? Icons.error_outline : Icons.smart_toy,
                color: isError ? Colors.red : const Color(0xFF4A90E2),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF4A90E2)
                    : isError
                        ? Colors.red.shade100
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
              ),
              child: SelectableText(
                chat['message']?.toString() ?? '',
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: const Color(0xFF4A90E2),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

