import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/manufacturer.dart';
import '../../models/weapon.dart';
import '../../models/weapon_query.dart';
import '../../repositories/manufacturer_repository.dart';
import '../../repositories/repository_exceptions.dart';
import '../../repositories/weapon_repository.dart';
import '../../widgets/confirm_dialog.dart';

class ManufacturerDetailScreen extends StatefulWidget {
  const ManufacturerDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<ManufacturerDetailScreen> createState() =>
      _ManufacturerDetailScreenState();
}

class _ManufacturerDetailScreenState extends State<ManufacturerDetailScreen> {
  Manufacturer? _manufacturer;
  List<Weapon> _weapons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final manufacturer = await context.read<ManufacturerRepository>().findById(
      widget.id,
    );
    if (!mounted) return;
    final weapons = manufacturer == null
        ? <Weapon>[]
        : (await context.read<WeaponRepository>().find(
            WeaponQuery(manufacturerId: manufacturer.id, size: 100),
          )).items;
    if (!mounted) return;
    setState(() {
      _manufacturer = manufacturer;
      _weapons = weapons;
      _loading = false;
    });
  }

  Future<void> _handleSoftDelete(Manufacturer m) async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить запись?',
      message: 'Логическое удаление: запись скроется из списка, её можно восстановить.',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<ManufacturerRepository>().softDelete(m.id);
    } on ReferentialIntegrityException catch (e) {
      if (mounted) _showBlockedDialog(e.message);
      return;
    }
    if (!mounted) return;
    await _load();
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

  Future<void> _handleRestore(Manufacturer m) async {
    await context.read<ManufacturerRepository>().restore(m.id);
    if (!mounted) return;
    await _load();
  }

  Future<void> _handleHardDelete(Manufacturer m) async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить безвозвратно?',
      message: 'Физическое удаление нельзя отменить.',
      confirmLabel: 'Удалить навсегда',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<ManufacturerRepository>().hardDelete(m.id);
    } on ReferentialIntegrityException catch (e) {
      if (mounted) _showBlockedDialog(e.message);
      return;
    }
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final m = _manufacturer;
    return Scaffold(
      appBar: AppBar(
        title: Text(m?.name ?? 'Производитель'),
        actions: [
          if (m != null)
            IconButton(
              tooltip: 'Изменить',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final changed = await context.push<bool>(
                  '/manufacturers/${m.id}/edit',
                );
                if (changed == true) await _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : m == null
          ? Center(child: Text('Запись №${widget.id} не найдена'))
          : _buildContent(context, m),
    );
  }

  Widget _buildContent(BuildContext context, Manufacturer m) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m.isDeleted)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.red.withValues(alpha: 0.1),
                child: const Text(
                  'Эта запись удалена',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            _row('Название', m.name),
            _row('Страна', m.country),
            _row('Год основания', '${m.founded}'),
            const SizedBox(height: 16),
            Text(
              'Модели в каталоге (${_weapons.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_weapons.isEmpty)
              const Text('Нет моделей этого производителя')
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
                if (!m.isDeleted)
                  OutlinedButton.icon(
                    onPressed: () => _handleSoftDelete(m),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Удалить'),
                  ),
                if (m.isDeleted)
                  OutlinedButton.icon(
                    onPressed: () => _handleRestore(m),
                    icon: const Icon(Icons.restore),
                    label: const Text('Восстановить'),
                  ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _handleHardDelete(m),
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
