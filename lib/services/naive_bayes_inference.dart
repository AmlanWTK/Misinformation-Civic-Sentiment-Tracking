// Pure Dart Naive Bayes Inference (No External Dependencies)
// lib/services/naive_bayes_inference.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class NaiveBayesModel {
  List<String> classes = [];
  List<double> classLogPrior = [];
  List<List<double>> featureLogProb = [];
  Map<String, int> vocabulary = {};
  List<String> featureNames = [];
  List<String> bengaliStopwords = [];

  /// Load model from JSON file
  static Future<NaiveBayesModel> loadFromAssets(String assetPath) async {
    try {
      print('📱 Loading Naive Bayes model from $assetPath');

      String jsonString = await rootBundle.loadString(assetPath);
      Map<String, dynamic> modelData = json.decode(jsonString);

      NaiveBayesModel model = NaiveBayesModel();

      model.classes = List<String>.from(modelData['classes']);
      model.classLogPrior =
          List<double>.from(modelData['class_log_prior'].map((e) => e.toDouble()));
      model.featureLogProb = (modelData['feature_log_prob'] as List)
          .map((row) => List<double>.from((row as List).map((e) => e.toDouble())))
          .toList();
      model.vocabulary = Map<String, int>.from(modelData['vocabulary']);
      model.featureNames = List<String>.from(modelData['feature_names']);
      model.bengaliStopwords =
          List<String>.from(modelData['metadata']['bengali_stopwords'] ?? []);

      print('✅ Model loaded successfully');
      print('📊 Classes: ${model.classes}');
      print('🔤 Vocabulary size: ${model.vocabulary.length}');

      return model;
    } catch (e) {
      print('❌ Error loading model: $e');
      rethrow;
    }
  }

  /// Preprocess Bengali text (same as Python preprocessing)
  String preprocessText(String text) {
    if (text.isEmpty) return '';

    // Convert to lowercase and trim
    text = text.toLowerCase().trim();

    // Remove punctuation but keep Bengali characters
    //text = text.replaceAll(RegExp(r'[।,.\?!;:"\'()\[\]\{\}]'), ' ');

    // Remove extra whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    // Remove numbers
    text = text.replaceAll(RegExp(r'[0-9]+'), '');

    return text.trim();
  }

  /// Simple TF vectorization (approximation)
  List<double> vectorizeText(String text) {
    String processedText = preprocessText(text);
    List<String> words = processedText
        .split(' ')
        .where((word) => word.isNotEmpty && !bengaliStopwords.contains(word))
        .toList();

    List<double> features = List.filled(vocabulary.length, 0.0);

    Map<String, int> wordCounts = {};
    for (String word in words) {
      wordCounts[word] = (wordCounts[word] ?? 0) + 1;
    }

    for (String word in wordCounts.keys) {
      if (vocabulary.containsKey(word)) {
        int index = vocabulary[word]!;
        if (index < features.length) {
          features[index] = wordCounts[word]!.toDouble();
        }
      }
    }

    return features;
  }

  /// Predict class probabilities for given text
  Map<String, double> predictProbabilities(String text) {
    List<double> features = vectorizeText(text);
    Map<String, double> probabilities = {};

    for (int i = 0; i < classes.length; i++) {
      String className = classes[i];
      double logProb = classLogPrior[i];

      for (int j = 0; j < features.length && j < featureLogProb[i].length; j++) {
        if (features[j] > 0) {
          logProb += features[j] * featureLogProb[i][j];
        }
      }

      probabilities[className] = exp(logProb);
    }

    double totalProb = probabilities.values.fold(0.0, (sum, prob) => sum + prob);
    if (totalProb > 0) {
      probabilities.updateAll((key, value) => value / totalProb);
    }

    return probabilities;
  }

  /// Predict class for given text
  PredictionResult predict(String text) {
    Map<String, double> probabilities = predictProbabilities(text);

    if (probabilities.isEmpty) {
      return PredictionResult(
        predictedClass: 'neutral',
        confidence: 0.5,
        probabilities: {'neutral': 0.5, 'credible': 0.25, 'rumor': 0.25},
      );
    }

    String predictedClass = 'neutral';
    double maxProb = 0.0;

    probabilities.forEach((className, prob) {
      if (prob > maxProb) {
        maxProb = prob;
        predictedClass = className;
      }
    });

    return PredictionResult(
      predictedClass: predictedClass,
      confidence: maxProb,
      probabilities: probabilities,
    );
  }
}

class PredictionResult {
  final String predictedClass;
  final double confidence;
  final Map<String, double> probabilities;

  PredictionResult({
    required this.predictedClass,
    required this.confidence,
    required this.probabilities,
  });

  bool get isRumor => predictedClass == 'rumor';
  bool get isCredible => predictedClass == 'credible';
  bool get isNeutral => predictedClass == 'neutral';

  @override
  String toString() {
    return 'PredictionResult(class: $predictedClass, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}
