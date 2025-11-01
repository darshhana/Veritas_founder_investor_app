class Memo1Model {
  final String title;
  final String founderName;
  final String? founderLinkedinUrl;
  final String? companyLinkedinUrl;
  final String problem;
  final String solution;
  final String traction;
  final String marketSize;
  final String businessModel;
  final List<String> competition;
  final String team;
  final List<String> initialFlags;
  final List<String> validationPoints;
  final String summaryAnalysis;
  final String industryCategory;
  final String companyStage;
  final String? amountRaising;
  final String? postMoneyValuation;
  final String? fundingAsk;
  final String? useOfFunds;

  Memo1Model({
    required this.title,
    required this.founderName,
    this.founderLinkedinUrl,
    this.companyLinkedinUrl,
    required this.problem,
    required this.solution,
    required this.traction,
    required this.marketSize,
    required this.businessModel,
    this.competition = const [],
    required this.team,
    this.initialFlags = const [],
    this.validationPoints = const [],
    required this.summaryAnalysis,
    required this.industryCategory,
    required this.companyStage,
    this.amountRaising,
    this.postMoneyValuation,
    this.fundingAsk,
    this.useOfFunds,
  });

  factory Memo1Model.fromMap(Map<String, dynamic> map) {
    // Parse competition array - backend sends array of maps with name/description
    List<String> parseCompetition(dynamic competitionData) {
      if (competitionData == null) return [];
      if (competitionData is List) {
        return competitionData.map((item) {
          if (item is String) return item;
          if (item is Map) {
            return item['name']?.toString() ?? '';
          }
          return '';
        }).where((s) => s.isNotEmpty).toList();
      }
      return [];
    }
    
    // Parse string arrays safely
    List<String> parseStringList(dynamic data) {
      if (data == null) return [];
      if (data is List) {
        return data.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      return [];
    }
    
    return Memo1Model(
      title: map['title']?.toString() ?? '',
      founderName: map['founder_name']?.toString() ?? '',
      founderLinkedinUrl: map['founder_linkedin_url']?.toString(),
      companyLinkedinUrl: map['company_linkedin_url']?.toString(),
      problem: map['problem']?.toString() ?? '',
      solution: map['solution']?.toString() ?? '',
      traction: map['traction']?.toString() ?? '',
      marketSize: map['market_size']?.toString() ?? '',
      businessModel: map['business_model']?.toString() ?? '',
      competition: parseCompetition(map['competition']),
      team: map['team']?.toString() ?? '',
      initialFlags: parseStringList(map['initial_flags']),
      validationPoints: parseStringList(map['validation_points']),
      summaryAnalysis: map['summary_analysis']?.toString() ?? '',
      industryCategory: map['industry_category']?.toString() ?? 'Unknown',
      companyStage: map['company_stage']?.toString() ?? 'Unknown',
      amountRaising: map['amount_raising']?.toString(),
      postMoneyValuation: map['post_money_valuation']?.toString(),
      fundingAsk: map['funding_ask']?.toString(),
      useOfFunds: map['use_of_funds']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'founder_name': founderName,
      'founder_linkedin_url': founderLinkedinUrl,
      'company_linkedin_url': companyLinkedinUrl,
      'problem': problem,
      'solution': solution,
      'traction': traction,
      'market_size': marketSize,
      'business_model': businessModel,
      'competition': competition,
      'team': team,
      'initial_flags': initialFlags,
      'validation_points': validationPoints,
      'summary_analysis': summaryAnalysis,
      'industry_category': industryCategory,
      'company_stage': companyStage,
      'amount_raising': amountRaising,
      'post_money_valuation': postMoneyValuation,
      'funding_ask': fundingAsk,
      'use_of_funds': useOfFunds,
    };
  }
}

