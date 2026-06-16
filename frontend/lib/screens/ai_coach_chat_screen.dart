import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/websocket_service.dart';

class AICoachChatScreen extends ConsumerStatefulWidget {
  final String? initialMessage;

  const AICoachChatScreen({
    super.key,
    this.initialMessage,
  });

  @override
  ConsumerState<AICoachChatScreen> createState() => _AICoachChatScreenState();
}

class _AICoachChatScreenState extends ConsumerState<AICoachChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  int _lastProcessedReplyCounter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ws = ref.read(webSocketServiceProvider.notifier);
      _lastProcessedReplyCounter = ref.read(webSocketServiceProvider).replyCounter;
      ws.selectedPersona = "AI Coach";
      ws.selectedContext = "General";
      ws.mode = "chat";
      ws.connect();

      setState(() {
        _messages.add({
          "sender": "coach",
          "text": "Hello! I am your SocialSync AI Coach. I'm here to help you navigate social anxiety, build communication confidence, or practice relationships and interviews. What's on your mind today?",
        });

        if (widget.initialMessage != null && widget.initialMessage!.trim().isNotEmpty) {
          _messages.add({
            "sender": "user",
            "text": widget.initialMessage!,
          });
          ws.sendText(widget.initialMessage!);
        }
      });
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    final ws = ref.read(webSocketServiceProvider.notifier);
    ws.sendText(text);

    setState(() {
      _messages.add({
        "sender": "user",
        "text": text,
      });
    });
    _scrollToBottom();
  }

  void _resetChat() {
    final ws = ref.read(webSocketServiceProvider.notifier);
    ws.sendText("hello");
    setState(() {
      _messages.clear();
      _messages.add({
        "sender": "coach",
        "text": "Hello! I am your SocialSync AI Coach. How can I help you build communication confidence today?",
      });
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final ws = ref.watch(webSocketServiceProvider);

    ref.listen<WebSocketService>(webSocketServiceProvider, (prev, next) {
      // Update user speech transcript in real-time only if currently listening to voice input
      if (next.isListening && next.transcript.isNotEmpty && next.transcript != "..." && next.transcript != "hello") {
        if (_messages.isNotEmpty && _messages.last["sender"] == "user") {
          setState(() {
            _messages.last["text"] = next.transcript;
          });
        } else {
          setState(() {
            _messages.add({
              "sender": "user",
              "text": next.transcript,
            });
          });
        }
        _scrollToBottom();
      }

      // Add coach responses using replyCounter to avoid duplicate event rendering
      if (next.replyCounter > _lastProcessedReplyCounter) {
        _lastProcessedReplyCounter = next.replyCounter;
        if (next.personaReply.isNotEmpty) {
          setState(() {
            _messages.add({
              "sender": "coach",
              "text": next.personaReply,
            });
          });
          _scrollToBottom();
        }
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: Theme.of(context).colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.brainCircuit, color: Theme.of(context).colorScheme.primary, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SocialSync AI Coach",
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "Conversational Assistant",
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _resetChat,
            child: Text(
              "Reset",
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Divider(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08), height: 1),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg["sender"] == "user";

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                        gradient: isUser
                            ? const LinearGradient(
                                colors: [Color(0xFF007AFF), Color(0xFF0A84FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isUser
                            ? null
                            : Theme.of(context).colorScheme.surface.withOpacity(0.4),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: isUser ? const Radius.circular(18) : Radius.zero,
                          bottomRight: isUser ? Radius.zero : const Radius.circular(18),
                        ),
                        border: Border.all(
                          color: isUser
                              ? Colors.white.withOpacity(0.08)
                              : Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
                          width: 0.8,
                        ),
                      ),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      child: Text(
                        msg["text"] ?? "",
                        style: GoogleFonts.inter(
                          color: isUser ? Colors.white : Theme.of(context).colorScheme.onBackground,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08), width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onBackground, fontSize: 14.5),
                              decoration: InputDecoration(
                                hintText: "Message AI Coach...",
                                hintStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4), fontSize: 14.5),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onSubmitted: (val) {
                                _sendMessage();
                              },
                            ),
                          ),
                          GestureDetector(
                            onTap: _sendMessage,
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(LucideIcons.arrowUp, color: Theme.of(context).colorScheme.primary, size: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: ws.toggleListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ws.isListening ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                        border: Border.all(
                          color: ws.isListening ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onBackground.withOpacity(0.08),
                        ),
                      ),
                      child: Icon(
                        ws.isListening ? LucideIcons.square : LucideIcons.mic,
                        color: ws.isListening ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onBackground,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
