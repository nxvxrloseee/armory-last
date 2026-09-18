import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/store.dart';
import '../../repositories/store_repository.dart';
import '../../utils/validators.dart';
import '../../widgets/entity_form_scaffold.dart';

class StoreFormScreen extends StatefulWidget {
  const StoreFormScreen({super.key, this.id});

  final String? id;
  bool get isEditing => id != null;

  @override
  State<StoreFormScreen> createState() => _StoreFormScreenState();
}

class _StoreFormScreenState extends State<StoreFormScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

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
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    Store? store;
    if (widget.isEditing) {
      store = await context.read<StoreRepository>().findById(widget.id!);
    }
    if (!mounted) return;
    setState(() {
      if (store != null) {
        _nameController.text = store.name;
        _addressController.text = store.address;
      }
      _loading = false;
    });
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _handleSubmit() async {
    final draft = Store(
      id: widget.id ?? '',
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
    );
    final repository = context.read<StoreRepository>();
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
          title: Text(widget.isEditing ? 'Изменить магазин' : 'Новый магазин'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return EntityFormScaffold(
      title: widget.isEditing ? 'Изменить магазин' : 'Новый магазин',
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
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Адрес',
            border: OutlineInputBorder(),
          ),
          validator: Validators.combine([
            Validators.required(),
            Validators.maxLength(300),
          ]),
          onChanged: (_) => _markDirty(),
        ),
      ],
    );
  }
}
