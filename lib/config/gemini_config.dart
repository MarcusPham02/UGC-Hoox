// Pulls Gemini API key from compile-time env vars.
// Run with --dart-define-from-file=.env.json so this gets populated.
class GeminiConfig {
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
}
