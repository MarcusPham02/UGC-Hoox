import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/gemini_config.dart';
import '../models/hook.dart';

class FeedbackService {
  final GenerativeModel _model;

  FeedbackService({GenerativeModel? model})
      : _model = model ??
            GenerativeModel(
              model: 'gemini-2.0-flash',
              apiKey: GeminiConfig.geminiApiKey,
            );

  /// Sends the user's prompt + reference hooks to Gemini and returns feedback.
  /// If [referenceHooks] is empty, uses built-in sample hooks for evaluation.
  Future<String> getFeedback({
    required String userPrompt,
    required List<Hook> referenceHooks,
  }) async {
    final hooks = referenceHooks.isNotEmpty
        ? referenceHooks
        : _sampleHooks;

    final hooksContext = hooks
        .map((h) => '- "${h.content}" (${h.category})')
        .join('\n');

    final prompt = '''
You are an expert at evaluating attention-grabbing content openers ("hooks").

Here are reference hooks from our library that are known to be effective:
$hooksContext

The user submitted the following hook for feedback:
"$userPrompt"

Please evaluate the user's hook by:
1. Rating its effectiveness (1-10)
2. Comparing it to the reference hooks above
3. Identifying what works well
4. Suggesting specific improvements
5. Providing 2-3 alternative versions

Keep feedback constructive, specific, and actionable.
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? 'Unable to generate feedback. Please try again.';
  }

  static final _sampleHooks = [
    Hook(id: '1', content: 'Did you know 90% of startups fail in the first year?', category: 'social_media'),
    Hook(id: '2', content: 'Stop scrolling. This will change how you think about money.', category: 'video_hook'),
    Hook(id: '3', content: 'The secret nobody tells you about getting promoted', category: 'blog_intro'),
    Hook(id: '4', content: 'I spent 10 years studying the habits of millionaires. Here\'s what I found.', category: 'social_media'),
    Hook(id: '5', content: 'What if everything you know about productivity is wrong?', category: 'email_subject'),
  ];
}
