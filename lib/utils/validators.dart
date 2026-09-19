typedef FieldValidator = String? Function(String? value);

class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(
    r'^[\w.+-]+@[\w-]+\.[\w-]+(\.[\w-]+)*$',
  );

  static FieldValidator required([String message = 'Обязательное поле']) {
    return (value) => (value == null || value.trim().isEmpty) ? message : null;
  }

  static FieldValidator maxLength(int max, {String? message}) {
    return (value) => (value != null && value.length > max)
        ? (message ?? 'Не более $max символов')
        : null;
  }

  static FieldValidator lengthRange(int min, int max, {String? message}) {
    return (value) {
      final length = value?.length ?? 0;
      if (length < min || length > max) {
        return message ?? 'Длина от $min до $max символов';
      }
      return null;
    };
  }

  static FieldValidator email({String message = 'Некорректный формат почты'}) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return null;
      }
      return _emailPattern.hasMatch(value.trim()) ? null : message;
    };
  }

  static FieldValidator intRange({
    int? min,
    int? max,
    String invalidMessage = 'Введите число',
  }) {
    return (value) {
      final n = int.tryParse(value?.trim() ?? '');
      if (n == null) return invalidMessage;
      if (min != null && n < min) return 'Не меньше $min';
      if (max != null && n > max) return 'Не больше $max';
      return null;
    };
  }

  static FieldValidator positiveInt({
    String message = 'Введите положительное число',
  }) {
    return (value) {
      final n = int.tryParse(value?.trim() ?? '');
      return (n == null || n <= 0) ? message : null;
    };
  }

  static FieldValidator combine(List<FieldValidator> validators) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  static FieldValidator password() {
    return (value) {
      final v = value ?? '';
      if (v.length < 8) return 'Пароль должен быть не короче 8 символов';
      final hasDigit = RegExp(r'[0-9]').hasMatch(v);
      final hasSpecial = RegExp(r'[^a-zA-Zа-яА-Я0-9\s]').hasMatch(v);
      if (!hasDigit) return 'Пароль должен содержать хотя бы одну цифру';
      if (!hasSpecial) {
        return 'Пароль должен содержать хотя бы один специальный символ';
      }
      return null;
    };
  }

  static String? nonEmptySelection(
    List<String>? value, [
    String message = 'Выберите хотя бы одно значение',
  ]) {
    return (value == null || value.isEmpty) ? message : null;
  }
}
