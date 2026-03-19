import 'package:flutter/foundation.dart';

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

  FeedbackNotifier({
    HooksService? hooksService,
    FeedbackService? feedbackService,
  })  : _hooksService = hooksService ?? HooksService(),
        _feedbackService = feedbackService ?? FeedbackService();

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

  Future<void> submitPrompt(String userPrompt) async {
    isLoading = true;
    feedback = null;
    error = null;
    notifyListeners();

    try {
      final result = await _feedbackService.getFeedback(
        userPrompt: userPrompt,
        category: selectedCategory,
      );
      feedback = result;
    } catch (e) {
      error = 'Failed to get feedback. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
