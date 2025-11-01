import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ai_feedback_screen.dart';
import 'interview_scheduling_screen.dart';
import '../../services/firestore_service.dart';
import '../../models/upload_model.dart';
import '../../models/memo1_model.dart';

class UnifiedDataHubScreen extends StatefulWidget {
  @override
  _UnifiedDataHubScreenState createState() => _UnifiedDataHubScreenState();
}

class _UnifiedDataHubScreenState extends State<UnifiedDataHubScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<UploadModel> _uploads = [];
  Map<String, Memo1Model?> _memos = {}; // Map upload ID to memo
  bool _isLoading = true;
  bool _loadingMemos = false;
  
  // Removed static mock data - all data now comes from Firestore dynamically
  
  @override
  void initState() {
    super.initState();
    _loadPitchData();
  }
  
  void _loadPitchData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestoreService.getUploadsStream(user.email!).listen((uploads) async {
        if (mounted) {
          setState(() {
            _uploads = uploads;
            _isLoading = false;
          });
          
          // Load memos for uploads to get insights
          await _loadMemos();
        }
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadMemos() async {
    if (_uploads.isEmpty) return;
    
    setState(() {
      _loadingMemos = true;
    });
    
    Map<String, Memo1Model?> loadedMemos = {};
    
    for (var upload in _uploads) {
      try {
        // Check if memo exists for this upload
        final memoId = await _firestoreService.checkMemoExists(upload.id);
        if (memoId != null) {
          final memo = await _firestoreService.getMemo1(memoId);
          loadedMemos[upload.id] = memo;
        }
      } catch (e) {
        print('Error loading memo for upload ${upload.id}: $e');
      }
    }
    
    if (mounted) {
      setState(() {
        _memos = loadedMemos;
        _loadingMemos = false;
      });
    }
  }
  
  Map<String, dynamic> _calculateInsights() {
    final memosList = _memos.values.whereType<Memo1Model>().toList();
    
    if (memosList.isEmpty) {
      return {
        'industries': <String, int>{},
        'stages': <String, int>{},
        'avgFundingAsk': 0,
        'totalCompetitors': 0,
        'avgFlags': 0.0,
      };
    }
    
    // Count industries
    Map<String, int> industries = {};
    for (var memo in memosList) {
      industries[memo.industryCategory] = (industries[memo.industryCategory] ?? 0) + 1;
    }
    
    // Count stages
    Map<String, int> stages = {};
    for (var memo in memosList) {
      stages[memo.companyStage] = (stages[memo.companyStage] ?? 0) + 1;
    }
    
    // Calculate average funding ask (extract numbers)
    List<double> fundingAsks = [];
    for (var memo in memosList) {
      if (memo.fundingAsk != null) {
        // Try to extract number from strings like "$2M", "2 million", etc.
        final match = RegExp(r'[\d.]+').firstMatch(memo.fundingAsk!);
        if (match != null) {
          fundingAsks.add(double.tryParse(match.group(0)!) ?? 0);
        }
      }
    }
    double avgFunding = fundingAsks.isEmpty ? 0 : fundingAsks.reduce((a, b) => a + b) / fundingAsks.length;
    
    // Count total competitors mentioned
    int totalCompetitors = memosList.fold(0, (sum, memo) => sum + memo.competition.length);
    
    // Calculate average flags per pitch
    double avgFlags = memosList.fold(0, (sum, memo) => sum + memo.initialFlags.length) / memosList.length;
    
    return {
      'industries': industries,
      'stages': stages,
      'avgFundingAsk': avgFunding,
      'totalCompetitors': totalCompetitors,
      'avgFlags': avgFlags,
      'totalMemos': memosList.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Unified Data Hub',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track your pitch analytics, get AI-powered feedback, and schedule investor interviews.',
              style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 24),

            // Main Features - Highlighted USPs (MOVED TO TOP)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4A90E2).withOpacity(0.1),
                    const Color(0xFF4CAF50).withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4A90E2).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A90E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '✨ POWERED BY AI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your AI Co-Pilot',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildEnhancedQuickActionCard(
                          title: 'AI Feedback',
                          subtitle: 'Get Recommendations',
                          icon: Icons.auto_awesome,
                          color: const Color(0xFF4A90E2),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AIFeedbackScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildEnhancedQuickActionCard(
                          title: 'Schedule Interview',
                          subtitle: 'Book with Investors',
                          icon: Icons.calendar_today,
                          color: const Color(0xFF4CAF50),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => InterviewSchedulingScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pitch Stats Overview
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _buildPitchStatsSection(),

            const SizedBox(height: 24),

            // AI-Powered Insights
            if (_loadingMemos)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Analyzing your pitches...'),
                    ],
                  ),
                ),
              )
            else if (_memos.isNotEmpty)
              _buildInsightsSection(),

            const SizedBox(height: 24),

            // KPI Cards Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildKPICard(
                  title: 'Total Pitches',
                  value: '${_uploads.length}',
                  change: 'Uploaded to Veritas AI',
                  icon: Icons.description,
                  isPositive: true,
                ),
                _buildKPICard(
                  title: 'Analyses Complete',
                  value: '${_uploads.where((u) => u.status == 'completed' || u.status == 'processing').length}',
                  change: 'AI-generated insights',
                  icon: Icons.psychology,
                  isPositive: true,
                ),
                _buildKPICard(
                  title: 'Processing',
                  value: '${_uploads.where((u) => u.status == 'processing').length}',
                  change: 'Currently analyzing',
                  icon: Icons.pending,
                  isPositive: true,
                ),
                _buildConnectSystemsCard(),
              ],
            ),

            // Removed static Connected Systems and Chart sections
            // Only show dynamic, data-driven content
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String change,
    required IconData icon,
    required bool isPositive,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: const Color(0xFF4A90E2), size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                change,
                style: TextStyle(
                  fontSize: 9,
                  color: isPositive
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF44336),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                textAlign: TextAlign.start,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectSystemsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFF4A90E2),
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link, color: Color(0xFF4A90E2), size: 24),
            const SizedBox(height: 6),
            ElevatedButton(
              onPressed: () {
                _showConnectSystemsDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Connect'),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add integrations',
              style: TextStyle(fontSize: 9, color: Color(0xFF757575)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedSystemCard(String systemName) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF4A90E2),
          child: Text(
            systemName[0],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(systemName),
        subtitle: const Text('Connected'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.sync, color: Color(0xFF4A90E2)),
              onPressed: () {
                // Sync data
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Color(0xFF757575)),
              onPressed: () {
                // Settings
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 3),
                        const FlSpot(1, 1),
                        const FlSpot(2, 4),
                        const FlSpot(3, 2),
                        const FlSpot(4, 5),
                        const FlSpot(5, 3),
                        const FlSpot(6, 4),
                      ],
                      isCurved: true,
                      color: const Color(0xFF4A90E2),
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF4A90E2).withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectSystemsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect Systems'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSystemOption('Stripe', 'Payment processing', Icons.payment),
            _buildSystemOption(
              'Google Analytics',
              'Website analytics',
              Icons.analytics,
            ),
            _buildSystemOption('HubSpot', 'CRM and marketing', Icons.business),
            _buildSystemOption('Slack', 'Team communication', Icons.chat),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemOption(String name, String description, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4A90E2)),
      title: Text(name),
      subtitle: Text(description),
      trailing: const Icon(Icons.add_circle_outline),
      onTap: () {
        // Connect system (silent, no snackbar)
        Navigator.pop(context);
      },
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.05),
                color.withOpacity(0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPitchStatsSection() {
    if (_uploads.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.description_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No Pitch Data Yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload your first pitch to see analytics',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final completedCount = _uploads.where((u) => u.status == 'completed').length;
    final processingCount = _uploads.where((u) => u.status == 'processing').length;
    final mostRecentUpload = _uploads.isNotEmpty 
        ? _uploads.reduce((a, b) => a.uploadedAt.isAfter(b.uploadedAt) ? a : b)
        : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: const Color(0xFF4A90E2)),
                const SizedBox(width: 8),
                const Text(
                  'Pitch Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(
                  child: _buildStatItem(
                    label: 'Total',
                    value: '${_uploads.length}',
                    icon: Icons.description,
                    color: Colors.blue,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                Flexible(
                  child: _buildStatItem(
                    label: 'Completed',
                    value: '$completedCount',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                Flexible(
                  child: _buildStatItem(
                    label: 'Processing',
                    value: '$processingCount',
                    icon: Icons.pending,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            if (mostRecentUpload != null) ...[
              const SizedBox(height: 16),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Latest: ${mostRecentUpload.originalName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInsightsSection() {
    final insights = _calculateInsights();
    final industries = insights['industries'] as Map<String, int>;
    final stages = insights['stages'] as Map<String, int>;
    final avgFunding = insights['avgFundingAsk'] as double;
    final totalCompetitors = insights['totalCompetitors'] as int;
    final avgFlags = insights['avgFlags'] as double;
    final totalMemos = insights['totalMemos'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
            const SizedBox(width: 8),
            const Text(
              'AI-Powered Insights',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Insights Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.4, // Slightly adjusted for better fit
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildInsightCard(
              title: 'Avg Funding Ask',
              value: avgFunding > 0 ? '\$${avgFunding.toStringAsFixed(1)}M' : 'N/A',
              icon: Icons.attach_money,
              color: Colors.green,
            ),
            _buildInsightCard(
              title: 'Avg Red Flags',
              value: avgFlags.toStringAsFixed(1),
              icon: Icons.flag,
              color: avgFlags > 3 ? Colors.red : Colors.orange,
            ),
            _buildInsightCard(
              title: 'Competitors Tracked',
              value: '$totalCompetitors',
              icon: Icons.business,
              color: Colors.blue,
            ),
            _buildInsightCard(
              title: 'Pitches Analyzed',
              value: '$totalMemos',
              icon: Icons.analytics,
              color: Colors.purple,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Industry & Stage Breakdown
        Row(
          children: [
            if (industries.isNotEmpty)
              Expanded(
                child: _buildBreakdownCard(
                  title: 'Industries',
                  data: industries,
                  icon: Icons.category,
                ),
              ),
            if (industries.isNotEmpty && stages.isNotEmpty)
              const SizedBox(width: 12),
            if (stages.isNotEmpty)
              Expanded(
                child: _buildBreakdownCard(
                  title: 'Company Stages',
                  data: stages,
                  icon: Icons.trending_up,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard({
    required String title,
    required Map<String, int> data,
    required IconData icon,
  }) {
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF4A90E2)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...sortedEntries.take(3).map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A90E2),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
