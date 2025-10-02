# Misinformation & Civic Sentiment Tracking

A comprehensive Flutter mobile application designed to monitor, analyze, and track misinformation and civic sentiment across multiple data sources in Bangladesh. This app integrates advanced machine learning for fake news detection with real-time sentiment analysis and SMS monitoring capabilities.

## 🌟 Features

### 🔍 **Enhanced News Feed with AI-Powered Rumor Detection**
- **Multi-source RSS aggregation** from major Bangladeshi news outlets
- **Real-time fake news detection** using trained Bengali Naive Bayes ML model
- **Three-tier categorization**: Verified News, General News, and Flagged Content
- **Visual confidence indicators** with trust scores and emoji-based classification
- **Keyword extraction** and reasoning display for transparency
- **Source verification** with color-coded source indicators

### 📊 **Social Sentiment Analysis Dashboard**
- **Multi-platform sentiment tracking** across social media channels
- **Interactive data visualizations** using FL Chart library
- **Customizable query monitoring** for civic and political topics
- **Real-time sentiment categorization**: Very Positive, Positive, Neutral, Negative, Very Negative
- **Platform-wise breakdown** showing Twitter, Reddit, and other social sources
- **Trending topics discovery** with sentiment scoring
- **Historical sentiment tracking** and trend analysis

### 📱 **SMS Keyword Monitoring System**
- **Opt-in SMS monitoring** with user consent and privacy protection
- **Real-time keyword detection** for emergency and civic-related messages
- **Customizable keyword management** with default and user-defined terms
- **Message highlighting** with matched keyword visualization
- **Permission-based access** with proper Android SMS permissions
- **Demo mode** for testing and development purposes

### 🤖 **Machine Learning Integration**
- **Custom Bengali Naive Bayes model** trained specifically for Bengali fake news detection
- **Python training pipeline** with model export for Flutter integration
- **TF-IDF vectorization** for text feature extraction
- **Model inference** running entirely on-device for privacy
- **Confidence scoring** and probability distribution analysis
- **Fallback analysis** when trained model is unavailable

## 🏗️ Technical Architecture

### **Frontend (Flutter/Dart)**
- **Material Design 3** UI with responsive layouts
- **Bottom navigation** with tab-based interface
- **Real-time data updates** with refresh indicators
- **Custom widgets** for enhanced user experience
- **State management** using StatefulWidget patterns

### **Backend Services**
- **RSS Feed Parser** with XML parsing and UTF-8 support
- **HTTP client** with proper headers and timeout handling
- **Sentiment Analysis Engine** using dart_sentiment package
- **SMS Permission Handler** with Android telephony integration
- **JSON model serialization** for data persistence

### **Data Sources**
- **Bangladeshi News Outlets**: Prothom Alo, Daily Star, Bangla Tribune, BD24Live, RisingBD
- **Social Media APIs**: Twitter/X integration, Reddit monitoring capability
- **SMS Messages**: On-device SMS monitoring with user consent
- **Local Storage**: Efficient caching and offline capability

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.1.0                    # HTTP requests for RSS feeds
  xml: ^6.4.2                     # XML parsing for RSS feeds
  url_launcher: ^6.2.0            # External URL handling
  dart_sentiment: ^0.0.4          # Text sentiment analysis
  fl_chart: ^0.68.0               # Interactive charts and graphs
  permission_handler: ^12.0.1     # Android permissions management
  another_telephony: ^0.4.1       # SMS reading and monitoring

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

## 🚀 Getting Started

### **Prerequisites**
- Flutter SDK (3.7.0 or later)
- Dart SDK
- Android Studio or VS Code with Flutter extensions
- Android device/emulator for SMS functionality testing

### **Installation**

1. **Clone the repository**
   ```bash
   git clone https://github.com/AmlanWTK/Misinformation-Civic-Sentiment-Tracking.git
   cd Misinformation-Civic-Sentiment-Tracking
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Train the ML model (Optional)**
   ```bash
   # Ensure you have your Bengali dataset in CSV format
   python train_naive_bayes.py
   ```

4. **Configure assets**
   ```yaml
   # Add to pubspec.yaml under flutter:
   assets:
     - assets/data/
     - assets/models/  # If using trained ML model
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

## 🧠 Machine Learning Model

### **Training Process**
1. **Dataset**: Bengali fake news detection dataset in CSV format
2. **Preprocessing**: Text cleaning, stopword removal, tokenization
3. **Vectorization**: TF-IDF with 1000 max features
4. **Algorithm**: Multinomial Naive Bayes classifier
5. **Export**: JSON model for Flutter integration

### **Model Performance**
- **Classes**: Rumor, Credible, Neutral
- **Features**: Bengali text processing optimized
- **Inference**: On-device prediction for privacy
- **Fallback**: Rule-based analysis when model unavailable

## 📱 App Screens

### **Main Interface**
- **Bottom Navigation**: Three main sections
- **Tab-based Design**: Easy navigation between features
- **Refresh Indicators**: Pull-to-refresh functionality
- **Loading States**: Proper loading and error handling

