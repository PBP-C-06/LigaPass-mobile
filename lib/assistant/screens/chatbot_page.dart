import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:ligapass/assistant/services/gemini_chat_service.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';
import 'package:ligapass/config/ai_config.dart';
import 'package:markdown/markdown.dart' as md;

class ChatMessage {
  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  final String text;
  final bool isUser;
  final DateTime timestamp;
}

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          'Halo! Saya LigaBot. Tanyakan apa saja tentang jadwal, tiket, berita, '
          'atau cara menggunakan aplikasi.',
      isUser: false,
    ),
  ];

  GeminiChatService? _chatService;
  bool _isSending = false;
  String? _error;
  bool _showSuggestions = true;

  List<String> get _suggestedPrompts => const [
    'Bagaimana cara membeli tiket pertandingan?',
    'Apa pertandingan terdekat yang bisa saya tonton?',
    'Tunjukkan berita terbaru tentang liga.',
    'Bagaimana cara memperbarui profil saya?',
    'Saya ingin menulis ulasan, mulai dari mana?',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ensureService() async {
    _chatService ??= GeminiChatService();
  }

  void _resetConversation() {
    setState(() {
      _messages
        ..clear()
        ..add(
          ChatMessage(
            text:
                'Halo! Saya LigaBot. Tanyakan apa saja tentang jadwal, tiket, berita, '
                'atau cara menggunakan aplikasi.',
            isUser: false,
          ),
        );
      _chatService = null;
      _error = null;
      _showSuggestions = true;
    });
  }

  Future<void> _sendMessage([String? preset]) async {
    final text = (preset ?? _inputController.text).trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isSending = true;
      _error = null;
      _showSuggestions = false;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      if (!AiConfig.hasApiKey) {
        throw StateError(
          'Gemini API key belum di-set. Jalankan dengan --dart-define=GEMINI_API_KEY=xxx '
          'atau isi Env.geminiApiKey untuk pengembangan lokal.',
        );
      }

      await _ensureService();
      final reply = await _chatService!.sendMessage(text);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'LigaBot',
          style: TextStyle(
            color: Color(0xFF1d4ed8),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: const Color(0xFF1d4ed8),
            tooltip: 'Mulai ulang percakapan',
            onPressed: _isSending ? null : _resetConversation,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFf6f9ff), Color(0xFFe8f0ff)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (!AiConfig.hasApiKey) _buildMissingKeyBanner(),
              if (_error != null) _buildErrorBanner(_error!),
              _buildSuggestions(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
              _buildInputArea(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(
        currentRoute: '/assistant',
        showAssistantButton: false,
      ),
    );
  }

  Widget _buildSuggestions() {
    if (!_showSuggestions) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestedPrompts.length,
                separatorBuilder: (context, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final prompt = _suggestedPrompts[index];
                  return ActionChip(
                    label: Text(prompt),
                    avatar: const Icon(
                      Icons.bolt,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                    onPressed: _isSending ? null : () => _sendMessage(prompt),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  );
                },
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sembunyikan',
            icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
            onPressed: () => setState(() => _showSuggestions = false),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final alignment = message.isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final bubbleColor = message.isUser ? const Color(0xFF2563EB) : Colors.white;
    final textColor = message.isUser ? Colors.white : const Color(0xFF1F2937);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x0D000000),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _MessageText(message: message.text, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tanyakan apa saja tentang LigaPass...',
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _isSending ? null : _sendMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingKeyBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.key, color: Color(0xFFF59E0B)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gemini API key belum diisi. Jalankan aplikasi dengan '
              '--dart-define=GEMINI_API_KEY=your-key atau set Env.geminiApiKey '
              'untuk pemakaian lokal.',
              style: TextStyle(color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDC2626)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF991B1B)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF991B1B)),
            onPressed: () => setState(() => _error = null),
          ),
        ],
      ),
    );
  }
}

/// Render chat message with LaTeX support (inline $...$ or $$...$$).
class _MessageText extends StatelessWidget {
  const _MessageText({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: message,
      selectable: true,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(color: color, fontSize: 14, height: 1.4),
        listBullet: TextStyle(color: color, fontSize: 14),
        strong: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        a: const TextStyle(
          color: Color(0xFF2563EB),
          decoration: TextDecoration.underline,
          fontSize: 14,
        ),
      ),
      inlineSyntaxes: [BlockLatexSyntax(), InlineLatexSyntax()],
      builders: {
        'inline_math': MathMarkdownBuilder(isBlock: false, color: color),
        'block_math': MathMarkdownBuilder(isBlock: true, color: color),
      },
    );
  }
}

class InlineLatexSyntax extends md.InlineSyntax {
  InlineLatexSyntax() : super(r'\$(.+?)\$', startCharacter: r'$'.codeUnitAt(0));

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('inline_math', match.group(1)!));
    return true;
  }
}

class BlockLatexSyntax extends md.InlineSyntax {
  BlockLatexSyntax()
    : super(r'\$\$(.+?)\$\$', startCharacter: r'$'.codeUnitAt(0));

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('block_math', match.group(1)!));
    return true;
  }
}

class MathMarkdownBuilder extends MarkdownElementBuilder {
  MathMarkdownBuilder({required this.isBlock, required this.color});

  final bool isBlock;
  final Color color;

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final formula = element.textContent.trim();
    final mathWidget = Math.tex(
      formula,
      mathStyle: MathStyle.text,
      textStyle: TextStyle(color: color, fontSize: 14),
    );

    if (isBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: mathWidget,
      );
    }
    return mathWidget;
  }
}
