import 'dart:convert';
import 'package:http/http.dart' as http;

/// Model for a social post
class SocialPost {
  final String content;
  final String platform;
  final String author;
  final DateTime createdAt;
  final String? location;
  final int likes;
  final int retweets;

  SocialPost({
    required this.content,
    required this.platform,
    required this.author,
    required this.createdAt,
    this.location,
    this.likes = 0,
    this.retweets = 0,
  });
}

/// Result of sentiment analysis
class SentimentResult {
  final String category;
  final String emoji;

  SentimentResult({required this.category, required this.emoji});
}

/// Service to fetch and analyze social posts
class SocialSentimentService {
  // Your existing Twitter Bearer Token
  static const String twitterBearerToken = 'AAAAAAAAAAAAAAAAAAAAADf04QEAAAAAkHb9ekFvmN6dyzBD8rWBPT9uHZM%3DymIlN4nY2Kit8VDjQuoDHXKgYQrfWgp2Knvs4ugdlmjKd11n6k';
  
  // Demo data as fallback
  static final List<Map<String, dynamic>> _demoTwitterData = [
    {
      'text': 'Great news about Bangladesh elections! Democracy wins! 🎉 #Bangladesh2025',
      'author_id': 'DhakaYouth',
      'created_at': '2025-09-30T00:00:00Z',
      'public_metrics': {'like_count': 234, 'retweet_count': 67},
    },
    {
      'text': 'Concerned about election irregularities in some areas 😟 #ElectionWatch',
      'author_id': 'BDObserver', 
      'created_at': '2025-09-29T18:00:00Z',
      'public_metrics': {'like_count': 156, 'retweet_count': 43},
    },
    {
      'text': 'New economic policies look promising for growth! 📈 #DigitalBangladesh',
      'author_id': 'EconAnalystBD',
      'created_at': '2025-09-29T12:00:00Z', 
      'public_metrics': {'like_count': 289, 'retweet_count': 78},
    },
    {
      'text': 'Mixed feelings about recent policy changes. Some good reforms 🤔',
      'author_id': 'PolicyWatchBD',
      'created_at': '2025-09-29T08:00:00Z',
      'public_metrics': {'like_count': 87, 'retweet_count': 29},
    },
    {
      'text': 'Disappointed with slow climate action progress 🌍 #ClimateAction',
      'author_id': 'GreenActivistBD',
      'created_at': '2025-09-28T16:00:00Z',
      'public_metrics': {'like_count': 198, 'retweet_count': 67},
    },
  ];

