import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/license.dart';
import '../../models/weapon.dart';
import '../../models/weapon_query.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/repository_exceptions.dart';
import '../../repositories/weapon_repository.dart';
import '../../widgets/confirm_dialog.dart';

class CategoryDetailScreen extends StatefulWidget {
  const CategoryDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  Category? _category;
  List<Weapon> _weapons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final category = await context.read<CategoryRepository>().findById(
      widget.id,
    );
    if (!mounted) return;
    final weapons = category == null
        ? <Weapon>[]
        : (await context.read<WeaponRepository>().find(
            WeaponQuery(categoryId: category.id, size: 100),
          )).items;
    if (!mounted) return;
    setState(() {
      _category = category;
      _weapons = weapons;
      _loading = false;
    });
  }

  Future<void> _handleSoftDelete(Category c) async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить запись?',
      message: 'Логическое удаление: запись скроется из списка, её можно восстановить.',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<CategoryRepository>().softDelete(c.id);
    } on ReferentialIntegrityException catch (e) {
      if (mounted) _showBlockedDialog(e.message);
      return;
    }
    if (!mounted) return;
    await _load();
  }

  Future<void> _handleRestore(Category c) async {
    await context.read<CategoryRepository>().restore(c.id);
    if (!mounted) return;
    await _load();
  }

  Future<void> _handleHardDelete(Category c) async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить безвозвратно?',
      message: 'Физическое удаление нельзя отменить.',
      confirmLabel: 'Удалить навсегда',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<CategoryRepository>().hardDelete(c.id);
    } on ReferentialIntegrityException catch (e) {
      if (mounted) _showBlockedDialog(e.message);
      return;
    }
    if (!mounted) return;
    context.pop();
  }

  void _showBlockedDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление невозможно'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _category;
    return Scaffold(
      appBar: AppBar(
        title: Text(c?.name ?? 'Категория'),
        actions: [
          if (c != null)
            IconButton(
              tooltip: 'Изменить',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final changed = await context.push<bool>(
                  '/categories/${c.id}/edit',
                );
                if (changed == true) await _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : c == null
          ? Center(child: Text('Запись №${widget.id} не найдена'))
          : _buildContent(context, c),
    );
  }

  Widget _buildContent(BuildContext context, Category c) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (c.isDeleted)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.red.withValues(alpha: 0.1),
                child: const Text(
                  'Эта запись удалена',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            Text('Название: ${c.name}'),
            Text('Нужная лицензия: ${License.typeLabels[c.licenseType] ?? c.licenseType}'),
            const SizedBox(height: 16),
            Text(
              'Оружие в категории (${_weapons.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_weapons.isEmpty)
              const Text('Нет оружия этой категории')
            else
              for (final w in _weapons)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(w.name),
                  subtitle: Text('${w.year} · ${w.sku}'),
                  onTap: () => context.push('/weapons/${w.id}'),
                ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              children: [
                if (!c.isDeleted)
                  OutlinedButton.icon(
                    onPressed: () => _handleSoftDelete(c),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Удалить'),
                  ),
                if (c.isDeleted)
                  OutlinedButton.icon(
                    onPressed: () => _handleRestore(c),
                    icon: const Icon(Icons.restore),
                    label: const Text('Восстановить'),
                  ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _handleHardDelete(c),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Удалить навсегда'),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Назад к списку'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
