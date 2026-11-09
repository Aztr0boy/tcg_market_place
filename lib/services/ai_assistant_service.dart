import 'package:supabase_flutter/supabase_flutter.dart';

class AiAssistantService {
  const AiAssistantService._();

  static Future<String> ask({
    required String mode,
    required String game,
    required String prompt,
    List<Map<String, dynamic>> cards = const [],
  }) async {
    final response = await Supabase.instance.client.functions.invoke(
      'tcg-assistant',
      body: {
        'mode': mode,
        'game': game,
        'prompt': prompt,
        'cards': cards,
      },
    );

    final data = response.data;
    if (response.status < 200 || response.status >= 300) {
      final message = data is Map ? data['error']?.toString() : null;
      throw Exception(message ?? 'AI request failed (${response.status})');
    }
    if (data is! Map || data['answer'] is! String) {
      throw Exception('AI returned an invalid response');
    }
    return data['answer'] as String;
  }
}