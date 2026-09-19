import 'package:flutter/material.dart';

Widget ellipsisCell(String text, {double width = 200, TextStyle? style}) {
  return SizedBox(
    width: width,
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    ),
  );
}

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    required this.titleOf,
    this.selected = const {},
    this.onToggleSelect,
    this.onToggleSelectAll,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
    this.onTap,
    this.narrowBreakpoint = 600,
  });

  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final String Function(T item) idOf;
  final String Function(T item) titleOf;
  final Set<String> selected;
  final ValueChanged<String>? onToggleSelect;
  final VoidCallback? onToggleSelectAll;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;
  final void Function(T item)? onTap;
  final double narrowBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < narrowBreakpoint) {
          return _buildCards(context);
        }
        return _buildTable(context);
      },
    );
  }

  Widget _buildCards(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final id = idOf(item);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: InkWell(
            onTap: onTap == null ? null : () => onTap!(item),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onToggleSelect != null)
                    Checkbox(
                      value: selected.contains(id),
                      onChanged: (_) => onToggleSelect!(id),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleOf(item),
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        for (final c in columns)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    '${c.label}:',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ),
                                Expanded(child: c.build(item)),
                              ],
                            ),
                          ),
                        if (actions != null) ...[
                          const SizedBox(height: 8),
                          Wrap(spacing: 4, children: actions!(item)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable(BuildContext context) {
    final sortColumnIndex = sortField == null
        ? null
        : columns.indexWhere((c) => c.sortField == sortField);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: onToggleSelect != null,
        sortColumnIndex: sortColumnIndex != null && sortColumnIndex >= 0
            ? sortColumnIndex
            : null,
        sortAscending: sortAscending,
        onSelectAll: onToggleSelectAll == null
            ? null
            : (_) => onToggleSelectAll!(),
        columns: [
          for (final c in columns)
            DataColumn(
              label: Text(c.label),
              numeric: c.numeric,
              onSort: (c.sortField != null && onSort != null)
                  ? (_, _) => onSort!(c.sortField!)
                  : null,
            ),
          if (actions != null) const DataColumn(label: Text('')),
        ],
        rows: [
          for (final item in items)
            DataRow(
              selected: selected.contains(idOf(item)),
              onSelectChanged: onToggleSelect == null
                  ? null
                  : (_) => onToggleSelect!(idOf(item)),
              cells: [
                for (final c in columns)
                  DataCell(
                    c.build(item),
                    onTap: onTap == null ? null : () => onTap!(item),
                  ),
                if (actions != null)
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!(item),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
