

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

import 'package:latlong2/latlong.dart';
import 'package:tst/models/rumor_analysis.dart';
import 'package:tst/services/rumor_detection_service.dart';

class CivicDashboardScreen extends StatefulWidget {
  @override
  _CivicDashboardScreenState createState() => _CivicDashboardScreenState();
}

class _CivicDashboardScreenState extends State<CivicDashboardScreen>
    with SingleTickerProviderStateMixin {
  MapController mapController = MapController();
  List<Marker> markers = [];
  List<AnalyzedNewsItem> rumorData = [];
  Map<String, int> regionStats = {};
  Map<String, double> sentimentStats = {};
  bool isLoading = true;
  late TabController _tabController;
  
  // Dhaka districts for demo - you can expand this
  final List<Map<String, dynamic>> dhakaRegions = [
    {'name': 'Dhanmondi', 'lat': 23.7461, 'lng': 90.3742},
    {'name': 'Gulshan', 'lat': 23.7925, 'lng': 90.4078},
    {'name': 'Uttara', 'lat': 23.8759, 'lng': 90.3795},
    {'name': 'Old Dhaka', 'lat': 23.7104, 'lng': 90.4074},
    {'name': 'Tejgaon', 'lat': 23.7636, 'lng': 90.3928},
    {'name': 'Motijheel', 'lat': 23.7337, 'lng': 90.4173},
    {'name': 'Ramna', 'lat': 23.7381, 'lng': 90.3967},
    {'name': 'Wari', 'lat': 23.7154, 'lng': 90.4265},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadDashboardData() async {
    setState(() => isLoading = true);
    
    try {
      // Get analyzed news data from your existing service
      Map<String, List<AnalyzedNewsItem>> analyzedNews = 
          await RumorDetectionService.getAnalyzedNews();
      
      // Extract rumor data
      rumorData = analyzedNews['rumor'] ?? [];
      
      // Simulate geographic distribution for rumors
      await _simulateGeographicData();
      
      // Get sentiment data
      await _loadSentimentData();
      
      setState(() => isLoading = false);
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _simulateGeographicData() async {
    // Simulate rumor distribution across Dhaka regions
    Map<String, int> tempStats = {};
    List<Marker> tempMarkers = [];
    
    for (int i = 0; i < rumorData.length && i < 20; i++) {
      // Randomly assign rumors to regions (in real app, you'd geocode or have location data)
      final region = dhakaRegions[math.Random().nextInt(dhakaRegions.length)];
      final regionName = region['name'] as String;
      
      tempStats[regionName] = (tempStats[regionName] ?? 0) + 1;
      
      // Add some random offset to avoid overlapping markers
      double lat = region['lat'] + (math.Random().nextDouble() - 0.5) * 0.01;
      double lng = region['lng'] + (math.Random().nextDouble() - 0.5) * 0.01;
      
      tempMarkers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showRumorDetails(rumorData[i]),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.warning,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }
    
    // Add region center markers with cluster indicators
    for (String region in tempStats.keys) {
      final regionData = dhakaRegions.firstWhere((r) => r['name'] == region);
      final count = tempStats[region]!;
      
      tempMarkers.add(
        Marker(
          point: LatLng(regionData['lat'], regionData['lng']),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => _showHotspotDetails(region, count),
            child: Container(
              decoration: BoxDecoration(
                color: _getHotspotColor(count),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    setState(() {
      regionStats = tempStats;
      markers = tempMarkers;
    });
  }

  Future<void> _loadSentimentData() async {
    // Simulate sentiment data - integrate with your SocialSentimentService
    Map<String, double> tempSentiment = {};
    for (String region in dhakaRegions.map((r) => r['name'])) {
      // Random sentiment between -1 and 1
      tempSentiment[region] = (math.Random().nextDouble() * 2) - 1;
    }
    
    setState(() {
      sentimentStats = tempSentiment;
    });
  }

  void _showHotspotDetails(String region, int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: _getHotspotColor(count)),
            SizedBox(width: 8),
            Text('$region Hotspot'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Region: $region', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Active Rumors: $count'),
            Text('Threat Level: ${_getThreatLevel(count)}'),
            SizedBox(height: 12),
            Text('Recent Activity:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...rumorData.take(3).map((rumor) => Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                '• ${rumor.title.length > 40 ? rumor.title.substring(0, 40) + "..." : rumor.title}',
                style: TextStyle(fontSize: 12),
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Focus map on this region
              mapController.move(
                LatLng(
                  dhakaRegions.firstWhere((r) => r['name'] == region)['lat'],
                  dhakaRegions.firstWhere((r) => r['name'] == region)['lng'],
                ),
                14.0,
              );
              _tabController.animateTo(0); // Switch to map view
            },
            child: Text('View on Map'),
          ),
        ],
      ),
    );
  }

  void _showRumorDetails(AnalyzedNewsItem rumor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 5,
              margin: EdgeInsets.only(bottom: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text('RUMOR DETECTED', style: TextStyle(
                        color: Colors.red, 
                        fontWeight: FontWeight.bold,
                        fontSize: 12
                      )),
                    ],
                  ),
                ),
                Spacer(),
                Text('${rumor.trustScore}% Trust Score', 
                     style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rumor.title,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    if (rumor.description.isNotEmpty)
                      Text(
                        rumor.description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    SizedBox(height: 16),
                    if (rumor.rumorAnalysis != null) ...[
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Analysis Results:', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text('Classification: ${rumor.rumorAnalysis!.classification.toUpperCase()}'),
                            Text('Confidence: ${(rumor.rumorAnalysis!.confidence * 100).round()}%'),
                            if (rumor.rumorAnalysis!.keywords.isNotEmpty)
                              Text('Keywords: ${rumor.rumorAnalysis!.keywords.join(", ")}'),
                            SizedBox(height: 8),
                            Text('Reasoning: ${rumor.rumorAnalysis!.reasoning}',
                                 style: TextStyle(fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.fact_check),
                    label: Text('Mark as Verified'),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Marked for manual verification'))
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.share),
                    label: Text('Share Alert'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading 
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading civic dashboard...'),
              ],
            ))
          : Column(
              children: [
                // Header with stats
                Container(
                  padding: EdgeInsets.fromLTRB(16, 40, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[700]!, Colors.blue[500]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Civic Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.refresh, color: Colors.white),
                            onPressed: loadDashboardData,
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Active Rumors',
                              '${rumorData.length}',
                              Icons.warning,
                              Colors.red,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Hotspot Areas',
                              '${regionStats.length}',
                              Icons.location_on,
                              Colors.orange,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Avg Sentiment',
                              _getAverageSentimentEmoji(),
                              Icons.sentiment_satisfied,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Tab bar
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(icon: Icon(Icons.map), text: 'Map View'),
                    Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
                  ],
                ),
                
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMapView(),
                      _buildAnalyticsView(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: LatLng(23.8103, 90.4125), // Dhaka center
        initialZoom: 11.0,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // OpenStreetMap tile layer - FREE!
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.tst',
          maxZoom: 18,
        ),
        
        // Marker cluster layer for better performance
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 45,
            size: Size(40, 40),
            alignment: Alignment.center,
            padding: EdgeInsets.all(50),
            maxZoom: 15,
            markers: markers,
            builder: (context, markers) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.blue,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    markers.length.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rumor Hotspots by Region',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ...regionStats.entries.map((entry) => Card(
            margin: EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getHotspotColor(entry.value),
                child: Text('${entry.value}', style: TextStyle(color: Colors.white)),
              ),
              title: Text(entry.key),
              subtitle: Text('${entry.value} rumors detected'),
              trailing: _getHotspotIcon(entry.value),
              onTap: () => _showHotspotDetails(entry.key, entry.value),
            ),
          )),
          
          SizedBox(height: 24),
          Text(
            'Regional Sentiment Analysis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ...sentimentStats.entries.map((entry) => Card(
            margin: EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getSentimentColor(entry.value),
                child: Text(_getSentimentEmoji(entry.value)),
              ),
              title: Text(entry.key),
              subtitle: Text(_getSentimentDescription(entry.value)),
              trailing: Text(
                '${(entry.value * 100).round()}%',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          )),
          
          SizedBox(height: 24),
          Text(
            'Recent Rumor Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ...rumorData.take(5).map((rumor) => Card(
            margin: EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(Icons.warning, color: Colors.red),
              title: Text(
                rumor.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('Trust Score: ${rumor.trustScore}%'),
              onTap: () => _showRumorDetails(rumor),
            ),
          )),
        ],
      ),
    );
  }

  Color _getHotspotColor(int count) {
    if (count > 3) return Colors.red;
    if (count > 1) return Colors.orange;
    return Colors.yellow[700]!;
  }

  String _getThreatLevel(int count) {
    if (count > 3) return 'HIGH';
    if (count > 1) return 'MODERATE';
    return 'LOW';
  }

  Icon _getHotspotIcon(int count) {
    if (count > 3) return Icon(Icons.whatshot, color: Colors.red);
    if (count > 1) return Icon(Icons.warning, color: Colors.orange);
    return Icon(Icons.info, color: Colors.yellow[700]);
  }

  Color _getSentimentColor(double sentiment) {
    if (sentiment > 0.3) return Colors.green;
    if (sentiment < -0.3) return Colors.red;
    return Colors.orange;
  }

  String _getSentimentEmoji(double sentiment) {
    if (sentiment > 0.3) return '😊';
    if (sentiment < -0.3) return '😟';
    return '😐';
  }

  String _getSentimentDescription(double sentiment) {
    if (sentiment > 0.3) return 'Positive sentiment';
    if (sentiment < -0.3) return 'Negative sentiment';
    return 'Neutral sentiment';
  }

  String _getAverageSentimentEmoji() {
    if (sentimentStats.isEmpty) return '😐';
    double avg = sentimentStats.values.reduce((a, b) => a + b) / sentimentStats.length;
    return _getSentimentEmoji(avg);
  }
}
