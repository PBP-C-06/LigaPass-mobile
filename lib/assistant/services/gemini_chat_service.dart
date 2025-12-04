import 'package:google_generative_ai/google_generative_ai.dart';

import '../../config/ai_config.dart';

/// Wrapper tipis untuk ngobrol dengan Gemini.
class GeminiChatService {
  GeminiChatService({String? apiKey})
    : _apiKey = apiKey ?? AiConfig.geminiApiKey {
    if (_apiKey.isEmpty) {
      throw StateError(
        'Gemini API key belum di-set. Tambahkan --dart-define=GEMINI_API_KEY=xxx '
        'atau isi Env.geminiApiKey.',
      );
    }

    _model = GenerativeModel(
      model: AiConfig.model,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        topK: 32,
        topP: 0.9,
        maxOutputTokens: 256,
      ),
    );

    _chat = _model.startChat(
      history: [
        Content.system(
          'Kamu adalah LigaPass Assist, asisten untuk aplikasi LigaPass. '
          'Fokus membantu pengguna menavigasi fitur: Home, Matches (jadwal & tiket), '
          'News, Reviews, Profile, login/register. Jawab ringkas dalam Bahasa Indonesia, '
          'beri langkah bernomor saat sesuai, dan hindari topik di luar aplikasi.',
        ),
      ],
    );
  }

  final String _apiKey;
  late final GenerativeModel _model;
  late ChatSession _chat;

  Future<String> sendMessage(String message) async {
    final response = await _chat.sendMessage(Content.text(message));
    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      throw StateError('Balasan dari Gemini kosong.');
    }
    return text;
  }
}
