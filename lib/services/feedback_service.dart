import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackService {
  final FunctionsClient _functions;

  FeedbackService({FunctionsClient? functions})
      : _functions = functions ?? Supabase.instance.client.functions;

  /// Calls the get-feedback Edge Function with the user's prompt.
  /// The Edge Function handles Gemini API calls server-side.
  Future<String> getFeedback({
    required String userPrompt,
    String? category,
    String? audience,
    List<String>? tones,
  }) async {
    final response = await _functions.invoke(
      'get-feedback',
      body: {
        'userPrompt': userPrompt,
        // ignore: use_null_aware_elements
        if (category != null) 'category': category,
        // ignore: use_null_aware_elements
        if (audience != null) 'audience': audience,
        if (tones != null && tones.isNotEmpty) 'tones': tones,
      },
    );

    final data = jsonDecode(response.data as String) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      throw Exception(data['error'] as String);
    }

    return data['feedback'] as String? ??
        'Unable to generate feedback. Please try again.';
  }
}
