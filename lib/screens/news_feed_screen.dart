import 'package:flutter/material.dart';
import 'package:misinformation_and_civic_sentiment/services/news_service.dart';
import 'package:url_launcher/url_launcher.dart';


class NewsFeedScreen extends StatefulWidget {
  @override
  _NewsFeedScreenState createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  List<NewsItem> newsItems = [];
  bool isLoading = true;
  String? errorMessage;
  
  @override
  void initState() {
    super.initState();
    loadNews();
  }
  
  Future<void> loadNews() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      final news = await RSSFeedService.aggregateNews();
      setState(() {
        newsItems = news;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load news: $e';
      });
    }
  }
  
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bangladesh News Feed'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadNews,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
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
              onPressed: loadNews,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (newsItems.isEmpty) {
      return const Center(
        child: Text('No news items found', style: TextStyle(fontSize: 16)),
      );
    }
    
    return RefreshIndicator(
      onRefresh: loadNews,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: newsItems.length,
        itemBuilder: (context, index) {
          final item = newsItems[index];
          return NewsCard(
            newsItem: item,
            onTap: () => _launchUrl(item.link),
          );
        },
      ),
    );
  }
}

class NewsCard extends StatelessWidget {
  final NewsItem newsItem;
  final VoidCallback onTap;
  
  const NewsCard({
    Key? key,
    required this.newsItem,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSourceColor(newsItem.source),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      newsItem.source,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(newsItem.pubDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Title
              Text(
                newsItem.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              if (newsItem.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _cleanDescription(newsItem.description),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Read more',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getSourceColor(String source) {
    switch (source) {
      case 'Prothom Alo':
        return Colors.red;
      case 'Prothom Alo EN':
        return Colors.redAccent;
      case 'Daily Star':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  
  String _cleanDescription(String description) {
    // Remove HTML tags and decode entities
    return description
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }
}