import 'package:flutter/material.dart';

class AIDiligenceEngineScreen extends StatefulWidget {
  @override
  _AIDiligenceEngineScreenState createState() =>
      _AIDiligenceEngineScreenState();
}

class _AIDiligenceEngineScreenState extends State<AIDiligenceEngineScreen> {
  // Mock data for diligence memos
  final List<Map<String, dynamic>> diligenceMemos = [
    {
      'id': '1',
      'founderName': 'Sarah Chen',
      'companyName': 'TechFlow Solutions',
      'stage': 'Memo 1',
      'status': 'Completed',
      'createdDate': '2024-01-20',
      'summary': 'Initial analysis of B2B SaaS startup with strong traction',
      'score': 8.5,
    },
    {
      'id': '2',
      'founderName': 'Michael Rodriguez',
      'companyName': 'HealthTech Innovations',
      'stage': 'Memo 2',
      'status': 'In Progress',
      'createdDate': '2024-01-22',
      'summary': 'AI interview analysis in progress',
      'score': null,
    },
    {
      'id': '3',
      'founderName': 'Emily Watson',
      'companyName': 'GreenEnergy Co',
      'stage': 'Memo 3',
      'status': 'Completed',
      'createdDate': '2024-01-18',
      'summary': 'Final comprehensive analysis with investment recommendation',
      'score': 7.2,
    },
  ];

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
              'AI Diligence Engine',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'From data dump to decision-ready memo in minutes.',
              style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 24),

            // Stats Cards
            _buildStatsSection(),

            const SizedBox(height: 24),

            // Memos List
            const Text(
              'Recent Analysis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 16),
            ...diligenceMemos.map((memo) => _buildMemoCard(memo)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Analysis',
            value: '24',
            icon: Icons.analytics,
            color: const Color(0xFF4A90E2),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Avg. Score',
            value: '7.8',
            icon: Icons.star,
            color: const Color(0xFFFF9800),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Time Saved',
            value: '48h',
            icon: Icons.timer,
            color: const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoCard(Map<String, dynamic> memo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewMemo(memo),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memo['companyName'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${memo['founderName']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            memo['status'],
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          memo['status'],
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(memo['status']),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        memo['stage'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4A90E2),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Summary
              Text(
                memo['summary'],
                style: const TextStyle(fontSize: 14, color: Color(0xFF424242)),
              ),
              const SizedBox(height: 12),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created: ${memo['createdDate']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (memo['score'] != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFF9800),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          memo['score'].toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFF4CAF50);
      case 'In Progress':
        return const Color(0xFFFF9800);
      case 'Pending':
        return const Color(0xFF757575);
      default:
        return const Color(0xFF757575);
    }
  }

  void _viewMemo(Map<String, dynamic> memo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${memo['stage']} - ${memo['companyName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Founder: ${memo['founderName']}'),
            const SizedBox(height: 8),
            Text('Summary: ${memo['summary']}'),
            const SizedBox(height: 8),
            Text('Status: ${memo['status']}'),
            if (memo['score'] != null) ...[
              const SizedBox(height: 8),
              Text('Score: ${memo['score']}/10'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening detailed memo...'),
                  backgroundColor: Color(0xFF4A90E2),
                ),
              );
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }
}
