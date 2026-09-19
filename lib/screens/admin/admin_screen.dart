import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/role.dart';
import '../../repositories/admin_api.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<AdminUserRow> _users = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AdminApi>();
      final users = await api.listUsers();
      final stats = await api.stats();
      if (!mounted) return;
      setState(() {
        _users = users;
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить: $e';
        _loading = false;
      });
    }
  }

  Future<void> _changeRole(AdminUserRow user, Role role) async {
    try {
      await context.read<AdminApi>().setRole(user.id, role);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Администрирование')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Статистика',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(label: 'Оружие', value: _stats['weapons']),
                    _StatCard(
                      label: 'Производители',
                      value: _stats['manufacturers'],
                    ),
                    _StatCard(label: 'Категории', value: _stats['categories']),
                    _StatCard(
                      label: 'Конструкторы',
                      value: _stats['designers'],
                    ),
                    _StatCard(label: 'Покупатели', value: _stats['clients']),
                    _StatCard(
                      label: 'Активные заказы',
                      value: _stats['ordersActive'],
                    ),
                    _StatCard(
                      label: 'Выдано заказов',
                      value: _stats['ordersPickedUp'],
                    ),
                    _StatCard(
                      label: 'Пользователей',
                      value: _stats['usersTotal'],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Пользователи и роли',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final user in _users)
                  Card(
                    child: ListTile(
                      title: Text(user.fullName),
                      subtitle: Text(user.email),
                      trailing: DropdownButton<Role>(
                        value: user.role,
                        items: Role.values
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.label),
                              ),
                            )
                            .toList(),
                        onChanged: (r) {
                          if (r != null && r != user.role) _changeRole(user, r);
                        },
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${value ?? '—'}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
