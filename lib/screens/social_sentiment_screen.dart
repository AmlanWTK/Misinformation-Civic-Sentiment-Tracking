import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tst/services/social_sentiment_service.dart';


class SocialSentimentScreen extends StatefulWidget {
  @override
  _SocialSentimentScreenState createState() => _SocialSentimentScreenState();
}

class _SocialSentimentScreenState extends State<SocialSentimentScreen> 
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? sentimentData;
  List<Map<String, dynamic>> trendingTopics = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedQuery = 'bangladesh election';
  late TabController _tabController;
  
  final List<String> predefinedQueries = [
    'bangladesh election',
    'government policy', 
    'economic growth',
    'political reform',
    'civic engagement'
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadSentimentData();
    loadTrendingData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> loadSentimentData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      final data = await SocialSentimentService.aggregateSentimentData(
        query: selectedQuery,
        limit: 30,
      );
      setState(() {
        sentimentData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load sentiment data: $e';
      });
    }
  }
  
  Future<void> loadTrendingData() async {
    try {
      final trends = await SocialSentimentService.getTrendingSentiments();
      setState(() {
        trendingTopics = trends;
      });
    } catch (e) {
      print('Failed to load trending data: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Sentiment Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,


        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.search),
            onSelected: (value) {
              setState(() {
                selectedQuery = value;
              });
              loadSentimentData();
            },
            itemBuilder: (context) => predefinedQueries
                .map((query) => PopupMenuItem(
                      value: query,
                      child: Text(query),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              loadSentimentData();
              loadTrendingData();
            },
          ),
        ],


        
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Posts', icon: Icon(Icons.message)),
            Tab(text: 'Trends', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPostsTab(),
          _buildTrendsTab(),
        ],
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadSentimentData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (sentimentData == null) {
      return const Center(child: Text('No data available'));
    }
    
    return RefreshIndicator(
      onRefresh: loadSentimentData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildSentimentChart(),
            const SizedBox(height: 16),
            _buildPlatformChart(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard() {
    final data = sentimentData!;
    final overallSentiment = data['overallSentiment'] as String;
final averageScore = (data['averageScore'] ?? 0).toDouble();
final totalPosts = (data['totalPosts'] ?? 0).toInt();

    
    final sentimentColor = _getSentimentColor(overallSentiment);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Query: "$selectedQuery"',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(
                  'Overall Sentiment',
                  overallSentiment,
                  sentimentColor,
                  _getSentimentEmoji(overallSentiment),
                ),
                _buildMetricItem(
                  'Average Score',
                  averageScore.toStringAsFixed(2),
                  sentimentColor,
                  '📊',
                ),
                _buildMetricItem(
                  'Total Posts',
                  totalPosts.toString(),
                  Colors.blue,
                  '📝',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricItem(String label, String value, Color color, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildSentimentChart() {
    final sentimentBreakdown = 
        sentimentData!['sentimentBreakdown'] as Map<String, int>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sentiment Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sentimentBreakdown.entries.map((entry) {
                    final color = _getSentimentColor(entry.key);
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${entry.key}\n${entry.value}',
                      color: color,
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlatformChart() {
    final platformBreakdown = 
        sentimentData!['platformBreakdown'] as Map<String, int>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Platform Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: platformBreakdown.entries.map((entry) {
                    final index = platformBreakdown.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: index == 0 ? Colors.blue : Colors.orange,
                          width: 40,
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final platforms = platformBreakdown.keys.toList();
                          if (value.toInt() < platforms.length) {
                            return Text(platforms[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPostsTab() {
    if (sentimentData == null) {
      return const Center(child: Text('No posts available'));
    }
    
    final posts = sentimentData!['posts'] as List<SocialPost>;
    final sentiments = sentimentData!['sentiments'] as List<SentimentResult>;
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final sentiment = sentiments[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: post.platform == 'Twitter' ? Colors.blue : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        post.platform,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(sentiment.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getSentimentColor(sentiment.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sentiment.category,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getSentimentColor(sentiment.category),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  post.content,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '@${post.author}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    if (post.location != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.location_on, size: 12, color: Colors.grey),
                      Text(
                        post.location!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      '${post.likes} ❤️',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${post.retweets} 🔁',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTrendsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trendingTopics.length,
      itemBuilder: (context, index) {
        final trend = trendingTopics[index];
        final topic = trend['topic'] as String;
        final sentiment = trend['sentiment'] as String;
        final score = trend['score'] as double;
        final posts = trend['posts'] as int;
        
        return Card(
          child: ListTile(
            leading: Text(
              _getSentimentEmoji(sentiment),
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(
              topic.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '$sentiment (Score: ${score.toStringAsFixed(2)})',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  posts.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text('posts', style: TextStyle(fontSize: 10)),
              ],
            ),
            onTap: () {
              setState(() {
                selectedQuery = topic;
                _tabController.animateTo(0);
              });
              loadSentimentData();
            },
          ),
        );
      },
    );
  }
  
  Color _getSentimentColor(String sentiment) {
    switch (sentiment) {
      case 'Very Positive': return Colors.green[700]!;
      case 'Positive': return Colors.green;
      case 'Neutral': return Colors.grey;
      case 'Negative': return Colors.orange;
      case 'Very Negative': return Colors.red;
      default: return Colors.grey;
    }
  }
  
  String _getSentimentEmoji(String sentiment) {
    switch (sentiment) {
      case 'Very Positive': return '😍';
      case 'Positive': return '😊';
      case 'Neutral': return '😐';
      case 'Negative': return '😞';
      case 'Very Negative': return '😡';
      default: return '😐';
    }
  }
}