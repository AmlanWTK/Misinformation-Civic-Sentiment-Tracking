import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:tst/services/sms_keyword_service.dart';

class SmsMonitorScreen extends StatefulWidget {
  @override
  _SmsMonitorScreenState createState() => _SmsMonitorScreenState();
}

class _SmsMonitorScreenState extends State<SmsMonitorScreen>
    with SingleTickerProviderStateMixin {
  List<ParsedSmsMessage> messages = [];
  bool isInitialized = false;
  bool isLoading = true;
  String? errorMessage;
  late TabController _tabController;

  final TextEditingController _keywordController = TextEditingController();
  List<String> customKeywords = [];
  Timer? demoTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeSmsService();
    _listenToNewMessages();
    _startDemoSmsTimer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _keywordController.dispose();
    SmsKeywordService.dispose();
    demoTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeSmsService() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final success = await SmsKeywordService.initialize();

      if (success) {
        setState(() {
          isInitialized = true;
          messages = SmsKeywordService.getFilteredMessages();
          isLoading = false;
        });
      } else {
        setState(() {
          isInitialized = false;
          isLoading = false;
          errorMessage =
              'SMS permissions required. Please grant permission to continue.';
        });
      }
    } catch (e) {
      setState(() {
        isInitialized = false;
        isLoading = false;
        errorMessage = 'Failed to initialize SMS service: $e';
      });
    }
  }

  void _listenToNewMessages() {
    final messageStream = SmsKeywordService.getMessageStream();
    messageStream?.listen((newMessage) {
      setState(() {
        messages = SmsKeywordService.getFilteredMessages();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.message, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'New keyword message: ${newMessage.matchedKeywords.join(', ')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  void _startDemoSmsTimer() {
    demoTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _simulateDemoSms();
    });
  }

  void _simulateDemoSms() {
    final demoMessages = [
      'ALERT: Flood in Dhaka. Evacuate immediately!',
      'Breaking news: Election results coming soon.',
      'Urgent: Heavy rain expected tomorrow',
      'Emergency: Road closed due to landslide',
    ];
    final msg =
        demoMessages[DateTime.now().second % demoMessages.length];
    SmsKeywordService.simulateIncomingMessage('+880170000000', msg);
  }

  Future<void> _refreshMessages() async {
    await _initializeSmsService();
  }

  void _addCustomKeyword() {
    final keyword = _keywordController.text.trim();
    if (keyword.isNotEmpty && !customKeywords.contains(keyword.toLowerCase())) {
      setState(() {
        customKeywords.add(keyword.toLowerCase());
      });
      SmsKeywordService.addCustomKeyword(keyword.toLowerCase());
      _keywordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added keyword: "$keyword"'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _removeCustomKeyword(String keyword) {
    setState(() {
      customKeywords.remove(keyword);
    });
    SmsKeywordService.removeCustomKeyword(keyword);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed keyword: "$keyword"'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Keyword Monitor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMessages,
          ),
          IconButton(
            icon: const Icon(Icons.message),
            tooltip: 'Simulate SMS',
            onPressed: _simulateDemoSms,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => openAppSettings(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Messages', icon: Icon(Icons.message)),
            Tab(text: 'Keywords', icon: Icon(Icons.label)),
            Tab(text: 'Status', icon: Icon(Icons.info)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMessagesTab(),
          _buildKeywordsTab(),
          _buildStatusTab(),
        ],
      ),
    );
  }

  Widget _buildMessagesTab() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading SMS messages...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeSmsService,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    if (messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No keyword messages found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Messages containing monitored keywords will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshMessages,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return _buildMessageCard(message);
        },
      ),
    );
  }

  Widget _buildMessageCard(ParsedSmsMessage message) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.phone_android, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    message.sender,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  _formatTime(message.date),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildHighlightedText(message.body, message.matchedKeywords),
            const SizedBox(height: 8),
            if (message.matchedKeywords.isNotEmpty)
              Wrap(
                spacing: 4,
                children: message.matchedKeywords
                    .map(
                      (keyword) => Chip(
                        label: Text(keyword, style: const TextStyle(fontSize: 10)),
                        backgroundColor: Colors.orange[100],
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, List<String> keywords) {
    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    int lastIndex = 0;

    final highlights = <MapEntry<int, int>>[];
    for (final keyword in keywords) {
      final lowerKeyword = keyword.toLowerCase();
      int startIndex = 0;
      while (true) {
        final index = lowerText.indexOf(lowerKeyword, startIndex);
        if (index == -1) break;
        highlights.add(MapEntry(index, index + lowerKeyword.length));
        startIndex = index + 1;
      }
    }
    highlights.sort((a, b) => a.key.compareTo(b.key));

    for (final highlight in highlights) {
      if (highlight.key > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, highlight.key)));
      }
      spans.add(TextSpan(
        text: text.substring(highlight.key, highlight.value),
        style: const TextStyle(
          backgroundColor: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ));
      lastIndex = highlight.value;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        children: spans.isEmpty ? [TextSpan(text: text)] : spans,
      ),
    );
  }

  Widget _buildKeywordsTab() {
    final allKeywords = [...SmsKeywordService.DEFAULT_KEYWORDS, ...customKeywords];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add keyword
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _keywordController,
                  decoration: const InputDecoration(
                    hintText: 'Enter keyword to monitor',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addCustomKeyword(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addCustomKeyword,
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Default Keywords', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: SmsKeywordService.DEFAULT_KEYWORDS
                .map((k) => Chip(label: Text(k), backgroundColor: Colors.blue[100]))
                .toList(),
          ),
          const SizedBox(height: 16),
          const Text('Custom Keywords', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          customKeywords.isEmpty
              ? const Text('No custom keywords added', style: TextStyle(color: Colors.grey))
              : Wrap(
                  spacing: 8,
                  children: customKeywords
                      .map(
                        (keyword) => Chip(
                          label: Text(keyword),
                          backgroundColor: Colors.green[100],
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeCustomKeyword(keyword),
                        ),
                      )
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildStatusTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard('Service Status', isInitialized ? 'Active' : 'Inactive',
              isInitialized ? Icons.check_circle : Icons.error, isInitialized ? Colors.green : Colors.red),
          _buildStatusCard('Messages Monitored', messages.length.toString(), Icons.message, Colors.blue),
          _buildStatusCard('Active Keywords', [...SmsKeywordService.DEFAULT_KEYWORDS, ...customKeywords].length.toString(),
              Icons.label, Colors.orange),
          const SizedBox(height: 24),
          const Text('Permissions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FutureBuilder<PermissionStatus>(
            future: SmsKeywordService.getPermissionStatus(),
            builder: (context, snapshot) {
              final status = snapshot.data;
              return ListTile(
                leading: Icon(Icons.sms, color: status == PermissionStatus.granted ? Colors.green : Colors.red),
                title: const Text('SMS Permission'),
                subtitle: Text(status?.name ?? 'Unknown'),
                trailing: status != PermissionStatus.granted
                    ? ElevatedButton(onPressed: () => openAppSettings(), child: const Text('Grant'))
                    : const Icon(Icons.check, color: Colors.green),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}
