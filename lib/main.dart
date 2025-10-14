import 'package:flutter/material.dart';
import 'package:misinformation_and_civic_sentiment/screens/news_feed_screen.dart';


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
      home: NewsFeedScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}