import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class NewsItem {
  final String title;
  final String description;
  final String link;
  final DateTime pubDate;
  final String? imageUrl;
  final String source;
  
  NewsItem({
    required this.title,
    required this.description,
    required this.link,
    required this.pubDate,
    this.imageUrl,
    required this.source,
  });
  
  factory NewsItem.fromXml(XmlElement item, String source) {
    return NewsItem(
      title: _getText(item, 'title'),
      description: _getText(item, 'description'),
      link: _getText(item, 'link'),
      pubDate: _parseDate(_getText(item, 'pubDate')),
      imageUrl: _extractImageUrl(item),
      source: source,
    );
  }
  
  static String _getText(XmlElement item, String tagName) {
    try {
      return item.findElements(tagName).first.text;
    } catch (e) {
      return '';
    }
  }
  
  static DateTime _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime.now();
    }
  }
  
  static String? _extractImageUrl(XmlElement item) {
    try {
      // Try media:content first
      final mediaContent = item.findElements('media:content');
      if (mediaContent.isNotEmpty) {
        return mediaContent.first.getAttribute('url');
      }
      
      // Try enclosure
      final enclosure = item.findElements('enclosure');
      if (enclosure.isNotEmpty) {
        final type = enclosure.first.getAttribute('type') ?? '';
        if (type.startsWith('image/')) {
          return enclosure.first.getAttribute('url');
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
}

class RSSFeedService {
  // Updated RSS feeds with working URLs
  static const Map<String, String> bangladeshiFeeds = {
    'https://banglatribune.com/feed': 'Bangla Tribune',
    'https://bd24live.com/bangla/feed': 'BD24Live',
    'https://risingbd.com/rss/rss.xml': 'RisingBD',
    'https://newsindex.fahadahammed.com/feed/get_feed_data/thedailystar/feed.xml': 'Daily Star',
    'https://prod-qt-images.s3.amazonaws.com/production/prothomalo-bangla/feed.xml': 'Prothom Alo',
  };
  
  static Future<List<NewsItem>> fetchRSSFeed(String url, String source) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'application/rss+xml, application/xml, text/xml',
          'Accept-Language': 'en-US,en;q=0.9',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');
        
        return items
            .map((item) => NewsItem.fromXml(item, source))
            .where((item) => item.title.isNotEmpty && item.link.isNotEmpty)
            .toList();
      }
      throw Exception('HTTP ${response.statusCode}: Failed to load RSS feed');
    } catch (e) {
      print('Error fetching RSS from $url: $e');
      return [];
    }
  }
  
  static Future<List<NewsItem>> aggregateNews() async {
    List<NewsItem> allNews = [];
    
    // Process feeds concurrently for better performance
    final futures = bangladeshiFeeds.entries.map((entry) => 
        fetchRSSFeed(entry.key, entry.value));
    
    final results = await Future.wait(futures);
    
    for (final feedItems in results) {
      allNews.addAll(feedItems);
    }
    
    // Sort by publication date (newest first)
    allNews.sort((a, b) => b.pubDate.compareTo(a.pubDate));
    
    // Remove duplicates based on title
    final uniqueNews = <String, NewsItem>{};
    for (final item in allNews) {
      final titleKey = item.title.toLowerCase().trim();
      if (!uniqueNews.containsKey(titleKey)) {
        uniqueNews[titleKey] = item;
      }
    }
    
    return uniqueNews.values.toList();
  }
}