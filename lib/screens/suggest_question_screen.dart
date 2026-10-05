import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/voting_provider.dart';

class SuggestQuestionScreen extends ConsumerStatefulWidget {
  const SuggestQuestionScreen({super.key});

  @override
  ConsumerState<SuggestQuestionScreen> createState() => _SuggestQuestionScreenState();
}

class _SuggestQuestionScreenState extends ConsumerState<SuggestQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  String _category = 'chow';
  bool _isSubmitting = false;

  final List<String> _categories = ['chow', 'street', 'lifestyle', 'campus', 'general'];

  @override
  void dispose() {
    _optionAController.dispose();
    _optionBController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(votingRepositoryProvider).submitSuggestion(
            optionA: _optionAController.text.trim(),
            optionB: _optionBController.text.trim(),
            category: _category,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suggestion submitted! We go review am.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        title: const Text('Suggest Dilemma', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Got a hot debate topic?',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Submit your option A and option B for the community to vote on.',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _optionAController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Option A (Green Side)',
                  labelStyle: const TextStyle(color: Colors.greenAccent),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter Option A' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _optionBController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Option B (Red Side)',
                  labelStyle: const TextStyle(color: Colors.redAccent),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter Option B' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c.toUpperCase()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('SUBMIT DILEMMA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
