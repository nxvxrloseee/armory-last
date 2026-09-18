import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/designer.dart';
import '../../models/designer_query.dart';
import '../../models/role.dart';
import '../../state/auth_notifier.dart';
import '../../state/list_notifier.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/debounced_search_field.dart';
import '../../widgets/entity_table.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/status_view.dart';

class DesignerListScreen extends StatefulWidget {
  const DesignerListScreen({super.key, required this.query});

  final DesignerQuery query;

  @override
  State<DesignerListScreen> createState() => _DesignerListScreenState();
}

class _DesignerListScreenState extends State<DesignerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _applyQuery(widget.query),
    );
  }

  @override
  void didUpdateWidget(covariant DesignerListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _applyQuery(widget.query),
      );
    }
  }

  void _applyQuery(DesignerQuery query) {
    context.read<ListNotifier<Designer, DesignerQuery>>().applyQuery(query);
  }

  void _navigate(DesignerQuery next) {
    context.go(
      Uri(
        path: '/designers',
        queryParameters: next.toQueryParameters(),
      ).toString(),
    );
  }

  Future<void> _confirmDeleteSelected(
    ListNotifier<Designer, DesignerQuery> notifier,
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
    final notifier = context.watch<ListNotifier<Designer, DesignerQuery>>();
    final isStaff = context.watch<AuthNotifier>().has(Role.seller);
    final query = widget.query;
    final result = notifier.result;
    final hasActiveFilters = query.search.isNotEmpty || query.includeDeleted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Конструкторы'),
        leading: BackButton(onPressed: () => context.go('/')),
        actions: [
          if (isStaff)
            IconButton(
              tooltip: 'Добавить конструктора',
              icon: const Icon(Icons.add),
              onPressed: () async {
                final changed = await context.push<bool>('/designers/new');
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
                        hintText: 'Имя или страна...',
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
                        onPressed: () => _navigate(const DesignerQuery()),
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
                  child: EntityTable<Designer>(
                    items: result.items,
                    idOf: (d) => d.id,
                    titleOf: (d) => d.fullName,
                    selected: notifier.selected,
                    onToggleSelect: (id) => notifier.toggleSelection(id),
                    onToggleSelectAll: () => notifier.toggleSelectAll(
                      result.items.map((d) => d.id).toList(),
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
                    onTap: (d) => context.push('/designers/${d.id}'),
                    columns: [
                      TableColumnSpec(
                        label: 'Имя',
                        sortField: 'fullName',
                        build: (d) => ellipsisCell(d.fullName),
                      ),
                      TableColumnSpec(
                        label: 'Страна',
                        sortField: 'country',
                        build: (d) => Text(d.country),
                      ),
                      TableColumnSpec(
                        label: 'Работает с',
                        sortField: 'activeSince',
                        numeric: true,
                        build: (d) => Text('${d.activeSince}'),
                      ),
                      if (query.includeDeleted)
                        TableColumnSpec(
                          label: 'Статус',
                          build: (d) => d.isDeleted
                              ? const Text(
                                  'Удалено',
                                  style: TextStyle(color: Colors.red),
                                )
                              : const Text('Активно'),
                        ),
                    ],
                    actions: (d) => [
                      IconButton(
                        tooltip: 'Открыть',
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => context.push('/designers/${d.id}'),
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
