import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Экран отказа — редирект приводит сюда, а не роняет приложение и не
/// показывает пустой экран, когда роль не подходит для маршрута (ПР5,
/// оценка «4»). Это то же самое решение, что мгновенно вернёт сервер кодом
/// 403, если кто-то доберётся до защищённого действия в обход интерфейса —
/// см. п.17 задания.
class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Доступ запрещён')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('Недостаточно прав для этого раздела'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    );
  }
}
