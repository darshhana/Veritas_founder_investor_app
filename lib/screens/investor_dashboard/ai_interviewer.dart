import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class AIInterviewerScreen extends StatefulWidget {
  @override
  _AIInterviewerScreenState createState() => _AIInterviewerScreenState();
}

class _AIInterviewerScreenState extends State<AIInterviewerScreen> {
  final ApiService _apiService = ApiService();
  int _selectedIndex = 0;
  final List<String> _tabs = [
    'Active Interview',
    'Scheduled',
    'Completed',
  ];

  List<Map<String, dynamic>> activeInterviews = [];
  List<Map<String, dynamic>> scheduledInterviews = [];
  List<Map<String, dynamic>> completedInterviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInterviews();
  }

  Future<void> _loadInterviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 Loading interviews from Firestore...');

      // Load ALL interviews from Firestore (not filtered by investor)
      List<QueryDocumentSnapshot> allInterviewDocs = [];
      
      // Primary collection: 'interviews' (this is where backend saves)
      final collectionsToCheck = ['interviews', 'scheduledInterviews'];
      
      for (final collectionName in collectionsToCheck) {
        try {
          print('🔍 Checking $collectionName collection...');
          
          // Try to get all interviews - first try without orderBy to avoid index issues
          QuerySnapshot? snapshot;
          try {
            // Try without orderBy first (most reliable)
            snapshot = await FirebaseFirestore.instance
                .collection(collectionName)
                .limit(100)  // Increased limit to get more interviews
                .get();
            print('✅ $collectionName: Found ${snapshot.docs.length} without orderBy');
            
            // If we have docs, try to sort in-memory by date
            if (snapshot.docs.isNotEmpty) {
              // Sort by scheduledAt or createdAt in memory
              snapshot.docs.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;
                
                DateTime? dateA = _extractDate(dataA, 'scheduledAt') ?? 
                                 _extractDate(dataA, 'scheduled_time') ??
                                 _extractDate(dataA, 'createdAt') ??
                                 _extractDate(dataA, 'created_at');
                DateTime? dateB = _extractDate(dataB, 'scheduledAt') ?? 
                                 _extractDate(dataB, 'scheduled_time') ??
                                 _extractDate(dataB, 'createdAt') ??
                                 _extractDate(dataB, 'created_at');
                
                if (dateA == null && dateB == null) return 0;
                if (dateA == null) return 1;
                if (dateB == null) return -1;
                return dateB.compareTo(dateA); // Descending
              });
            }
            
            // Add to list if we have docs
            if (snapshot.docs.isNotEmpty) {
              allInterviewDocs.addAll(snapshot.docs);
              print('✅ Added ${snapshot.docs.length} interviews from $collectionName');
            }
          } catch (e) {
            print('⚠️ Error fetching $collectionName: $e');
            continue;
          }
        } catch (e) {
          print('⚠️ Error checking $collectionName: $e');
        }
      }
      
      // Deduplicate by document ID
      final uniqueDocs = <String, QueryDocumentSnapshot>{};
      for (var doc in allInterviewDocs) {
        uniqueDocs[doc.id] = doc;
      }
      
      print('📊 Total unique interviews found: ${uniqueDocs.length}');
      
      if (uniqueDocs.isEmpty) {
        print('⚠️ No interview data found in any collection');
        if (mounted) {
          setState(() {
            activeInterviews = [];
            scheduledInterviews = [];
            completedInterviews = [];
            _isLoading = false;
          });
        }
        return;
      }
      
      print('📊 Processing ${uniqueDocs.length} unique interviews');

      List<Map<String, dynamic>> scheduled = [];
      List<Map<String, dynamic>> active = [];
      List<Map<String, dynamic>> completed = [];

      // Process all unique documents
      for (var doc in uniqueDocs.values) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        
        // Handle both camelCase and snake_case field names
        final founderName = data['founder_name']?.toString() ?? 
                           data['founderName']?.toString() ??
                           data['founder_email']?.toString() ?? 
                           data['founderEmail']?.toString() ?? 
                           'Unknown Founder';
        final company = data['startup_name']?.toString() ?? 
                       data['startupName']?.toString() ??
                       data['company_name']?.toString() ?? 
                       data['companyName']?.toString() ??
                       'Unknown Company';
        final status = data['status']?.toString() ?? 'scheduled';
        
        // Parse scheduled time - handle multiple field names and formats
        DateTime scheduledTime = DateTime.now();
        try {
          // Try scheduledAt (camelCase, string)
          if (data['scheduledAt'] != null) {
            if (data['scheduledAt'] is Timestamp) {
              scheduledTime = (data['scheduledAt'] as Timestamp).toDate();
            } else if (data['scheduledAt'] is String) {
              scheduledTime = DateTime.tryParse(data['scheduledAt']) ?? DateTime.now();
            }
          }
          // Try scheduled_time (snake_case, timestamp)
          else if (data['scheduled_time'] != null) {
            if (data['scheduled_time'] is Timestamp) {
              scheduledTime = (data['scheduled_time'] as Timestamp).toDate();
            } else if (data['scheduled_time'] is String) {
              scheduledTime = DateTime.tryParse(data['scheduled_time']) ?? DateTime.now();
            }
          }
          // Try createdAt or created_at
          else if (data['createdAt'] != null) {
            if (data['createdAt'] is Timestamp) {
              scheduledTime = (data['createdAt'] as Timestamp).toDate();
            } else if (data['createdAt'] is String) {
              scheduledTime = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
            }
          }
          // Fallback to timestamp
          else if (data['timestamp'] != null) {
            if (data['timestamp'] is Timestamp) {
              scheduledTime = (data['timestamp'] as Timestamp).toDate();
            } else if (data['timestamp'] is String) {
              scheduledTime = DateTime.tryParse(data['timestamp']) ?? DateTime.now();
            }
          }
        } catch (e) {
          print('  ⚠️ Date parsing error: $e');
        }

        final interview = {
          'id': doc.id,
          'founderName': founderName,
          'company': company,
          'stage': data['stage']?.toString() ?? 'Not Specified',
          'status': status,
          'scheduledTime': scheduledTime,
          'investorEmail': data['investor_email']?.toString() ?? 
                          data['investorEmail']?.toString() ?? '',
          'questions': data['questions'] as List? ?? [],
          'responses': data['responses'] as List? ?? data['answers'] as List? ?? [],
          'transcript': data['transcript']?.toString() ?? data['summary']?['transcript']?.toString(),
          'summary': data['summary'] as Map? ?? {},
          'progress': 0.0,
          'nextQuestion': 'Interview not started',
          'score': data['score'] ?? data['summary']?['confidenceScore'],
          'duration': _calculateDuration(scheduledTime),
          'interviewUrl': data['interviewUrl']?.toString(),
        };

        // Categorize based on status
        if (status.toLowerCase() == 'completed') {
          completed.add(interview);
        } else if (status.toLowerCase() == 'in_progress' || status.toLowerCase() == 'active') {
          active.add(interview);
        } else {
          scheduled.add(interview);
        }

        print('  ✅ Added interview: $company ($status)');
      }

      // If no real data, show sample data
      if (scheduled.isEmpty && active.isEmpty && completed.isEmpty) {
        print('⚠️ No interview data found, using samples');
        _loadSampleData();
        return;
      }

      print('✅ Loaded: ${active.length} active, ${scheduled.length} scheduled, ${completed.length} completed');

      if (mounted) {
        setState(() {
          activeInterviews = active;
          scheduledInterviews = scheduled;
          completedInterviews = completed;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading interviews: $e');
      // Load sample data on error
      _loadSampleData();
    }
  }

  void _loadSampleData() {
    setState(() {
      activeInterviews = [];
      scheduledInterviews = [];
      completedInterviews = [];
      _isLoading = false;
    });
  }

  /// Helper method to extract DateTime from various field names and formats
  DateTime? _extractDate(Map<String, dynamic> data, String fieldName) {
    final value = data[fieldName];
    if (value == null) return null;
    
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value);
    } else if (value is DateTime) {
      return value;
    }
    return null;
  }

  String _calculateDuration(DateTime scheduledTime) {
    final now = DateTime.now();
    if (scheduledTime.isAfter(now)) {
      final diff = scheduledTime.difference(now);
      if (diff.inDays > 0) {
        return 'In ${diff.inDays} days';
      } else if (diff.inHours > 0) {
        return 'In ${diff.inHours} hours';
      } else {
        return 'In ${diff.inMinutes} minutes';
      }
    } else {
      return 'Now';
    }
  }

  Future<void> _scheduleNewInterview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to schedule interviews'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _ScheduleInterviewDialog(
        apiService: _apiService,
        investorEmail: user.email!,
        onScheduled: () {
          _loadInterviews();
        },
      ),
    );
  }

  void _viewTranscript(Map<String, dynamic> interview) {
    showDialog(
      context: context,
      builder: (context) => _TranscriptViewDialog(
        interview: interview,
        onExport: () {
          Navigator.of(context).pop();
          _exportTranscript(interview);
        },
      ),
    );
  }

  Future<void> _exportTranscript(Map<String, dynamic> interview) async {
    if (!mounted) return;
    
    // Store the context to use throughout the function
    final navigatorContext = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false, // Prevent back button from closing
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Exporting transcript...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Build transcript content
      final transcriptContent = _buildTranscriptContent(interview);
      
      // Get document directory with error handling
      Directory directory;
      try {
        directory = await getApplicationDocumentsDirectory();
      } catch (e) {
        print('❌ Error getting documents directory: $e');
        if (mounted) {
          navigatorContext.pop(); // Close loading dialog
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Error: Could not access file system. Please check app permissions.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      
      // Sanitize company name for filename
      final rawCompanyName = interview['company']?.toString() ?? 'Unknown';
      final sanitizedCompanyName = rawCompanyName
          .replaceAll(RegExp(r'[^\w\s-]'), '_')
          .replaceAll(' ', '_');
      final companyName = sanitizedCompanyName.length > 30 
          ? sanitizedCompanyName.substring(0, 30) 
          : sanitizedCompanyName;
      
      final fileName = 'interview_${companyName}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.txt';
      final file = File('${directory.path}/$fileName');
      
      print('📝 Exporting to: ${file.path}');
      
      // Write to file
      await file.writeAsString(transcriptContent);
      print('✅ File written successfully');
      
      // Close loading dialog
      if (mounted) {
        navigatorContext.pop(); // Close loading dialog
        
        // Small delay to ensure dialog is closed
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Show success dialog with file location
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Export Successful'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transcript exported successfully!',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                const Text(
                  'File Location:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SelectableText(
                    file.path,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getPlatformSpecificLocation(directory.path),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  // Try to open file location (platform-specific)
                  _openFileLocation(file.path);
                },
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('Open Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Error exporting transcript: $e');
      print('Stack trace: $stackTrace');
      
      // Close loading dialog if still open
      if (mounted) {
        if (navigatorContext.canPop()) {
          navigatorContext.pop(); // Close loading dialog
        }
        
        // Small delay to ensure dialog is closed
        await Future.delayed(const Duration(milliseconds: 100));
        
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '❌ Export failed', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Error: ${e.toString()}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                scaffoldMessenger.hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  String _buildTranscriptContent(Map<String, dynamic> interview) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('=' * 60);
    buffer.writeln('AI INTERVIEW TRANSCRIPT');
    buffer.writeln('=' * 60);
    buffer.writeln();
    
    // Interview Details
    buffer.writeln('Founder: ${interview['founderName']}');
    buffer.writeln('Company: ${interview['company']}');
    buffer.writeln('Stage: ${interview['stage']}');
    buffer.writeln('Scheduled: ${DateFormat('yyyy-MM-dd HH:mm').format(interview['scheduledTime'] as DateTime)}');
    if (interview['score'] != null) {
      buffer.writeln('Score: ${interview['score']}');
    }
    buffer.writeln();
    buffer.writeln('-' * 60);
    buffer.writeln();
    
    // Check if we have a direct transcript
    if (interview['transcript'] != null && interview['transcript'].toString().isNotEmpty) {
      buffer.writeln('TRANSCRIPT:');
      buffer.writeln();
      buffer.writeln(interview['transcript']);
    } else {
      // Build from questions and responses
      final questions = interview['questions'] as List? ?? [];
      final responses = interview['responses'] as List? ?? [];
      final summary = interview['summary'] as Map? ?? {};
      
      if (questions.isNotEmpty || responses.isNotEmpty) {
        buffer.writeln('INTERVIEW Q&A:');
        buffer.writeln();
        
        // Match questions with responses
        for (int i = 0; i < questions.length; i++) {
          final question = questions[i];
          String questionText = '';
          
          if (question is Map) {
            questionText = question['question']?.toString() ?? 
                          question['text']?.toString() ?? 
                          question.toString();
          } else {
            questionText = question.toString();
          }
          
          buffer.writeln('Q${i + 1}: $questionText');
          buffer.writeln();
          
          // Get corresponding response
          if (i < responses.length) {
            final response = responses[i];
            String responseText = '';
            
            if (response is Map) {
              responseText = response['answer']?.toString() ?? 
                            response['response']?.toString() ?? 
                            response['text']?.toString() ?? 
                            response.toString();
            } else {
              responseText = response.toString();
            }
            
            buffer.writeln('A${i + 1}: $responseText');
            buffer.writeln();
          }
          
          buffer.writeln('-' * 60);
          buffer.writeln();
        }
      }
      
      // Add summary if available
      if (summary.isNotEmpty) {
        buffer.writeln('SUMMARY:');
        buffer.writeln();
        summary.forEach((key, value) {
          if (value != null && value.toString().isNotEmpty) {
            buffer.writeln('${key.toString().replaceAll('_', ' ').toUpperCase()}: $value');
          }
        });
        buffer.writeln();
      }
    }
    
    buffer.writeln('=' * 60);
    buffer.writeln('End of Transcript');
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('=' * 60);
    
    return buffer.toString();
  }

  String _getPlatformSpecificLocation(String path) {
    if (Platform.isWindows) {
      return 'Windows: Saved in AppData\\Roaming directory';
    } else if (Platform.isAndroid) {
      return 'Android: Saved in app documents directory (internal storage)';
    } else if (Platform.isIOS) {
      return 'iOS: Saved in app Documents directory';
    } else if (Platform.isMacOS) {
      return 'macOS: Saved in app Documents directory';
    } else {
      return 'Saved in application documents directory';
    }
  }

  Future<void> _openFileLocation(String filePath) async {
    try {
      final directory = Directory(filePath.substring(0, filePath.lastIndexOf(Platform.pathSeparator)));
      
      if (Platform.isWindows) {
        // On Windows, use explorer
        Process.run('explorer', [directory.path]);
      } else if (Platform.isMacOS) {
        // On macOS, use open
        Process.run('open', [directory.path]);
      } else if (Platform.isLinux) {
        // On Linux, use xdg-open
        Process.run('xdg-open', [directory.path]);
      } else {
        // On Android/iOS, show message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File location:\n$filePath'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error opening file location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file location. Path: $filePath'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'AI Interviewer',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _scheduleNewInterview,
                  icon: const Icon(Icons.add),
                  label: const Text('Schedule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                  ),
          ),
        ],
      ),
          ),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabs.length, (index) {
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: _selectedIndex == index
                    ? const Color(0xFF4A90E2)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _tabs[index],
                style: TextStyle(
                  color: _selectedIndex == index
                      ? Colors.white
                      : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildInterviewList(activeInterviews, 'active');
      case 1:
        return _buildInterviewList(scheduledInterviews, 'scheduled');
      case 2:
        return _buildInterviewList(completedInterviews, 'completed');
      default:
        return Container();
    }
  }

  Widget _buildInterviewList(List<Map<String, dynamic>> interviews, String type) {
    if (interviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
      children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type} interviews',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'scheduled'
                  ? 'Schedule an interview to get started'
                  : type == 'active'
                      ? 'Start a scheduled interview'
                      : 'Completed interviews will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
      ),
    );
  }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: interviews.length,
      itemBuilder: (context, index) {
        final interview = interviews[index];
        if (type == 'completed') {
          return _buildCompletedCard(interview);
        } else {
          return _buildScheduledCard(interview);
        }
      },
    );
  }

  Widget _buildScheduledCard(Map<String, dynamic> interview) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF4A90E2),
                  child: Text(
                    interview['founderName'][0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        interview['founderName'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${interview['company']} • ${interview['stage']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    interview['duration'],
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Reschedule'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                    ),
                    child: const Text('Start Interview'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedCard(Map<String, dynamic> interview) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF4A90E2),
                  child: Text(
                    interview['founderName'][0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        interview['founderName'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${interview['company']} • ${interview['stage']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (interview['score'] != null)
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                      'Score: ${interview['score']}',
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                      fontSize: 12,
                        fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewTranscript(interview),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Transcript'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportTranscript(interview),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
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
}

class _TranscriptViewDialog extends StatelessWidget {
  final Map<String, dynamic> interview;
  final VoidCallback? onExport;

  const _TranscriptViewDialog({required this.interview, this.onExport});

  @override
  Widget build(BuildContext context) {
    final questions = interview['questions'] as List? ?? [];
    final responses = interview['responses'] as List? ?? [];
    final transcript = interview['transcript']?.toString();
    final summary = interview['summary'] as Map? ?? {};

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interview Transcript',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${interview['founderName']} - ${interview['company']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),
                Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Interview Details
                    _buildSection(
                      'Interview Details',
                      [
                        'Founder: ${interview['founderName']}',
                        'Company: ${interview['company']}',
                        'Stage: ${interview['stage']}',
                        'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(interview['scheduledTime'] as DateTime)}',
                        if (interview['score'] != null) 'Score: ${interview['score']}',
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Transcript or Q&A
                    if (transcript != null && transcript.isNotEmpty)
                      _buildSection('Full Transcript', [transcript])
                    else if (questions.isNotEmpty || responses.isNotEmpty)
                      _buildQASection(questions, responses)
                    else
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No transcript available yet. Interview may still be in progress.',
                          style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    // Summary
                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildSummarySection(summary),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onExport?.call();
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content.map((line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQASection(List questions, List responses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interview Q&A',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(
          questions.length > responses.length ? questions.length : responses.length,
          (index) {
            String questionText = '';
            if (index < questions.length) {
              final question = questions[index];
              if (question is Map) {
                questionText = question['question']?.toString() ?? 
                              question['text']?.toString() ?? 
                              question.toString();
              } else {
                questionText = question.toString();
              }
            }

            String responseText = '';
            if (index < responses.length) {
              final response = responses[index];
              if (response is Map) {
                responseText = response['answer']?.toString() ?? 
                              response['response']?.toString() ?? 
                              response['text']?.toString() ?? 
                              response.toString();
              } else {
                responseText = response.toString();
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  if (questionText.isNotEmpty) ...[
            Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Q${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            questionText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (responseText.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'A${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                Expanded(
                          child: Text(
                            responseText,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                  ),
                ),
              ],
            ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummarySection(Map summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(
          'Summary',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: summary.entries.map((entry) {
              if (entry.value == null || entry.value.toString().isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key.toString().replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.value.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ScheduleInterviewDialog extends StatefulWidget {
  final ApiService apiService;
  final String investorEmail;
  final VoidCallback onScheduled;

  const _ScheduleInterviewDialog({
    required this.apiService,
    required this.investorEmail,
    required this.onScheduled,
  });

  @override
  _ScheduleInterviewDialogState createState() => _ScheduleInterviewDialogState();
}

class _ScheduleInterviewDialogState extends State<_ScheduleInterviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _founderEmailController = TextEditingController();
  final _companyNameController = TextEditingController();
  bool _isScheduling = false;

  @override
  void dispose() {
    _founderEmailController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _scheduleInterview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isScheduling = true;
    });

    try {
      final response = await widget.apiService.scheduleInterview(
        founderEmail: _founderEmailController.text.trim(),
        investorEmail: widget.investorEmail,
        startupName: _companyNameController.text.trim(),
      );

      if (response['success'] && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Interview scheduled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onScheduled();
      } else {
        throw Exception(response['error'] ?? 'Failed to schedule');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScheduling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule AI Interview'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _founderEmailController,
              decoration: const InputDecoration(
                labelText: 'Founder Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter founder email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter company name';
                }
                return null;
              },
            ),
          ],
        ),
        ),
        actions: [
          TextButton(
          onPressed: _isScheduling ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
          ),
          ElevatedButton(
          onPressed: _isScheduling ? null : _scheduleInterview,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
          ),
          child: _isScheduling
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Schedule'),
        ),
      ],
    );
  }
}
