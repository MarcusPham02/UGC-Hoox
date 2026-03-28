import 'package:flutter/foundation.dart';

import '../auth/auth_notifier.dart';
import '../services/script_analyzer_service.dart';

class ScriptAnalyzerNotifier extends ChangeNotifier {
  final ScriptAnalyzerService _service;
  final AuthNotifier? _authNotifier;

  bool isLoading = false;
  String? analysis;
  String? error;

  ScriptAnalyzerNotifier({
    ScriptAnalyzerService? service,
    AuthNotifier? authNotifier,
  })  : _service = service ?? ScriptAnalyzerService(),
        _authNotifier = authNotifier;

  Future<void> analyzeScript(String scriptText) async {
    isLoading = true;
    analysis = null;
    error = null;
    notifyListeners();

    try {
      analysis = await _service.analyzeScript(scriptText: scriptText);
    } on ScriptAnalyzerAuthException {
      if (_authNotifier == null) {
        error = 'Your session has expired. Please sign in again.';
      } else {
        // Token expired — refresh session and retry once.
        try {
          await _authNotifier.refreshSession();
          analysis = await _service.analyzeScript(scriptText: scriptText);
        } catch (e) {
          debugPrint('Auth retry failed: $e');
          error = 'Your session has expired. Please sign in again.';
        }
      }
    } catch (e) {
      debugPrint('Script analysis error: $e');
      error = 'Failed to analyze script. Please try again later.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    error = null;
  }

  void reset() {
    analysis = null;
    error = null;
    notifyListeners();
  }
}
