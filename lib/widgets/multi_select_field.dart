import 'package:flutter/material.dart';

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
                .errorText,
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
                        field.didChange(next);
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
