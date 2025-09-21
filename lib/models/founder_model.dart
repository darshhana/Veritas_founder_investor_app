class FounderModel {
  final String id;
  final String userId;
  final String fullName;
  final String? companyName;
  final String? problemStatement;
  final String? qualifications;
  final String? motivation;
  final String? pitchDeckUrl;
  final String? videoPitchUrl;
  final String? audioSummaryUrl;
  final Map<String, dynamic>? kpiData;
  final List<String> connectedSystems;
  final DateTime createdAt;
  final DateTime updatedAt;

  FounderModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.companyName,
    this.problemStatement,
    this.qualifications,
    this.motivation,
    this.pitchDeckUrl,
    this.videoPitchUrl,
    this.audioSummaryUrl,
    this.kpiData,
    this.connectedSystems = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory FounderModel.fromMap(Map<String, dynamic> map) {
    return FounderModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      companyName: map['companyName'],
      problemStatement: map['problemStatement'],
      qualifications: map['qualifications'],
      motivation: map['motivation'],
      pitchDeckUrl: map['pitchDeckUrl'],
      videoPitchUrl: map['videoPitchUrl'],
      audioSummaryUrl: map['audioSummaryUrl'],
      kpiData: map['kpiData'],
      connectedSystems: List<String>.from(map['connectedSystems'] ?? []),
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'companyName': companyName,
      'problemStatement': problemStatement,
      'qualifications': qualifications,
      'motivation': motivation,
      'pitchDeckUrl': pitchDeckUrl,
      'videoPitchUrl': videoPitchUrl,
      'audioSummaryUrl': audioSummaryUrl,
      'kpiData': kpiData,
      'connectedSystems': connectedSystems,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  FounderModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? companyName,
    String? problemStatement,
    String? qualifications,
    String? motivation,
    String? pitchDeckUrl,
    String? videoPitchUrl,
    String? audioSummaryUrl,
    Map<String, dynamic>? kpiData,
    List<String>? connectedSystems,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FounderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      companyName: companyName ?? this.companyName,
      problemStatement: problemStatement ?? this.problemStatement,
      qualifications: qualifications ?? this.qualifications,
      motivation: motivation ?? this.motivation,
      pitchDeckUrl: pitchDeckUrl ?? this.pitchDeckUrl,
      videoPitchUrl: videoPitchUrl ?? this.videoPitchUrl,
      audioSummaryUrl: audioSummaryUrl ?? this.audioSummaryUrl,
      kpiData: kpiData ?? this.kpiData,
      connectedSystems: connectedSystems ?? this.connectedSystems,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isProfileComplete {
    return fullName.isNotEmpty &&
        problemStatement != null &&
        problemStatement!.isNotEmpty &&
        qualifications != null &&
        qualifications!.isNotEmpty &&
        motivation != null &&
        motivation!.isNotEmpty;
  }
}
