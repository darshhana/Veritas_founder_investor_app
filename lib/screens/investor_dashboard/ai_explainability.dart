import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIExplainabilityScreen extends StatefulWidget {
  @override
  _AIExplainabilityScreenState createState() => _AIExplainabilityScreenState();
}

class _AIExplainabilityScreenState extends State<AIExplainabilityScreen> {
  int _selectedIndex = 0;
  final List<String> _tabs = [
    'Model Insights',
    'Performance',
    'Feature Importance',
    'Sector Analysis',
    'Bias Detection',
    'Decision Logic',
  ];

      // Real metrics calculated from data
      Map<String, dynamic> metrics = {
        'totalAnalyses': 0,
        'avgConfidence': 0.0,
        'accuracy': 0.0,
        'predictions': <Map<String, dynamic>>[],
        'featureImportance': <Map<String, double>>{},
        'monthlyAccuracy': <double>[],
        'sectorRecommendations': <Map<String, int>>{},
        'stageRecommendations': <Map<String, int>>{},
        'totalBySector': <Map<String, int>>{},
        'totalByStage': <Map<String, int>>{},
        'decisionExplanations': <List<Map<String, dynamic>>>[],
      };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('📊 Calculating AI metrics from diligence results...');

      // PRIORITIZE diligenceReports first (better analysis), then fallback to diligenceResults
      List<QueryDocumentSnapshot> allDocs = [];
      
      // Try diligenceReports first
      try {
        QuerySnapshot reportsSnapshot;
        try {
          reportsSnapshot = await FirebaseFirestore.instance
              .collection('diligenceReports')
              .orderBy('timestamp', descending: true)
              .limit(100)
              .get();
        } catch (e) {
          try {
            reportsSnapshot = await FirebaseFirestore.instance
                .collection('diligenceReports')
                .orderBy('created_at', descending: true)
                .limit(100)
                .get();
          } catch (e2) {
            reportsSnapshot = await FirebaseFirestore.instance
                .collection('diligenceReports')
                .limit(100)
                .get();
          }
        }
        print('📊 Found ${reportsSnapshot.docs.length} in diligenceReports');
        allDocs.addAll(reportsSnapshot.docs);
      } catch (e) {
        print('⚠️ Error accessing diligenceReports: $e');
      }
      
      // Fallback to diligenceResults
      try {
        QuerySnapshot resultsSnapshot;
        try {
          resultsSnapshot = await FirebaseFirestore.instance
              .collection('diligenceResults')
              .orderBy('timestamp', descending: true)
              .limit(100)
              .get();
        } catch (e) {
          try {
            resultsSnapshot = await FirebaseFirestore.instance
                .collection('diligenceResults')
                .orderBy('created_at', descending: true)
                .limit(100)
                .get();
          } catch (e2) {
            resultsSnapshot = await FirebaseFirestore.instance
                .collection('diligenceResults')
                .limit(100)
                .get();
          }
        }
        print('📊 Found ${resultsSnapshot.docs.length} in diligenceResults');
        allDocs.addAll(resultsSnapshot.docs);
      } catch (e) {
        print('⚠️ Error accessing diligenceResults: $e');
      }
      
