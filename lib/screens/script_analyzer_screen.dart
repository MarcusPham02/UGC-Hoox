import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../auth/auth_notifier.dart';
import '../script_analyzer/script_analyzer_notifier.dart';
import '../services/script_analyzer_service.dart';

class ScriptAnalyzerScreen extends StatefulWidget {
  final ScriptAnalyzerService? service;
  final AuthNotifier? authNotifier;

  const ScriptAnalyzerScreen({
    super.key,
    this.service,
    this.authNotifier,
  });

  @override
  State<ScriptAnalyzerScreen> createState() => _ScriptAnalyzerScreenState();
}

class _ScriptAnalyzerScreenState extends State<ScriptAnalyzerScreen> {
  late final ScriptAnalyzerNotifier _notifier;
  final _scriptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notifier = ScriptAnalyzerNotifier(
      service: widget.service,
      authNotifier: widget.authNotifier,
    );
    _notifier.addListener(_onNotifierChanged);
    _scriptController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _onNotifierChanged() {
    if (_notifier.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_notifier.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 6),
        ),
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    _notifier.removeListener(_onNotifierChanged);
    _scriptController.removeListener(_onTextChanged);
    _scriptController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _scriptController.text.trim();
    if (text.isNotEmpty) {
      _notifier.analyzeScript(text);
    }
  }

  void _startOver() {
    _scriptController.clear();
    _notifier.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Script Analyzer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _notifier.analysis != null
          ? _buildResult()
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Analyze your UGC pitch script',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Paste your full script — opening hook, body, and call-to-action — for a detailed structure and flow analysis.',
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _scriptController,
                maxLines: 10,
                maxLength: 3000,
                decoration: const InputDecoration(
                  labelText: 'Paste your UGC pitch script',
                  hintText:
                      'Enter your full script — opening hook, body, and call-to-action...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your script will be sent to Google Gemini AI for analysis.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _notifier.isLoading ||
                        _scriptController.text.trim().isEmpty
                    ? null
                    : _submit,
                child: _notifier.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Analyze Script'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
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
                    data: _notifier.analysis!,
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
