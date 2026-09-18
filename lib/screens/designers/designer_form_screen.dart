import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/designer.dart';
import '../../repositories/designer_repository.dart';
import '../../utils/validators.dart';
import '../../widgets/entity_form_scaffold.dart';

class DesignerFormScreen extends StatefulWidget {
  const DesignerFormScreen({super.key, this.id});

  final String? id;
  bool get isEditing => id != null;

  @override
  State<DesignerFormScreen> createState() => _DesignerFormScreenState();
}

class _DesignerFormScreenState extends State<DesignerFormScreen> {
  final _fullNameController = TextEditingController();
  final _countryController = TextEditingController();
  final _activeSinceController = TextEditingController();

  bool _loading = true;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _countryController.dispose();
    _activeSinceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    Designer? designer;
    if (widget.isEditing) {
      designer = await context.read<DesignerRepository>().findById(widget.id!);
    }
    if (!mounted) return;
    setState(() {
      if (designer != null) {
        _fullNameController.text = designer.fullName;
        _countryController.text = designer.country;
        _activeSinceController.text = '${designer.activeSince}';
      }
      _loading = false;
    });
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _handleSubmit() async {
    final draft = Designer(
      id: widget.id ?? '',
      fullName: _fullNameController.text.trim(),
      country: _countryController.text.trim(),
      activeSince: int.parse(_activeSinceController.text.trim()),
    );
    final repository = context.read<DesignerRepository>();
    if (widget.isEditing) {
      await repository.update(draft);
    } else {
      await repository.create(draft);
    }
    if (!mounted) return;
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEditing ? 'Изменить конструктора' : 'Новый конструктор',
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return EntityFormScaffold(
      title: widget.isEditing ? 'Изменить конструктора' : 'Новый конструктор',
      isDirty: _dirty,
      onSave: _handleSubmit,
      fields: [
        TextFormField(
          controller: _fullNameController,
          decoration: const InputDecoration(
            labelText: 'Имя',
            border: OutlineInputBorder(),
          ),
          validator: Validators.combine([
            Validators.required(),
            Validators.maxLength(120),
          ]),
          onChanged: (_) => _markDirty(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _countryController,
          decoration: const InputDecoration(
            labelText: 'Страна',
            border: OutlineInputBorder(),
          ),
          validator: Validators.combine([
            Validators.required(),
            Validators.maxLength(60),
          ]),
          onChanged: (_) => _markDirty(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _activeSinceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Работает с (год)',
            border: OutlineInputBorder(),
          ),
          validator: Validators.intRange(min: 1300, max: 2100),
          onChanged: (_) => _markDirty(),
        ),
      ],
    );
  }
}
