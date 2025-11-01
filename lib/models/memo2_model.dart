class Memo2Model {
  final GoogleAnalyticsSummary? googleAnalyticsSummary;
  final AnalysisSection founderAnalysis;
  final AnalysisSection problemValidation;
  final AnalysisSection solutionAnalysis;
  final AnalysisSection? marketAnalysis;
  final String investmentThesis;
  final double confidenceScore;
  final String investmentRecommendation;
  final List<String> keyRisks;

  Memo2Model({
    this.googleAnalyticsSummary,
    required this.founderAnalysis,
    required this.problemValidation,
    required this.solutionAnalysis,
    this.marketAnalysis,
    required this.investmentThesis,
    required this.confidenceScore,
    required this.investmentRecommendation,
    this.keyRisks = const [],
  });

  factory Memo2Model.fromMap(Map<String, dynamic> map) {
    // Safe parsing helper for string lists
    List<String> parseStringList(dynamic data) {
      if (data == null) return [];
      if (data is List) {
        return data.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      return [];
    }
    
    // Safe parsing helper for maps
    Map<String, dynamic> ensureMap(dynamic data) {
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {};
    }
    
    return Memo2Model(
      googleAnalyticsSummary: map['google_analytics_summary'] != null
          ? GoogleAnalyticsSummary.fromMap(ensureMap(map['google_analytics_summary']))
          : null,
      founderAnalysis: AnalysisSection.fromMap(ensureMap(map['founder_analysis'])),
      problemValidation: AnalysisSection.fromMap(ensureMap(map['problem_validation'])),
      solutionAnalysis: AnalysisSection.fromMap(ensureMap(map['solution_analysis'])),
      marketAnalysis: map['market_analysis'] != null
          ? AnalysisSection.fromMap(ensureMap(map['market_analysis']))
          : null,
      investmentThesis: map['investment_thesis']?.toString() ?? '',
      confidenceScore: () {
        // Your Firestore stores confidence_score as 0-10 scale, normalize to 0-1
        if (map['confidence_score'] is num) {
          double score = (map['confidence_score'] as num).toDouble();
          // If score > 1, assume 0-10 scale, normalize to 0-1
          if (score > 1.0) {
            return score / 10.0;
          }
          return score;
        }
        return 0.0;
      }(),
      investmentRecommendation: map['investment_recommendation']?.toString() ?? '',
      keyRisks: parseStringList(map['key_risks']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'google_analytics_summary': googleAnalyticsSummary?.toMap(),
      'founder_analysis': founderAnalysis.toMap(),
      'problem_validation': problemValidation.toMap(),
      'solution_analysis': solutionAnalysis.toMap(),
      'market_analysis': marketAnalysis?.toMap(),
      'investment_thesis': investmentThesis,
      'confidence_score': confidenceScore,
      'investment_recommendation': investmentRecommendation,
      'key_risks': keyRisks,
    };
  }
}

class GoogleAnalyticsSummary {
  final String dataSource;
  final int? totalActiveUsersLast28Days;
  final String status;

  GoogleAnalyticsSummary({
    required this.dataSource,
    this.totalActiveUsersLast28Days,
    required this.status,
  });

  factory GoogleAnalyticsSummary.fromMap(Map<String, dynamic> map) {
    return GoogleAnalyticsSummary(
      dataSource: map['data_source']?.toString() ?? '',
      totalActiveUsersLast28Days: map['total_active_users_last_28_days'] is num
          ? (map['total_active_users_last_28_days'] as num).toInt()
          : null,
      status: map['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'data_source': dataSource,
      'total_active_users_last_28_days': totalActiveUsersLast28Days,
      'status': status,
    };
  }
}

class AnalysisSection {
  final double score;
  final String? background;
  final String? marketFit;
  final String? severity;
  final String? marketNeed;
  final String? uniqueness;
  final String? feasibility;
  final String? opportunity;
  final String? competition;

  AnalysisSection({
    required this.score,
    this.background,
    this.marketFit,
    this.severity,
    this.marketNeed,
    this.uniqueness,
    this.feasibility,
    this.opportunity,
    this.competition,
  });

  factory AnalysisSection.fromMap(Map<String, dynamic> map) {
    // Parse score - handle different formats (0-1, 0-10, or missing)
    double parseScore(dynamic scoreValue) {
      if (scoreValue == null) {
        print('  ⚠️ AnalysisSection: score is null, returning 0.0');
        return 0.0;
      }
      
      if (scoreValue is num) {
        double score = scoreValue.toDouble();
        print('  📊 AnalysisSection: Raw score = $score (type: num)');
        // If score > 1, assume 0-10 scale, normalize to 0-1
        if (score > 1.0) {
          final normalized = score / 10.0;
          print('  ✅ AnalysisSection: Normalized from 0-10 scale: $score → $normalized');
          return normalized;
        }
        print('  ✅ AnalysisSection: Using as-is (0-1 scale): $score');
        return score;
      }
      
      // Try parsing as string
      if (scoreValue is String) {
        final parsed = double.tryParse(scoreValue);
        if (parsed != null) {
          print('  📊 AnalysisSection: Parsed string score = $parsed');
          if (parsed > 1.0) {
            final normalized = parsed / 10.0;
            print('  ✅ AnalysisSection: Normalized from 0-10 scale: $parsed → $normalized');
            return normalized;
          }
          print('  ✅ AnalysisSection: Using as-is (0-1 scale): $parsed');
          return parsed;
        }
      }
      
      print('  ⚠️ AnalysisSection: Could not parse score value: $scoreValue (type: ${scoreValue.runtimeType})');
      return 0.0;
    }
    
    return AnalysisSection(
      score: parseScore(map['score']),
      background: map['background']?.toString(),
      marketFit: map['market_fit']?.toString(),
      severity: map['severity']?.toString(),
      marketNeed: map['market_need']?.toString(),
      uniqueness: map['uniqueness']?.toString(),
      feasibility: map['feasibility']?.toString(),
      opportunity: map['opportunity']?.toString(),
      competition: map['competition']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'background': background,
      'market_fit': marketFit,
      'severity': severity,
      'market_need': marketNeed,
      'uniqueness': uniqueness,
      'feasibility': feasibility,
      'opportunity': opportunity,
      'competition': competition,
    };
  }
}

