import 'package:flutter/material.dart';

import '../feedback/feedback_notifier.dart';
import '../services/feedback_service.dart';
import '../services/hooks_service.dart';

class FeedbackScreen extends StatefulWidget {
  final HooksService? hooksService;
  final FeedbackService? feedbackService;

  const FeedbackScreen({
    super.key,
    this.hooksService,
    this.feedbackService,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  late final FeedbackNotifier _notifier;
  final _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notifier = FeedbackNotifier(
      hooksService: widget.hooksService,
      feedbackService: widget.feedbackService,
    );
    _notifier.addListener(_onNotifierChanged);
    _notifier.loadCategories();
  }

  void _onNotifierChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _notifier.removeListener(_onNotifierChanged);
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hook Feedback'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category picker
            if (_notifier.categories.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: _notifier.selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All categories'),
                  ),
                  ..._notifier.categories.map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      )),
                ],
                onChanged: (value) => _notifier.selectCategory(value),
              ),
              const SizedBox(height: 16),
            ],

            // Prompt input
            TextField(
              controller: _promptController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Enter your hook',
                hintText: 'Write your attention-grabbing opener here...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            // Privacy notice
            Text(
              'Your text will be sent to Google Gemini AI for analysis.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),

            // Submit button
            FilledButton(
              onPressed: _notifier.isLoading
                  ? null
                  : () {
                      final text = _promptController.text.trim();
                      if (text.isNotEmpty) {
                        _notifier.submitPrompt(text);
                      }
                    },
              child: _notifier.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Get Feedback'),
            ),
            const SizedBox(height: 24),

            // Error display
            if (_notifier.error != null)
              Text(
                _notifier.error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),

            // Feedback display
            if (_notifier.feedback != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SelectableText(_notifier.feedback!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
