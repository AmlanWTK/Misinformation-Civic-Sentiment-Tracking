// Rumor Analysis Model
// lib/models/rumor_analysis.dart

class RumorAnalysis {
  final String classification;  // 'rumor', 'credible', 'neutral'
  final double confidence;      // Probability score (0.0 - 1.0)
  final Map<String, double> probabilities;  // All class probabilities
  final Map<String, double> indicators;     // Feature indicators
  final List<String> keywords;             // Extracted keywords
  final String reasoning;                  // Why classified as rumor/credible

  RumorAnalysis({
    required this.classification,
    required this.confidence,
    required this.probabilities,
    required this.indicators,
    required this.keywords,
    required this.reasoning,
  });

  bool get isRumor => classification == 'rumor';
  bool get isCredible => classification == 'credible';
  bool get isNeutral => classification == 'neutral';

  /// Get color based on classification
  int get classificationColor {
    switch (classification) {
      case 'rumor':
        return 0xFFE57373; // Light red
      case 'credible':
        return 0xFF81C784; // Light green
      default:
        return 0xFFFFB74D; // Light orange (neutral)
    }
  }

  /// Get emoji representation
  String get emoji {
    switch (classification) {
      case 'rumor':
        return '⚠️';
      case 'credible':
        return '✅';
      default:
        return '🤔';
    }
  }

  /// Get human-readable confidence level
  String get confidenceLevel {
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.6) return 'Medium';
    if (confidence >= 0.4) return 'Low';
    return 'Very Low';
  }

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'classification': classification,
      'confidence': confidence,
      'probabilities': probabilities,
      'indicators': indicators,
      'keywords': keywords,
      'reasoning': reasoning,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Create from JSON
  factory RumorAnalysis.fromJson(Map<String, dynamic> json) {
    return RumorAnalysis(
      classification: json['classification'] ?? 'neutral',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      probabilities: Map<String, double>.from(json['probabilities'] ?? {}),
      indicators: Map<String, double>.from(json['indicators'] ?? {}),
      keywords: List<String>.from(json['keywords'] ?? []),
      reasoning: json['reasoning'] ?? '',
    );
  }
}

/// Enhanced NewsItem with rumor analysis
class AnalyzedNewsItem {
  final String title;
  final String description;
  final String link;
  final DateTime pubDate;
  final String source;
  final RumorAnalysis? rumorAnalysis;

  AnalyzedNewsItem({
    required this.title,
    required this.description,
    required this.link,
    required this.pubDate,
    required this.source,
    this.rumorAnalysis,
  });

  /// Create from existing NewsItem
  factory AnalyzedNewsItem.fromNewsItem(dynamic newsItem, [RumorAnalysis? analysis]) {
    return AnalyzedNewsItem(
      title: newsItem.title,
      description: newsItem.description,
      link: newsItem.link,
      pubDate: newsItem.pubDate,
      source: newsItem.source,
      rumorAnalysis: analysis,
    );
  }

  /// Check if this news item is flagged as potential rumor
  bool get isPotentialRumor => rumorAnalysis?.isRumor ?? false;

  /// Check if this news item is verified as credible
  bool get isVerified => rumorAnalysis?.isCredible ?? false;

  /// Get trust score (0-100)
  int get trustScore {
    if (rumorAnalysis == null) return 50;
    if (rumorAnalysis!.isCredible) return (rumorAnalysis!.confidence * 100).round();
    if (rumorAnalysis!.isRumor) return (100 - rumorAnalysis!.confidence * 100).round();
    return 50;
  }
}