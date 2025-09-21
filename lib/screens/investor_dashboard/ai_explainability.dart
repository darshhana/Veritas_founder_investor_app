import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AIExplainabilityScreen extends StatefulWidget {
  @override
  _AIExplainabilityScreenState createState() => _AIExplainabilityScreenState();
}

class _AIExplainabilityScreenState extends State<AIExplainabilityScreen> {
  int _selectedIndex = 0;
  final List<String> _tabs = [
    'Model Insights',
    'Decision Trees',
    'Feature Importance',
    'Bias Detection',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Explainability'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _refreshInsights(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              margin: EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: _selectedIndex == index
                    ? Color(0xFF4A90E2)
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
        },
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildModelInsights();
      case 1:
        return _buildDecisionTrees();
      case 2:
        return _buildFeatureImportance();
      case 3:
        return _buildBiasDetection();
      default:
        return Container();
    }
  }

  Widget _buildModelInsights() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildModelOverviewCard(),
        SizedBox(height: 16),
        _buildPerformanceMetricsCard(),
        SizedBox(height: 16),
        _buildModelAccuracyChart(),
        SizedBox(height: 16),
        _buildRecentPredictionsCard(),
      ],
    );
  }

  Widget _buildDecisionTrees() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildDecisionTreeCard(
          title: 'Investment Decision Tree',
          description: 'Shows the decision path for investment recommendations',
          accuracy: 0.87,
          nodes: 45,
          depth: 8,
        ),
        SizedBox(height: 12),
        _buildDecisionTreeCard(
          title: 'Risk Assessment Tree',
          description: 'Decision tree for risk evaluation and scoring',
          accuracy: 0.92,
          nodes: 32,
          depth: 6,
        ),
        SizedBox(height: 12),
        _buildDecisionTreeCard(
          title: 'Market Fit Analysis',
          description: 'Tree structure for market fit predictions',
          accuracy: 0.79,
          nodes: 28,
          depth: 5,
        ),
      ],
    );
  }

  Widget _buildFeatureImportance() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildFeatureImportanceChart(),
        SizedBox(height: 16),
        _buildFeatureListCard(),
      ],
    );
  }

  Widget _buildBiasDetection() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildBiasOverviewCard(),
        SizedBox(height: 16),
        _buildBiasMetricsCard(),
        SizedBox(height: 16),
        _buildBiasRecommendationsCard(),
      ],
    );
  }

  Widget _buildModelOverviewCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Model Overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewStat(
                    'Model Type',
                    'Ensemble',
                    Icons.psychology,
                  ),
                ),
                Expanded(
                  child: _buildOverviewStat('Version', 'v2.1.3', Icons.tag),
                ),
                Expanded(
                  child: _buildOverviewStat(
                    'Last Updated',
                    '2 days ago',
                    Icons.update,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Model Description',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'Advanced ensemble model combining multiple algorithms for investment decision making. Includes risk assessment, market analysis, and founder evaluation components.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF4A90E2), size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Color(0xFF4A90E2),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPerformanceMetricsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem('Accuracy', '87.3%', Colors.green),
                ),
                Expanded(
                  child: _buildMetricItem('Precision', '84.1%', Colors.blue),
                ),
                Expanded(
                  child: _buildMetricItem('Recall', '89.2%', Colors.orange),
                ),
                Expanded(
                  child: _buildMetricItem('F1-Score', '86.5%', Colors.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildModelAccuracyChart() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Model Accuracy Over Time',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${(value * 100).toInt()}%');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                          ];
                          return Text(months[value.toInt() % months.length]);
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 0.82),
                        FlSpot(1, 0.85),
                        FlSpot(2, 0.83),
                        FlSpot(3, 0.87),
                        FlSpot(4, 0.86),
                        FlSpot(5, 0.89),
                      ],
                      isCurved: true,
                      color: Color(0xFF4A90E2),
                      barWidth: 3,
                      dotData: FlDotData(show: true),
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

  Widget _buildRecentPredictionsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Recent Predictions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            _buildPredictionItem(
              company: 'TechFlow Solutions',
              prediction: 'High Investment Potential',
              confidence: 0.89,
              date: '2024-01-15',
            ),
            SizedBox(height: 12),
            _buildPredictionItem(
              company: 'GreenTech Innovations',
              prediction: 'Medium Risk',
              confidence: 0.76,
              date: '2024-01-14',
            ),
            SizedBox(height: 12),
            _buildPredictionItem(
              company: 'DataSync Pro',
              prediction: 'Low Market Fit',
              confidence: 0.82,
              date: '2024-01-13',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionItem({
    required String company,
    required String prediction,
    required double confidence,
    required String date,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(company, style: Theme.of(context).textTheme.titleLarge),
                Text(prediction, style: Theme.of(context).textTheme.bodyMedium),
                Text(date, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF4A90E2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${(confidence * 100).toInt()}%',
              style: TextStyle(
                color: Color(0xFF4A90E2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionTreeCard({
    required String title,
    required String description,
    required double accuracy,
    required int nodes,
    required int depth,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTreeStat(
                    'Accuracy',
                    '${(accuracy * 100).toInt()}%',
                    Icons.check_circle,
                  ),
                ),
                Expanded(
                  child: _buildTreeStat(
                    'Nodes',
                    nodes.toString(),
                    Icons.account_tree,
                  ),
                ),
                Expanded(
                  child: _buildTreeStat(
                    'Depth',
                    depth.toString(),
                    Icons.height,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: Text('View Tree'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: Text('Export'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF4A90E2), size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Color(0xFF4A90E2),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildFeatureImportanceChart() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Feature Importance',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            Container(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1.0,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${(value * 100).toInt()}%');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const features = [
                            'Revenue',
                            'Growth',
                            'Team',
                            'Market',
                            'Tech',
                          ];
                          return Text(
                            features[value.toInt() % features.length],
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(toY: 0.85, color: Color(0xFF4A90E2)),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(toY: 0.78, color: Color(0xFF4A90E2)),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(toY: 0.72, color: Color(0xFF4A90E2)),
                      ],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [
                        BarChartRodData(toY: 0.68, color: Color(0xFF4A90E2)),
                      ],
                    ),
                    BarChartGroupData(
                      x: 4,
                      barRods: [
                        BarChartRodData(toY: 0.61, color: Color(0xFF4A90E2)),
                      ],
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

  Widget _buildFeatureListCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Top Features',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            _buildFeatureItem('Revenue Growth Rate', 0.85, Colors.green),
            _buildFeatureItem('Team Experience', 0.78, Colors.blue),
            _buildFeatureItem('Market Size', 0.72, Colors.orange),
            _buildFeatureItem('Technology Innovation', 0.68, Colors.purple),
            _buildFeatureItem('Competitive Advantage', 0.61, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String name, double importance, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(name, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            '${(importance * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiasOverviewCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bias Detection Overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBiasStat(
                    'Overall Bias Score',
                    'Low',
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                Expanded(
                  child: _buildBiasStat(
                    'Gender Bias',
                    'Minimal',
                    Colors.green,
                    Icons.person,
                  ),
                ),
                Expanded(
                  child: _buildBiasStat(
                    'Geographic Bias',
                    'Low',
                    Colors.orange,
                    Icons.location_on,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiasStat(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBiasMetricsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bias Metrics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            _buildBiasMetric('Demographic Parity', 0.92, Colors.green),
            _buildBiasMetric('Equalized Odds', 0.88, Colors.green),
            _buildBiasMetric('Calibration', 0.85, Colors.orange),
            _buildBiasMetric('Fairness Score', 0.90, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildBiasMetric(String name, double score, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(name, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Container(
            width: 100,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: score,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Text(
            '${(score * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiasRecommendationsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bias Mitigation Recommendations',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            _buildRecommendationItem(
              'Increase diversity in training data',
              'Add more examples from underrepresented groups',
              Icons.diversity_3,
            ),
            _buildRecommendationItem(
              'Regular bias audits',
              'Conduct monthly bias assessments',
              Icons.assessment,
            ),
            _buildRecommendationItem(
              'Feature engineering',
              'Review and adjust feature selection',
              Icons.build,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(
    String title,
    String description,
    IconData icon,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(0xFF4A90E2), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _refreshInsights() {
    // Refresh AI insights
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Refreshing AI insights...')));
  }
}