  /// Fetch tweets using YOUR Bearer Token
  static Future<List<SocialPost>> fetchTweets(String keyword, {int maxResults = 30}) async {
    print('🐦 Attempting Twitter API with your Bearer Token...');
    
    final uri = Uri.https(
      'api.twitter.com',
      '/2/tweets/search/recent',
      {
        'query': '$keyword -is:retweet lang:en',
        'max_results': maxResults.toString(),
        'tweet.fields': 'created_at,public_metrics,author_id,context_annotations',
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $twitterBearerToken',
          'User-Agent': 'BangladeshSentimentTracker/1.0',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('🐦 Twitter API Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tweets = (data['data'] ?? []) as List;
        
        if (tweets.isNotEmpty) {
          print('✅ Twitter API Success: ${tweets.length} real tweets');
          
          return tweets.map((tweet) {
            final metrics = tweet['public_metrics'] ?? {};
            return SocialPost(
              content: tweet['text'] ?? '',
              platform: 'Twitter',
              author: tweet['author_id'] ?? 'Unknown',
              createdAt: DateTime.tryParse(tweet['created_at'] ?? '') ?? DateTime.now(),
              likes: metrics['like_count'] ?? 0,
              retweets: metrics['retweet_count'] ?? 0,
            );
          }).toList();
        }
      } else if (response.statusCode == 401) {
        print('❌ Twitter API: Unauthorized - Token may be expired or invalid');
        print('Response: ${response.body}');
      } else if (response.statusCode == 403) {
        print('❌ Twitter API: Forbidden - App may need to be attached to Project');
        print('Response: ${response.body}');
      } else if (response.statusCode == 429) {
        print('❌ Twitter API: Rate limit exceeded');
        print('Response: ${response.body}');
      } else {
        print('❌ Twitter API Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Twitter API Exception: $e');
    }
    
    // Fallback to demo data
    print('📱 Using Twitter demo data as fallback');
    return _demoTwitterData.map((tweet) {
      final metrics = tweet['public_metrics'] ?? {};
      return SocialPost(
        content: tweet['text'] ?? '',
        platform: 'Twitter',
        author: tweet['author_id'] ?? 'Unknown',
        createdAt: DateTime.tryParse(tweet['created_at'] ?? '') ?? DateTime.now(),
        likes: metrics['like_count'] ?? 0,
        retweets: metrics['retweet_count'] ?? 0,
      );
    }).toList();
  }

  /// Test if your Bearer Token is working
  static Future<bool> testTwitterToken() async {
    print('🔍 Testing Twitter Bearer Token...');
    
    final uri = Uri.https('api.twitter.com', '/2/tweets/search/recent', {
      'query': 'hello -is:retweet',
      'max_results': '10',
    });

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $twitterBearerToken',
          'User-Agent': 'TokenTest/1.0',
        },
      ).timeout(const Duration(seconds: 5));

      switch (response.statusCode) {
        case 200:
          print('✅ Twitter Token: WORKING');
          return true;
        case 401:
          print('❌ Twitter Token: EXPIRED or INVALID');
          print('Error: ${response.body}');
          return false;
        case 403:
          print('❌ Twitter Token: FORBIDDEN - Need Project attachment');
          print('Error: ${response.body}');
          return false;
        case 429:
          print('⚠️ Twitter Token: RATE LIMITED but valid');
          return true;
        default:
          print('❌ Twitter Token: ERROR ${response.statusCode}');
          print('Error: ${response.body}');
          return false;
      }
    } catch (e) {
      print('❌ Twitter Token Test Failed: $e');
      return false;
    }
  }

  /// Fetch Reddit data (working endpoints)
  static Future<List<SocialPost>> fetchRedditPosts(String keyword, {int size = 30}) async {
    print('📊 Fetching Reddit data...');
    
    final endpoints = [
      'https://www.reddit.com/r/bangladesh.json?limit=25',
      'https://www.reddit.com/r/southasia.json?limit=25',
      'https://www.reddit.com/r/worldnews.json?limit=25',
    ];
    
    for (final endpoint in endpoints) {
      try {
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {
            'User-Agent': 'SentimentAnalysis/1.0 (Flutter)',
          },
        ).timeout(const Duration(seconds: 8));
        
        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          if (jsonData is Map<String, dynamic> && jsonData['data'] != null) {
            final posts = jsonData['data']['children'] as List<dynamic>? ?? [];
            
            if (posts.isNotEmpty) {
              print('✅ Reddit Success: ${posts.length} posts from ${endpoint.split('/')[4]}');
              
              return posts
                  .map((post) => post['data'] as Map<String, dynamic>)
                  .take(size)
                  .map((data) => SocialPost(
                        content: data['title'] ?? '',
                        platform: 'Reddit',
                        author: data['author'] ?? 'unknown',
                        createdAt: DateTime.fromMillisecondsSinceEpoch(
                          (data['created_utc']?.toInt() ?? 0) * 1000),
                        likes: data['score'] ?? 0,
                        retweets: data['num_comments'] ?? 0,
                      ))
                  .toList();
            }
          }
        }
      } catch (e) {
        print('Reddit endpoint failed: ${endpoint.split('/')[4]} - $e');
        continue;
      }
    }
    
    print('📊 Using Reddit demo data');
    return [
      SocialPost(
        content: 'Excellent voter turnout in Bangladesh elections',
        platform: 'Reddit',
        author: 'election_observer',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        likes: 456,
        retweets: 89,
      ),
      SocialPost(
        content: 'New government policies promise economic growth',
        platform: 'Reddit',
        author: 'policy_analyst',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        likes: 234,
        retweets: 67,
      ),
    ];
  }

  /// Enhanced sentiment analysis
  static SentimentResult analyzeSentiment(String text) {
    text = text.toLowerCase();
    
    final positiveWords = ['good', 'great', 'excellent', 'awesome', 'success', 'love', 'win', 'promising', 'democracy', '🎉', '📈', '✨'];
    final negativeWords = ['bad', 'hate', 'problem', 'fail', 'disappointed', 'concerned', 'irregularities', '😟', '😞', '🤔'];
    
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (String word in positiveWords) {
      if (text.contains(word)) positiveCount++;
    }
    
    for (String word in negativeWords) {
      if (text.contains(word)) negativeCount++;
    }
    
    if (positiveCount > negativeCount) {
      return SentimentResult(category: 'Positive', emoji: '😊');
    } else if (negativeCount > positiveCount) {
      return SentimentResult(category: 'Negative', emoji: '😞');
    } else {
      return SentimentResult(category: 'Neutral', emoji: '😐');
    }
  }

  /// Main aggregation function with token testing
  static Future<Map<String, dynamic>> aggregateSentimentData({
    required String query,
    int limit = 30,
  }) async {
    print('🚀 Starting sentiment analysis for: "$query"');
    
    // Test Twitter token first
    final tokenWorks = await testTwitterToken();
    
    final tweets = await fetchTweets(query, maxResults: limit);
    final reddit = await fetchRedditPosts(query, size: limit);
    final posts = [...tweets, ...reddit];
    final sentiments = posts.map((p) => analyzeSentiment(p.content)).toList();

    final totalPosts = posts.length;
    final sentimentCounts = <String, int>{};
    
    for (var s in sentiments) {
      sentimentCounts[s.category] = (sentimentCounts[s.category] ?? 0) + 1;
    }

    String overallSentiment = 'Neutral';
    if (sentimentCounts['Positive'] != null && sentimentCounts['Positive']! > (totalPosts / 2)) {
      overallSentiment = 'Positive';
    } else if (sentimentCounts['Negative'] != null && sentimentCounts['Negative']! > (totalPosts / 2)) {
      overallSentiment = 'Negative';
    }

    final positiveScore = (sentimentCounts['Positive'] ?? 0) * 1;
    final negativeScore = (sentimentCounts['Negative'] ?? 0) * -1;
    final neutralScore = (sentimentCounts['Neutral'] ?? 0) * 0;
    final totalScore = positiveScore + negativeScore + neutralScore;
    
    final averageScore = totalPosts > 0 ? totalScore.toDouble() / totalPosts : 0.0;

    final platformBreakdown = <String, int>{};
    for (var p in posts) {
      platformBreakdown[p.platform] = (platformBreakdown[p.platform] ?? 0) + 1;
    }

    print('✅ Analysis complete: ${sentimentCounts.toString()}');
    print('🐦 Twitter Token Status: ${tokenWorks ? "WORKING" : "NOT WORKING"}');

    return {
      'posts': posts,
      'sentiments': sentiments,
      'totalPosts': totalPosts,
      'overallSentiment': overallSentiment,
      'averageScore': averageScore,
      'sentimentBreakdown': sentimentCounts,
      'platformBreakdown': platformBreakdown,
      'timestamp': DateTime.now(),
      'twitterTokenWorking': tokenWorks,
    };
  }

  /// Trending topics
  static Future<List<Map<String, dynamic>>> getTrendingSentiments() async {
    return [
      {'topic': 'bangladesh election', 'sentiment': 'Positive', 'score': 0.7, 'posts': 42},
      {'topic': 'civic engagement', 'sentiment': 'Neutral', 'score': 0.0, 'posts': 30},
      {'topic': 'government policy', 'sentiment': 'Negative', 'score': -0.3, 'posts': 25},
      {'topic': 'economic growth', 'sentiment': 'Positive', 'score': 0.5, 'posts': 38},
      {'topic': 'political reform', 'sentiment': 'Neutral', 'score': 0.1, 'posts': 28},
    ];
  }
}