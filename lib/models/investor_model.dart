class InvestorModel {
  final String id;
  final String userId;
  final String fullName;
  final String? companyName;
  final String? investmentThesis;
  final List<String> preferredIndustries;
  final Map<String, dynamic>? investmentCriteria;
  final List<String> portfolioCompanies;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvestorModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.companyName,
    this.investmentThesis,
    this.preferredIndustries = const [],
    this.investmentCriteria,
    this.portfolioCompanies = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvestorModel.fromMap(Map<String, dynamic> map) {
    return InvestorModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      companyName: map['companyName'],
      investmentThesis: map['investmentThesis'],
      preferredIndustries: List<String>.from(map['preferredIndustries'] ?? []),
      investmentCriteria: map['investmentCriteria'],
      portfolioCompanies: List<String>.from(map['portfolioCompanies'] ?? []),
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
      'investmentThesis': investmentThesis,
      'preferredIndustries': preferredIndustries,
      'investmentCriteria': investmentCriteria,
      'portfolioCompanies': portfolioCompanies,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  InvestorModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? companyName,
    String? investmentThesis,
    List<String>? preferredIndustries,
    Map<String, dynamic>? investmentCriteria,
    List<String>? portfolioCompanies,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvestorModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      companyName: companyName ?? this.companyName,
      investmentThesis: investmentThesis ?? this.investmentThesis,
      preferredIndustries: preferredIndustries ?? this.preferredIndustries,
      investmentCriteria: investmentCriteria ?? this.investmentCriteria,
      portfolioCompanies: portfolioCompanies ?? this.portfolioCompanies,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isProfileComplete {
    return fullName.isNotEmpty &&
        investmentThesis != null &&
        investmentThesis!.isNotEmpty &&
        preferredIndustries.isNotEmpty;
  }
}
