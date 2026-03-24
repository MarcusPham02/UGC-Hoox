import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
  final _audienceController = TextEditingController();

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
    _audienceController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _promptController.text.trim();
    if (text.isNotEmpty) {
      _notifier.setAudience(_audienceController.text);
      _notifier.submitPrompt(text);
    }
  }

  void _startOver() {
    _promptController.clear();
    _audienceController.clear();
    _notifier.resetWizard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hook Feedback'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _notifier.feedback != null
          ? _buildFeedbackResult()
          : _buildWizard(),
    );
  }

  Widget _buildWizard() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _notifier.currentStep,
          onStepContinue: _notifier.currentStep < 3
              ? () => _notifier.nextStep()
              : _notifier.isLoading
                  ? null
                  : _submit,
          onStepCancel: _notifier.currentStep > 0
              ? () => _notifier.previousStep()
              : null,
          onStepTapped: (step) => _notifier.goToStep(step),
          controlsBuilder: (context, details) {
            final isLastStep = details.stepIndex == 3;
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  if (isLastStep)
                    FilledButton(
                      onPressed: _notifier.isLoading
                          ? null
                          : _submit,
                      child: _notifier.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Get Feedback'),
                    )
                  else
                    FilledButton(
                      onPressed: details.onStepContinue,
                      child: const Text('Continue'),
                    ),
                  if (details.stepIndex > 0) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            _buildCategoryStep(),
            _buildAudienceStep(),
            _buildToneStep(),
            _buildHookTextStep(),
          ],
        ),
      ),
    );
  }

  Step _buildCategoryStep() {
    final categories = [
      'social_media',
      'video_hook',
      'blog_intro',
      'email_subject',
    ];
    final labels = {
      'social_media': 'Social Media',
      'video_hook': 'Video Hook',
      'blog_intro': 'Blog Intro',
      'email_subject': 'Email Subject',
    };

    return Step(
      title: const Text('Platform'),
      subtitle: _notifier.selectedCategory != null
          ? Text(labels[_notifier.selectedCategory] ?? _notifier.selectedCategory!)
          : null,
      isActive: _notifier.currentStep >= 0,
      state: _notifier.currentStep > 0
          ? StepState.complete
          : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What type of hook are you writing?'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Any'),
                selected: _notifier.selectedCategory == null,
                onSelected: (_) => _notifier.selectCategory(null),
              ),
              ...categories.map((cat) => ChoiceChip(
                    label: Text(labels[cat] ?? cat),
                    selected: _notifier.selectedCategory == cat,
                    onSelected: (_) => _notifier.selectCategory(cat),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Step _buildAudienceStep() {
    return Step(
      title: const Text('Audience'),
      subtitle: _audienceController.text.isNotEmpty
          ? Text(_audienceController.text)
          : null,
      isActive: _notifier.currentStep >= 1,
      state: _notifier.currentStep > 1
          ? StepState.complete
          : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Who are you trying to reach?'),
          const SizedBox(height: 12),
          TextField(
            controller: _audienceController,
            maxLength: 100,
            decoration: const InputDecoration(
              hintText: 'e.g., startup founders, Gen-Z on TikTok',
              helperText: 'Optional — helps the AI tailor feedback to your readers',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Step _buildToneStep() {
    return Step(
      title: const Text('Tone'),
      subtitle: _notifier.selectedTones.isNotEmpty
          ? Text(_notifier.selectedTones.join(', '))
          : null,
      isActive: _notifier.currentStep >= 2,
      state: _notifier.currentStep > 2
          ? StepState.complete
          : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What tone are you going for? (pick up to 2)'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FeedbackNotifier.availableTones.map((tone) {
              final selected = _notifier.selectedTones.contains(tone);
              return ChoiceChip(
                label: Text(tone[0].toUpperCase() + tone.substring(1)),
                selected: selected,
                onSelected: (_) => _notifier.toggleTone(tone),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Step _buildHookTextStep() {
    return Step(
      title: const Text('Your Hook'),
      isActive: _notifier.currentStep >= 3,
      state: StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary of previous selections
          if (_notifier.selectedCategory != null ||
              _audienceController.text.isNotEmpty ||
              _notifier.selectedTones.isNotEmpty)
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_notifier.selectedCategory != null)
                      Text('Platform: ${_notifier.selectedCategory}'),
                    if (_audienceController.text.isNotEmpty)
                      Text('Audience: ${_audienceController.text}'),
                    if (_notifier.selectedTones.isNotEmpty)
                      Text('Tone: ${_notifier.selectedTones.join(', ')}'),
                  ],
                ),
              ),
            ),
          if (_notifier.selectedCategory != null ||
              _audienceController.text.isNotEmpty ||
              _notifier.selectedTones.isNotEmpty)
            const SizedBox(height: 12),

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
          Text(
            'Your text will be sent to Google Gemini AI for analysis.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),

          // Error display
          if (_notifier.error != null) ...[
            const SizedBox(height: 12),
            Text(
              _notifier.error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackResult() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: MarkdownBody(
                    data: _notifier.feedback!,
                    selectable: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _startOver,
                child: const Text('Start Over'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
