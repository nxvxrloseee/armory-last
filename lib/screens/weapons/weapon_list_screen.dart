import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/designer.dart';
import '../../models/manufacturer.dart';
import '../../models/role.dart';
import '../../models/weapon.dart';
import '../../models/weapon_query.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/designer_repository.dart';
import '../../repositories/manufacturer_repository.dart';
import '../../state/auth_notifier.dart';
import '../../state/list_notifier.dart';
import '../../utils/debouncer.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/debounced_search_field.dart';
import '../../widgets/entity_table.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/status_view.dart';

class WeaponListScreen extends StatefulWidget {
  const WeaponListScreen({super.key, required this.query});

  final WeaponQuery query;

  @override
  State<WeaponListScreen> createState() => _WeaponListScreenState();
}

class _WeaponListScreenState extends State<WeaponListScreen> {
  List<Manufacturer> _manufacturers = [];
  List<Category> _categories = [];
  List<Designer> _designers = [];
  final _yearDebouncer = Debouncer(duration: const Duration(milliseconds: 300));
  late final TextEditingController _yearFromController = TextEditingController(
    text: widget.query.yearFrom?.toString() ?? '',
  );
  late final TextEditingController _yearToController = TextEditingController(
    text: widget.query.yearTo?.toString() ?? '',
  );

