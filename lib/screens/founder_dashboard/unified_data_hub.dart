import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class UnifiedDataHubScreen extends StatefulWidget {
  @override
  _UnifiedDataHubScreenState createState() => _UnifiedDataHubScreenState();
}

class _UnifiedDataHubScreenState extends State<UnifiedDataHubScreen> {
  // Mock KPI data - in real app, this would come from your backend
  final Map<String, dynamic> kpiData = {
    'mrr': 12234.56,
    'mrrGrowth': 15.2,
    'userGrowth': 1405,
    'userGrowthPercent': 20.1,
    'churnRate': 3.2,
    'churnChange': -0.5,
  };

  final List<String> connectedSystems = ['Stripe', 'Google Analytics'];

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
              'Your business\'s single source of truth. Connect your core systems to see live KPIs.',
              style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
            ),
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
                  title: 'Monthly Recurring Revenue',
                  value: '\$${kpiData['mrr'].toStringAsFixed(2)}',
                  change: '+${kpiData['mrrGrowth']}% from last month',
                  icon: Icons.attach_money,
                  isPositive: true,
                ),
                _buildKPICard(
                  title: 'User Growth',
                  value: '+${kpiData['userGrowth']}',
                  change: '+${kpiData['userGrowthPercent']}% from last month',
                  icon: Icons.people,
                  isPositive: true,
                ),
                _buildKPICard(
                  title: 'Churn Rate',
                  value: '${kpiData['churnRate']}%',
                  change: '${kpiData['churnChange']}% from last month',
                  icon: Icons.trending_down,
                  isPositive: kpiData['churnChange'] < 0,
                ),
                _buildConnectSystemsCard(),
              ],
            ),

            const SizedBox(height: 24),

            // Connected Systems Section
            if (connectedSystems.isNotEmpty) ...[
              const Text(
                'Connected Systems',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 16),
              ...connectedSystems.map(
                (system) => _buildConnectedSystemCard(system),
              ),
            ],

            const SizedBox(height: 24),

            // Chart Section
            _buildChartSection(),
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              change,
              style: TextStyle(
                fontSize: 10,
                color: isPositive
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFF44336),
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
        // Connect system
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connecting to $name...')));
      },
    );
  }
}
