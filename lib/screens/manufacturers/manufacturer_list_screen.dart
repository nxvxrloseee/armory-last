import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/manufacturer.dart';
import '../../models/manufacturer_query.dart';
import '../../models/role.dart';
import '../../state/auth_notifier.dart';
import '../../state/list_notifier.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/debounced_search_field.dart';
import '../../widgets/entity_table.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/status_view.dart';

class ManufacturerListScreen extends StatefulWidget {
  const ManufacturerListScreen({super.key, required this.query});

  final ManufacturerQuery query;

  @override
  State<ManufacturerListScreen> createState() => _ManufacturerListScreenState();
}

class _ManufacturerListScreenState extends State<ManufacturerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _applyQuery(widget.query),
    );
  }

  @override
  void didUpdateWidget(covariant ManufacturerListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _applyQuery(widget.query),
      );
    }
  }

  void _applyQuery(ManufacturerQuery query) {
    context.read<ListNotifier<Manufacturer, ManufacturerQuery>>().applyQuery(
      query,
    );
  }

  void _navigate(ManufacturerQuery next) {
    context.go(
      Uri(
        path: '/manufacturers',
        queryParameters: next.toQueryParameters(),
      ).toString(),
    );
  }

  Future<void> _confirmDeleteSelected(
    ListNotifier<Manufacturer, ManufacturerQuery> notifier,
  ) async {
    final count = notifier.selected.length;
    final ok = await confirmDialog(
      context,
      title: 'Удалить выбранные?',
      message: 'Будет выполнено логическое удаление $count записей.',
    );
    if (ok) await notifier.deleteSelected();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context
        .watch<ListNotifier<Manufacturer, ManufacturerQuery>>();
    final isStaff = context.watch<AuthNotifier>().has(Role.seller);
    final query = widget.query;
    final result = notifier.result;
    final hasActiveFilters = query.search.isNotEmpty || query.includeDeleted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Производители'),
        leading: BackButton(onPressed: () => context.go('/')),
        actions: [
          if (isStaff)
            IconButton(
              tooltip: 'Добавить производителя',
              icon: const Icon(Icons.add),
              onPressed: () async {
                final changed = await context.push<bool>('/manufacturers/new');
                if (changed == true) _applyQuery(query);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 280,
                      child: DebouncedSearchField(
                        initialValue: query.search,
                        hintText: 'Название или страна...',
                        onChanged: (value) =>
                            _navigate(query.copyWith(search: value)),
                      ),
                    ),
                    FilterChip(
                      label: const Text('Показывать удалённые'),
                      selected: query.includeDeleted,
                      onSelected: (value) =>
                          _navigate(query.copyWith(includeDeleted: value)),
                    ),
                    if (hasActiveFilters)
                      TextButton.icon(
                        onPressed: () => _navigate(const ManufacturerQuery()),
                        icon: const Icon(Icons.clear),
                        label: const Text('Сбросить'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (notifier.hasSelection)
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text('Выбрано: ${notifier.selected.length}'),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _confirmDeleteSelected(notifier),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Удалить выбранные'),
                      ),
                    ],
                  ),
                ),
              ),
            if (notifier.hasSelection) const SizedBox(height: 8),
            Expanded(
              child: StatusView(
                status: notifier.status,
                error: notifier.error,
                isEmpty: result.items.isEmpty,
                onRetry: notifier.load,
                builder: (context) => SingleChildScrollView(
                  child: EntityTable<Manufacturer>(
                    items: result.items,
                    idOf: (m) => m.id,
                    titleOf: (m) => m.name,
                    selected: notifier.selected,
                    onToggleSelect: (id) => notifier.toggleSelection(id),
                    onToggleSelectAll: () => notifier.toggleSelectAll(
                      result.items.map((m) => m.id).toList(),
                    ),
                    sortField: query.sortField,
                    sortAscending: query.sortAscending,
                    onSort: (field) => _navigate(
                      query.copyWith(
                        sortField: field,
                        sortAscending: field == query.sortField
                            ? !query.sortAscending
                            : true,
                      ),
                    ),
                    onTap: (m) => context.push('/manufacturers/${m.id}'),
                    columns: [
                      TableColumnSpec(
                        label: 'Название',
                        sortField: 'name',
                        build: (m) => ellipsisCell(m.name),
                      ),
                      TableColumnSpec(
                        label: 'Страна',
                        sortField: 'country',
                        build: (m) => Text(m.country),
                      ),
                      TableColumnSpec(
                        label: 'Год основания',
                        sortField: 'founded',
                        numeric: true,
                        build: (m) => Text('${m.founded}'),
                      ),
                      if (query.includeDeleted)
                        TableColumnSpec(
                          label: 'Статус',
                          build: (m) => m.isDeleted
                              ? const Text(
                                  'Удалено',
                                  style: TextStyle(color: Colors.red),
                                )
                              : const Text('Активно'),
                        ),
                    ],
                    actions: (m) => [
                      IconButton(
                        tooltip: 'Открыть',
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => context.push('/manufacturers/${m.id}'),
                      ),
                      if (isStaff)
                        IconButton(
                          tooltip: 'Изменить',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () async {
                            final changed = await context.push<bool>(
                              '/manufacturers/${m.id}/edit',
                            );
                            if (changed == true) _applyQuery(query);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            PaginationBar(
              page: result.page,
              totalPages: result.totalPages,
              total: result.total,
              size: query.size,
              onPageChanged: (p) => _navigate(query.copyWith(page: p)),
              onSizeChanged: (s) => _navigate(query.copyWith(size: s)),
            ),
          ],
        ),
      ),
    );
  }
}
