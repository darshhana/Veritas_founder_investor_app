import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class InterviewSchedulingScreen extends StatefulWidget {
  @override
  _InterviewSchedulingScreenState createState() =>
      _InterviewSchedulingScreenState();
}

class _InterviewSchedulingScreenState extends State<InterviewSchedulingScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _investorEmailController =
      TextEditingController();
  final TextEditingController _startupNameController = TextEditingController();
  final TextEditingController _calendarIdController = TextEditingController();

  bool _isScheduling = false;
  String? _scheduledEventLink;

  @override
  void dispose() {
    _investorEmailController.dispose();
    _startupNameController.dispose();
    _calendarIdController.dispose();
    super.dispose();
  }

  Future<void> _scheduleInterview() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to schedule interviews'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('📅 INTERVIEW: Scheduling interview...');
    print('📅 Founder: ${user.email}');
    print('📅 Investor: ${_investorEmailController.text.trim()}');
    print('📅 Startup: ${_startupNameController.text.trim()}');
    print('📅 Calendar ID: ${_calendarIdController.text.trim()}');

    setState(() {
      _isScheduling = true;
      _scheduledEventLink = null;
    });

    try {
      final response = await _apiService.scheduleInterview(
        founderEmail: user.email!,
        investorEmail: _investorEmailController.text.trim(),
        startupName: _startupNameController.text.trim(),
        calendarId: _calendarIdController.text.trim().isNotEmpty
            ? _calendarIdController.text.trim()
            : null,
      );

      print('📅 INTERVIEW: Response success: ${response['success']}');
      print('📅 INTERVIEW: Response data: ${response['data']}');
      print('📅 INTERVIEW: Response error: ${response['error']}');

      if (response['success']) {
        setState(() {
          // Backend returns interviewUrl, not eventLink
          final data = response['data'];
          _scheduledEventLink = data['interviewUrl'] ?? 
                               data['interview_url'] ?? 
                               data['eventLink'] ?? 
                               data['event_link'] ??
                               data.toString();
          _isScheduling = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Interview scheduled successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _investorEmailController.clear();
        _startupNameController.clear();
        _calendarIdController.clear();
      } else {
        throw Exception(response['error'] ?? 'Scheduling failed');
      }
    } catch (e, stackTrace) {
      print('❌ INTERVIEW ERROR: $e');
      print('❌ STACK TRACE: $stackTrace');
      setState(() {
        _isScheduling = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule AI Interview'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Card(
                elevation: 0,
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 40,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI-Powered Interview',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Schedule an automated interview with potential investors',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Investor Email
              TextFormField(
                controller: _investorEmailController,
                decoration: InputDecoration(
                  labelText: 'Investor Email *',
                  hintText: 'investor@example.com',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isScheduling,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter investor email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Startup Name
              TextFormField(
                controller: _startupNameController,
                decoration: InputDecoration(
                  labelText: 'Startup Name *',
                  hintText: 'Your Company Name',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                enabled: !_isScheduling,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your startup name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Calendar ID (Optional)
              TextFormField(
                controller: _calendarIdController,
                decoration: InputDecoration(
                  labelText: 'Calendar ID (Optional)',
                  hintText: 'Leave empty for default calendar',
                  prefixIcon: const Icon(Icons.event),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Optional: Specify a calendar ID',
                ),
                enabled: !_isScheduling,
              ),

              const SizedBox(height: 24),

              // Schedule Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isScheduling ? null : _scheduleInterview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isScheduling
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Scheduling...'),
                          ],
                        )
                      : const Text(
                          'Schedule Interview',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Event Link Display
              if (_scheduledEventLink != null) ...[
                Card(
                  elevation: 2,
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Interview Scheduled!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Calendar Event Link:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          _scheduledEventLink!,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (_scheduledEventLink != null) {
                              try {
                                final uri = Uri.parse(_scheduledEventLink!);
                                print('🌐 Opening URL: $_scheduledEventLink');
                                
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                  print('✅ URL opened successfully');
                                } else {
                                  throw Exception('Could not launch URL');
                                }
                              } catch (e) {
                                print('❌ Error opening URL: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('URL: $_scheduledEventLink\n\nCopy this link to open in browser'),
                                    duration: const Duration(seconds: 7),
                                    action: SnackBarAction(
                                      label: 'OK',
                                      onPressed: () {},
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('Open in Browser'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Info Card
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'How it works',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoItem(
                        '1',
                        'Enter the investor\'s email and your startup name',
                      ),
                      _buildInfoItem(
                        '2',
                        'Our AI will automatically schedule a convenient time',
                      ),
                      _buildInfoItem(
                        '3',
                        'Both parties will receive calendar invites',
                      ),
                      _buildInfoItem(
                        '4',
                        'The AI interviewer will conduct the initial screening',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

