import 'package:flutter/material.dart';

import '../utils/debouncer.dart';

/// Поле поиска, которое не запускает выборку на каждое нажатие клавиши, а
/// ждёт паузы в наборе (300 мс) — иначе список перезапрашивался бы на каждый
/// введённый символ.
class DebouncedSearchField extends StatefulWidget {
  const DebouncedSearchField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.hintText = 'Поиск...',
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  final _debouncer = Debouncer(duration: const Duration(milliseconds: 300));
  final _focusNode = FocusNode();

  @override
  void didUpdateWidget(covariant DebouncedSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Внешнее изменение (например, кнопка «назад» браузера) обновляет поле,
    // но только пока пользователь в него не печатает — иначе прыгал бы курсор.
    if (!_focusNode.hasFocus && widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (value) => _debouncer.run(() => widget.onChanged(value)),
    );
  }
}
