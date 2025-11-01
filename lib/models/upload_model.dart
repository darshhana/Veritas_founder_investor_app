class UploadModel {
  final String id;
  final String fileName;
  final String originalName;
  final String fileType;
  final String founderEmail;
  final String status;
  final String? downloadUrl;
  final String? memoId;
  final DateTime uploadedAt;
  final DateTime? processedAt;

  UploadModel({
    required this.id,
    required this.fileName,
    required this.originalName,
    required this.fileType,
    required this.founderEmail,
    required this.status,
    this.downloadUrl,
    this.memoId,
    required this.uploadedAt,
    this.processedAt,
  });

  factory UploadModel.fromMap(String id, Map<String, dynamic> map) {
    // Helper function to parse date from various formats
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      // Handle Firestore Timestamp
      if (value.runtimeType.toString() == 'Timestamp') {
        // Firestore Timestamp has seconds and nanoseconds
        return (value as dynamic).toDate();
      }
      return null;
    }

    return UploadModel(
      id: id,
      fileName: map['fileName'] ?? '',
      originalName: map['originalName'] ?? '',
      // Backend uses 'type' or 'contentType' field
      fileType: map['fileType'] ?? map['type'] ?? map['contentType'] ?? '',
      founderEmail: map['founderEmail'] ?? '',
      status: map['status'] ?? 'uploaded',
      // Backend uses 'downloadURL' (uppercase)
      downloadUrl: map['downloadUrl'] ?? map['downloadURL'],
      memoId: map['memo_id'] ?? map['memoId'],
      uploadedAt: parseDate(map['uploadedAt']) ?? DateTime.now(),
      processedAt: parseDate(map['processedAt'] ?? map['processed_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'originalName': originalName,
      'fileType': fileType,
      'founderEmail': founderEmail,
      'status': status,
      'downloadUrl': downloadUrl,
      'memo_id': memoId,
      'uploadedAt': uploadedAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
    };
  }

  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get hasError => status == 'error';
}

