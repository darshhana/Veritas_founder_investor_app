import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/memo1_model.dart';
import '../../models/memo2_model.dart';

class MemoDisplayScreen extends StatefulWidget {
  final String memoId;

  const MemoDisplayScreen({Key? key, required this.memoId}) : super(key: key);

  @override
  _MemoDisplayScreenState createState() => _MemoDisplayScreenState();
}

class _MemoDisplayScreenState extends State<MemoDisplayScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  Memo1Model? _memo1;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Founders only see Memo 1 (Founders Checklist)
    _loadMemo1();
  }

  Future<void> _loadMemo1() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Only load Memo 1 for founders
      final memo1 = await _firestoreService.getMemo1(widget.memoId);

      setState(() {
        _memo1 = memo1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading analysis: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Founders Checklist'),
        // No tabs - only showing Memo 1
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildMemo1View(), // Only show Memo 1
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMemo1,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemo1View() {
    if (_memo1 == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Founders Checklist is being processed...\nPlease check back shortly.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMemo1,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Header
            _buildSection(
              title: 'Company Information',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Company', _memo1!.title),
                  _buildInfoRow('Founder', _memo1!.founderName),
                  _buildInfoRow('Industry', _memo1!.industryCategory),
                  _buildInfoRow('Stage', _memo1!.companyStage),
                  if (_memo1!.fundingAsk != null)
                    _buildInfoRow('Funding Ask', _memo1!.fundingAsk!),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Problem
            _buildSection(
              title: 'Problem Statement',
              child: Text(_memo1!.problem),
            ),

            const SizedBox(height: 16),

            // Solution
            _buildSection(
              title: 'Solution',
              child: Text(_memo1!.solution),
            ),

            const SizedBox(height: 16),

            // Traction
            _buildSection(
              title: 'Traction',
              child: Text(_memo1!.traction),
            ),

            const SizedBox(height: 16),

            // Market Size
            _buildSection(
              title: 'Market Size',
              child: Text(_memo1!.marketSize),
            ),

            const SizedBox(height: 16),

            // Business Model
            _buildSection(
              title: 'Business Model',
              child: Text(_memo1!.businessModel),
            ),

            const SizedBox(height: 16),

            // Team
            _buildSection(
              title: 'Team',
              child: Text(_memo1!.team),
            ),

            const SizedBox(height: 16),

            // Competition
            if (_memo1!.competition.isNotEmpty)
              _buildSection(
                title: 'Competition',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _memo1!.competition
                      .map((comp) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 8),
                                const SizedBox(width: 8),
                                Expanded(child: Text(comp)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),

            const SizedBox(height: 16),

            // Initial Flags
            if (_memo1!.initialFlags.isNotEmpty)
              _buildSection(
                title: 'Initial Flags',
                color: Colors.red.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _memo1!.initialFlags
                      .map((flag) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning_amber,
                                    size: 20, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(child: Text(flag)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),

            const SizedBox(height: 16),

            // Validation Points
            if (_memo1!.validationPoints.isNotEmpty)
              _buildSection(
                title: 'Points to Validate',
                color: Colors.orange.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _memo1!.validationPoints
                      .map((point) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    size: 20, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(child: Text(point)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),

            const SizedBox(height: 16),

            // Summary Analysis
            _buildSection(
              title: 'Summary Analysis',
              child: Text(_memo1!.summaryAnalysis),
            ),
          ],
        ),
      ),
    );
  }

  // Memo 2 view removed - founders only see Memo 1 (Founders Checklist)
  // Investors see Memo 2 in the investor dashboard

  Widget _buildSection({
    required String title,
    required Widget child,
    Color? color,
  }) {
    return Card(
      elevation: 1,
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF757575),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF424242)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, double score) {
    Color scoreColor;
    if (score >= 8.0) {
      scoreColor = Colors.green;
    } else if (score >= 6.0) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF757575),
              ),
            ),
          ),
          Text(
            '${score.toStringAsFixed(1)}/10',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: scoreColor,
            ),
          ),
        ],
      ),
    );
  }
}

