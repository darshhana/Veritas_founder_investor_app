import 'package:flutter/material.dart';

class AIInterviewerScreen extends StatefulWidget {
  @override
  _AIInterviewerScreenState createState() => _AIInterviewerScreenState();
}

class _AIInterviewerScreenState extends State<AIInterviewerScreen> {
  int _selectedIndex = 0;
  final List<String> _tabs = [
    'Active Interviews',
    'Interview History',
    'Templates',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Interviewer'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showCreateInterviewDialog(),
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
        return _buildActiveInterviews();
      case 1:
        return _buildInterviewHistory();
      case 2:
        return _buildTemplates();
      default:
        return Container();
    }
  }

  Widget _buildActiveInterviews() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildStatsCard(),
        SizedBox(height: 16),
        _buildActiveInterviewCard(
          founderName: 'Sarah Chen',
          company: 'TechFlow Solutions',
          stage: 'Series A',
          progress: 0.7,
          nextQuestion: 'What is your customer acquisition strategy?',
          timeRemaining: '15 min',
        ),
        SizedBox(height: 12),
        _buildActiveInterviewCard(
          founderName: 'Michael Rodriguez',
          company: 'GreenTech Innovations',
          stage: 'Seed',
          progress: 0.3,
          nextQuestion: 'How do you plan to scale your operations?',
          timeRemaining: '45 min',
        ),
      ],
    );
  }

  Widget _buildInterviewHistory() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildHistoryCard(
          founderName: 'Emily Watson',
          company: 'DataSync Pro',
          stage: 'Series B',
          score: 8.5,
          duration: '45 min',
          date: '2024-01-15',
          status: 'Completed',
        ),
        SizedBox(height: 12),
        _buildHistoryCard(
          founderName: 'David Kim',
          company: 'CloudSecure',
          stage: 'Series A',
          score: 7.2,
          duration: '38 min',
          date: '2024-01-12',
          status: 'Completed',
        ),
        SizedBox(height: 12),
        _buildHistoryCard(
          founderName: 'Lisa Thompson',
          company: 'AI Vision',
          stage: 'Seed',
          score: 9.1,
          duration: '52 min',
          date: '2024-01-10',
          status: 'Completed',
        ),
      ],
    );
  }

  Widget _buildTemplates() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildTemplateCard(
          title: 'Technical Due Diligence',
          description: 'Comprehensive technical assessment template',
          questions: 25,
          duration: '60 min',
        ),
        SizedBox(height: 12),
        _buildTemplateCard(
          title: 'Market Analysis',
          description: 'Market opportunity and competitive landscape',
          questions: 18,
          duration: '45 min',
        ),
        SizedBox(height: 12),
        _buildTemplateCard(
          title: 'Financial Review',
          description: 'Financial performance and projections',
          questions: 22,
          duration: '50 min',
        ),
        SizedBox(height: 12),
        _buildTemplateCard(
          title: 'Team Assessment',
          description: 'Founder and team evaluation',
          questions: 15,
          duration: '35 min',
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Interview Statistics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Total Interviews', '24', Icons.quiz),
                ),
                Expanded(child: _buildStatItem('Avg Score', '8.2', Icons.star)),
                Expanded(
                  child: _buildStatItem('Time Saved', '12h', Icons.timer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF4A90E2), size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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

  Widget _buildActiveInterviewCard({
    required String founderName,
    required String company,
    required String stage,
    required double progress,
    required String nextQuestion,
    required String timeRemaining,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFF4A90E2),
                  child: Text(
                    founderName[0],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        founderName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '$company • $stage',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    timeRemaining,
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text('Progress', style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
            ),
            SizedBox(height: 8),
            Text(
              '${(progress * 100).toInt()}% Complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: 16),
            Text(
              'Next Question:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 4),
            Text(nextQuestion, style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: Text('Resume Interview'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: Text('View Progress'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard({
    required String founderName,
    required String company,
    required String stage,
    required double score,
    required String duration,
    required String date,
    required String status,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFF4A90E2),
                  child: Text(
                    founderName[0],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        founderName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '$company • $stage',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHistoryStat(
                    'Score',
                    score.toString(),
                    Icons.star,
                  ),
                ),
                Expanded(
                  child: _buildHistoryStat('Duration', duration, Icons.timer),
                ),
                Expanded(
                  child: _buildHistoryStat('Date', date, Icons.calendar_today),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: Text('View Report'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: Text('Replay'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryStat(String label, String value, IconData icon) {
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

  Widget _buildTemplateCard({
    required String title,
    required String description,
    required int questions,
    required String duration,
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
                Icon(Icons.quiz, color: Color(0xFF4A90E2), size: 16),
                SizedBox(width: 4),
                Text(
                  '$questions questions',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(width: 16),
                Icon(Icons.timer, color: Color(0xFF4A90E2), size: 16),
                SizedBox(width: 4),
                Text(duration, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: Text('Preview'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: Text('Use Template'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateInterviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Interview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Founder Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Company Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Stage',
                border: OutlineInputBorder(),
              ),
              items: ['Seed', 'Series A', 'Series B', 'Series C']
                  .map(
                    (stage) =>
                        DropdownMenuItem(value: stage, child: Text(stage)),
                  )
                  .toList(),
              onChanged: (value) {},
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Template',
                border: OutlineInputBorder(),
              ),
              items:
                  [
                        'Technical Due Diligence',
                        'Market Analysis',
                        'Financial Review',
                        'Team Assessment',
                      ]
                      .map(
                        (template) => DropdownMenuItem(
                          value: template,
                          child: Text(template),
                        ),
                      )
                      .toList(),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Create Interview'),
          ),
        ],
      ),
    );
  }
}
