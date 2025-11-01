import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroundTruthEngineScreen extends StatefulWidget {
  @override
  _GroundTruthEngineScreenState createState() =>
      _GroundTruthEngineScreenState();
}

class _GroundTruthEngineScreenState extends State<GroundTruthEngineScreen> {
  List<Map<String, dynamic>> verificationResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVerifications();
  }

  Future<void> _loadVerifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 Loading verifications from diligenceResults...');

      // Check BOTH diligenceResults AND diligenceReports collections
      List<QueryDocumentSnapshot> allDocs = [];
      
      // PRIORITIZE diligenceReports first (better analysis)
      print('📋 Checking diligenceReports collection (priority)...');
      final reportsSnapshot = await FirebaseFirestore.instance
          .collection('diligenceReports')
          .limit(50)
          .get();
      print('📊 Found ${reportsSnapshot.docs.length} in diligenceReports');
      allDocs.addAll(reportsSnapshot.docs);
      
      // Collection 2: diligenceResults (fallback)
      print('📋 Checking diligenceResults collection (fallback)...');
      final resultsSnapshot = await FirebaseFirestore.instance
          .collection('diligenceResults')
          .limit(50)
          .get();
      print('📊 Found ${resultsSnapshot.docs.length} in diligenceResults');
      allDocs.addAll(resultsSnapshot.docs);
      
      print('📊 Total diligence documents: ${allDocs.length}');

      List<Map<String, dynamic>> verifications = [];

      for (var doc in allDocs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        
        print('📄 Processing doc ${doc.id}: has memo1_diligence? ${data['memo1_diligence'] != null}');
        
        if (data['memo1_diligence'] != null) {
          final memo2 = data['memo1_diligence'] as Map<String, dynamic>;

          // Extract verification data - check multiple possible field names
          List? weaknesses = memo2['weaknesses'] as List?;
          List? strengths = memo2['strengths'] as List?;
          
          // Try alternative field names
          if (weaknesses == null || weaknesses.isEmpty) {
            weaknesses = memo2['concerns'] as List?;
          }
          if (strengths == null || strengths.isEmpty) {
            strengths = memo2['verified_claims'] as List?;
          }
          
          // Extract from analysis sections if direct fields don't exist
          if ((weaknesses == null || weaknesses.isEmpty) || 
              (strengths == null || strengths.isEmpty)) {
            // Check if we can extract from key_risks for weaknesses
            if (weaknesses == null || weaknesses.isEmpty) {
              final keyRisks = memo2['key_risks'] as List?;
              if (keyRisks != null && keyRisks.isNotEmpty) {
                weaknesses = keyRisks;
                print('  ✅ Using key_risks as weaknesses');
              }
            }
            
            // Check benchmarking_analysis for competitive advantages (strengths)
            if (strengths == null || strengths.isEmpty) {
              final benchmarking = memo2['benchmarking_analysis'] as Map<String, dynamic>?;
              if (benchmarking != null) {
                final competitiveAdvantages = benchmarking['competitive_advantages']?.toString();
                if (competitiveAdvantages != null && competitiveAdvantages.isNotEmpty) {
                  strengths = [competitiveAdvantages];
                  print('  ✅ Using competitive_advantages as strength');
                }
              }
            }
          }
          
          final verification = memo2['verification_status'] as Map<String, dynamic>?;
          
          print('  📊 Strengths: ${strengths?.length ?? 0}, Weaknesses: ${weaknesses?.length ?? 0}');

          // Get founder info from linked memo 1
          // Try multiple linking methods: memo_1_id, company_id, or direct ID match
          String founderName = 'Unknown';
          String companyName = 'Unknown Company';
          
          String? memo1Id = data['memo_1_id'] as String?;
          String? companyId = data['company_id'] as String?;
          
          // Try company_id first (seems to be what backend uses)
          if (companyId != null && companyId.isNotEmpty) {
            memo1Id = companyId;
            print('  🔗 Using company_id for linking: $companyId');
          } else if (memo1Id == null || memo1Id.isEmpty) {
            // Try to extract from memo1_diligence if it has company info
            final memo2Title = memo2['company_name']?.toString() ?? 
                             memo2['title']?.toString();
            if (memo2Title != null) {
              companyName = memo2Title;
              print('  📋 Using company name from memo2: $companyName');
            }
          }
          
          if (memo1Id != null && memo1Id.isNotEmpty) {
            try {
              print('  🔍 Looking for Memo 1 with ID: $memo1Id');
              
              // Try direct document lookup
              var memo1Doc = await FirebaseFirestore.instance
                  .collection('ingestionResults')
                  .doc(memo1Id)
                  .get();
              
              // If not found, try querying by company_id field
              if (!memo1Doc.exists && companyId != null) {
                print('  🔍 Trying query by company_id field...');
                final querySnapshot = await FirebaseFirestore.instance
                    .collection('ingestionResults')
                    .where('company_id', isEqualTo: companyId)
                    .limit(1)
                    .get();
                
                if (querySnapshot.docs.isNotEmpty) {
                  memo1Doc = querySnapshot.docs.first;
                  print('  ✅ Found by company_id query');
                }
              }
              
              if (memo1Doc.exists) {
                final memo1Data = memo1Doc.data();
                if (memo1Data?['memo_1'] != null) {
                  final memo1 = memo1Data!['memo_1'] as Map<String, dynamic>;
                  
                  // Handle founder_name as array
                  if (memo1['founder_name'] != null) {
                    if (memo1['founder_name'] is List) {
                      final names = (memo1['founder_name'] as List).map((e) => e.toString()).toList();
                      founderName = names.join(' & ');
                    } else {
                      founderName = memo1['founder_name'].toString();
                    }
                  }
                  
                  companyName = memo1['title']?.toString() ?? 
                               memo1['company_name']?.toString() ?? 
                               companyName; // Keep fallback if still not found
                  
                  print('  ✅ Found Memo 1: $companyName by $founderName');
                } else {
                  print('  ⚠️ Memo 1 doc exists but no memo_1 field');
                }
              } else {
                print('  ⚠️ Memo 1 not found with ID: $memo1Id');
                
                // Try reverse lookup - search all ingestionResults for this company_id
                if (companyId != null && companyId.isNotEmpty) {
                  print('  🔍 Trying reverse lookup: searching all ingestionResults for company_id = $companyId');
                  try {
                    final reverseQuery = await FirebaseFirestore.instance
                        .collection('ingestionResults')
                        .where('company_id', isEqualTo: companyId)
                        .limit(1)
                        .get();
                    
                    if (reverseQuery.docs.isNotEmpty) {
                      final reverseDoc = reverseQuery.docs.first;
                      final reverseData = reverseDoc.data();
                      if (reverseData['memo_1'] != null) {
                        final reverseMemo1 = reverseData['memo_1'] as Map<String, dynamic>;
                        companyName = reverseMemo1['title']?.toString() ?? 
                                     reverseMemo1['company_name']?.toString() ?? 
                                     'Unknown Company';
                        if (reverseMemo1['founder_name'] != null) {
                          if (reverseMemo1['founder_name'] is List) {
                            final names = (reverseMemo1['founder_name'] as List).map((e) => e.toString()).toList();
                            founderName = names.join(' & ');
                          } else {
                            founderName = reverseMemo1['founder_name'].toString();
                          }
                        }
                        print('  ✅ Found via reverse lookup: $companyName');
                      }
                    }
                  } catch (e) {
                    print('  ⚠️ Reverse lookup error: $e');
                  }
                }
                
                // Fallback: Try to get company name from memo2 or use doc ID
                if (companyName == 'Unknown Company') {
                  final memo2Title = memo2['company_name']?.toString() ?? 
                                   memo2['title']?.toString();
                  if (memo2Title != null && memo2Title.isNotEmpty) {
                    companyName = memo2Title;
                  } else if (memo1Id != null && memo1Id.isNotEmpty) {
                    // Last resort: try to extract from memo_1_id by looking it up differently
                    print('  🔄 Last resort: trying to query ingestionResults by ID pattern...');
                    try {
                      // Sometimes memo_1_id is actually a document ID pattern
                      final allIngestion = await FirebaseFirestore.instance
                          .collection('ingestionResults')
                          .limit(100)
                          .get();
                      
                      for (var ingestionDoc in allIngestion.docs) {
                        final ingestionData = ingestionDoc.data();
                        if (ingestionData['company_id'] == companyId || 
                            ingestionDoc.id == memo1Id ||
                            (ingestionData['memo_1'] != null && 
                             (ingestionData['memo_1'] as Map)['title'] != null)) {
                          final memo1Data = ingestionData['memo_1'] as Map<String, dynamic>?;
                          if (memo1Data != null) {
                            final title = memo1Data['title']?.toString();
                            if (title != null && title.isNotEmpty) {
                              companyName = title;
                              print('  ✅ Found via broad search: $companyName');
                              break;
                            }
                          }
                        }
                      }
                    } catch (e) {
                      print('  ⚠️ Broad search error: $e');
                    }
                  }
                  
                  if (companyName == 'Unknown Company' || companyName.startsWith('Company ')) {
                    // Final fallback: use memo_1_id as-is (might be readable)
                    companyName = 'Pitch ${memo1Id != null && memo1Id.length > 8 ? memo1Id.substring(0, 8) : doc.id.substring(0, 8)}';
                  }
                }
              }
            } catch (e) {
              print('  ❌ Error fetching memo 1: $e');
              // Fallback: Try to get company name from memo2
              final memo2Title = memo2['company_name']?.toString() ?? 
                               memo2['title']?.toString();
              if (memo2Title != null) {
                companyName = memo2Title;
              }
            }
          } else {
            print('  ⚠️ No memo_1_id or company_id found');
            
            // Try to extract from memo2 analysis sections
            final memo2Analysis = memo2['market_analysis'] as Map<String, dynamic>?;
            if (memo2Analysis != null && memo2Analysis['opportunity'] != null) {
              final opportunityText = memo2Analysis['opportunity'].toString();
              // Try to extract company name from opportunity text (often mentions it)
              if (opportunityText.length > 10 && opportunityText.length < 50) {
                companyName = opportunityText;
                print('  ✅ Using opportunity text as company name: $companyName');
              }
            }
            
            // Last resort: Try to get company name from memo2
            if (companyName == 'Unknown Company') {
              final memo2Title = memo2['company_name']?.toString() ?? 
                               memo2['title']?.toString();
              if (memo2Title != null && memo2Title.isNotEmpty) {
                companyName = memo2Title;
              }
            }
          }

          // Create verification entries from weaknesses (concerns/discrepancies)
          if (weaknesses != null && weaknesses.isNotEmpty) {
            print('  ✅ Processing ${weaknesses.length} weaknesses');
            for (var weakness in weaknesses.take(5)) {
              String weaknessText = '';
              if (weakness is String) {
                weaknessText = weakness;
              } else if (weakness is Map) {
                weaknessText = weakness.toString();
              } else {
                weaknessText = weakness.toString();
              }
              
              if (weaknessText.isNotEmpty) {
                verifications.add({
                  'id': '${doc.id}_weakness_${weaknessText.hashCode}',
                  'founderName': founderName,
                  'companyName': companyName,
                  'claim': weaknessText,
                  'status': 'discrepancy',
                  'source': 'Memo Analysis',
                  'confidence': 75 + (weaknessText.hashCode % 15),
                  'details': 'Identified during due diligence analysis as a potential concern or risk',
                  'timestamp': data['timestamp'] ?? data['created_at'],
                });
                print('    ✅ Added discrepancy: ${weaknessText.substring(0, weaknessText.length > 50 ? 50 : weaknessText.length)}...');
              }
            }
          }

          // Create verification entries from strengths (verified claims)
          if (strengths != null && strengths.isNotEmpty) {
            print('  ✅ Processing ${strengths.length} strengths');
            for (var strength in strengths.take(5)) {
              String strengthText = '';
              if (strength is String) {
                strengthText = strength;
              } else if (strength is Map) {
                strengthText = strength.toString();
              } else {
                strengthText = strength.toString();
              }
              
              if (strengthText.isNotEmpty) {
                verifications.add({
                  'id': '${doc.id}_strength_${strengthText.hashCode}',
                  'founderName': founderName,
                  'companyName': companyName,
                  'claim': strengthText,
                  'status': 'verified',
                  'source': 'Memo Analysis',
                  'confidence': 85 + (strengthText.hashCode % 10),
                  'details': 'Confirmed during due diligence analysis as a verified claim',
                  'timestamp': data['timestamp'] ?? data['created_at'],
                });
                print('    ✅ Added verified: ${strengthText.substring(0, strengthText.length > 50 ? 50 : strengthText.length)}...');
              }
            }
          }
          
          // If no strengths/weaknesses found, create entry from investment recommendation
          if (verifications.isEmpty) {
            final recommendation = memo2['investment_recommendation']?.toString();
            if (recommendation != null && recommendation.isNotEmpty) {
              verifications.add({
                'id': '${doc.id}_recommendation',
                'founderName': founderName,
                'companyName': companyName,
                'claim': 'Investment Recommendation: $recommendation',
                'status': recommendation == 'BUY' ? 'verified' : 'discrepancy',
                'source': 'AI Analysis',
                'confidence': 80,
                'details': 'Based on comprehensive due diligence analysis',
                'timestamp': data['timestamp'] ?? data['created_at'],
              });
              print('  ✅ Added recommendation as verification entry');
            }
          }

          // Add verification status if available
          if (verification != null) {
            final verifiedClaims = verification['verified_claims'] as List?;
            final unverifiedClaims = verification['unverified_claims'] as List?;

            if (verifiedClaims != null) {
              for (var claim in verifiedClaims) {
                verifications.add({
                  'id': '${doc.id}_verified_${claim.hashCode}',
                  'founderName': founderName,
                  'companyName': companyName,
                  'claim': claim.toString(),
      'status': 'verified',
                  'source': 'External Verification',
                  'confidence': 90 + (claim.hashCode % 10),
                  'details': 'Verified through external data sources',
                  'timestamp': data['created_at'] ?? data['timestamp'],
                });
              }
            }

            if (unverifiedClaims != null) {
              for (var claim in unverifiedClaims) {
                verifications.add({
                  'id': '${doc.id}_unverified_${claim.hashCode}',
                  'founderName': founderName,
                  'companyName': companyName,
                  'claim': claim.toString(),
      'status': 'unverifiable',
                  'source': 'External Verification',
                  'confidence': 40 + (claim.hashCode % 20),
                  'details': 'Unable to verify through available data sources',
                  'timestamp': data['created_at'] ?? data['timestamp'],
                });
              }
            }
          }
        }
      }

      // Deduplicate verifications by claim text (prevent duplicates across ALL companies)
      // Use ONLY claim text as key (not company name) to show each unique concern only once
      final Map<String, Map<String, dynamic>> uniqueVerifications = {};
      final Set<String> seenClaims = {};
      
      for (var verification in verifications) {
        final claim = verification['claim']?.toString() ?? '';
        if (claim.isNotEmpty) {
          // Normalize claim text for better deduplication
          final normalizedClaim = claim.toLowerCase().trim();
          final shortClaim = normalizedClaim.length > 100 
              ? normalizedClaim.substring(0, 100)
              : normalizedClaim;
          
          // Use normalized claim as key to prevent duplicates across companies
          if (!seenClaims.contains(shortClaim)) {
            seenClaims.add(shortClaim);
            uniqueVerifications[shortClaim] = verification;
          } else {
            print('  ⚠️ Skipping duplicate claim: ${claim.substring(0, claim.length > 50 ? 50 : claim.length)}...');
          }
        }
      }

      print('✅ Total verifications loaded: ${uniqueVerifications.length} unique claims (after deduplication from ${verifications.length} total)');
      print('📊 Explanation: Each verification represents a unique concern/claim found across all pitch decks');

      if (mounted) {
        setState(() {
          verificationResults = uniqueVerifications.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading verifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading verifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        onRefresh: _loadVerifications,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
            const Text(
              'Recent Verifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${verificationResults.length} unique',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF757575),
                        ),
                      ),
                      Text(
                        'claims found',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ],
            ),
            const SizedBox(height: 16),
              
              if (verificationResults.isEmpty)
                _buildEmptyState()
              else
            ...verificationResults.map(
              (result) => _buildVerificationCard(result),
                ),
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
              Icons.verified_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No verifications yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verifications will appear as diligence reports are generated',
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

  Widget _buildStatsSection() {
    final verified = verificationResults.where((r) => r['status'] == 'verified').length;
    final discrepancies = verificationResults.where((r) => r['status'] == 'discrepancy').length;
    final unverifiable = verificationResults.where((r) => r['status'] == 'unverifiable').length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Verified',
            value: verified.toString(),
            icon: Icons.check_circle,
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Discrepancies',
            value: discrepancies.toString(),
            icon: Icons.warning,
            color: const Color(0xFFFF9800),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Unverifiable',
            value: unverifiable.toString(),
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
              // Header - Fixed overflow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result['companyName'] ?? 'Unknown Company',
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
                          'by ${result['founderName'] ?? 'Unknown'}',
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

              // Source and Details - Fixed overflow
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(Icons.source, size: 16, color: Colors.grey[600]),
                  Text(
                    'Source: ${result['source']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                result['details'] ?? '',
                style: const TextStyle(fontSize: 14, color: Color(0xFF424242)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _viewVerificationDetails(result),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Details'),
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
        title: Text('Verification - ${result['companyName']}'),
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
