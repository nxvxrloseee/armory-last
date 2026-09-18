import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/license.dart';
import '../../repositories/category_repository.dart';
import '../../utils/validators.dart';
import '../../widgets/entity_form_scaffold.dart';

class CategoryFormScreen extends StatefulWidget {
  const CategoryFormScreen({super.key, this.id});

  final String? id;
  bool get isEditing => id != null;

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _nameController = TextEditingController();
  String _licenseType = 'other';
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
    super.dispose();
  }

  Future<void> _load() async {
    Category? category;
    if (widget.isEditing) {
      category = await context.read<CategoryRepository>().findById(widget.id!);
    }
    if (!mounted) return;
    setState(() {
      if (category != null) {
        _nameController.text = category.name;
        _licenseType = category.licenseType;
      }
      _loading = false;
    });
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _handleSubmit() async {
    final draft = Category(
      id: widget.id ?? '',
      name: _nameController.text.trim(),
      licenseType: _licenseType,
    );
    final repository = context.read<CategoryRepository>();
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
            widget.isEditing ? 'Изменить категорию' : 'Новая категория',
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return EntityFormScaffold(
      title: widget.isEditing ? 'Изменить категорию' : 'Новая категория',
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
            Validators.maxLength(60),
          ]),
          onChanged: (_) => _markDirty(),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _licenseType,
          decoration: const InputDecoration(
            labelText: 'Требуемый тип лицензии',
            border: OutlineInputBorder(),
            helperText:
                'Определяет, какая лицензия покупателя нужна для заказа '
                'оружия этой категории.',
          ),
          items: License.typeLabels.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (value) {
            setState(() => _licenseType = value ?? 'other');
            _markDirty();
          },
        ),
      ],
    );
  }
}
