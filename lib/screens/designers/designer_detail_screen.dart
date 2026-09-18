import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/designer.dart';
import '../../models/weapon.dart';
import '../../models/weapon_query.dart';
import '../../repositories/designer_repository.dart';
import '../../repositories/repository_exceptions.dart';
import '../../repositories/weapon_repository.dart';
import '../../widgets/confirm_dialog.dart';

class DesignerDetailScreen extends StatefulWidget {
  const DesignerDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<DesignerDetailScreen> createState() => _DesignerDetailScreenState();
}

class _DesignerDetailScreenState extends State<DesignerDetailScreen> {
  Designer? _designer;
  List<Weapon> _weapons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final designer = await context.read<DesignerRepository>().findById(
      widget.id,
    );
    if (!mounted) return;
    final weapons = designer == null
        ? <Weapon>[]
        : (await context.read<WeaponRepository>().find(
            WeaponQuery(designerId: designer.id, size: 100),
          )).items;
    if (!mounted) return;
    setState(() {
      _designer = designer;
      _weapons = weapons;
      _loading = false;
    });
  }

  Future<void> _handleSoftDelete(Designer d) async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить запись?',
      message: 'Логическое удаление: запись скроется из списка, её можно восстановить.',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<DesignerRepository>().softDelete(d.id);
    } on ReferentialIntegrityException catch (e) {
      if (mounted) _showBlockedDialog(e.message);
      return;
    }
    if (!mounted) return;
    await _load();
  }

  Future<void> _handleRestore(Designer d) async {
    await context.read<DesignerRepository>().restore(d.id);
    if (!mounted) return;
    await _load();
  }

  Future<void> _handleHardDelete(Designer d) async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить безвозвратно?',
      message: 'Физическое удаление нельзя отменить.',
      confirmLabel: 'Удалить навсегда',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<DesignerRepository>().hardDelete(d.id);
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
    final d = _designer;
    return Scaffold(
      appBar: AppBar(
        title: Text(d?.fullName ?? 'Конструктор'),
        actions: [
          if (d != null)
            IconButton(
              tooltip: 'Изменить',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final changed = await context.push<bool>(
                  '/designers/${d.id}/edit',
                );
                if (changed == true) await _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : d == null
          ? Center(child: Text('Запись №${widget.id} не найдена'))
          : _buildContent(context, d),
    );
  }

  Widget _buildContent(BuildContext context, Designer d) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (d.isDeleted)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.red.withValues(alpha: 0.1),
                child: const Text(
                  'Эта запись удалена',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            _row('Имя', d.fullName),
            _row('Страна', d.country),
            _row('Работает с', '${d.activeSince}'),
            const SizedBox(height: 16),
            Text(
              'Оружие в разработке (${_weapons.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_weapons.isEmpty)
              const Text('Нет оружия этого конструктора')
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
                if (!d.isDeleted)
                  OutlinedButton.icon(
                    onPressed: () => _handleSoftDelete(d),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Удалить'),
                  ),
                if (d.isDeleted)
                  OutlinedButton.icon(
                    onPressed: () => _handleRestore(d),
                    icon: const Icon(Icons.restore),
                    label: const Text('Восстановить'),
                  ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _handleHardDelete(d),
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

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
