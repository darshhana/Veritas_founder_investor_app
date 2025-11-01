import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/api_service.dart';
import '../../models/memo2_model.dart';

class AIDiligenceEngineScreen extends StatefulWidget {
  @override
  _AIDiligenceEngineScreenState createState() =>
      _AIDiligenceEngineScreenState();
}

class _AIDiligenceEngineScreenState extends State<AIDiligenceEngineScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> _opportunities = [];
  bool _isLoading = true;
  String? _selectedCompanyId;
  bool _isRunningDiligence = false;
  StreamSubscription<QuerySnapshot>? _diligenceListener;

  @override
  void initState() {
    super.initState();
    _loadOpportunities();
  }

  Future<void> _loadOpportunities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 Loading opportunities...');
      
      // DIAGNOSTIC: Check what collections exist
      print('\n📋 DIAGNOSTIC: Checking Firestore collections...');
      try {
        final allIngestion = await FirebaseFirestore.instance
            .collection('ingestionResults')
            .limit(5)
            .get();
        print('  ✅ ingestionResults collection exists: ${allIngestion.docs.length} docs (showing first 5)');
        
        // Inspect first doc structure
        if (allIngestion.docs.isNotEmpty) {
          final firstDoc = allIngestion.docs.first;
          final firstData = firstDoc.data();
          print('  📄 First doc ID: ${firstDoc.id}');
          print('  📄 First doc keys: ${firstData.keys.toList()}');
          print('  📄 Has memo_1? ${firstData.containsKey('memo_1')}');
          if (firstData.containsKey('memo_1')) {
            final memo1 = firstData['memo_1'];
            if (memo1 is Map) {
              print('  📄 memo_1 keys: ${memo1.keys.toList()}');
            }
          }
        }
        
        final allDiligence = await FirebaseFirestore.instance
            .collection('diligenceResults')
            .limit(5)
            .get();
        print('  ✅ diligenceResults collection exists: ${allDiligence.docs.length} docs');
        
        final allUploads = await FirebaseFirestore.instance
            .collection('uploads')
            .limit(5)
            .get();
        print('  ✅ uploads collection exists: ${allUploads.docs.length} docs');
        
        print('\n📊 DIAGNOSTIC COMPLETE\n');
      } catch (e) {
        print('  ⚠️ Diagnostic error: $e');
      }
      
      List<Map<String, dynamic>> opportunities = [];
      
      // Method 1: Try ingestionResults collection
      // NOTE: Diagnostic query works without orderBy, so use that approach!
      try {
        print('  📂 Trying ingestionResults collection...');
        QuerySnapshot snapshot;
        
        // Use same approach as diagnostic (no orderBy) - this works!
        print('  📋 Using same query method as diagnostic (no orderBy)...');
        snapshot = await FirebaseFirestore.instance
            .collection('ingestionResults')
            .limit(50)
            .get();
        
        print('  ✅ Query succeeded: Found ${snapshot.docs.length} documents');
        
        // Sort in memory by timestamp if available
        final docsList = snapshot.docs.toList();
        docsList.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>?;
          final bData = b.data() as Map<String, dynamic>?;
          
          DateTime? aTime;
          DateTime? bTime;
          
          if (aData != null) {
            if (aData['timestamp'] != null) {
              try {
                if (aData['timestamp'] is String) {
                  aTime = DateTime.tryParse(aData['timestamp']);
                }
              } catch (e) {}
            }
          }
          
          if (bData != null) {
            if (bData['timestamp'] != null) {
              try {
                if (bData['timestamp'] is String) {
                  bTime = DateTime.tryParse(bData['timestamp']);
                }
              } catch (e) {}
            }
          }
          
          if (aTime != null && bTime != null) {
            return bTime.compareTo(aTime); // Descending
          }
          return 0; // Keep original order if can't parse
        });
        
        print('  📊 Found ${docsList.length} ingestion results (sorted in memory)');
        
        // Process sorted documents
        for (var doc in docsList) {
          print('    🔍 Processing doc: ${doc.id}');
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            print('      ❌ Doc ${doc.id} has null data');
            continue;
          }
          
          print('      📄 Doc keys: ${data.keys.toList()}');
          print('      📄 Has memo_1? ${data.containsKey('memo_1')}');
          
          // Check if has memo_1 or try to extract from data directly
          Map<String, dynamic>? memo1;
          if (data['memo_1'] != null) {
            memo1 = data['memo_1'] as Map<String, dynamic>?;
            print('      ✅ Found memo_1, keys: ${memo1?.keys.toList() ?? 'null'}');
          } else if (data['title'] != null || data['founder_name'] != null) {
            // Data might be directly in the doc
            memo1 = data;
            print('      ✅ Using flat data structure');
          } else {
            print('      ⚠️ No memo_1 or title/founder_name found, skipping');
          }
          
          if (memo1 != null) {
            print('      ✅ Processing memo1 for doc ${doc.id}');
            // Try to get Memo 2 - try multiple linking methods
            Memo2Model? memo2;
            
            // Method 1: Try with document ID
            memo2 = await _firestoreService.getMemo2(doc.id);
            
            // Method 2: If not found, try with company_id from ingestionResults
            if (memo2 == null && data['company_id'] != null) {
              final companyId = data['company_id'].toString();
              print('  🔄 Trying to find Memo 2 with company_id: $companyId');
              
              try {
                // PRIORITIZE diligenceReports first (better analysis), then fallback to diligenceResults
                var diligenceQuery = await FirebaseFirestore.instance
                    .collection('diligenceReports')
                    .where('company_id', isEqualTo: companyId)
                    .limit(1)
                    .get();
                
                // If not found, try diligenceResults as fallback
                if (diligenceQuery.docs.isEmpty) {
                  print('  🔄 Trying diligenceResults collection (fallback)...');
                  diligenceQuery = await FirebaseFirestore.instance
                      .collection('diligenceResults')
                      .where('company_id', isEqualTo: companyId)
                      .limit(1)
                      .get();
                }
                
                if (diligenceQuery.docs.isNotEmpty) {
                  final diligenceData = diligenceQuery.docs.first.data() as Map<String, dynamic>?;
                  if (diligenceData?['memo1_diligence'] != null) {
                    memo2 = Memo2Model.fromMap(diligenceData!['memo1_diligence'] as Map<String, dynamic>);
                    print('  ✅ Found Memo 2 via company_id!');
                  }
                }
              } catch (e) {
                print('  ⚠️ Error querying by company_id: $e');
              }
            }
            
            // Extract data safely - handle arrays and strings
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
                               (data['original_filename']?.toString().split('/').last.split('.').first) ??
                               'Unknown Company';
            final stage = memo1['company_stage']?.toString() ?? 
                         memo1['stage']?.toString() ?? 
                         'Not Specified';
            
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
            
            final summary = memo1['summary_analysis']?.toString() ?? 
                           memo1['executive_summary']?.toString() ??
                           memo1['problem']?.toString() ??
                           'No summary available';
            
            // Parse timestamp - handle both Timestamp object and string format
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
                  // Handle ISO string format: "2025-11-01T06:54:39.163794"
                  createdAt = DateTime.tryParse(data['timestamp']) ?? DateTime.now();
                }
              }
            } catch (e) {
              print('  ⚠️ Date parsing error: $e');
            }
            
            // Calculate score from memo2
            double? score;
            if (memo2 != null) {
              score = memo2.confidenceScore;
            }
            
            final opp = {
              'id': doc.id,
              'founderName': founderName,
              'companyName': companyName,
              'stage': stage,
              'industry': industry,
              'status': memo2 != null ? 'Completed' : 'Pending Diligence',
              'createdDate': createdAt,
              'summary': summary,
              'score': score,
              'recommendation': memo2?.investmentRecommendation,
              'hasMemo2': memo2 != null,
              'memo1': memo1,
              'memo2': memo2,
            };
            
            opportunities.add(opp);
            
            print('      ✅ SUCCESSFULLY ADDED: $companyName by $founderName (Stage: $stage, Industry: $industry)');
          } else {
            print('      ❌ SKIPPED: memo1 is null for doc ${doc.id}');
          }
        }
      } catch (e) {
        print('  ❌ Error querying ingestionResults: $e');
      }
      
      // Method 2: Also try uploads collection as fallback
      if (opportunities.isEmpty) {
        print('  📂 Trying uploads collection as fallback...');
        try {
          final uploadsSnapshot = await FirebaseFirestore.instance
              .collection('uploads')
              .where('status', isEqualTo: 'completed')
              .limit(50)
              .get();
          
          print('  📊 Found ${uploadsSnapshot.docs.length} completed uploads');
          
          for (var doc in uploadsSnapshot.docs) {
            final data = doc.data();
            final fileName = data['fileName']?.toString() ?? 'Unknown';
            
            // Try to find corresponding memo1
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
                  
                  opportunities.add({
                    'id': memoId,
                    'founderName': memo1['founder_name']?.toString() ?? 'Unknown',
                    'companyName': memo1['title']?.toString() ?? fileName.split('.').first,
                    'stage': memo1['company_stage']?.toString() ?? 'Not Specified',
                    'industry': memo1['industry_category']?.toString() ?? 'General',
                    'status': memo2 != null ? 'Completed' : 'Pending Diligence',
                    'createdDate': (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    'summary': memo1['summary_analysis']?.toString() ?? 'No summary',
                    'score': memo2?.confidenceScore,
                    'recommendation': memo2?.investmentRecommendation,
                    'hasMemo2': memo2 != null,
                    'memo1': memo1,
                    'memo2': memo2,
                  });
                  
                  print('  ✅ Added from uploads: ${memo1['title']}');
                }
              }
            }
          }
        } catch (e) {
          print('  ❌ Error querying uploads: $e');
        }
      }

      print('\n✅ FINAL RESULT: Total opportunities loaded: ${opportunities.length}');
      if (opportunities.isEmpty) {
        print('⚠️ WARNING: No opportunities found! Check diagnostics above.');
      } else {
        print('📋 Opportunities list:');
        for (var i = 0; i < opportunities.length; i++) {
          print('  ${i + 1}. ${opportunities[i]['companyName']} by ${opportunities[i]['founderName']}');
        }
      }

      setState(() {
        _opportunities = opportunities;
        _isLoading = false;
      });
      
      print('✅ UI STATE UPDATED: _opportunities.length = ${_opportunities.length}');
    } catch (e) {
      print('❌ Error loading opportunities: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _runDiligenceAnalysis(String memoId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to run diligence'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isRunningDiligence = true;
      _selectedCompanyId = memoId;
    });

    try {
      print('🚀 Starting diligence analysis for memo: $memoId');
      
      // Use triggerDiligence API
      final response = await _apiService.triggerDiligence(
        memo1Id: memoId,
      );

      print('📥 Diligence API response: $response');

      if (response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Diligence analysis started! This may take 2-5 minutes...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
        
        // Set up real-time listener to watch for Memo 2 completion
        print('👂 Setting up real-time listener for Memo 2...');
        _watchForMemo2(memoId);
        
        // Show detailed message about waiting
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🚀 Diligence Analysis Started!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Analyzing: ${memoId.substring(0, memoId.length > 20 ? 20 : memoId.length)}...',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '⏳ Estimated time: 2-5 minutes\n📱 App will auto-refresh when complete',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: 'Refresh Now',
                textColor: Colors.white,
                onPressed: () {
                  _loadOpportunities();
                },
              ),
            ),
          );
        }
      } else {
        throw Exception(response['error'] ?? 'Analysis failed');
      }
    } catch (e) {
      print('❌ Diligence error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isRunningDiligence = false;
        _selectedCompanyId = null;
      });
    }
  }

  void _watchForMemo2(String memo1Id) {
    // Cancel any existing listener
    _diligenceListener?.cancel();
    
    print('👂 Watching for Memo 2 with memo_1_id: $memo1Id');
    
    // Listen for new diligence results - PRIORITIZE diligenceReports first (better analysis)
    _diligenceListener = FirebaseFirestore.instance
        .collection('diligenceReports')
        .where('memo_1_id', isEqualTo: memo1Id)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.docs.isEmpty) {
          // If not found in diligenceReports, try diligenceResults as fallback
          print('⚠️ Memo 2 not found in diligenceReports, trying diligenceResults...');
          FirebaseFirestore.instance
              .collection('diligenceResults')
              .where('memo_1_id', isEqualTo: memo1Id)
              .snapshots()
              .listen(
            (resultsSnapshot) {
              _handleMemo2Found(resultsSnapshot, memo1Id);
            },
            onError: (error) {
              print('❌ Memo 2 listener error (diligenceResults): $error');
            },
          );
        } else {
          _handleMemo2Found(snapshot, memo1Id);
        }
      },
      onError: (error) {
        print('❌ Memo 2 listener error (diligenceReports): $error');
      },
    );
  }

  void _handleMemo2Found(QuerySnapshot snapshot, String memo1Id) {
    print('📥 Memo 2 listener triggered: ${snapshot.docs.length} docs');
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>?;
      print('✅ Memo 2 found! Doc ID: ${doc.id}');
      print('📄 Memo 2 keys: ${data?.keys.toList() ?? []}');
      
      // Wait a bit for data to be fully written
      Future.delayed(const Duration(seconds: 1), () {
        print('🔄 Refreshing opportunities list...');
        _loadOpportunities();
        
        // Show success message with details
        if (mounted) {
          final recommendation = data?['memo1_diligence']?['investment_recommendation']?.toString() ?? 
                                 data?['investment_recommendation']?.toString() ?? 
                                 'Complete';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✅ Diligence Analysis Complete!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recommendation: $recommendation',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap on the pitch card to view full analysis',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        
        // Cancel listener after success
        _diligenceListener?.cancel();
        _diligenceListener = null;
      });
    } else {
      print('⏳ Memo 2 not ready yet... waiting...');
    }
    
    // Auto-cancel after 10 minutes (diligence should complete by then)
    Future.delayed(const Duration(minutes: 10), () {
      _diligenceListener?.cancel();
      _diligenceListener = null;
      print('⏰ Memo 2 listener cancelled after 10 minutes');
    });
  }

  @override
  void dispose() {
    _diligenceListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOpportunities,
              child: SingleChildScrollView(
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
                    // DEBUG: Show count
                    Text(
                      'DEBUG: ${_opportunities.length} opportunities in state',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats Cards
                    _buildStatsSection(),

                    const SizedBox(height: 24),

                    // Opportunities List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Investment Opportunities',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424242),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadOpportunities,
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_opportunities.isEmpty)
                      _buildEmptyState()
                    else
                      ..._opportunities.map((opp) => _buildOpportunityCard(opp)),
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
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No investment opportunities yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new pitch decks to analyze',
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

  Widget _buildOpportunityCard(Map<String, dynamic> opportunity) {
    final hasMemo2 = opportunity['hasMemo2'] == true;
    final score = opportunity['score'];
    final companyName = opportunity['companyName'] ?? 'Unknown Company';
    final founderName = opportunity['founderName'] ?? 'Unknown Founder';
    final summary = opportunity['summary'] ?? 'No description available';
    final status = opportunity['status'] ?? 'Pending';
    final memoId = opportunity['id'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                        companyName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by $founderName',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                if (score != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getScoreColor(score).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: _getScoreColor(score),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(score * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(score),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              summary,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF616161),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
                if (!hasMemo2)
                  ElevatedButton.icon(
                    onPressed: _isRunningDiligence && _selectedCompanyId == memoId
                        ? null
                        : () => _runDiligenceAnalysis(memoId),
                    icon: _isRunningDiligence && _selectedCompanyId == memoId
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.play_arrow, size: 16),
                    label: Text(_isRunningDiligence && _selectedCompanyId == memoId
                        ? 'Running...'
                        : 'Run Diligence'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () => _viewMemoDetails(opportunity),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Analysis'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4A90E2),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.7) return Colors.green;
    if (score >= 0.5) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStatsSection() {
    final completed = _opportunities.where((o) => o['hasMemo2'] == true).length;
    final avgScore = _opportunities
        .where((o) => o['score'] != null)
        .fold<double>(0, (sum, o) => sum + (o['score'] as double)) /
        (completed > 0 ? completed : 1);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Pitches',
            value: '${_opportunities.length}',
            icon: Icons.analytics,
            color: const Color(0xFF4A90E2),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Analyzed',
            value: '$completed',
            icon: Icons.check_circle,
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Avg. Score',
            value: completed > 0 ? avgScore.toStringAsFixed(1) : 'N/A',
            icon: Icons.star,
            color: const Color(0xFFFF9800),
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

  void _viewMemoDetails(Map<String, dynamic> opportunity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoDetailScreen(
          opportunity: opportunity,
        ),
      ),
    );
  }
}

class MemoDetailScreen extends StatelessWidget {
  final Map<String, dynamic> opportunity;

  const MemoDetailScreen({Key? key, required this.opportunity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final memo1 = opportunity['memo1'] as Map<String, dynamic>?;
    final memo2 = opportunity['memo2'];
    final hasMemo2 = opportunity['hasMemo2'] == true;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(opportunity['companyName'] ?? 'Company Details'),
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
                    Text(
                      opportunity['companyName'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Founder: ${opportunity['founderName'] ?? 'Unknown'}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.business,
                          opportunity['stage'] ?? 'Unknown',
                          Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        
                          Flexible(
                            child: _buildInfoChip(
                              Icons.category,
                              opportunity['industry'] ?? 'Unknown',
                              Colors.green,
                              maxLines: 1,
                            ),
                          ),
                      ],
                    ),
                    if (opportunity['score'] != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getScoreColor(opportunity['score'])
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: _getScoreColor(opportunity['score']),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Confidence Score: ${(opportunity['score'] * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(opportunity['score']),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Memo 1 Section
            if (memo1 != null) ...[
              _buildSectionHeader('Initial Analysis (Memo 1)'),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (memo1['summary_analysis'] != null) ...[
                        const Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          memo1['summary_analysis'].toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (memo1['problem'] != null) ...[
                        const Text(
                          'Problem',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          memo1['problem'].toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (memo1['solution'] != null) ...[
                        const Text(
                          'Solution',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          memo1['solution'].toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Memo 2 Section
            if (hasMemo2 && memo2 != null) ...[
              _buildSectionHeader('Due Diligence Results (Memo 2)'),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (memo2.investmentRecommendation != null) ...[
                        const Text(
                          'Investment Recommendation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            memo2.investmentRecommendation!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Show Investment Thesis
                      if (memo2.investmentThesis.isNotEmpty) ...[
                        const Text(
                          'Investment Thesis',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            memo2.investmentThesis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Show Key Risks (from keyRisks field)
                      if (memo2.keyRisks.isNotEmpty) ...[
                        const Text(
                          'Key Risks & Concerns',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...memo2.keyRisks.map((risk) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  risk,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 16),
                      ],
                      
                      // Show Analysis Sections
                      if (memo2.founderAnalysis != null) ...[
                        _buildAnalysisSection('Founder Analysis', memo2.founderAnalysis),
                        const SizedBox(height: 12),
                      ],
                      if (memo2.problemValidation != null) ...[
                        _buildAnalysisSection('Problem Validation', memo2.problemValidation),
                        const SizedBox(height: 12),
                      ],
                      if (memo2.solutionAnalysis != null) ...[
                        _buildAnalysisSection('Solution Analysis', memo2.solutionAnalysis),
                        const SizedBox(height: 12),
                      ],
                      if (memo2.marketAnalysis != null) ...[
                        _buildAnalysisSection('Market Analysis', memo2.marketAnalysis),
                      ],
                    ],
                  ),
                ),
              ),
            ] else ...[
              _buildSectionHeader('Due Diligence'),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Diligence analysis not yet run',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF424242),
      ),
    );
  }

  Widget _buildAnalysisSection(String title, AnalysisSection section) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(section.score >= 1.0 ? section.score / 10.0 : section.score).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    section.score >= 1.0 
                        ? '${section.score.toInt()}%' 
                        : '${(section.score * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(section.score >= 1.0 ? section.score / 10.0 : section.score),
                    ),
                  ),
                ),
              ],
            ),
            if (section.background != null && section.background!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                section.background!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (section.marketFit != null && section.marketFit!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Market Fit: ${section.marketFit}',
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color, {int? maxLines}) {
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
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              maxLines: maxLines,
              overflow: maxLines != null ? TextOverflow.ellipsis : null,
            ),
          ),
        ],
      ),
    );
  }

  static Color _getScoreColor(double score) {
    if (score >= 0.7) return Colors.green;
    if (score >= 0.5) return Colors.orange;
    return Colors.red;
  }
}
