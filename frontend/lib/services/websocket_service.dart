import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

final webSocketServiceProvider = ChangeNotifierProvider<WebSocketService>((ref) {
  return WebSocketService();
});

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _isUsingLocalSimulation = false;
  
  // State variables
  String _transcript = "...";
  String _emotion = "Neutral";
  String _confidence = "0%";
  String _anxiety = "0%";
  String _clarity = "0%";
  String _pace = "N/A";
  String _suggestion = "Ready to analyze...";
  String _improved = "";
  List<String> _coachingTips = [];
  String _personaReply = "";
  int _replyCounter = 0;
  
  String _selectedContext = "Friendship";
  String _selectedPersona = "";
  String _mode = "chat";
  
  bool _isListening = false;
  
  final _supabase = Supabase.instance.client;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;

  WebSocketService() {
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' && _isListening) {
            _speech.listen(onResult: _onSpeechResult);
          }
        },
        onError: (errorNotification) => debugPrint('STT Error: $errorNotification'),
      );
    } catch (e) {
      debugPrint("STT initialization failed: $e");
    }
  }

  // Getters
  String get transcript => _transcript;
  String get emotion => _emotion;
  String get confidence => _confidence;
  String get anxiety => _anxiety;
  String get clarity => _clarity;
  String get pace => _pace;
  String get suggestion => _suggestion;
  String get improved => _improved;
  List<String> get coachingTips => _coachingTips;
  String get personaReply => _personaReply;
  int get replyCounter => _replyCounter;
  bool get isListening => _isListening;
  bool get isConnected => _isConnected;
  bool get isUsingLocalSimulation => _isUsingLocalSimulation;
  
  String get selectedContext => _selectedContext;
  String get selectedPersona => _selectedPersona;
  String get mode => _mode;

  set selectedContext(String val) {
    _selectedContext = val;
    notifyListeners();
  }

  set selectedPersona(String val) {
    _selectedPersona = val;
    notifyListeners();
  }

  set mode(String val) {
    _mode = val;
    notifyListeners();
  }

  void connect() {
    if (_isConnected && !_isUsingLocalSimulation) return;
    _channel?.sink.close();
    _initConnection();
  }

  void _initConnection() {
    try {
      debugPrint("WS: Attempting to connect to ws://127.0.0.1:8000/ws");
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://127.0.0.1:8000/ws'),
      );
      
      _isConnected = true;
      _isUsingLocalSimulation = false;
      _suggestion = "Connected to local server";
      notifyListeners();

      _channel!.stream.listen((message) {
        debugPrint("WS: Received message: $message");
        final data = jsonDecode(message);
        
        _transcript = data['transcript'] ?? _transcript;
        _emotion = data['emotion'] ?? _emotion;
        _confidence = data['confidence'] ?? _confidence;
        _anxiety = data['anxiety'] ?? _anxiety;
        _clarity = data['clarity'] ?? _clarity;
        _pace = data['pace'] ?? _pace;
        _suggestion = data['suggestion'] ?? _suggestion;
        _improved = data['improved'] ?? "";
        
        if (data['coaching_tips'] != null) {
          _coachingTips = List<String>.from(data['coaching_tips']);
        } else {
          _coachingTips = [];
        }
        
        _personaReply = data['persona_reply'] ?? "";
        _replyCounter++;
        
        _saveToSupabase();
        notifyListeners();
      }, onDone: () {
        debugPrint("WS: Stream closed. Activating client-side simulation fallback.");
        _enableLocalSimulation();
      }, onError: (error) {
        debugPrint("WS: Stream error: $error. Activating client-side simulation fallback.");
        _enableLocalSimulation();
      });
    } catch (e) {
      debugPrint("WS: Exception during connect: $e. Activating client-side simulation fallback.");
      _enableLocalSimulation();
    }
  }

  void _enableLocalSimulation() {
    _isConnected = true;
    _isUsingLocalSimulation = true;
    _suggestion = "Active (Offline AI Coach Engine)";
    notifyListeners();
  }

  void simulateLocalResponse(String text) {
    // Mimic processing latency
    Future.delayed(const Duration(milliseconds: 400), () {
      final textLower = text.toLowerCase();
      
      int anxiety = 20;
      int confidence = 75;
      int clarity = 85;
      String emotion = "Neutral";
      String suggestion = "Excellent flow. Try to expand slightly on your points.";
      String improved = "";
      List<String> tips = [];
      String coachReply = "";
      
      if (textLower.contains("ignoring me")) {
        anxiety = 84;
        confidence = 35;
        clarity = 70;
        emotion = "Anxious";
        improved = "Hey, I just wanted to check in. Is everything okay?";
        suggestion = "Express your feelings without blame to avoid putting them on the defensive.";
        tips = ["Avoid accusatory tone", "Focus on check-in"];
        coachReply = "Hey! I was just in a meeting. Everything is good on my end!";
      } else if (textLower.contains("begging") || textLower.contains("bothering you")) {
        anxiety = 92;
        confidence = 18;
        clarity = 55;
        emotion = "Anxious";
        improved = "I look forward to the possibility of contributing to your team's success.";
        suggestion = "Be direct, professional, and emphasize mutual value fit.";
        tips = ["Speak with confidence", "Avoid desperate pleading"];
        coachReply = "Thank you for expressing your interest. What aspects of our product motivate you the most?";
      } else if (textLower.contains("fix this right now") || textLower.contains("need to fix")) {
        anxiety = 68;
        confidence = 42;
        clarity = 78;
        emotion = "Frustrated";
        improved = "Could we look at this issue together to find a quick solution?";
        suggestion = "State the problem professionally and invite collaboration.";
        tips = ["State issues calmly", "Use collaborative phrasing"];
        coachReply = "Sure, let's open the code and see what might be causing the block.";
      } else if (text == "k" || textLower == "k") {
        anxiety = 15;
        confidence = 50;
        clarity = 90;
        emotion = "Neutral";
        improved = "Okay, that sounds good! Let me know if anything changes.";
        suggestion = "Expand beyond single words to keep the conversation flowing naturally.";
        tips = ["Avoid single-letter responses", "Keep the channel active"];
        coachReply = "Cool, let's connect later then.";
      } else {
        if (textLower.contains("nervous") || textLower.contains("shake") || textLower.contains("fear")) {
          anxiety = 75;
          confidence = 30;
          clarity = 80;
          emotion = "Nervous";
          improved = "I want to share my thoughts clearly and invite your feedback.";
          suggestion = "Take a breath, slow down your pace, and speak with assurance.";
          tips = ["Slow down your pace", "Maintain eye contact"];
        } else if (textLower.contains("excite") || textLower.contains("pitch") || textLower.contains("win")) {
          anxiety = 15;
          confidence = 90;
          clarity = 88;
          emotion = "Confident";
          improved = "We have a strong proposal, and I'm very excited about our chances.";
          suggestion = "Solid confidence. Maintain strong, clear eye contact.";
          tips = ["Maintain high energy", "Smile naturally"];
        }
      }
      
      _transcript = text;
      _anxiety = "$anxiety%";
      _confidence = "$confidence%";
      _clarity = "$clarity%";
      _emotion = emotion;
      _suggestion = suggestion;
      _improved = improved;
      _coachingTips = tips;
      _personaReply = coachReply.isNotEmpty ? coachReply : "Understood. Keep practicing to maintain this pacing.";
      _replyCounter++;
      
      _saveToSupabase();
      notifyListeners();
    });
  }

  Future<void> _saveToSupabase() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      await _supabase.from('conversations').insert({
        'user_id': user.id,
        'transcript': _transcript,
        'emotion': _emotion,
        'pace': _pace,
        'confidence': _confidence,
        'suggestion': _suggestion,
        'context': _selectedContext,
        'mode': _mode,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      int anxietyVal = int.tryParse(_anxiety.replaceAll('%', '')) ?? 0;
      int confidenceVal = int.tryParse(_confidence.replaceAll('%', '')) ?? 0;
      int clarityVal = int.tryParse(_clarity.replaceAll('%', '')) ?? 0;
      
      await _supabase.from('anxiety_logs').insert({
        'user_id': user.id,
        'anxiety': anxietyVal,
        'confidence': confidenceVal,
        'clarity': clarityVal,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Supabase insert suppressed (expected in offline demo): $e");
    }
  }

  void toggleListening() {
    if (!_isConnected) return;
    _isListening = !_isListening;
    _mode = "voice";
    
    if (_isListening) {
      if (_speechEnabled) {
        _suggestion = "Listening...";
        _speech.listen(onResult: _onSpeechResult);
      } else {
        _suggestion = "Mic permission denied.";
        sendText("Starting voice analysis...");
      }
    } else {
      _speech.stop();
      _suggestion = "Paused";
    }
    notifyListeners();
  }

  void _onSpeechResult(result) {
    if (result.recognizedWords.isNotEmpty) {
      _transcript = result.recognizedWords;
      if (result.finalResult) {
        sendText(result.recognizedWords);
      }
      notifyListeners();
    }
  }

  void sendText(String text) {
    if (_channel != null && text.isNotEmpty && _isConnected && !_isUsingLocalSimulation) {
      try {
        final payload = {
          "text": text,
          "context": _selectedContext,
          "mode": _mode,
          "persona": _selectedPersona
        };
        debugPrint("WS: Sending payload: ${jsonEncode(payload)}");
        _channel!.sink.add(jsonEncode(payload));
        _transcript = text;
        notifyListeners();
      } catch (e) {
        debugPrint("WebSocket write error, fallback to local simulation: $e");
        _enableLocalSimulation();
        simulateLocalResponse(text);
      }
    } else {
      _transcript = text;
      notifyListeners();
      simulateLocalResponse(text);
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    super.dispose();
  }
}
