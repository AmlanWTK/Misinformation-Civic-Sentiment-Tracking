// lib/services/sms_keyword_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:another_telephony/telephony.dart' as at;

/// Your internal model (renamed to avoid collisions)
class ParsedSmsMessage {
  final String id;
  final String sender;
  final String body;
  final DateTime date;
  final bool containsKeyword;
  final List<String> matchedKeywords;

  ParsedSmsMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.date,
    required this.containsKeyword,
    required this.matchedKeywords,
  });
}

class SmsKeywordService {
  static const List<String> DEFAULT_KEYWORDS = [
    'alert',
    'emergency',
    'urgent',
    'breaking',
    'news',
    'election',
    'vote',
    'voting',
    'corruption',
    'protest',
    'government',
    'politics',
    'crisis',
    'flood',
    'cyclone',
    'weather',
    'disaster',
  ];

  static List<String> _customKeywords = [];
  static final List<ParsedSmsMessage> _filteredMessages = [];
  static StreamController<ParsedSmsMessage>? _messageStreamController;
  static final at.Telephony _telephony = at.Telephony.instance;
  static bool _isListening = false;

  /// Initialize: request permission, load last messages, start listener
  static Future<bool> initialize() async {
    try {
      final smsStatus = await Permission.sms.status;
      if (!smsStatus.isGranted) {
        final result = await Permission.sms.request();
        if (!result.isGranted) {
          debugPrint('SMS permission denied by user');
          return false;
        }
      }

      // Load last 10 messages (inbox)
      await _loadRecentMessages();

      // Start listener for new incoming messages
      await _startMessageListener();

      return true;
    } catch (e) {
      debugPrint('Error initializing SMS service: $e');
      _createDemoMessages(); // fallback for demo/testing
      return true;
    }
  }

  /// Load last 10 inbox messages.
  /// NOTE: we avoid relying on a specific typed package class — we use the runtime object.
  static Future<void> _loadRecentMessages() async {
    try {
      debugPrint('Loading recent inbox SMS (last 10)...');

      // Many telephony implementations expose getInboxSms() which returns a List of package message objects.
      // Keep it untyped so the code compiles regardless of exact package type.
      final messages = await _telephony.getInboxSms();

      if (messages == null) {
        debugPrint('No messages returned from telephony.getInboxSms()');
        return;
      }

      _filteredMessages.clear();

      // iterate last -> newest: messages list ordering may vary, so take last 10 safely
      final iterable = messages.length <= 10
          ? messages
          : messages.reversed.take(10).toList().reversed.toList();

      for (var rawMsg in iterable) {
        final parsed = _processTelephonyMessage(rawMsg);
        if (parsed.containsKeyword) {
          _filteredMessages.add(parsed);
        }
      }

      debugPrint('Loaded ${_filteredMessages.length} keyword-matching messages from inbox');
    } catch (e) {
      debugPrint('Error loading recent messages: $e');
      _createDemoMessages();
    }
  }

  /// Start listening for incoming SMS (real-time)
  static Future<void> _startMessageListener() async {
    if (_isListening) return;
    _isListening = true;
    _messageStreamController ??= StreamController<ParsedSmsMessage>.broadcast();

    try {
      // Listen callback: do not annotate parameter with a package-specific type.
      _telephony.listenIncomingSms(
        onNewMessage: (message) {
          // message type is inferred at runtime; we treat it dynamically.
          final parsed = _processTelephonyMessage(message);
          if (parsed.containsKeyword) {
            _filteredMessages.insert(0, parsed);
            _messageStreamController?.add(parsed);
            debugPrint('Keyword match from incoming SMS: ${parsed.matchedKeywords.join(", ")}');
          }
        },
        listenInBackground: false,
      );

      debugPrint('SMS listener started.');
    } catch (e) {
      debugPrint('Failed to start SMS listener: $e');
      _isListening = false;
      // optional: start simulation fallback
      _startPeriodicSimulation();
    }
  }

