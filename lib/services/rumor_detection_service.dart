// Updated Rumor Detection Service (No External ML Dependencies)
// lib/services/rumor_detection_service_v2.dart

import '../models/rumor_analysis.dart';
import '../services/news_service.dart';
import 'naive_bayes_inference.dart';

class RumorDetectionService {
  static NaiveBayesModel? _model;
  static bool _isInitialized = false;

  /// Initialize the rumor detection service with trained model
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('ðŸ” Initializing Rumor Detection Service with trained model...');
    
    try {
      // Load the trained model from assets
      _model = await NaiveBayesModel.loadFromAssets('assets/models/naive_bayes_model.json');
      _isInitialized = true;
      print('âœ… Rumor Detection Service initialized successfully');
    } catch (e) {
      print('âŒ Failed to load trained model: $e');
      print('âš ï¸ Make sure you have trained the model in Python and exported it to assets/');
      _isInitialized = false;
    }
  }

  /// Analyze text for rumor indicators using trained model
  static Future<RumorAnalysis> analyzeText(String text) async {
    if (!_isInitialized || _model == null) {
      await initialize();
    }

    if (_model == null) {
      // Fallback analysis if model fails to load
      return _fallbackAnalysis(text);
    }

    try {
      // Use the trained model for prediction
      PredictionResult prediction = _model!.predict(text);
      
      // Extract features for additional analysis
      Map<String, double> indicators = _calculateIndicators(text);
      List<String> keywords = _extractKeywords(text);

      // Generate reasoning
      String reasoning = _generateReasoning(prediction, indicators);

      return RumorAnalysis(
        classification: prediction.predictedClass,
        confidence: prediction.confidence,
        probabilities: prediction.probabilities,
        indicators: indicators,
        keywords: keywords,
        reasoning: reasoning,
      );

    } catch (e) {
      print('âŒ Error in rumor analysis: $e');
      return _fallbackAnalysis(text);
    }
  }

  /// Analyze a NewsItem for rumors
  static Future<AnalyzedNewsItem> analyzeNewsItem(dynamic newsItem) async {
    String combinedText = '${newsItem.title} ${newsItem.description}';
    RumorAnalysis analysis = await analyzeText(combinedText);
    
    return AnalyzedNewsItem.fromNewsItem(newsItem, analysis);
  }

  /// Analyze multiple news items
  static Future<List<AnalyzedNewsItem>> analyzeNewsList(List<dynamic> newsItems) async {
    List<AnalyzedNewsItem> analyzedItems = [];
    
    for (dynamic item in newsItems) {
      AnalyzedNewsItem analyzedItem = await analyzeNewsItem(item);
      analyzedItems.add(analyzedItem);
    }
    
    return analyzedItems;
  }

  /// Get aggregated news with rumor separation
  static Future<Map<String, List<AnalyzedNewsItem>>> getAnalyzedNews() async {
    try {
      List<dynamic> newsItems = await RSSFeedService.aggregateNews();
      List<AnalyzedNewsItem> analyzedItems = await analyzeNewsList(newsItems);
      
      // Separate by classification
      Map<String, List<AnalyzedNewsItem>> categorized = {
        'credible': [],
        'neutral': [],
        'rumor': [],
      };
      
      for (AnalyzedNewsItem item in analyzedItems) {
        String category = item.rumorAnalysis?.classification ?? 'neutral';
        categorized[category]!.add(item);
      }
      
      // Sort by confidence (highest confidence first)
      categorized.forEach((key, items) {
        items.sort((a, b) => (b.rumorAnalysis?.confidence ?? 0.0)
            .compareTo(a.rumorAnalysis?.confidence ?? 0.0));
      });
      
      return categorized;
    } catch (e) {
      print('âŒ Error in getting analyzed news: $e');
      return {'credible': [], 'neutral': [], 'rumor': []};
    }
  }

  /// Calculate additional indicators (manual features)
  static Map<String, double> _calculateIndicators(String text) {
    String lowerText = text.toLowerCase();
    
    // Rumor indicator words
    List<String> rumorWords = [
      'à¦—à§à¦œà¦¬', 'à¦®à¦¿à¦¥à§à¦¯à¦¾', 'à¦­à§à¦¯à¦¼à¦¾', 'à¦¬à¦¾à¦¨à§‹à¦¯à¦¼à¦¾à¦Ÿ', 'à¦œà¦¾à¦²', 'à¦¨à¦•à¦²', 'à¦…à¦¬à¦¿à¦¶à§à¦¬à¦¸à§à¦¤',
      'à¦¶à§‹à¦¨à¦¾ à¦¯à¦¾à¦šà§à¦›à§‡', 'à¦¬à¦²à¦¾ à¦¹à¦šà§à¦›à§‡', 'à¦¦à¦¾à¦¬à¦¿ à¦•à¦°à¦¾ à¦¹à¦šà§à¦›à§‡', 'à¦¸à¦¨à§à¦¦à§‡à¦¹à¦œà¦¨à¦•',
      'à¦…à¦¨à¦¿à¦¶à§à¦šà¦¿à¦¤', 'à¦…à¦¸à§à¦ªà¦·à§à¦Ÿ', 'à¦…à¦¨à§à¦®à¦¾à¦¨', 'à¦¹à¦¤à§‡ à¦ªà¦¾à¦°à§‡', 'à¦¸à¦®à§à¦­à¦¬à¦¤',
      'à¦¤à¦¾à§Žà¦•à§à¦·à¦£à¦¿à¦•', 'à¦œà¦°à§à¦°à¦¿', 'à¦¦à§à¦°à§à¦¤ à¦¶à§‡à¦¯à¦¼à¦¾à¦° à¦•à¦°à§à¦¨', 'à¦¬à¦¿à¦ªà¦œà§à¦œà¦¨à¦•', 'à¦šà¦¾à¦žà§à¦šà¦²à§à¦¯à¦•à¦°'
    ];
    
    // Credibility indicators
    List<String> credibleWords = [
      'à¦¸à¦°à¦•à¦¾à¦°à¦¿', 'à¦…à¦«à¦¿à¦¸à¦¿à¦¯à¦¼à¦¾à¦²', 'à¦¨à¦¿à¦¶à§à¦šà¦¿à¦¤', 'à¦¯à¦¾à¦šà¦¾à¦‡à¦•à§ƒà¦¤', 'à¦ªà§à¦°à¦®à¦¾à¦£à¦¿à¦¤',
      'à¦—à¦¬à§‡à¦·à¦£à¦¾', 'à¦¸à¦®à§€à¦•à§à¦·à¦¾', 'à¦°à¦¿à¦ªà§‹à¦°à§à¦Ÿ', 'à¦¬à¦¿à¦¶à§‡à¦·à¦œà§à¦ž', 'à¦ªà¦°à§€à¦•à§à¦·à¦¿à¦¤',
      'à¦¨à¦¿à¦°à§à¦­à¦°à¦¯à§‹à¦—à§à¦¯', 'à¦¬à¦¿à¦¶à§à¦¬à¦¸à§à¦¤', 'à¦¸à¦¤à§à¦¯à¦¿', 'à¦¸à¦ à¦¿à¦•', 'à¦¨à¦¿à¦–à§à¦à¦¤'
    ];
    
    int rumorCount = rumorWords.where((word) => lowerText.contains(word)).length;
    int credibleCount = credibleWords.where((word) => lowerText.contains(word)).length;
    
    return {
      'rumor_indicators': rumorCount.toDouble(),
      'credible_indicators': credibleCount.toDouble(),
      'text_length': text.length.toDouble(),
      'word_count': text.split(' ').length.toDouble(),
    };
  }

  /// Extract key words from text
  static List<String> _extractKeywords(String text) {
    if (_model == null) return [];
    
    String processed = _model!.preprocessText(text);
    List<String> words = processed.split(' ')
        .where((word) => word.isNotEmpty && word.length > 2)
        .toList();
    
    // Return top 5 words that are in model vocabulary
    return words.where((word) => _model!.vocabulary.containsKey(word))
        .take(5)
        .toList();
  }

  /// Generate human-readable reasoning
  static String _generateReasoning(PredictionResult prediction, Map<String, double> indicators) {
    String baseReason = 'ML Model: ${(prediction.confidence * 100).round()}% confidence';
    
    int rumorIndicators = (indicators['rumor_indicators'] ?? 0).toInt();
    int credibleIndicators = (indicators['credible_indicators'] ?? 0).toInt();
    
    if (prediction.isRumor) {
      return '$baseReason. Contains $rumorIndicators rumor indicators.';
    } else if (prediction.isCredible) {
      return '$baseReason. Contains $credibleIndicators credibility indicators.';
    } else {
      return '$baseReason. Neutral classification.';
    }
  }

  /// Fallback analysis when trained model is unavailable
  static RumorAnalysis _fallbackAnalysis(String text) {
    Map<String, double> indicators = _calculateIndicators(text);
    
    double rumorScore = indicators['rumor_indicators'] ?? 0.0;
    double credibleScore = indicators['credible_indicators'] ?? 0.0;
    
    String classification = 'neutral';
    double confidence = 0.5;
    
    if (rumorScore > credibleScore && rumorScore > 0) {
      classification = 'rumor';
      confidence = (0.5 + (rumorScore * 0.1)).clamp(0.0, 0.9);
    } else if (credibleScore > rumorScore && credibleScore > 0) {
      classification = 'credible';
      confidence = (0.5 + (credibleScore * 0.1)).clamp(0.0, 0.9);
    }
    
    return RumorAnalysis(
      classification: classification,
      confidence: confidence,
      probabilities: {
        'rumor': rumorScore / (rumorScore + credibleScore + 1),
        'credible': credibleScore / (rumorScore + credibleScore + 1),
        'neutral': 1 / (rumorScore + credibleScore + 1),
      },
      indicators: indicators,
      keywords: text.split(' ').take(5).toList(),
      reasoning: 'Fallback analysis - trained model not available. Based on keyword indicators only.',
    );
  }

  /// Check if model is properly loaded
  static bool get isModelLoaded => _model != null && _isInitialized;
  
  /// Get model information
  static Map<String, dynamic> getModelInfo() {
    if (_model == null) return {'status': 'not_loaded'};
    
    return {
      'status': 'loaded',
      'classes': _model!.classes,
      'vocabulary_size': _model!.vocabulary.length,
      'features': _model!.featureNames.length,
    };
  }
}