  @override
  void initState() {
    super.initState();
    _loadReferences();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _applyQuery(widget.query),
    );
  }

  @override
  void didUpdateWidget(covariant WeaponListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query) {
      _yearFromController.text = widget.query.yearFrom?.toString() ?? '';
      _yearToController.text = widget.query.yearTo?.toString() ?? '';
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _applyQuery(widget.query),
      );
    }
  }

  @override
  void dispose() {
    _yearDebouncer.dispose();
    _yearFromController.dispose();
    _yearToController.dispose();
    super.dispose();
  }

  Future<void> _loadReferences() async {
    final manufacturerRepository = context.read<ManufacturerRepository>();
    final categoryRepository = context.read<CategoryRepository>();
    final designerRepository = context.read<DesignerRepository>();

    final manufacturers = await manufacturerRepository.listAll();
    final categories = await categoryRepository.listAll();
    final designers = await designerRepository.listAll();
    if (!mounted) return;
    setState(() {
      _manufacturers = manufacturers;
      _categories = categories;
      _designers = designers;
    });
  }

  void _applyQuery(WeaponQuery query) {
    context.read<ListNotifier<Weapon, WeaponQuery>>().applyQuery(query);
  }

  void _navigate(WeaponQuery next) {
    context.go(
      Uri(
        path: '/weapons',
        queryParameters: next.toQueryParameters(),
      ).toString(),
    );
  }

  String _manufacturerName(String id) {
    for (final m in _manufacturers) {
      if (m.id == id) return m.name;
    }
    return '—';
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

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ListNotifier<Weapon, WeaponQuery>>();
    final isStaff = context.watch<AuthNotifier>().has(Role.seller);
    final query = widget.query;
    final result = notifier.result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Оружие'),
        leading: BackButton(onPressed: () => context.go('/')),
        actions: [
          if (isStaff)
            IconButton(
              tooltip: 'Добавить оружие',
              icon: const Icon(Icons.add),
              onPressed: () async {
                final changed = await context.push<bool>('/weapons/new');
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
            _buildFilters(context, query),
            const SizedBox(height: 12),
            if (notifier.hasSelection) _buildSelectionBar(context, notifier),
            if (notifier.hasSelection) const SizedBox(height: 8),
            Expanded(
              child: StatusView(
                status: notifier.status,
                error: notifier.error,
                isEmpty: result.items.isEmpty,
                onRetry: notifier.load,
                builder: (context) => SingleChildScrollView(
                  child: EntityTable<Weapon>(
                    items: result.items,
                    idOf: (w) => w.id,
                    titleOf: (w) => w.name,
                    selected: notifier.selected,
                    onToggleSelect: (id) => notifier.toggleSelection(id),
                    onToggleSelectAll: () => notifier.toggleSelectAll(
                      result.items.map((w) => w.id).toList(),
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
                    onTap: (w) => context.push('/weapons/${w.id}'),
                    columns: [
                      TableColumnSpec(
                        label: 'Название',
                        sortField: 'name',
                        build: (w) => ellipsisCell(w.name, width: 160),
                      ),
                      TableColumnSpec(
                        label: 'Артикул',
                        build: (w) => Text(w.sku),
                      ),
                      TableColumnSpec(
                        label: 'Год',
                        sortField: 'year',
                        numeric: true,
                        build: (w) => Text('${w.year}'),
                      ),
                      TableColumnSpec(
                        label: 'Категории',
                        build: (w) =>
                            ellipsisCell(_categoryNames(w.categoryIds)),
                      ),
                      TableColumnSpec(
                        label: 'Конструкторы',
                        build: (w) =>
                            ellipsisCell(_designerNames(w.designerIds)),
                      ),
                      TableColumnSpec(
                        label: 'Производитель',
                        build: (w) => ellipsisCell(
                          _manufacturerName(w.manufacturerId),
                          width: 160,
                        ),
                      ),
                      TableColumnSpec(
                        label: 'Цена',
                        sortField: 'price',
                        numeric: true,
                        build: (w) => Text('${w.price} ₽'),
                      ),
                      TableColumnSpec(
                        label: 'На складе',
                        numeric: true,
                        build: (w) =>
                            Text('${w.stockAvailable}/${w.stockTotal}'),
                      ),
                      if (query.includeDeleted)
                        TableColumnSpec(
                          label: 'Статус',
                          build: (w) => w.isDeleted
                              ? const Text(
                                  'Удалено',
                                  style: TextStyle(color: Colors.red),
                                )
                              : const Text('Активно'),
                        ),
                    ],
                    actions: (w) => [
                      IconButton(
                        tooltip: 'Открыть',
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => context.push('/weapons/${w.id}'),
                      ),
                      if (isStaff)
                        IconButton(
                          tooltip: 'Изменить',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () async {
                            final changed = await context.push<bool>(
                              '/weapons/${w.id}/edit',
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

  Widget _buildFilters(BuildContext context, WeaponQuery query) {
    final hasActiveFilters =
        query.search.isNotEmpty ||
        query.categoryId != null ||
        query.manufacturerId != null ||
        query.designerId != null ||
        query.yearFrom != null ||
        query.yearTo != null ||
        query.includeDeleted;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              child: DebouncedSearchField(
                initialValue: query.search,
                hintText: 'Название или артикул...',
                onChanged: (value) => _navigate(query.copyWith(search: value)),
              ),
            ),
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<String?>(
                key: ValueKey('category-${query.categoryId}'),
                initialValue: query.categoryId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(
                      'Все категории',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ..._categories.map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    _navigate(query.copyWith(categoryId: value)),
              ),
            ),
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<String?>(
                key: ValueKey('manufacturer-${query.manufacturerId}'),
                initialValue: query.manufacturerId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Производитель',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(
                      'Все производители',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ..._manufacturers.map(
                    (m) => DropdownMenuItem(
                      value: m.id,
                      child: Text(m.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    _navigate(query.copyWith(manufacturerId: value)),
              ),
            ),
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<String?>(
                key: ValueKey('designer-${query.designerId}'),
                initialValue: query.designerId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Конструктор',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(
                      'Все конструкторы',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ..._designers.map(
                    (d) => DropdownMenuItem(
                      value: d.id,
                      child: Text(d.fullName, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    _navigate(query.copyWith(designerId: value)),
              ),
            ),
            SizedBox(
              width: 110,
              child: TextField(
                controller: _yearFromController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Год от',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _yearDebouncer.run(
                  () =>
                      _navigate(query.copyWith(yearFrom: int.tryParse(value))),
                ),
              ),
            ),
            SizedBox(
              width: 110,
              child: TextField(
                controller: _yearToController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Год до',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _yearDebouncer.run(
                  () => _navigate(query.copyWith(yearTo: int.tryParse(value))),
                ),
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
                onPressed: () {
                  _yearFromController.clear();
                  _yearToController.clear();
                  _navigate(const WeaponQuery());
                },
                icon: const Icon(Icons.clear),
                label: const Text('Сбросить'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBar(
    BuildContext context,
    ListNotifier<Weapon, WeaponQuery> notifier,
  ) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    );
  }

  Future<void> _confirmDeleteSelected(
    ListNotifier<Weapon, WeaponQuery> notifier,
  ) async {
    final count = notifier.selected.length;
    final ok = await confirmDialog(
      context,
      title: 'Удалить выбранные?',
      message: 'Будет выполнено логическое удаление $count записей.',
    );
    if (ok) await notifier.deleteSelected();
  }
}
