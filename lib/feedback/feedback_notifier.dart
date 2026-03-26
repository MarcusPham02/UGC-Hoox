import 'package:flutter/foundation.dart';

import '../auth/auth_notifier.dart';
import '../services/feedback_service.dart';
import '../services/hooks_service.dart';

class FeedbackNotifier extends ChangeNotifier {
  final HooksService _hooksService;
  final FeedbackService _feedbackService;

  bool isLoading = false;
  String? feedback;
  String? error;
  List<String> categories = [];
  String? selectedCategory;

  // Wizard state
  int currentStep = 0;
  String? audience;
  List<String> selectedTones = [];

  void clearError() {
    error = null;
    notifyListeners();
  }

  static const List<String> availableTones = [
    'casual',
    'professional',
    'provocative',
    'inspirational',
    'humorous',
    'urgent',
  ];

  final AuthNotifier? _authNotifier;

  FeedbackNotifier({
    HooksService? hooksService,
    FeedbackService? feedbackService,
    AuthNotifier? authNotifier,
  })  : _hooksService = hooksService ?? HooksService(),
        _feedbackService = feedbackService ?? FeedbackService(),
        _authNotifier = authNotifier;

  Future<void> loadCategories() async {
    try {
      categories = await _hooksService.getCategories();
      notifyListeners();
    } catch (_) {
      // Hooks table may not exist yet — silently skip.
    }
  }

  void selectCategory(String? category) {
    selectedCategory = category;
    notifyListeners();
  }

  // Wizard navigation
  void nextStep() {
    if (currentStep < 3) {
      currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 3) {
      currentStep = step;
      notifyListeners();
    }
  }

  // Audience — no notifyListeners to avoid per-keystroke rebuilds
  void setAudience(String? value) {
    audience = value?.trim();
  }

  // Tone toggling (max 2)
  void toggleTone(String tone) {
    if (selectedTones.contains(tone)) {
      selectedTones.remove(tone);
    } else if (selectedTones.length < 2) {
      selectedTones.add(tone);
    }
    notifyListeners();
  }

  // Reset wizard for a new submission
  void resetWizard() {
    currentStep = 0;
    selectedCategory = null;
    audience = null;
    selectedTones = [];
    feedback = null;
    error = null;
    notifyListeners();
  }

  Future<String> _callFeedback(String userPrompt) {
    return _feedbackService.getFeedback(
      userPrompt: userPrompt,
      category: selectedCategory,
      audience: audience,
      tones: selectedTones.isNotEmpty ? selectedTones : null,
    );
  }

  Future<void> submitPrompt(String userPrompt) async {
    isLoading = true;
    feedback = null;
    error = null;
    notifyListeners();

    try {
      feedback = await _callFeedback(userPrompt);
    } on FeedbackAuthException {
      // Token expired — refresh session and retry once.
      try {
        await _authNotifier?.refreshSession();
        feedback = await _callFeedback(userPrompt);
      } catch (e) {
        debugPrint('Auth retry failed: $e');
        error = 'Your session has expired. Please sign in again.';
      }
    } catch (e) {
      debugPrint('Feedback error: $e');
      error = 'Failed to get feedback. Please try again later.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
