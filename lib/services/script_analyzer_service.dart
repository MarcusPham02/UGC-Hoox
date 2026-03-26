import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when the Edge Function returns a 401 (expired/invalid token).
class ScriptAnalyzerAuthException implements Exception {
  final String message;
  ScriptAnalyzerAuthException(this.message);

  @override
  String toString() => message;
}

class ScriptAnalyzerService {
  final FunctionsClient _functions;

  ScriptAnalyzerService({FunctionsClient? functions})
      : _functions = functions ?? Supabase.instance.client.functions;

  /// Calls the analyze-script Edge Function with the user's pitch script.
  Future<String> analyzeScript({required String scriptText}) async {
    try {
      final response = await _functions.invoke(
        'analyze-script',
        body: {'scriptText': scriptText},
      );

      final data = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      if (data.containsKey('error')) {
        throw Exception(data['error'] as String);
      }

      return data['analysis'] as String? ??
          'Unable to generate analysis. Please try again.';
    } on FunctionException catch (e) {
      if (e.status == 401) {
        throw ScriptAnalyzerAuthException('Session expired');
      }
      rethrow;
    }
  }
}
