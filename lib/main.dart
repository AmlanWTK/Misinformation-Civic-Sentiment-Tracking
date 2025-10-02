import 'package:flutter/material.dart';
import 'package:tst/screens/enhanced_news_feed_screen.dart';

import 'package:tst/screens/news_feed_screen.dart';
import 'package:tst/screens/sms_monitor_screen.dart';
import 'package:tst/screens/social_sentiment_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Misinformation Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    EnhancedNewsFeedScreen(),
    SocialSentimentScreen(),
    SmsMonitorScreen()
  ];
  
  final List<String> _titles = [
    'News & Rumors',
    'Social Sentiment',
    'SMS Opt-In',

  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper),
            label: 'News Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sentiment_satisfied),
            label: 'Sentiment',
          ),
           BottomNavigationBarItem(
            icon: Icon(Icons.sentiment_satisfied),
            label:  'SMS Opt-In',
          ),
        ],
      ),
    );
  }
}