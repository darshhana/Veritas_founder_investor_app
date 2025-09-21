import 'package:flutter/material.dart';

class MatchmakingScreen extends StatefulWidget {
  @override
  _MatchmakingScreenState createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  // Mock data for matched founders
  final List<Map<String, dynamic>> matchedFounders = [
    {
      'id': '1',
      'name': 'Sarah Chen',
      'companyName': 'TechFlow Solutions',
      'industry': 'B2B SaaS',
      'stage': 'Seed',
      'mrr': 15000,
      'churnRate': 2.5,
      'matchScore': 95,
      'description': 'AI-powered workflow automation for enterprise teams',
      'location': 'San Francisco, CA',
      'lastActive': '2 hours ago',
    },
    {
      'id': '2',
      'name': 'Michael Rodriguez',
      'companyName': 'HealthTech Innovations',
      'industry': 'Healthcare',
      'stage': 'Series A',
      'mrr': 45000,
      'churnRate': 1.8,
      'matchScore': 88,
      'description': 'Telemedicine platform with AI diagnostics',
      'location': 'Austin, TX',
      'lastActive': '1 day ago',
    },
    {
      'id': '3',
      'name': 'Emily Watson',
      'companyName': 'GreenEnergy Co',
      'industry': 'CleanTech',
      'stage': 'Seed',
      'mrr': 8500,
      'churnRate': 3.2,
      'matchScore': 82,
      'description': 'Renewable energy management software',
      'location': 'Seattle, WA',
      'lastActive': '3 hours ago',
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
              'Intelligent Matchmaking',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your personal AI deal scout. High-quality, pre-vetted opportunities.',
              style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 24),

            // Investment Thesis Card
            _buildThesisCard(),

            const SizedBox(height: 24),

            // Matched Founders
            const Text(
              'Recommended Matches',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 16),
            ...matchedFounders.map((founder) => _buildFounderCard(founder)),
          ],
        ),
      ),
    );
  }

  Widget _buildThesisCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Investment Thesis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                ),
                IconButton(
                  onPressed: () => _editThesis(),
                  icon: const Icon(Icons.edit, color: Color(0xFF4A90E2)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildThesisItem('Industries', [
              'B2B SaaS',
              'Healthcare',
              'FinTech',
            ]),
            const SizedBox(height: 8),
            _buildThesisItem('Stage', ['Seed', 'Series A']),
            const SizedBox(height: 8),
            _buildThesisItem('MRR Range', ['\$10K - \$50K']),
            const SizedBox(height: 8),
            _buildThesisItem('Churn Rate', ['< 5%']),
            const SizedBox(height: 8),
            _buildThesisItem('Location', ['US', 'Canada']),
          ],
        ),
      ),
    );
  }

  Widget _buildThesisItem(String label, List<String> values) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF757575)),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: values.map((value) => _buildTag(value)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4A90E2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF4A90E2),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFounderCard(Map<String, dynamic> founder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewFounder(founder),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
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
                          founder['companyName'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${founder['name']}',
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
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getMatchScoreColor(
                            founder['matchScore'],
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${founder['matchScore']}% Match',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getMatchScoreColor(founder['matchScore']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        founder['stage'],
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

              // Description
              Text(
                founder['description'],
                style: const TextStyle(fontSize: 14, color: Color(0xFF424242)),
              ),
              const SizedBox(height: 12),

              // Metrics
              Row(
                children: [
                  _buildMetric('MRR', '\$${founder['mrr'].toString()}'),
                  const SizedBox(width: 16),
                  _buildMetric('Churn', '${founder['churnRate']}%'),
                  const SizedBox(width: 16),
                  _buildMetric('Industry', founder['industry']),
                ],
              ),
              const SizedBox(height: 12),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        founder['location'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Text(
                    'Active ${founder['lastActive']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _passFounder(founder),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Pass'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF757575),
                        side: const BorderSide(color: Color(0xFF757575)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _connectFounder(founder),
                      icon: const Icon(Icons.favorite, size: 16),
                      label: const Text('Connect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF424242),
          ),
        ),
      ],
    );
  }

  Color _getMatchScoreColor(int score) {
    if (score >= 90) return const Color(0xFF4CAF50);
    if (score >= 80) return const Color(0xFF4A90E2);
    if (score >= 70) return const Color(0xFFFF9800);
    return const Color(0xFF757575);
  }

  void _editThesis() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Investment Thesis'),
        content: const Text(
          'This feature will open a form to customize your investment criteria and preferences.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening thesis editor...'),
                  backgroundColor: Color(0xFF4A90E2),
                ),
              );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _viewFounder(Map<String, dynamic> founder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(founder['companyName']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Founder: ${founder['name']}'),
            const SizedBox(height: 8),
            Text('Description: ${founder['description']}'),
            const SizedBox(height: 8),
            Text('MRR: \$${founder['mrr']}'),
            const SizedBox(height: 8),
            Text('Churn Rate: ${founder['churnRate']}%'),
            const SizedBox(height: 8),
            Text('Match Score: ${founder['matchScore']}%'),
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
              _connectFounder(founder);
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _passFounder(Map<String, dynamic> founder) {
    setState(() {
      matchedFounders.remove(founder);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Passed on ${founder['companyName']}'),
        backgroundColor: const Color(0xFF757575),
      ),
    );
  }

  void _connectFounder(Map<String, dynamic> founder) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connecting with ${founder['name']}...'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }
}
