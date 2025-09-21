import 'package:flutter/material.dart';

class GroundTruthEngineScreen extends StatefulWidget {
  @override
  _GroundTruthEngineScreenState createState() =>
      _GroundTruthEngineScreenState();
}

class _GroundTruthEngineScreenState extends State<GroundTruthEngineScreen> {
  // Mock data for verification results
  final List<Map<String, dynamic>> verificationResults = [
    {
      'id': '1',
      'founderName': 'Sarah Chen',
      'companyName': 'TechFlow Solutions',
      'claim': 'Previous experience at Google as Senior Engineer',
      'status': 'verified',
      'source': 'LinkedIn Profile',
      'confidence': 95,
      'details':
          'LinkedIn profile shows 3 years at Google as Senior Software Engineer (2020-2023)',
    },
    {
      'id': '2',
      'founderName': 'Michael Rodriguez',
      'companyName': 'HealthTech Innovations',
      'claim': 'Patent holder for AI diagnostic algorithm',
      'status': 'discrepancy',
      'source': 'USPTO Database',
      'confidence': 78,
      'details': 'Patent found but co-inventor, not sole inventor as claimed',
    },
    {
      'id': '3',
      'founderName': 'Emily Watson',
      'companyName': 'GreenEnergy Co',
      'claim': 'Market size of \$50B for renewable energy software',
      'status': 'unverifiable',
      'source': 'Industry Reports',
      'confidence': 45,
      'details':
          'Multiple conflicting reports found, unable to verify specific claim',
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
              'Ground Truth Engine',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Trust, instantly verified. Automated fact-checking for all claims.',
              style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 24),

            // Stats Cards
            _buildStatsSection(),

            const SizedBox(height: 24),

            // Verification Results
            const Text(
              'Recent Verifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 16),
            ...verificationResults.map(
              (result) => _buildVerificationCard(result),
            ),
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
            title: 'Verified',
            value: '156',
            icon: Icons.check_circle,
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Discrepancies',
            value: '23',
            icon: Icons.warning,
            color: const Color(0xFFFF9800),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Unverifiable',
            value: '12',
            icon: Icons.help,
            color: const Color(0xFF757575),
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

  Widget _buildVerificationCard(Map<String, dynamic> result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewVerificationDetails(result),
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
                          result['companyName'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${result['founderName']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusIndicator(result['status'], result['confidence']),
                ],
              ),
              const SizedBox(height: 16),

              // Claim
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Claim:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result['claim'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Source and Details
              Row(
                children: [
                  Icon(Icons.source, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Source: ${result['source']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                result['details'],
                style: const TextStyle(fontSize: 14, color: Color(0xFF424242)),
              ),
              const SizedBox(height: 16),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _viewVerificationDetails(result),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Evidence'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A90E2),
                    side: const BorderSide(color: Color(0xFF4A90E2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status, int confidence) {
    IconData icon;
    Color color;
    String label;

    switch (status) {
      case 'verified':
        icon = Icons.check_circle;
        color = const Color(0xFF4CAF50);
        label = 'Verified';
        break;
      case 'discrepancy':
        icon = Icons.warning;
        color = const Color(0xFFFF9800);
        label = 'Discrepancy';
        break;
      case 'unverifiable':
        icon = Icons.help;
        color = const Color(0xFF757575);
        label = 'Unverifiable';
        break;
      default:
        icon = Icons.help;
        color = const Color(0xFF757575);
        label = 'Unknown';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$confidence% confidence',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _viewVerificationDetails(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verification Details - ${result['companyName']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Founder: ${result['founderName']}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'Claim:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(result['claim']),
              const SizedBox(height: 12),
              const Text(
                'Verification Status:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Icon(
                    _getStatusIcon(result['status']),
                    color: _getStatusColor(result['status']),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getStatusLabel(result['status']),
                    style: TextStyle(
                      color: _getStatusColor(result['status']),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Source:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(result['source']),
              const SizedBox(height: 12),
              const Text(
                'Details:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(result['details']),
              const SizedBox(height: 12),
              Text(
                'Confidence: ${result['confidence']}%',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
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
                  content: Text('Opening source evidence...'),
                  backgroundColor: Color(0xFF4A90E2),
                ),
              );
            },
            child: const Text('View Source'),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'verified':
        return Icons.check_circle;
      case 'discrepancy':
        return Icons.warning;
      case 'unverifiable':
        return Icons.help;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return const Color(0xFF4CAF50);
      case 'discrepancy':
        return const Color(0xFFFF9800);
      case 'unverifiable':
        return const Color(0xFF757575);
      default:
        return const Color(0xFF757575);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'verified':
        return 'Verified';
      case 'discrepancy':
        return 'Discrepancy Found';
      case 'unverifiable':
        return 'Unverifiable';
      default:
        return 'Unknown';
    }
  }
}
