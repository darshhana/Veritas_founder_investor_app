import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/firestore_service.dart';
import '../../models/upload_model.dart';
import '../founder_dashboard/memo_display_screen.dart';

class PitchIngestionScreen extends StatefulWidget {
  @override
  _PitchIngestionScreenState createState() => _PitchIngestionScreenState();
}

class _PitchIngestionScreenState extends State<PitchIngestionScreen> {
  final ApiService _apiService = ApiService();
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _currentUploadFileName;
  
  List<UploadModel> _uploads = [];
  Map<String, String?> _memoIdMap = {}; // Track memo IDs for uploads
  Timer? _memoCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadUploads();
    
    // Periodically check for new memos (every 30 seconds)
    // This helps detect when a memo is created for a processing upload
    _memoCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      print('🔄 PERIODIC CHECK: Refreshing memo checks for processing uploads...');
      _recheckProcessingUploads();
    });
  }
  
  @override
  void dispose() {
    _memoCheckTimer?.cancel();
    super.dispose();
  }
  
  void _recheckProcessingUploads() async {
    // Only recheck uploads that are still processing
    final processingUploads = _uploads.where((u) => u.status == 'processing' && _memoIdMap[u.id] == null).toList();
    if (processingUploads.isEmpty) return;
    
    print('🔄 Rechecking ${processingUploads.length} processing uploads...');
    Map<String, String?> updatedMemos = {};
    
    for (var upload in processingUploads) {
      final memoId = await _firestoreService.checkMemoExists(upload.id);
      if (memoId != null) {
        updatedMemos[upload.id] = memoId;
        print('✅ Found new memo for ${upload.id}: $memoId');
      }
    }
    
    if (updatedMemos.isNotEmpty && mounted) {
      setState(() {
        _memoIdMap.addAll(updatedMemos);
      });
    }
  }

  void _loadUploads() async {
    final user = FirebaseAuth.instance.currentUser;
    print('🔍 LOAD UPLOADS: Current user: ${user?.email}');
    
    if (user != null) {
      print('🔍 LOAD UPLOADS: Starting Firestore stream for ${user.email}');
      _firestoreService.getUploadsStream(user.email!).listen((uploads) async {
        print('🔍 LOAD UPLOADS: Received ${uploads.length} uploads from Firestore');
        
        // Check if ingestion results exist for each upload
        Map<String, String?> newMemoMap = {};
        for (var upload in uploads) {
          print('  📄 Upload: ${upload.originalName} - Status: ${upload.status}');
          
          // Always check if memo exists (for processing or completed status)
          String? memoId = await _firestoreService.checkMemoExists(upload.id);
          
          // If not found by ID, try searching by file name and founder email
          if (memoId == null) {
            print('  🔍 Memo not found by ID, trying broader search...');
            final user = FirebaseAuth.instance.currentUser;
            if (user != null && user.email != null) {
              try {
                // Query ingestionResults by founder email and file name
                final results = await FirebaseFirestore.instance
                    .collection('ingestionResults')
                    .where('founder_email', isEqualTo: user.email)
                    .limit(20)
                    .get();
                
                print('  🔍 Found ${results.docs.length} memos for ${user.email}');
                
                for (var doc in results.docs) {
                  final data = doc.data();
                  final originalFilename = data['original_filename']?.toString() ?? 
                                         data['file_name']?.toString() ?? 
                                         data['fileName']?.toString() ?? '';
                  final uploadId = data['upload_id']?.toString();
                  
                  print('    📄 Checking memo ${doc.id}: filename=$originalFilename, upload_id=$uploadId');
                  
                  // Match by file name or upload_id
                  if (originalFilename == upload.originalName || 
                      uploadId == upload.id ||
                      (uploadId != null && uploadId.isNotEmpty && data['upload_id'] == upload.id)) {
                    memoId = doc.id;
                    print('  ✅ Found memo by file name match: ${doc.id}');
                    break;
                  }
                }
              } catch (e) {
                print('  ⚠️  Error in broader search: $e');
              }
            }
          }
          
          newMemoMap[upload.id] = memoId;
          
          if (memoId != null) {
            print('  ✅ Memo found for ${upload.id} -> $memoId');
          } else {
            print('  ⏳ No memo yet for ${upload.id}');
            
            // If status is processing for more than 10 minutes, log it
            final age = DateTime.now().difference(upload.uploadedAt);
            if (upload.status == 'processing' && age.inMinutes > 10) {
              print('  ⚠️  WARNING: Upload ${upload.id} has been processing for ${age.inMinutes} minutes without a memo');
            }
          }
        }
        
        if (mounted) {
          setState(() {
            _uploads = uploads;
            _memoIdMap = newMemoMap;
          });
          print('✅ LOAD UPLOADS: UI updated with ${_uploads.length} uploads');
          print('✅ Memos found for: ${newMemoMap.values.where((e) => e != null).length} uploads');
        }
      }, onError: (error) {
        print('❌ LOAD UPLOADS ERROR: $error');
      });
    } else {
      print('⚠️  LOAD UPLOADS: No user logged in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Manually refresh uploads list
          _loadUploads();
          // Wait a bit for the stream to update
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Tell Your Story, Your Way',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Present your pitch in the format that best tells your story.',
                style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
              ),
              const SizedBox(height: 4),
              // Pull to refresh hint
              Text(
                '↓ Pull down to refresh • Updates automatically in real-time',
                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),

              // Upload Progress Indicator
              if (_isUploading) _buildUploadProgress(),

              const SizedBox(height: 16),

              // Upload Options
              _buildUploadOptions(),

              const SizedBox(height: 24),

              // Existing Pitches
              if (_uploads.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Pitches',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424242),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.green[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${_uploads.length} total',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._uploads.map((upload) => _buildUploadCard(upload)),
              ] else if (!_isUploading) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.upload_file,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pitches uploaded yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uploading ${_currentUploadFileName ?? 'file'}...',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: _uploadProgress),
                      const SizedBox(height: 4),
                      Text(
                        '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOptions() {
    return Column(
      children: [
        _buildUploadOption(
          title: 'Upload Pitch Deck (PDF)',
          description: 'Upload your traditional pitch deck',
          icon: Icons.upload_file,
          color: const Color(0xFF4A90E2),
          onTap: () => _uploadPDF(),
        ),
        const SizedBox(height: 16),
        _buildUploadOption(
          title: 'Record Video Pitch',
          description: 'Record a passionate video pitch',
          icon: Icons.videocam,
          color: const Color(0xFF757575),
          onTap: () => _recordVideo(),
        ),
        const SizedBox(height: 16),
        _buildUploadOption(
          title: 'Submit Audio Summary',
          description: 'Record an audio summary of your pitch',
          icon: Icons.mic,
          color: const Color(0xFF757575),
          onTap: () => _recordAudio(),
        ),
      ],
    );
  }

  Widget _buildUploadOption({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard(UploadModel upload) {
    // Check if memo exists for this upload (override status)
    final memoId = _memoIdMap[upload.id];
    final hasMemo = memoId != null;
    final effectiveStatus = hasMemo ? 'completed' : upload.status;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getFileTypeColor(upload.fileType).withOpacity(0.1),
          child: Icon(
            _getFileTypeIcon(upload.fileType),
            color: _getFileTypeColor(upload.fileType),
          ),
        ),
        title: Text(
          upload.originalName,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF424242),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('MMM dd, yyyy • hh:mm a').format(upload.uploadedAt)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(effectiveStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                effectiveStatus.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: _getStatusColor(effectiveStatus),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasMemo)
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () => _viewAnalysis(memoId),
                tooltip: 'View Analysis',
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteUpload(upload);
                } else if (value == 'view' && hasMemo) {
                  _viewAnalysis(memoId);
                }
              },
              itemBuilder: (context) => [
                if (hasMemo)
                  const PopupMenuItem(value: 'view', child: Text('View Analysis')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getFileTypeColor(String type) {
    if (type.contains('pdf') || type == 'deck') {
      return const Color(0xFF4A90E2);
    } else if (type.contains('video') || type.contains('mp4')) {
      return const Color(0xFFE91E63);
    } else if (type.contains('audio') || type.contains('mp3')) {
      return const Color(0xFF4CAF50);
    }
    return const Color(0xFF757575);
  }

  IconData _getFileTypeIcon(String type) {
    if (type.contains('pdf') || type == 'deck') {
      return Icons.picture_as_pdf;
    } else if (type.contains('video') || type.contains('mp4')) {
      return Icons.videocam;
    } else if (type.contains('audio') || type.contains('mp3')) {
      return Icons.audiotrack;
    }
    return Icons.file_present;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'uploaded':
        return const Color(0xFF4CAF50);
      case 'processing':
        return const Color(0xFFFF9800);
      case 'processed':
      case 'completed':
        return const Color(0xFF4A90E2);
      case 'error':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF757575);
    }
  }

  void _uploadPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        await _uploadFile(file, 'deck');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadFile(File file, String fileType) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to upload files'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _currentUploadFileName = file.path.split('/').last;
    });

    try {
      // Simulate progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            _uploadProgress = i / 100;
          });
        }
      }

      // Upload file
      print('📤 UPLOAD: Starting upload for ${file.path}');
      print('📤 UPLOAD: User email: ${user.email}');
      print('📤 UPLOAD: File type: $fileType');
      
      final response = await _apiService.uploadFile(
        file: file,
        founderEmail: user.email!,
        fileType: fileType,
      );

      print('📤 UPLOAD RESPONSE: $response');
      
      if (response['success']) {
        print('✅ UPLOAD: Success! Response data: ${response['data']}');
        
        // Refresh uploads list after 2 seconds (silent, no snackbar)
        Future.delayed(const Duration(seconds: 2), () {
          print('🔄 UPLOAD: Refreshing uploads list...');
          _loadUploads();
        });
      } else {
        print('❌ UPLOAD: Failed with error: ${response['error']}');
        throw Exception(response['error'] ?? 'Upload failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _currentUploadFileName = null;
        });
      }
    }
  }

  void _recordVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'avi', 'mkv'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        await _uploadFile(file, 'video');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _recordAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        await _uploadFile(file, 'audio');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting audio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteUpload(UploadModel upload) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Upload'),
        content: Text('Are you sure you want to delete "${upload.originalName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestoreService.deleteDocument('uploads', upload.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Upload deleted successfully'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewAnalysis(String memoId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoDisplayScreen(memoId: memoId),
      ),
    );
  }
}
