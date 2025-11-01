import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/upload_model.dart';
import '../models/memo1_model.dart';
import '../models/memo2_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============ UPLOADS COLLECTION ============

  /// Get all uploads for a founder
  Stream<List<UploadModel>> getUploadsStream(String founderEmail) {
    print('🔥 FIRESTORE: Starting uploads stream for: $founderEmail');
    return _db
        .collection('uploads')
        .where('founderEmail', isEqualTo: founderEmail)
        // Removed orderBy to avoid composite index requirement
        // Will sort in memory instead
        .snapshots()
        .map((snapshot) {
          print('🔥 FIRESTORE: Snapshot received with ${snapshot.docs.length} documents');
          if (snapshot.docs.isEmpty) {
            print('⚠️  FIRESTORE: No documents found in uploads collection for $founderEmail');
          }
          
          final uploads = snapshot.docs.map((doc) {
            print('  📄 Doc ID: ${doc.id}');
            print('  📄 Doc Data: ${doc.data()}');
            return UploadModel.fromMap(doc.id, doc.data());
          }).toList();
          
          // Sort in memory by uploadedAt descending
          uploads.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
          
          print('🔥 FIRESTORE: Returning ${uploads.length} upload models (sorted in memory)');
          return uploads;
        });
  }

  /// Get single upload by ID
  Stream<UploadModel?> getUploadStream(String uploadId) {
    return _db.collection('uploads').doc(uploadId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UploadModel.fromMap(doc.id, doc.data()!);
    });
  }

  /// Get upload by ID (one-time)
  Future<UploadModel?> getUpload(String uploadId) async {
    try {
      final doc = await _db.collection('uploads').doc(uploadId).get();
      if (!doc.exists) return null;
      return UploadModel.fromMap(doc.id, doc.data()!);
    } catch (e) {
      print('Error getting upload: $e');
      return null;
    }
  }

  /// Update upload status
  Future<void> updateUploadStatus(String uploadId, String status) async {
    try {
      await _db.collection('uploads').doc(uploadId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating upload status: $e');
    }
  }

  /// Check if a memo exists for this upload
  Future<String?> checkMemoExists(String uploadId) async {
    try {
      // First, get the upload to know the file details
      final uploadDoc = await _db.collection('uploads').doc(uploadId).get();
      if (!uploadDoc.exists) {
        print('⚠️  Upload $uploadId not found');
        return null;
      }
      
      final uploadData = uploadDoc.data()!;
      final fileName = uploadData['fileName'] as String?;
      final originalName = uploadData['originalName'] as String?;
      final founderEmail = uploadData['founderEmail'] as String?;
      
      // Use originalName if available, fallback to fileName
      final searchFileName = originalName ?? fileName ?? '';
      
      print('🔍 Searching memo for upload: $uploadId');
      print('  📄 fileName: $fileName');
      print('  📄 originalName: $originalName');
      print('  📄 searchFileName: $searchFileName');
      print('  📄 founderEmail: $founderEmail');
      
      // Try method 1: Direct ID match
      final doc = await _db.collection('ingestionResults').doc(uploadId).get();
      if (doc.exists) {
        print('✅ Found memo with direct ID match: $uploadId');
        return uploadId;
      }
      
      // Try method 2: Query by upload_id field
      var querySnapshot = await _db
          .collection('ingestionResults')
          .where('upload_id', isEqualTo: uploadId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        print('✅ Found memo by upload_id field: ${querySnapshot.docs.first.id}');
        return querySnapshot.docs.first.id;
      }
      
      // Try method 3: Query by file names (try both originalName and fileName)
      if (searchFileName.isNotEmpty) {
        // Try original_filename (backend format)
        querySnapshot = await _db
            .collection('ingestionResults')
            .where('original_filename', isEqualTo: searchFileName)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          print('✅ Found memo by original_filename query: ${querySnapshot.docs.first.id}');
          return querySnapshot.docs.first.id;
        }
        
        // Try file_name
        querySnapshot = await _db
            .collection('ingestionResults')
            .where('file_name', isEqualTo: searchFileName)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          print('✅ Found memo by file_name query: ${querySnapshot.docs.first.id}');
          return querySnapshot.docs.first.id;
        }
        
        // Also try with fileName if different from originalName
        if (fileName != null && fileName != originalName) {
          querySnapshot = await _db
              .collection('ingestionResults')
              .where('original_filename', isEqualTo: fileName)
              .limit(1)
              .get();
          
          if (querySnapshot.docs.isNotEmpty) {
            print('✅ Found memo by fileName original_filename query: ${querySnapshot.docs.first.id}');
            return querySnapshot.docs.first.id;
          }
        }
      }
      
      // Try method 4: Query by founder email + file name (more reliable)
      if (founderEmail != null && searchFileName.isNotEmpty) {
        querySnapshot = await _db
            .collection('ingestionResults')
            .where('founder_email', isEqualTo: founderEmail)
            .limit(50)
            .get();
        
        print('🔍 Searching ${querySnapshot.docs.length} memos for founder: $founderEmail');
        
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          final memoFileName = data['original_filename']?.toString() ?? 
                              data['file_name']?.toString() ?? 
                              data['fileName']?.toString() ?? 
                              data['original_name']?.toString() ?? '';
          
          if (memoFileName == searchFileName || 
              memoFileName == originalName ||
              memoFileName == fileName ||
              data['upload_id']?.toString() == uploadId) {
            print('✅ Found memo by founder email + filename match: ${doc.id}');
            return doc.id;
          }
        }
      }
      
      // Try method 5: Get all ingestion results and match manually (broader search)
      print('🔍 Trying broader search in ingestionResults...');
      final allResults = await _db.collection('ingestionResults').limit(50).get();
      print('📊 Total ingestionResults checked: ${allResults.docs.length}');
      
      for (var result in allResults.docs) {
        final data = result.data();
        final memoFileName = data['original_filename']?.toString() ?? 
                            data['file_name']?.toString() ?? 
                            data['fileName']?.toString() ?? 
                            data['original_name']?.toString() ?? '';
        
        // Check multiple matching criteria
        if (memoFileName == searchFileName || 
            memoFileName == originalName ||
            memoFileName == fileName ||
            data['upload_id']?.toString() == uploadId) {
          print('✅ Found memo by broad search match: ${result.id}');
          print('  📄 Matched: memoFileName=$memoFileName, searchFileName=$searchFileName');
          return result.id;
        }
      }
      
      print('⏳ No memo found for upload $uploadId after all methods');
      return null;
    } catch (e) {
      print('❌ Error checking memo existence: $e');
      return null;
    }
  }

  // ============ INGESTION RESULTS (MEMO 1) ============

  /// Get Memo 1 by ID
  Future<Memo1Model?> getMemo1(String memoId) async {
    try {
      final doc = await _db.collection('ingestionResults').doc(memoId).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null || data['memo_1'] == null) return null;

      return Memo1Model.fromMap(data['memo_1']);
    } catch (e) {
      print('Error getting Memo 1: $e');
      return null;
    }
  }

  /// Stream Memo 1 by ID
  Stream<Memo1Model?> getMemo1Stream(String memoId) {
    return _db.collection('ingestionResults').doc(memoId).snapshots().map(
      (doc) {
        if (!doc.exists) return null;
        final data = doc.data();
        if (data == null || data['memo_1'] == null) return null;
        return Memo1Model.fromMap(data['memo_1']);
      },
    );
  }

  /// Get all Memo 1 results for a founder
  Stream<List<Map<String, dynamic>>> getMemo1ListStream(String founderEmail) {
    return _db
        .collection('ingestionResults')
        .where('founder_email', isEqualTo: founderEmail)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'memo_1': doc.data()['memo_1'],
                  'created_at': doc.data()['created_at'],
                })
            .toList());
  }

  // ============ DILIGENCE RESULTS (MEMO 2) ============

  /// Get Memo 2 by memo1 ID
  /// Tries multiple linking methods: memo_1_id, company_id
  /// Checks BOTH diligenceResults AND diligenceReports collections
  Future<Memo2Model?> getMemo2(String memo1Id) async {
    try {
      print('🔍 getMemo2: Searching for memo_1_id = $memo1Id');
      
      // Try both collections: PRIORITIZE diligenceReports first (better analysis)
      final collections = ['diligenceReports', 'diligenceResults'];
      
      QuerySnapshot? querySnapshot;
      DocumentSnapshot? directDoc;
      
      for (final collectionName in collections) {
        print('🔍 getMemo2: Checking $collectionName collection...');
        
        // Method 1: Try memo_1_id field
        var snapshot = await _db
            .collection(collectionName)
            .where('memo_1_id', isEqualTo: memo1Id)
            .limit(1)
            .get();

        print('🔍 getMemo2: $collectionName query by memo_1_id returned ${snapshot.docs.length} documents');
        
        if (snapshot.docs.isNotEmpty) {
          querySnapshot = snapshot;
          break;
        }
        
        // Method 2: If not found, try company_id field
        print('🔍 getMemo2: Trying company_id field in $collectionName...');
        
        // First, get the company_id from memo1
        final memo1Doc = await _db.collection('ingestionResults').doc(memo1Id).get();
        if (memo1Doc.exists) {
          final memo1Data = memo1Doc.data();
          final companyId = memo1Data?['company_id'] as String?;
          
          if (companyId != null && companyId.isNotEmpty) {
            print('🔍 getMemo2: Found company_id = $companyId, querying $collectionName...');
            snapshot = await _db
                .collection(collectionName)
                .where('company_id', isEqualTo: companyId)
                .limit(1)
                .get();
            print('🔍 getMemo2: $collectionName query by company_id returned ${snapshot.docs.length} documents');
            
            if (snapshot.docs.isNotEmpty) {
              querySnapshot = snapshot;
              break;
            }
          }
        }
        
        // Method 3: Try direct ID match
        print('🔍 getMemo2: Trying direct document ID match in $collectionName...');
        final doc = await _db.collection(collectionName).doc(memo1Id).get();
        if (doc.exists) {
          directDoc = doc;
          print('🔍 getMemo2: Direct ID match found in $collectionName');
          break;
        }
      }
      
      // Use directDoc if found, otherwise use query result
      DocumentSnapshot doc;
      if (directDoc != null && directDoc.exists) {
        doc = directDoc;
      } else if (querySnapshot != null && querySnapshot.docs.isNotEmpty) {
        doc = querySnapshot.docs.first;
      } else {
        print('⚠️ getMemo2: No Memo 2 found for memo_1_id = $memo1Id');
        print('💡 Tip: Check if backend uses company_id instead of memo_1_id');
        print('💡 Tip: Also check diligenceReports collection (not just diligenceResults)');
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        print('❌ getMemo2: Document data is null');
        return null;
      }
      
      print('📄 getMemo2: Doc ID = ${doc.id}');
      print('📄 getMemo2: Doc keys = ${data.keys.toList()}');
      print('📄 getMemo2: Has memo1_diligence? ${data['memo1_diligence'] != null}');
      print('📄 getMemo2: memo_1_id in doc = ${data['memo_1_id']}');
      print('📄 getMemo2: company_id in doc = ${data['company_id']}');
      
      final memo1Diligence = data['memo1_diligence'];
      if (memo1Diligence == null) {
        print('❌ getMemo2: memo1_diligence is null');
        return null;
      }
      
      if (memo1Diligence is! Map<String, dynamic>) {
        print('❌ getMemo2: memo1_diligence is not a Map');
        return null;
      }

      final memo2 = Memo2Model.fromMap(memo1Diligence);
      print('✅ getMemo2: Successfully parsed Memo2Model');
      return memo2;
    } catch (e, stackTrace) {
      print('❌ Error getting Memo 2: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Stream Memo 2 by memo1 ID
  Stream<Memo2Model?> getMemo2Stream(String memo1Id) {
    return _db
        .collection('diligenceResults')
        .where('memo_1_id', isEqualTo: memo1Id)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final data = snapshot.docs.first.data();
      if (data['memo1_diligence'] == null) return null;
      return Memo2Model.fromMap(data['memo1_diligence']);
    });
  }

  /// Get Memo 2 with document ID
  Future<Map<String, dynamic>?> getMemo2WithId(String memo1Id) async {
    try {
      final querySnapshot = await _db
          .collection('diligenceResults')
          .where('memo_1_id', isEqualTo: memo1Id)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return {
        'id': doc.id,
        'data': doc.data(),
      };
    } catch (e) {
      print('Error getting Memo 2 with ID: $e');
      return null;
    }
  }

  // ============ FOUNDER PROFILES ============

  /// Get founder profile
  Future<Map<String, dynamic>?> getFounderProfile(String userId) async {
    try {
      final doc = await _db.collection('founderProfiles').doc(userId).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      print('Error getting founder profile: $e');
      return null;
    }
  }

  /// Update founder profile
  Future<void> updateFounderProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      await _db.collection('founderProfiles').doc(userId).set(
            data,
            SetOptions(merge: true),
          );
    } catch (e) {
      print('Error updating founder profile: $e');
    }
  }

  // ============ INVESTOR PROFILES ============

  /// Get investor profile
  Future<Map<String, dynamic>?> getInvestorProfile(String userId) async {
    try {
      final doc = await _db.collection('investorProfiles').doc(userId).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      print('Error getting investor profile: $e');
      return null;
    }
  }

  /// Update investor profile
  Future<void> updateInvestorProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      await _db.collection('investorProfiles').doc(userId).set(
            data,
            SetOptions(merge: true),
          );
    } catch (e) {
      print('Error updating investor profile: $e');
    }
  }

  // ============ RECOMMENDATIONS ============

  /// Get investor recommendations for a startup
  Stream<List<Map<String, dynamic>>> getRecommendationsStream(
      String startupId) {
    return _db
        .collection('recommendations')
        .where('startup_id', isEqualTo: startupId)
        .orderBy('match_score', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  /// Get all startup opportunities for an investor
  Stream<List<Map<String, dynamic>>> getStartupOpportunitiesStream(
      String investorEmail) {
    return _db
        .collection('recommendations')
        .where('investor_email', isEqualTo: investorEmail)
        .orderBy('match_score', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  // ============ GENERAL HELPERS ============

  /// Check if a collection document exists
  Future<bool> documentExists(String collection, String docId) async {
    try {
      final doc = await _db.collection(collection).doc(docId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking document existence: $e');
      return false;
    }
  }

  /// Delete a document
  Future<void> deleteDocument(String collection, String docId) async {
    try {
      await _db.collection(collection).doc(docId).delete();
    } catch (e) {
      print('Error deleting document: $e');
    }
  }
}

