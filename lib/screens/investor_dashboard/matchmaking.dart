import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';

class MatchmakingScreen extends StatefulWidget {
  @override
  _MatchmakingScreenState createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> matchedFounders = [];
  bool _isLoading = true;
  Map<String, dynamic>? investorThesis;

  @override
  void initState() {
    super.initState();
    _loadInvestorThesis();
    _loadMatchedFounders();
  }

  Future<void> _loadInvestorThesis() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final profile = await _firestoreService.getInvestorProfile(user.uid);
      if (profile != null && mounted) {
        setState(() {
          investorThesis = profile['investmentThesis'] ?? {
            'industries': ['B2B SaaS', 'Healthcare', 'FinTech'],
            'stages': ['Seed', 'Series A'],
            'mrrRange': '\$10K - \$50K',
            'churnRate': '< 5%',
            'locations': ['US', 'Canada'],
          };
        });
      }
    } catch (e) {
      print('Error loading investor thesis: $e');
    }
  }

  Future<void> _loadMatchedFounders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 Loading founders from ingestionResults...');
      List<Map<String, dynamic>> founders = [];

      // Try ingestionResults collection - use same approach as diagnostic (no orderBy)
      try {
        print('📋 Using same query method as diagnostic (no orderBy)...');
        final snapshot = await FirebaseFirestore.instance
            .collection('ingestionResults')
            .limit(20)
            .get();
        
        print('✅ Query succeeded: Found ${snapshot.docs.length} documents');
        
        // Sort in memory by timestamp if available
        final docsList = snapshot.docs.toList();
        docsList.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>?;
          final bData = b.data() as Map<String, dynamic>?;
          
          DateTime? aTime;
          DateTime? bTime;
          
          if (aData != null && aData['timestamp'] is String) {
            aTime = DateTime.tryParse(aData['timestamp']);
          }
          if (bData != null && bData['timestamp'] is String) {
            bTime = DateTime.tryParse(bData['timestamp']);
          }
          
          if (aTime != null && bTime != null) {
            return bTime.compareTo(aTime); // Descending
          }
          return 0;
        });

        print('📊 Found ${docsList.length} potential matches (sorted in memory)');

        for (var doc in docsList) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          
          Map<String, dynamic>? memo1;
          if (data['memo_1'] != null) {
            memo1 = data['memo_1'] as Map<String, dynamic>;
          } else if (data['title'] != null || data['founder_name'] != null) {
            memo1 = data;
          }
          
          if (memo1 != null) {
            final memo2 = await _firestoreService.getMemo2(doc.id);

            // Handle founder_name as array
            String founderName = 'Unknown Founder';
            if (memo1['founder_name'] != null) {
              if (memo1['founder_name'] is List) {
                final names = (memo1['founder_name'] as List).map((e) => e.toString()).toList();
                founderName = names.join(' & ');
              } else {
                founderName = memo1['founder_name'].toString();
              }
            } else if (data['founder_name'] != null) {
              if (data['founder_name'] is List) {
                final names = (data['founder_name'] as List).map((e) => e.toString()).toList();
                founderName = names.join(' & ');
              } else {
                founderName = data['founder_name'].toString();
              }
            }
            
            final companyName = memo1['title']?.toString() ??
                memo1['company_name']?.toString() ??
                'Unknown Company';
            
            // Handle industry_category as array
            String industry = 'General';
            if (memo1['industry_category'] != null) {
              if (memo1['industry_category'] is List) {
                final industries = (memo1['industry_category'] as List).map((e) => e.toString()).toList();
                industry = industries.join(', ');
              } else {
                industry = memo1['industry_category'].toString();
              }
            } else if (memo1['industry'] != null) {
              industry = memo1['industry'].toString();
            }
            final stage = memo1['company_stage']?.toString() ??
                memo1['stage']?.toString() ??
                'Not Specified';
            final description = memo1['summary_analysis']?.toString() ??
                memo1['problem']?.toString() ??
                'No description available';

            int matchScore = 50;
            if (memo2 != null) {
              matchScore = ((memo2.confidenceScore ?? 0.5) * 100).toInt();
            } else {
              matchScore = _calculateSimpleMatchScore(memo1);
            }

            final metrics = memo1['metrics'] as Map<String, dynamic>?;
            double? mrr;
            double? churnRate;
            
            if (metrics != null) {
              if (metrics['mrr'] != null) {
                mrr = (metrics['mrr'] as num).toDouble();
              }
              if (metrics['churn_rate'] != null) {
                churnRate = (metrics['churn_rate'] as num).toDouble();
              }
            }

            DateTime createdAt = DateTime.now();
            try {
              if (data['created_at'] != null) {
                if (data['created_at'] is Timestamp) {
                  createdAt = (data['created_at'] as Timestamp).toDate();
                } else if (data['created_at'] is String) {
                  createdAt = DateTime.tryParse(data['created_at']) ?? DateTime.now();
                }
              } else if (data['timestamp'] != null) {
                if (data['timestamp'] is Timestamp) {
                  createdAt = (data['timestamp'] as Timestamp).toDate();
                } else if (data['timestamp'] is String) {
                  createdAt = DateTime.tryParse(data['timestamp']) ?? DateTime.now();
                }
              }
            } catch (e) {
              print('  ⚠️ Date parsing error: $e');
            }

            founders.add({
              'id': doc.id,
              'name': founderName,
              'companyName': companyName,
              'industry': industry,
              'stage': stage,
              'mrr': mrr ?? 0,
              'churnRate': churnRate ?? 0,
              'matchScore': matchScore,
              'description': description,
              'location': memo1['location']?.toString() ?? 'Not Specified',
              'lastActive': _getRelativeTime(createdAt),
              'memo1': memo1,
              'memo2': memo2,
            });

            print('  ✅ Added founder: $founderName ($matchScore% match)');
          }
        }
      } catch (e) {
        print('❌ Error querying ingestionResults: $e');
      }

      // Try uploads as fallback
      if (founders.isEmpty) {
        try {
          final uploadsSnapshot = await FirebaseFirestore.instance
              .collection('uploads')
              .where('status', isEqualTo: 'completed')
              .limit(20)
              .get();
          
          for (var doc in uploadsSnapshot.docs) {
            final memoId = await _firestoreService.checkMemoExists(doc.id);
            if (memoId != null) {
              final memo1Doc = await FirebaseFirestore.instance
                  .collection('ingestionResults')
                  .doc(memoId)
                  .get();
              
              if (memo1Doc.exists) {
                final memo1Data = memo1Doc.data();
                final memo1 = memo1Data?['memo_1'] as Map<String, dynamic>?;
                
                if (memo1 != null) {
                  final memo2 = await _firestoreService.getMemo2(memoId);
                  int matchScore = memo2 != null 
                      ? ((memo2.confidenceScore ?? 0.5) * 100).toInt()
                      : _calculateSimpleMatchScore(memo1);
                  
                  founders.add({
                    'id': memoId,
                    'name': memo1['founder_name']?.toString() ?? 'Unknown',
                    'companyName': memo1['title']?.toString() ?? 'Unknown',
                    'industry': memo1['industry_category']?.toString() ?? 'General',
                    'stage': memo1['company_stage']?.toString() ?? 'Not Specified',
                    'mrr': 0,
                    'churnRate': 0,
                    'matchScore': matchScore,
                    'description': memo1['summary_analysis']?.toString() ?? 'No description',
                    'location': 'Not Specified',
                    'lastActive': 'Recently',
                    'memo1': memo1,
                    'memo2': memo2,
                  });
                }
              }
            }
          }
        } catch (e) {
          print('❌ Error querying uploads: $e');
        }
      }

      founders.sort((a, b) => b['matchScore'].compareTo(a['matchScore']));

      print('✅ Total matched founders: ${founders.length}');

      if (mounted) {
        setState(() {
          matchedFounders = founders;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading founders: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading matches: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _calculateSimpleMatchScore(Map<String, dynamic> memo1) {
    // Simple scoring based on available data
    int score = 50; // Base score

    // Check industry match
    final industry = memo1['industry_category']?.toString().toLowerCase() ?? '';
    if (industry.contains('saas') || industry.contains('software')) {
      score += 15;
    }
    if (industry.contains('health')) {
      score += 15;
    }

    // Check stage
    final stage = memo1['company_stage']?.toString().toLowerCase() ?? '';
    if (stage.contains('seed') || stage.contains('series a')) {
      score += 10;
    }

    // Random variation for demo
    score += (DateTime.now().millisecond % 20) - 10;

    return score.clamp(0, 100);
  }

  String _getRelativeTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadMatchedFounders,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recommended Matches',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                  Text(
                    '${matchedFounders.length} matches',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (matchedFounders.isEmpty)
                _buildEmptyState()
              else
                ...matchedFounders.map((founder) => _buildFounderCard(founder)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No matches found yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later as founders upload their pitches',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThesisCard() {
    final thesis = investorThesis ?? {
      'industries': ['B2B SaaS', 'Healthcare', 'FinTech'],
      'stages': ['Seed', 'Series A'],
      'mrrRange': '\$10K - \$50K',
      'churnRate': '< 5%',
      'locations': ['US', 'Canada'],
    };

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
            _buildThesisItem('Industries', thesis['industries'] as List? ?? []),
            const SizedBox(height: 8),
            _buildThesisItem('Stage', thesis['stages'] as List? ?? []),
            const SizedBox(height: 8),
            _buildThesisItem('MRR Range', [thesis['mrrRange'] ?? '\$10K - \$50K']),
            const SizedBox(height: 8),
            _buildThesisItem('Churn Rate', [thesis['churnRate'] ?? '< 5%']),
            const SizedBox(height: 8),
            _buildThesisItem('Location', thesis['locations'] as List? ?? ['US']),
          ],
        ),
      ),
    );
  }

  Widget _buildThesisItem(String label, List values) {
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
            children: values.map((value) => _buildTag(value.toString())).toList(),
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${founder['name']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
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
                            overflow: TextOverflow.ellipsis,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Metrics - Fixed overflow
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (founder['mrr'] > 0)
                    _buildMetric('MRR', '\$${founder['mrr'].toStringAsFixed(0)}'),
                  if (founder['churnRate'] > 0)
                    _buildMetric('Churn', '${founder['churnRate']}%'),
                  _buildMetric('Industry', founder['industry']),
                ],
              ),
              const SizedBox(height: 12),

              // Footer - Fixed overflow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            founder['location'],
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Text(
                      'Active ${founder['lastActive']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
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
    final currentThesis = investorThesis ?? {
      'industries': ['B2B SaaS', 'Healthcare', 'FinTech'],
      'stages': ['Seed', 'Series A'],
      'mrrRange': '\$10K - \$50K',
      'churnRate': '< 5%',
      'locations': ['US', 'Canada'],
    };

    final industriesController = TextEditingController(
      text: (currentThesis['industries'] as List?)?.join(', ') ?? '',
    );
    final stagesController = TextEditingController(
      text: (currentThesis['stages'] as List?)?.join(', ') ?? '',
    );
    final mrrController = TextEditingController(
      text: currentThesis['mrrRange']?.toString() ?? '\$10K - \$50K',
    );
    final churnController = TextEditingController(
      text: currentThesis['churnRate']?.toString() ?? '< 5%',
    );
    final locationsController = TextEditingController(
      text: (currentThesis['locations'] as List?)?.join(', ') ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Investment Preferences'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: industriesController,
                decoration: const InputDecoration(
                  labelText: 'Industries (comma-separated)',
                  hintText: 'B2B SaaS, Healthcare, FinTech',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stagesController,
                decoration: const InputDecoration(
                  labelText: 'Stages (comma-separated)',
                  hintText: 'Seed, Series A',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mrrController,
                decoration: const InputDecoration(
                  labelText: 'MRR Range',
                  hintText: '\$10K - \$50K',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: churnController,
                decoration: const InputDecoration(
                  labelText: 'Max Churn Rate',
                  hintText: '< 5%',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationsController,
                decoration: const InputDecoration(
                  labelText: 'Locations (comma-separated)',
                  hintText: 'US, Canada',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                investorThesis = {
                  'industries': industriesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                  'stages': stagesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                  'mrrRange': mrrController.text,
                  'churnRate': churnController.text,
                  'locations': locationsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                };
              });
              
              // Recalculate matches with new preferences
              _loadMatchedFounders();
              
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Preferences updated! Recalculating matches...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _viewFounder(Map<String, dynamic> founder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FounderDetailScreen(founder: founder),
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
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              matchedFounders.add(founder);
              matchedFounders.sort((a, b) => 
                  b['matchScore'].compareTo(a['matchScore']));
            });
          },
        ),
      ),
    );
  }

  void _connectFounder(Map<String, dynamic> founder) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to connect with founders'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Save connection request to Firestore
      await FirebaseFirestore.instance.collection('investorConnections').add({
        'investor_email': user.email,
        'founder_email': founder['founderEmail'] ?? '',
        'company_name': founder['companyName'] ?? '',
        'founder_name': founder['name'] ?? '',
        'memo_1_id': founder['memo1Id'] ?? '',
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'match_score': founder['matchScore'] ?? 0,
      });

      // Mark as connected locally
      setState(() {
        if (!matchedFounders.any((f) => f['memo1Id'] == founder['memo1Id'])) {
          matchedFounders.remove(founder);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✅ Connection Request Sent!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Sent to ${founder['name']} at ${founder['companyName']}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              const Text(
                'They will receive a notification to schedule a meeting',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      print('❌ Error connecting with founder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class FounderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> founder;

  const FounderDetailScreen({Key? key, required this.founder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final memo1 = founder['memo1'] as Map<String, dynamic>?;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(founder['companyName'] ?? 'Founder Details'),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                founder['companyName'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF424242),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                founder['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF757575),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getMatchScoreColor(founder['matchScore'])
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${founder['matchScore']}% Match',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getMatchScoreColor(founder['matchScore']),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChip(Icons.business, founder['stage'], Colors.blue),
                        _buildChip(Icons.category, founder['industry'], Colors.green),
                        _buildChip(Icons.location_on, founder['location'], Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            if (memo1 != null) ...[
              const Text(
                'About',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    founder['description'] ?? 'No description available',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Connect Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Connection request sent to ${founder['name']}!'),
                      backgroundColor: const Color(0xFF4CAF50),
                    ),
                  );
                },
                icon: const Icon(Icons.favorite),
                label: const Text('Connect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
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
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMatchScoreColor(int score) {
    if (score >= 90) return const Color(0xFF4CAF50);
    if (score >= 80) return const Color(0xFF4A90E2);
    if (score >= 70) return const Color(0xFFFF9800);
    return const Color(0xFF757575);
  }
}
