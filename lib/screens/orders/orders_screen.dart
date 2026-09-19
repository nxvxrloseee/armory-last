import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../models/order.dart';
import '../../models/role.dart';
import '../../repositories/order_repository.dart';
import '../../state/auth_notifier.dart';
import '../../state/load_status.dart';
import '../../widgets/entity_table.dart';
import '../../widgets/status_view.dart';

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _items = [];
  LoadStatus _status = LoadStatus.loading;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
    });
    try {
      final result = await context.read<OrderRepository>().find(size: 50);
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _status = LoadStatus.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить заказы: $e';
        _status = LoadStatus.error;
      });
    }
  }

  Future<void> _cancel(Order order) async {
    try {
      await context.read<OrderRepository>().cancel(order.id);
      await _load();
    } on ApiException catch (e) {
      _showSnack(e.message);
    }
  }

  Future<void> _pickup(Order order) async {
    final controller = TextEditingController();
    final serial = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выдать оружие'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Серийный номер единицы',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Выдать'),
          ),
        ],
      ),
    );
    if (serial == null || serial.isEmpty) return;
    if (!mounted) return;
    try {
      await context.read<OrderRepository>().pickup(order.id, serial);
      await _load();
    } on ApiException catch (e) {
      _showSnack(e.message);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthNotifier>().user?.role ?? Role.buyer;
    final isStaff = role.level >= Role.seller.level;

    return Scaffold(
      appBar: AppBar(title: Text(isStaff ? 'Заказы' : 'Мои заказы')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StatusView(
          status: _status,
          error: _error,
          isEmpty: _items.isEmpty,
          onRetry: _load,
          emptyMessage: isStaff
              ? 'Заказов пока нет'
              : 'Вы ещё ничего не заказывали',
          builder: (context) => EntityTable<Order>(
            items: _items,
            idOf: (o) => o.id,
            titleOf: (o) => o.weaponName,
            columns: [
              TableColumnSpec(
                label: 'Модель',
                build: (o) => Text(o.weaponName),
              ),
              if (isStaff)
                TableColumnSpec(
                  label: 'Покупатель',
                  build: (o) => Text(o.clientName),
                ),
              TableColumnSpec(
                label: 'Статус',
                build: (o) => Text(o.statusLabel),
              ),
              TableColumnSpec(
                label: 'Серийник',
                build: (o) => Text(o.serialNumber ?? '—'),
              ),
              TableColumnSpec(
                label: 'Оформлен',
                build: (o) => Text(_formatDate(o.createdAt)),
              ),
            ],
            actions: (o) {
              if (!o.isOrdered) return const [];
              if (isStaff) {
                return [
                  TextButton(
                    onPressed: () => _pickup(o),
                    child: const Text('Выдать'),
                  ),
                ];
              }
              return [
                TextButton(
                  onPressed: () => _cancel(o),
                  child: const Text('Отменить'),
                ),
              ];
            },
          ),
        ),
      ),
    );
  }
}