### **News & Rumor Detection**
- **Categorized Tabs**: Verified, General, Flagged content
- **Enhanced Cards**: Visual trust indicators and confidence scores
- **Source Badges**: Color-coded news source identification
- **Analysis Details**: ML reasoning and keyword highlighting

### **Social Sentiment**
- **Overview Dashboard**: Pie charts and bar graphs
- **Posts Timeline**: Individual post analysis with sentiment
- **Trending Topics**: Popular topics with sentiment trends
- **Query Management**: Custom search terms and filtering

### **SMS Monitoring**
- **Message List**: Filtered messages with keyword highlighting
- **Keyword Management**: Add/remove custom monitoring terms
- **Status Dashboard**: Permissions, statistics, and service health
- **Privacy Controls**: User consent and data protection

## 🔧 Configuration

### **RSS Feed Sources**
```dart
static const Map bangladeshiFeeds = {
  'https://banglatribune.com/feed': 'Bangla Tribune',
  'https://bd24live.com/bangla/feed': 'BD24Live',
  'https://risingbd.com/rss/rss.xml': 'RisingBD',
  'https://newsindex.fahadahammed.com/feed/get_feed_data/thedailystar/feed.xml': 'Daily Star',
  'https://prod-qt-images.s3.amazonaws.com/production/prothomalo-bangla/feed.xml': 'Prothom Alo',
};
```

### **SMS Keywords**
```dart
static const List<String> DEFAULT_KEYWORDS = [
  'emergency', 'flood', 'fire', 'earthquake', 'election',
  'government', 'protest', 'strike', 'alert', 'urgent'
];
```

### **Sentiment Queries**
```dart
final List<String> predefinedQueries = [
  'bangladesh election',
  'government policy',   
  'economic growth',
  'political reform',
  'civic engagement'
];
```

## 🔒 Privacy & Permissions

### **Android Permissions Required**
- `READ_SMS`: For SMS keyword monitoring (with user consent)
- `INTERNET`: For RSS feed fetching and social media data
- `ACCESS_NETWORK_STATE`: For network connectivity checks

### **Privacy Features**
- **Opt-in SMS monitoring**: Users must explicitly grant permission
- **On-device ML inference**: No data sent to external servers
- **Local data storage**: All analysis performed locally
- **Transparent processing**: Clear indication of data usage

## 🛠️ Development

### **Project Structure**
```
lib/
├── main.dart                    # App entry point
├── models/
│   └── rumor_analysis.dart      # ML analysis models
├── screens/
│   ├── enhanced_news_feed_screen.dart
│   ├── social_sentiment_screen.dart
│   └── sms_monitor_screen.dart
├── services/
│   ├── news_service.dart        # RSS feed handling
│   ├── rumor_detection_service.dart
│   ├── social_sentiment_service.dart
│   ├── sms_keyword_service.dart
│   └── naive_bayes_inference.dart
└── assets/
    ├── data/                    # Training datasets
    └── models/                  # Trained ML models
```

### **Key Service Classes**
- **RSSFeedService**: Multi-source news aggregation
- **RumorDetectionService**: AI-powered fake news detection
- **SocialSentimentService**: Sentiment analysis engine
- **SmsKeywordService**: SMS monitoring and filtering
- **NaiveBayesModel**: On-device ML inference

## 🔄 Data Flow

1. **News Collection**: RSS feeds fetched from multiple Bangladeshi sources
2. **ML Processing**: Each article analyzed by Bengali Naive Bayes model
3. **Categorization**: Content sorted into Verified/General/Flagged buckets
4. **Sentiment Analysis**: Social media content processed for sentiment trends
5. **SMS Monitoring**: Keyword-based filtering of SMS messages (with consent)
6. **Visualization**: Real-time dashboard updates with charts and insights

## 🎯 Use Cases

- **Journalists**: Verify news authenticity and track misinformation
- **Researchers**: Study civic sentiment and information flow patterns
- **Citizens**: Stay informed with verified news and avoid fake information
- **Emergency Response**: Monitor SMS alerts and public sentiment during crises
- **Policy Makers**: Understand public opinion on government policies

## 🚧 Future Enhancements

- **Multi-language Support**: Expand beyond Bengali to other regional languages
- **Advanced ML Models**: Integrate transformer-based models for better accuracy
- **Real-time Notifications**: Push alerts for high-confidence misinformation detection
- **Social Media Integration**: Direct API integration with Twitter, Facebook, etc.
- **Collaborative Filtering**: User reporting and community-based fact-checking
- **Analytics Dashboard**: Detailed reporting and trend analysis tools

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Bengali NLP Research**: Thanks to the Bengali language processing community
- **Flutter Team**: For the excellent cross-platform framework
- **Open Source Libraries**: All the amazing packages that made this possible
- **News Organizations**: Bangladeshi media outlets providing RSS feeds
- **Research Community**: Academic work on misinformation detection

## 📞 Support

For questions, suggestions, or support:
- **GitHub Issues**: [Create an issue](https://github.com/AmlanWTK/Misinformation-Civic-Sentiment-Tracking/issues)
- **Documentation**: Check the code comments and inline documentation
- **Community**: Join discussions in the repository

---

**Built with ❤️ for civic transparency and information integrity in Bangladesh**
