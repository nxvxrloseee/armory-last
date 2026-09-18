import 'package:flutter/material.dart';

/// Реализация связи «многие ко многим» в интерфейсе: набор [FilterChip] в
/// [FormField]&lt;List&lt;int&gt;&gt;, как описано в приложении Б (раздел 3.3) —
/// готового виджета множественного выбора в Material нет. Один и тот же
/// виджет переиспользуется для категорий и конструкторов оружия.
class MultiSelectField extends StatelessWidget {
  const MultiSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.initialValue,
    required this.onChanged,
    this.validator,
  });

  final String label;

  /// Пары (id, отображаемое имя) — обычно из `repository.listAll()`, а не
  /// из констант в коде.
  final List<(String, String)> options;
  final List<String> initialValue;
  final ValueChanged<List<String>> onChanged;
  final String? Function(List<String>?)? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
      initialValue: initialValue,
      validator: validator,
      builder: (field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            errorText: field
                .errorText, // ошибка показывается так же, как у обычного поля
          ),
          child: options.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Нет доступных значений',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options.map((option) {
                    final (id, name) = option;
                    final selected = field.value!.contains(id);
                    return FilterChip(
                      label: Text(name),
                      selected: selected,
                      onSelected: (_) {
                        final next = [...field.value!];
                        selected ? next.remove(id) : next.add(id);
                        field.didChange(next); // сообщаем форме об изменении
                        onChanged(next);
                      },
                    );
                  }).toList(),
                ),
        );
      },
    );
  }
}
