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

    const systemInstruction =
        'Kamu adalah LigaBot, asisten resmi pengguna aplikasi LigaPass. '
        'Tugasmu adalah membantu pengguna menavigasi fitur-fitur aplikasi, termasuk: '
        'Home, Matches (jadwal & pembelian tiket), News, Reviews, Profile, serta proses login dan registrasi. '
        'Berikan jawaban singkat, jelas, dan menggunakan Bahasa Indonesia. '
        'Jika menjelaskan langkah, gunakan format bernomor. '
        'Hindari membahas hal teknis seperti backend, database, admin panel, atau struktur internal aplikasi. '
        'Jika pertanyaan tidak jelas, minta pengguna untuk memperjelas.';

    _model = GenerativeModel(
      model: AiConfig.model,
      apiKey: _apiKey,
      systemInstruction: Content.system(systemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.3,
        topK: 32,
        topP: 0.9,
        maxOutputTokens: 256,
      ),
    );

    _chat = _model.startChat(history: []);
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
