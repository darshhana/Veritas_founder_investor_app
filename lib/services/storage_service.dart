import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload file to Firebase Storage
  Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String folderPath,
    String? customFileName,
    Function(double)? onProgress,
  }) async {
    try {
      // Generate unique filename if not provided
      String fileName = customFileName ??
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';

      // Create storage reference
      Reference ref = _storage.ref().child('$folderPath/$fileName');

      // Start upload task
      UploadTask uploadTask = ref.putFile(file);

      // Listen to progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (onProgress != null) {
          onProgress(progress);
        }
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return {
        'success': true,
        'downloadUrl': downloadUrl,
        'fileName': fileName,
        'fullPath': ref.fullPath,
      };
    } on FirebaseException catch (e) {
      print('Firebase Storage Error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'error': 'Storage error: ${e.message}',
      };
    } catch (e) {
      print('Upload Error: $e');
      return {
        'success': false,
        'error': 'Upload failed: $e',
      };
    }
  }

  /// Upload pitch deck
  Future<Map<String, dynamic>> uploadPitchDeck({
    required File file,
    required String founderEmail,
    Function(double)? onProgress,
  }) async {
    String sanitizedEmail = founderEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return uploadFile(
      file: file,
      folderPath: 'pitch-decks/$sanitizedEmail',
      onProgress: onProgress,
    );
  }

  /// Upload video pitch
  Future<Map<String, dynamic>> uploadVideoPitch({
    required File file,
    required String founderEmail,
    Function(double)? onProgress,
  }) async {
    String sanitizedEmail = founderEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return uploadFile(
      file: file,
      folderPath: 'video-pitches/$sanitizedEmail',
      onProgress: onProgress,
    );
  }

  /// Upload audio summary
  Future<Map<String, dynamic>> uploadAudioSummary({
    required File file,
    required String founderEmail,
    Function(double)? onProgress,
  }) async {
    String sanitizedEmail = founderEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return uploadFile(
      file: file,
      folderPath: 'audio-summaries/$sanitizedEmail',
      onProgress: onProgress,
    );
  }

  /// Get download URL for a file
  Future<String?> getDownloadUrl(String filePath) async {
    try {
      Reference ref = _storage.ref().child(filePath);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      print('Error getting download URL: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  /// Delete a file
  Future<bool> deleteFile(String filePath) async {
    try {
      Reference ref = _storage.ref().child(filePath);
      await ref.delete();
      return true;
    } on FirebaseException catch (e) {
      print('Error deleting file: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  /// List files in a folder
  Future<List<String>> listFiles(String folderPath) async {
    try {
      Reference ref = _storage.ref().child(folderPath);
      ListResult result = await ref.listAll();
      return result.items.map((item) => item.fullPath).toList();
    } on FirebaseException catch (e) {
      print('Error listing files: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  /// Get file metadata
  Future<Map<String, dynamic>?> getFileMetadata(String filePath) async {
    try {
      Reference ref = _storage.ref().child(filePath);
      FullMetadata metadata = await ref.getMetadata();
      return {
        'name': metadata.name,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'timeCreated': metadata.timeCreated,
        'updated': metadata.updated,
      };
    } on FirebaseException catch (e) {
      print('Error getting metadata: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}