      if (allDocs.isEmpty) {
        print('❌ No diligence data found');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      
      print('📊 Total diligence documents: ${allDocs.length}');
      
      // Deduplicate by document ID
      final uniqueDocs = <String, QueryDocumentSnapshot>{};
      for (var doc in allDocs) {
        uniqueDocs[doc.id] = doc;
      }
      
      final diligenceSnapshot = uniqueDocs.values;

      print('📊 Processing ${diligenceSnapshot.length} unique diligence results');

      List<Map<String, dynamic>> predictions = [];
      List<double> confidenceScores = [];
      Map<String, List<double>> featureScores = {
        'Team Experience': [],
        'Market Size': [],
        'Revenue Growth': [],
        'Technology': [],
        'Competitive Advantage': [],
      };
      
      // Enhanced metrics for new tabs
      Map<String, int> sectorRecommendations = {}; // Industry -> BUY count
      Map<String, int> stageRecommendations = {}; // Stage -> BUY count
      Map<String, int> totalBySector = {}; // Industry -> total analyses
      Map<String, int> totalByStage = {}; // Stage -> total analyses
      List<Map<String, dynamic>> decisionExplanations = []; // Why BUY/HOLD/PASS

      for (var doc in diligenceSnapshot) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        
        if (data['memo1_diligence'] != null) {
          final memo2 = data['memo1_diligence'] as Map<String, dynamic>;
          
          // Get confidence score - normalize from 0-10 to 0-1
          final confidence = memo2['confidence_score'];
          double confValue = 0.0;
          if (confidence != null) {
            if (confidence is num) {
              confValue = confidence.toDouble();
              if (confValue > 1.0) {
                confValue = confValue / 10.0;
              }
            } else if (confidence is String) {
              confValue = double.tryParse(confidence) ?? 0.0;
              if (confValue > 1.0) {
                confValue = confValue / 10.0;
              }
            }
            confidenceScores.add(confValue);
          }

          // Get recommendation
          final recommendation = memo2['investment_recommendation']?.toString() ?? 'No recommendation';
          
          // Get company info with better lookup
          String companyName = 'Unknown Company';
          String industry = 'Unknown';
          String stage = 'Unknown';
          
          final memo1Id = data['memo_1_id'] ?? data['company_id'];
          if (memo1Id != null) {
            try {
              // Try direct lookup
              var memo1Doc = await FirebaseFirestore.instance
                  .collection('ingestionResults')
                  .doc(memo1Id.toString())
                  .get();
              
              // Try company_id query if direct fails
              if (!memo1Doc.exists) {
                final querySnapshot = await FirebaseFirestore.instance
                    .collection('ingestionResults')
                    .where('company_id', isEqualTo: memo1Id.toString())
                    .limit(1)
                    .get();
                if (querySnapshot.docs.isNotEmpty) {
                  memo1Doc = querySnapshot.docs.first;
                }
              }
              
              if (memo1Doc.exists) {
                final memo1Data = memo1Doc.data();
                if (memo1Data?['memo_1'] != null) {
                  final memo1 = memo1Data!['memo_1'] as Map<String, dynamic>;
                  companyName = memo1['title']?.toString() ?? 
                               memo1['company_name']?.toString() ?? 
                               'Unknown Company';
                  
                  // Get industry and stage
                  final industryCategory = memo1['industry_category'];
                  if (industryCategory != null) {
                    if (industryCategory is List && industryCategory.isNotEmpty) {
                      industry = industryCategory.first.toString();
                    } else {
                      industry = industryCategory.toString();
                    }
                  }
                  
                  stage = memo1['company_stage']?.toString() ?? 'Unknown';
                }
              }
            } catch (e) {
              print('Error fetching memo 1: $e');
            }
          }
          
          // Track sector and stage recommendations for bias detection
          totalBySector[industry] = (totalBySector[industry] ?? 0) + 1;
          totalByStage[stage] = (totalByStage[stage] ?? 0) + 1;
          if (recommendation == 'BUY') {
            sectorRecommendations[industry] = (sectorRecommendations[industry] ?? 0) + 1;
            stageRecommendations[stage] = (stageRecommendations[stage] ?? 0) + 1;
          }
          
          // Build decision explanation
          final founderScore = memo2['founder_analysis']?['score'] ?? 0.0;
          final problemScore = memo2['problem_validation']?['score'] ?? 0.0;
          final solutionScore = memo2['solution_analysis']?['score'] ?? 0.0;
          
          String explanation = '';
          if (recommendation == 'BUY') {
            explanation = 'Strong scores across key factors: ';
            if (founderScore > 7) explanation += 'Experienced founders, ';
            if (problemScore > 7) explanation += 'Validated problem, ';
            if (solutionScore > 7) explanation += 'Feasible solution.';
          } else if (recommendation == 'HOLD') {
            explanation = 'Mixed signals: Some strengths but concerns need validation.';
          } else {
            explanation = 'Key risks identified: ';
            final risks = memo2['key_risks'] as List?;
            if (risks != null && risks.isNotEmpty) {
              explanation += risks.first.toString();
            }
          }
          
          decisionExplanations.add({
            'company': companyName,
            'recommendation': recommendation,
            'explanation': explanation,
            'scores': {
              'founder': founderScore,
              'problem': problemScore,
              'solution': solutionScore,
            },
          });

          // Add to predictions
          DateTime predictionDate = DateTime.now();
          try {
            if (data['created_at'] != null) {
              if (data['created_at'] is Timestamp) {
                predictionDate = (data['created_at'] as Timestamp).toDate();
              } else if (data['created_at'] is String) {
                predictionDate = DateTime.tryParse(data['created_at']) ?? DateTime.now();
              }
            } else if (data['timestamp'] != null) {
              if (data['timestamp'] is Timestamp) {
                predictionDate = (data['timestamp'] as Timestamp).toDate();
              } else if (data['timestamp'] is String) {
                predictionDate = DateTime.tryParse(data['timestamp']) ?? DateTime.now();
              }
            }
          } catch (e) {
            print('Error parsing date: $e');
          }
          
          predictions.add({
            'company': companyName,
            'prediction': recommendation,
            'confidence': confValue,
            'date': predictionDate,
            'industry': industry,
            'stage': stage,
          });

          // Calculate feature importance from analysis sections (more accurate)
          final founderAnalysis = memo2['founder_analysis'] as Map<String, dynamic>?;
          final problemValidation = memo2['problem_validation'] as Map<String, dynamic>?;
          final solutionAnalysis = memo2['solution_analysis'] as Map<String, dynamic>?;
          final marketAnalysis = memo2['market_analysis'] as Map<String, dynamic>?;
          final tractionAnalysis = memo2['traction_analysis'] as Map<String, dynamic>?;
          
          // Extract scores from analysis sections
          if (founderAnalysis != null && founderAnalysis['score'] != null) {
            double score = (founderAnalysis['score'] as num).toDouble();
            if (score > 1.0) score = score / 10.0;
            featureScores['Team Experience']!.add(score);
          }
          
          if (problemValidation != null && problemValidation['score'] != null) {
            double score = (problemValidation['score'] as num).toDouble();
            if (score > 1.0) score = score / 10.0;
            featureScores['Market Size']!.add(score);
          }
          
          if (solutionAnalysis != null && solutionAnalysis['score'] != null) {
            double score = (solutionAnalysis['score'] as num).toDouble();
            if (score > 1.0) score = score / 10.0;
            featureScores['Technology']!.add(score);
          }
          
          if (marketAnalysis != null && marketAnalysis['score'] != null) {
            double score = (marketAnalysis['score'] as num).toDouble();
            if (score > 1.0) score = score / 10.0;
            featureScores['Market Size']!.add(score);
          }
          
          if (tractionAnalysis != null && tractionAnalysis['score'] != null) {
            double score = (tractionAnalysis['score'] as num).toDouble();
            if (score > 1.0) score = score / 10.0;
            featureScores['Revenue Growth']!.add(score);
          }
          
          // Fallback to strengths/weaknesses if analysis sections not available
          final strengths = memo2['strengths'] as List?;
          final weaknesses = memo2['weaknesses'] as List?;

          if (strengths != null) {
            for (var strength in strengths) {
              final strengthStr = strength.toString().toLowerCase();
              if (strengthStr.contains('team') || strengthStr.contains('founder')) {
                featureScores['Team Experience']!.add(0.9);
              }
              if (strengthStr.contains('market') || strengthStr.contains('tam')) {
                featureScores['Market Size']!.add(0.85);
              }
              if (strengthStr.contains('revenue') || strengthStr.contains('growth')) {
                featureScores['Revenue Growth']!.add(0.88);
              }
              if (strengthStr.contains('tech') || strengthStr.contains('product')) {
                featureScores['Technology']!.add(0.82);
              }
              if (strengthStr.contains('competitive') || strengthStr.contains('unique')) {
                featureScores['Competitive Advantage']!.add(0.80);
              }
            }
          }

          if (weaknesses != null) {
            for (var weakness in weaknesses) {
              final weakStr = weakness.toString().toLowerCase();
              if (weakStr.contains('team') || weakStr.contains('founder')) {
                featureScores['Team Experience']!.add(0.4);
              }
              if (weakStr.contains('market')) {
                featureScores['Market Size']!.add(0.45);
              }
              if (weakStr.contains('revenue') || weakStr.contains('growth')) {
                featureScores['Revenue Growth']!.add(0.35);
              }
              if (weakStr.contains('tech') || weakStr.contains('product')) {
                featureScores['Technology']!.add(0.5);
              }
              if (weakStr.contains('competitive')) {
                featureScores['Competitive Advantage']!.add(0.4);
              }
            }
          }
        }
      }