  /// Convert a raw package message (dynamic) into your ParsedSmsMessage model.
  static ParsedSmsMessage _processTelephonyMessage(dynamic sms) {
    // Safely extract fields with fallbacks & conversions
    final body = (sms?.body ?? sms?.message ?? '').toString();
    final sender = (sms?.address ?? sms?.sender ?? 'Unknown').toString();

    // date: package may supply 'date' as int (ms) or 'timestamp' or null
    DateTime dateTime = DateTime.now();
    try {
      if (sms != null) {
        final rawDate = sms.date ?? sms.timestamp ?? sms.time ?? sms?.receivedDate;
        if (rawDate != null) {
          if (rawDate is int) {
            dateTime = DateTime.fromMillisecondsSinceEpoch(rawDate);
          } else if (rawDate is String) {
            final parsed = int.tryParse(rawDate);
            if (parsed != null) dateTime = DateTime.fromMillisecondsSinceEpoch(parsed);
          }
        }
      }
    } catch (_) {
      dateTime = DateTime.now();
    }

    final matched = _findKeywords(body);

    return ParsedSmsMessage(
      id: (sms?.id?.toString()) ?? DateTime.now().millisecondsSinceEpoch.toString(),
      sender: sender,
      body: body,
      date: dateTime,
      containsKeyword: matched.isNotEmpty,
      matchedKeywords: matched,
    );
  }

  /// Basic demo fallback messages for testing
  static void _createDemoMessages() {
    final demo = [
      {
        'sender': '+8801712345678',
        'body': 'ALERT: Flood in Dhaka. Evacuate!',
        'date': DateTime.now().subtract(Duration(minutes: 10)),
      },
      {
        'sender': '+8801812345679',
        'body': 'Election update: votes counting.',
        'date': DateTime.now().subtract(Duration(hours: 1)),
      },
    ];

    _filteredMessages.clear();
    for (int i = 0; i < demo.length; i++) {
      final d = demo[i];
      final matched = _findKeywords(d['body'] as String);
      _filteredMessages.add(ParsedSmsMessage(
        id: 'demo_$i',
        sender: d['sender'] as String,
        body: d['body'] as String,
        date: d['date'] as DateTime,
        containsKeyword: matched.isNotEmpty,
        matchedKeywords: matched,
      ));
    }
  }

  static void _startPeriodicSimulation() {
    Timer.periodic(Duration(seconds: 30), (t) {
      _simulateNewMessage();
    });
  }
  // Add this to SmsKeywordService

/// Simulate a new incoming message for demo/testing
static void simulateIncomingMessage(String sender, String body) {
  final matched = _findKeywords(body);
  final msg = ParsedSmsMessage(
    id: 'sim_${DateTime.now().millisecondsSinceEpoch}',
    sender: sender,
    body: body,
    date: DateTime.now(),
    containsKeyword: matched.isNotEmpty,
    matchedKeywords: matched,
  );
  _filteredMessages.insert(0, msg);
  _messageStreamController?.add(msg);
}

static void addCustomKeyword(String keyword) {
    if (!_customKeywords.contains(keyword.toLowerCase())) {
      _customKeywords.add(keyword.toLowerCase());
    }
  }

  
  /// Remove a custom keyword
  static void removeCustomKeyword(String keyword) {
    _customKeywords.remove(keyword.toLowerCase());
  }

  static void _simulateNewMessage() {
    final items = [
      'ALERT: New emergency in your area',
      'Breaking: heavy rains expected tomorrow',
      'Info: community meeting at 6pm',
    ];
    final msg = items[DateTime.now().second % items.length];
    final matched = _findKeywords(msg);
    if (matched.isNotEmpty) {
      final parsed = ParsedSmsMessage(
        id: 'sim_${DateTime.now().millisecondsSinceEpoch}',
        sender: '+880170000000',
        body: msg,
        date: DateTime.now(),
        containsKeyword: true,
        matchedKeywords: matched,
      );
      _filteredMessages.insert(0, parsed);
      _messageStreamController?.add(parsed);
    }
  }

  /// return list of matching keywords found in text
  static List<String> _findKeywords(String text) {
    final all = [...DEFAULT_KEYWORDS, ..._customKeywords];
    final lower = text.toLowerCase();
    return all.where((k) => lower.contains(k.toLowerCase())).toList();
  }

  // Public helpers
  static List<ParsedSmsMessage> getFilteredMessages() => List.unmodifiable(_filteredMessages);
  static Stream<ParsedSmsMessage>? getMessageStream() => _messageStreamController?.stream;
  static Future<PermissionStatus> getPermissionStatus() => Permission.sms.status;
  static void dispose() {
    _messageStreamController?.close();
    _messageStreamController = null;
    _isListening = false;
  }
}
