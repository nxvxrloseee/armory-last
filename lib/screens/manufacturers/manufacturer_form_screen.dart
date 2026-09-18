import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/manufacturer.dart';
import '../../repositories/manufacturer_repository.dart';
import '../../utils/validators.dart';
import '../../widgets/entity_form_scaffold.dart';

class ManufacturerFormScreen extends StatefulWidget {
  const ManufacturerFormScreen({super.key, this.id});

  final String? id;
  bool get isEditing => id != null;

  @override
  State<ManufacturerFormScreen> createState() => _ManufacturerFormScreenState();
}

class _ManufacturerFormScreenState extends State<ManufacturerFormScreen> {
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _foundedController = TextEditingController();

  bool _loading = true;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _foundedController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    Manufacturer? manufacturer;
    if (widget.isEditing) {
      manufacturer = await context.read<ManufacturerRepository>().findById(
        widget.id!,
      );
    }
    if (!mounted) return;
    setState(() {
      if (manufacturer != null) {
        _nameController.text = manufacturer.name;
        _countryController.text = manufacturer.country;
        _foundedController.text = '${manufacturer.founded}';
      }
      _loading = false;
    });
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _handleSubmit() async {
    final draft = Manufacturer(
      id: widget.id ?? '',
      name: _nameController.text.trim(),
      country: _countryController.text.trim(),
      founded: int.parse(_foundedController.text.trim()),
    );
    final repository = context.read<ManufacturerRepository>();
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
            widget.isEditing ? 'Изменить производителя' : 'Новый производитель',
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return EntityFormScaffold(
      title: widget.isEditing
          ? 'Изменить производителя'
          : 'Новый производитель',
      isDirty: _dirty,
      onSave: _handleSubmit,
      fields: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Название',
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
          controller: _foundedController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Год основания',
            border: OutlineInputBorder(),
          ),
          validator: Validators.intRange(min: 1300, max: 2100),
          onChanged: (_) => _markDirty(),
        ),
      ],
    );
  }
}
