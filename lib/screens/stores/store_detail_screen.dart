import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/role.dart';
import '../../models/store.dart';
import '../../repositories/repository_exceptions.dart';
import '../../repositories/store_repository.dart';
import '../../state/auth_notifier.dart';
import '../../widgets/confirm_dialog.dart';

class StoreDetailScreen extends StatefulWidget {
  const StoreDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  Store? _store;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final store = await context.read<StoreRepository>().findById(widget.id);
    if (!mounted) return;
    setState(() {
      _store = store;
      _loading = false;
    });
  }

  Future<void> _handleSoftDelete(Store s) async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить запись?',
      message: 'Логическое удаление: запись скроется из списка, её можно восстановить.',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<StoreRepository>().softDelete(s.id);
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

  Future<void> _handleRestore(Store s) async {
    await context.read<StoreRepository>().restore(s.id);
    if (!mounted) return;
    await _load();
  }

  Future<void> _handleHardDelete(Store s) async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить безвозвратно?',
      message: 'Физическое удаление нельзя отменить.',
      confirmLabel: 'Удалить навсегда',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<StoreRepository>().hardDelete(s.id);
    } on ReferentialIntegrityException catch (e) {
      if (mounted) _showBlockedDialog(e.message);
      return;
    }
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = _store;
    final isStaff = context.watch<AuthNotifier>().has(Role.seller);
    final isAdmin = context.watch<AuthNotifier>().has(Role.admin);
    return Scaffold(
      appBar: AppBar(
        title: Text(s?.name ?? 'Магазин'),
        actions: [
          if (s != null && isStaff)
            IconButton(
              tooltip: 'Изменить',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final changed = await context.push<bool>('/stores/${s.id}/edit');
                if (changed == true) await _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : s == null
          ? Center(child: Text('Запись №${widget.id} не найдена'))
          : _buildContent(context, s, isStaff, isAdmin),
    );
  }

  Widget _buildContent(BuildContext context, Store s, bool isStaff, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (s.isDeleted)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.red.withValues(alpha: 0.1),
                child: const Text(
                  'Эта запись удалена',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            Text('Название: ${s.name}'),
            Text('Адрес: ${s.address}'),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              children: [
                if (isStaff && !s.isDeleted)
                  OutlinedButton.icon(
                    onPressed: () => _handleSoftDelete(s),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Удалить'),
                  ),
                if (isAdmin && s.isDeleted)
                  OutlinedButton.icon(
                    onPressed: () => _handleRestore(s),
                    icon: const Icon(Icons.restore),
                    label: const Text('Восстановить'),
                  ),
                if (isAdmin)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => _handleHardDelete(s),
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
