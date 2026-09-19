import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../models/category.dart';
import '../../models/designer.dart';
import '../../models/manufacturer.dart';
import '../../models/role.dart';
import '../../models/weapon.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/designer_repository.dart';
import '../../repositories/manufacturer_repository.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/store_repository.dart';
import '../../repositories/weapon_repository.dart';
import '../../state/auth_notifier.dart';
import '../../widgets/confirm_dialog.dart';

class WeaponDetailScreen extends StatefulWidget {
  const WeaponDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<WeaponDetailScreen> createState() => _WeaponDetailScreenState();
}

class _WeaponDetailScreenState extends State<WeaponDetailScreen> {
  Weapon? _weapon;
  Manufacturer? _manufacturer;
  List<Category> _categories = [];
  List<Designer> _designers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final weaponRepository = context.read<WeaponRepository>();
    final manufacturerRepository = context.read<ManufacturerRepository>();
    final categoryRepository = context.read<CategoryRepository>();
    final designerRepository = context.read<DesignerRepository>();

    final weapon = await weaponRepository.findById(widget.id);
    final manufacturer = weapon == null
        ? null
        : await manufacturerRepository.findById(weapon.manufacturerId);
    final categories = await categoryRepository.listAll();
    final designers = await designerRepository.listAll();
    if (!mounted) return;
    setState(() {
      _weapon = weapon;
      _manufacturer = manufacturer;
      _categories = categories;
      _designers = designers;
      _loading = false;
    });
  }

  String _categoryNames(List<String> ids) {
    if (ids.isEmpty) return '—';
    return ids
        .map((id) {
          for (final c in _categories) {
            if (c.id == id) return c.name;
          }
          return '—';
        })
        .join(', ');
  }

  String _designerNames(List<String> ids) {
    if (ids.isEmpty) return '—';
    return ids
        .map((id) {
          for (final d in _designers) {
            if (d.id == id) return d.fullName;
          }
          return '—';
        })
        .join(', ');
  }

  Future<void> _handleSoftDelete(Weapon w) async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить запись?',
      message: 'Логическое удаление: запись скроется из списка, её можно восстановить.',
    );
    if (!ok || !mounted) return;
    await context.read<WeaponRepository>().softDelete(w.id);
    if (!mounted) return;
    await _load();
  }

  Future<void> _handleRestore(Weapon w) async {
    await context.read<WeaponRepository>().restore(w.id);
    if (!mounted) return;
    await _load();
  }

  Future<void> _handleHardDelete(Weapon w) async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить безвозвратно?',
      message: 'Физическое удаление нельзя отменить.',
      confirmLabel: 'Удалить навсегда',
    );
    if (!ok || !mounted) return;
    await context.read<WeaponRepository>().hardDelete(w.id);
    if (!mounted) return;
    context.pop();
  }

  Future<void> _order(Weapon w) async {
    final stores = await context.read<StoreRepository>().listAll();
    if (!mounted) return;
    final storeId = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Выберите магазин для получения'),
        children: [
          for (final s in stores)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(s.id),
              child: Text(s.name),
            ),
        ],
      ),
    );
    if (storeId == null || !mounted) return;
    try {
      await context.read<OrderRepository>().create(
        weaponId: w.id,
        storeId: storeId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заказ оформлен — заберите в магазине.')),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = _weapon;
    final auth = context.watch<AuthNotifier>();
    final isStaff = auth.has(Role.seller);
    final isAdmin = auth.has(Role.admin);
    return Scaffold(
      appBar: AppBar(
        title: Text(w?.name ?? 'Оружие'),
        actions: [
          if (w != null && isStaff)
            IconButton(
              tooltip: 'Изменить',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final changed = await context.push<bool>(
                  '/weapons/${w.id}/edit',
                );
                if (changed == true) await _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : w == null
          ? Center(child: Text('Запись №${widget.id} не найдена'))
          : _buildContent(context, w, isStaff, isAdmin),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Weapon w,
    bool isStaff,
    bool isAdmin,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (w.isDeleted)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.red.withValues(alpha: 0.1),
                child: const Text(
                  'Эта запись удалена',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            _row('Название', w.name),
            _row('Артикул', w.sku),
            _row('Год выпуска', '${w.year}'),
            _row('Калибр', w.caliber),
            _row('Производитель', _manufacturer?.name ?? '—'),
            _row('Категории', _categoryNames(w.categoryIds)),
            _row('Конструкторы', _designerNames(w.designerIds)),
            _row('Цена', '${w.price} ₽'),
            _row('На складе', '${w.stockAvailable} из ${w.stockTotal}'),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              children: [
                if (!isStaff && !w.isDeleted)
                  FilledButton.icon(
                    onPressed: w.stockAvailable > 0 ? () => _order(w) : null,
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: Text(
                      w.stockAvailable > 0 ? 'Заказать' : 'Нет в наличии',
                    ),
                  ),
                if (isStaff && !w.isDeleted)
                  OutlinedButton.icon(
                    onPressed: () => _handleSoftDelete(w),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Удалить'),
                  ),
                if (isAdmin && w.isDeleted)
                  OutlinedButton.icon(
                    onPressed: () => _handleRestore(w),
                    icon: const Icon(Icons.restore),
                    label: const Text('Восстановить'),
                  ),
                if (isAdmin)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    onPressed: () => _handleHardDelete(w),
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
