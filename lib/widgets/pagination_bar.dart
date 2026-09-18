import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.size,
    required this.onPageChanged,
    required this.onSizeChanged,
  });

  final int page;
  final int totalPages;
  final int total;
  final int size;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Всего: $total'),
        IconButton(
          tooltip: 'Первая страница',
          onPressed: page > 1 ? () => onPageChanged(1) : null,
          icon: const Icon(Icons.first_page),
        ),
        IconButton(
          tooltip: 'Предыдущая страница',
          onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Стр. $page из $totalPages'),
        IconButton(
          tooltip: 'Следующая страница',
          onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
        IconButton(
          tooltip: 'Последняя страница',
          onPressed: page < totalPages ? () => onPageChanged(totalPages) : null,
          icon: const Icon(Icons.last_page),
        ),
        const SizedBox(width: 8),
        const Text('На странице:'),
        DropdownButton<int>(
          value: size,
          items: const [
            10,
            25,
            50,
          ].map((s) => DropdownMenuItem(value: s, child: Text('$s'))).toList(),
          onChanged: (value) {
            if (value != null) onSizeChanged(value);
          },
        ),
      ],
    );
  }
}
