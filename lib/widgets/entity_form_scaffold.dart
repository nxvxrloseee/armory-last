import 'package:flutter/material.dart';

import 'confirm_dialog.dart';

class EntityFormScaffold extends StatefulWidget {
  const EntityFormScaffold({
    super.key,
    required this.title,
    required this.fields,
    required this.onSave,
    required this.isDirty,
    this.saveLabel = 'Сохранить',
  });

  final String title;
  final List<Widget> fields;

  final Future<void> Function() onSave;

  final bool isDirty;

  final String saveLabel;

  @override
  State<EntityFormScaffold> createState() => _EntityFormScaffoldState();
}

class _EntityFormScaffoldState extends State<EntityFormScaffold> {
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _submitError;

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await widget.onSave();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitError = '$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool> _confirmDiscard() {
    return confirmDialog(
      context,
      title: 'Уйти без сохранения?',
      message: 'Несохранённые изменения будут потеряны.',
      confirmLabel: 'Уйти',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await _confirmDiscard();
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  ...widget.fields,
                  if (_submitError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _submitError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: _submitting ? null : _handleSave,
                        child: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(widget.saveLabel),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Отмена'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