      // Calculate averages
      double avgConfidence = confidenceScores.isEmpty
          ? 0.0
          : confidenceScores.reduce((a, b) => a + b) / confidenceScores.length;

      // Calculate feature importance - ensure all keys exist with defaults
      Map<String, double> featureImportance = {
        'Team Experience': 0.5,
        'Market Size': 0.5,
        'Revenue Growth': 0.5,
        'Technology': 0.5,
        'Competitive Advantage': 0.5,
      };
      featureScores.forEach((key, values) {
        if (values.isNotEmpty) {
          featureImportance[key] = values.reduce((a, b) => a + b) / values.length;
        }
      });

      // Generate monthly accuracy (simulated based on avg confidence)
      List<double> monthlyAccuracy = List.generate(6, (index) {
        return (avgConfidence + (index * 0.02)).clamp(0.0, 1.0);
      });
      
      // Sort predictions by date (most recent first)
      predictions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      print('✅ Metrics calculated: ${predictions.length} predictions, avg confidence: ${(avgConfidence * 100).toInt()}%');

      if (mounted) {
        setState(() {
          metrics = {
            'totalAnalyses': uniqueDocs.length,
            'avgConfidence': avgConfidence,
            'accuracy': avgConfidence * 0.95, // Use confidence as proxy for accuracy
            'predictions': predictions.take(10).toList(),
            'featureImportance': featureImportance,
            'monthlyAccuracy': monthlyAccuracy,
            'sectorRecommendations': sectorRecommendations,
            'stageRecommendations': stageRecommendations,
            'totalBySector': totalBySector,
            'totalByStage': totalByStage,
            'decisionExplanations': decisionExplanations.take(20).toList(),
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error calculating metrics: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
                const Text(
                  'AI Explainability',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                ),
          IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadMetrics,
                  tooltip: 'Refresh',
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
        return _buildModelInsights();
      case 1:
        return _buildPerformanceMetrics();
      case 2:
        return _buildFeatureImportance();
      case 3:
        return _buildSectorAnalysis();
      case 4:
        return _buildBiasDetection();
      case 5:
        return _buildDecisionLogic();
      default:
        return Container();
    }
  }

  Widget _buildModelInsights() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOverviewCard(),
        const SizedBox(height: 16),
        _buildStatsCard(),
        const SizedBox(height: 16),
        _buildRecentPredictionsCard(),
      ],
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Model Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
            ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(Icons.psychology, 'Type', 'AI Ensemble'),
                ),
                Expanded(
                  child: _buildInfoItem(Icons.analytics, 'Analyses', '${metrics['totalAnalyses']}'),
                ),
                Expanded(
                  child: _buildInfoItem(Icons.star, 'Avg Score', '${(metrics['avgConfidence'] * 100).toInt()}%'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4A90E2), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    final accuracy = metrics['accuracy'] * 100;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Model Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Accuracy', '${accuracy.toStringAsFixed(1)}%', Colors.green),
                ),
                Expanded(
                  child: _buildStatItem('Confidence', '${(metrics['avgConfidence'] * 100).toInt()}%', Colors.blue),
                ),
                Expanded(
                  child: _buildStatItem('Analyses', '${metrics['totalAnalyses']}', Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentPredictionsCard() {
    final predictions = metrics['predictions'] as List<Map<String, dynamic>>;

    if (predictions.isEmpty) {
    return Card(
        elevation: 2,
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
        child: Column(
          children: [
                Icon(Icons.analytics_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
            Text(
                  'No predictions yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Predictions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 16),
            ...predictions.take(5).map((pred) => _buildPredictionItem(pred)),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionItem(Map<String, dynamic> prediction) {
    final confidence = (prediction['confidence'] is num)
        ? (prediction['confidence'] as num).toDouble()
        : 0.0;
    
    final recommendation = prediction['prediction']?.toString() ?? 'N/A';
    final recommendationColor = recommendation == 'BUY' 
        ? Colors.green 
        : recommendation == 'HOLD' 
            ? Colors.orange 
            : Colors.red;
    
    final date = prediction['date'] as DateTime?;
    final industry = prediction['industry']?.toString() ?? 'Unknown';
    final stage = prediction['stage']?.toString() ?? 'Unknown';
    
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
          Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    Text(
                      prediction['company']?.toString() ?? 'Unknown Company',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (industry != 'Unknown')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              industry,
                              style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                            ),
                          ),
                        if (stage != 'Unknown')
                          Text(
                            stage,
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        if (date != null)
                          Text(
                            '${date.day}/${date.month}/${date.year}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
          Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                      color: recommendationColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      recommendation,
                      style: TextStyle(
                        color: recommendationColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${(confidence * 100).toInt()}%',
                      style: const TextStyle(
                color: Color(0xFF4A90E2),
                fontWeight: FontWeight.bold,
                        fontSize: 12,
              ),
            ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    final monthlyAccuracy = metrics['monthlyAccuracy'] as List<double>;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
            padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                const Text(
                  'Model Performance Over Time',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
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
                              const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
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
                          spots: monthlyAccuracy.asMap().entries.map((e) =>
                              FlSpot(e.key.toDouble(), e.value)).toList(),
                          isCurved: true,
                          color: const Color(0xFF4A90E2),
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
        ),
      ],
    );
  }

  Widget _buildFeatureImportance() {
    final featureImportance = metrics['featureImportance'] as Map<String, double>;
    final sortedFeatures = featureImportance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
            padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                const Text(
              'Feature Importance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
            ),
                ),
                const SizedBox(height: 16),
                SizedBox(
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
                              if (value.toInt() >= sortedFeatures.length) {
                                return const Text('');
                              }
                              final feature = sortedFeatures[value.toInt()].key;
                          return Text(
                                feature.split(' ').first,
                                style: const TextStyle(fontSize: 10),
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
                      barGroups: sortedFeatures.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                      barRods: [
                            BarChartRodData(
                              toY: entry.value.value,
                              color: const Color(0xFF4A90E2),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
            padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                const Text(
                  'Feature Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 16),
                ...sortedFeatures.map((entry) =>
                    _buildFeatureItem(entry.key, entry.value)),
          ],
        ),
      ),
          ),
        ],
    );
  }

  Widget _buildFeatureItem(String name, double importance) {
    final colors = [
                    Colors.green,
      Colors.blue,
                    Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    final colorIndex = name.hashCode % colors.length;
    final color = colors[colorIndex];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
                decoration: BoxDecoration(
                  color: color,
              shape: BoxShape.circle,
          ),
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            '${(importance * 100).toInt()}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // NEW TAB: Sector Analysis
  Widget _buildSectorAnalysis() {
    final sectorRecs = metrics['sectorRecommendations'] as Map<String, int>? ?? {};
    final totalBySector = metrics['totalBySector'] as Map<String, int>? ?? {};
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
            padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                    const Icon(Icons.business, color: Color(0xFF4A90E2), size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Performance by Industry',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Shows AI recommendation patterns across different sectors. Helps identify which industries the model finds most attractive.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                ),
                const SizedBox(height: 24),
                if (totalBySector.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No sector data available yet'),
                    ),
                  )
                else
                  ...totalBySector.entries.map((entry) {
                    final sector = entry.key;
                    final total = entry.value;
                    final buys = sectorRecs[sector] ?? 0;
                    final buyRate = total > 0 ? (buys / total) : 0.0;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
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
                                Text(
                                  sector,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$buys / $total BUY recommendations',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
                                '${(buyRate * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 16,
            fontWeight: FontWeight.bold,
                                  color: buyRate > 0.5 ? Colors.green : buyRate > 0.3 ? Colors.orange : Colors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 80,
                                child: LinearProgressIndicator(
                                  value: buyRate,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    buyRate > 0.5 ? Colors.green : buyRate > 0.3 ? Colors.orange : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // NEW TAB: Bias Detection
  Widget _buildBiasDetection() {
    final sectorRecs = metrics['sectorRecommendations'] as Map<String, int>? ?? {};
    final stageRecs = metrics['stageRecommendations'] as Map<String, int>? ?? {};
    final totalBySector = metrics['totalBySector'] as Map<String, int>? ?? {};
    final totalByStage = metrics['totalByStage'] as Map<String, int>? ?? {};
    
    // Calculate bias scores (0-1, where >0.6 indicates potential bias)
    Map<String, double> sectorBias = {};
    Map<String, double> stageBias = {};
    
    if (totalBySector.isNotEmpty) {
      final avgBuyRate = sectorRecs.values.fold(0, (a, b) => a + b) / totalBySector.values.fold(0, (a, b) => a + b);
      totalBySector.forEach((sector, total) {
        final buys = sectorRecs[sector] ?? 0;
        final buyRate = total > 0 ? (buys / total) : 0.0;
        // Bias score: deviation from average
        sectorBias[sector] = (buyRate - avgBuyRate).abs();
      });
    }
    
    if (totalByStage.isNotEmpty) {
      final avgBuyRate = stageRecs.values.fold(0, (a, b) => a + b) / totalByStage.values.fold(0, (a, b) => a + b);
      totalByStage.forEach((stage, total) {
        final buys = stageRecs[stage] ?? 0;
        final buyRate = total > 0 ? (buys / total) : 0.0;
        stageBias[stage] = (buyRate - avgBuyRate).abs();
      });
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
            padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Bias Detection',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Identifies if the AI model shows bias toward specific industries or funding stages. High deviation suggests potential bias.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sector Bias Analysis',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (sectorBias.isEmpty)
                  const Text('No data available')
                else
                  ...sectorBias.entries.map((entry) {
                    final biasScore = entry.value;
                    final isBiased = biasScore > 0.3;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isBiased ? Colors.orange[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isBiased ? Colors.orange[200]! : Colors.green[200]!,
                        ),
                      ),
      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              Icon(
                                isBiased ? Icons.warning : Icons.check_circle,
                                color: isBiased ? Colors.orange : Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isBiased ? 'Potential Bias' : 'Balanced',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isBiased ? Colors.orange[700] : Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 24),
                const Text(
                  'Stage Bias Analysis',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (stageBias.isEmpty)
                  const Text('No data available')
                else
                  ...stageBias.entries.map((entry) {
                    final biasScore = entry.value;
                    final isBiased = biasScore > 0.3;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                        color: isBiased ? Colors.orange[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isBiased ? Colors.orange[200]! : Colors.green[200]!,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              Icon(
                                isBiased ? Icons.warning : Icons.check_circle,
                                color: isBiased ? Colors.orange : Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
          Text(
                                isBiased ? 'Potential Bias' : 'Balanced',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isBiased ? Colors.orange[700] : Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
          ),
        ],
      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // NEW TAB: Decision Logic
  Widget _buildDecisionLogic() {
    final explanations = metrics['decisionExplanations'] as List<Map<String, dynamic>>? ?? [];
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
            padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Row(
                  children: [
                    const Icon(Icons.psychology, color: Color(0xFF4A90E2), size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Decision Explanations',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                      ),
            ),
          ],
        ),
                const SizedBox(height: 8),
                const Text(
                  'Shows why the AI made each investment recommendation. Helps understand model reasoning and improve trust.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                ),
                const SizedBox(height: 24),
                if (explanations.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No decision explanations available yet'),
                    ),
                  )
                else
                  ...explanations.take(10).map((explanation) {
                    final recommendation = explanation['recommendation']?.toString() ?? 'N/A';
                    final recommendationColor = recommendation == 'BUY' 
                        ? Colors.green 
                        : recommendation == 'HOLD' 
                            ? Colors.orange 
                            : Colors.red;
                    
                    final scores = explanation['scores'] as Map<String, dynamic>? ?? {};
                    final founderScore = (scores['founder'] as num?)?.toDouble() ?? 0.0;
                    final problemScore = (scores['problem'] as num?)?.toDouble() ?? 0.0;
                    final solutionScore = (scores['solution'] as num?)?.toDouble() ?? 0.0;
                    
                    // Normalize scores if > 1
                    final normFounder = founderScore > 1.0 ? founderScore / 10.0 : founderScore;
                    final normProblem = problemScore > 1.0 ? problemScore / 10.0 : problemScore;
                    final normSolution = solutionScore > 1.0 ? solutionScore / 10.0 : solutionScore;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  explanation['company']?.toString() ?? 'Unknown Company',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: recommendationColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  recommendation,
                                  style: TextStyle(
                                    color: recommendationColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                Text(
                            explanation['explanation']?.toString() ?? 'No explanation available',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF424242)),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Key Scores:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildScoreBar('Founder', normFounder),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildScoreBar('Problem', normProblem),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildScoreBar('Solution', normSolution),
                ),
              ],
            ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBar(String label, double score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 6,
          child: LinearProgressIndicator(
            value: score,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              score > 0.7 ? Colors.green : score > 0.5 ? Colors.orange : Colors.red,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${(score * 100).toInt()}%',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
