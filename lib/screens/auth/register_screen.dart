import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../models/register_input.dart';
import '../../state/auth_notifier.dart';
import '../../utils/validators.dart';
import '../../widgets/entity_form_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _password = TextEditingController();
  final _lastName = TextEditingController();
  final _firstName = TextEditingController();
  final _patronymic = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  String? _emailServerError;

  @override
  void dispose() {
    for (final c in [
      _password,
      _lastName,
      _firstName,
      _patronymic,
      _email,
      _phone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _emailServerError = null);
    final input = RegisterInput(
      email: _email.text.trim(),
      password: _password.text,
      lastName: _lastName.text.trim(),
      firstName: _firstName.text.trim(),
      patronymic: _patronymic.text.trim().isEmpty
          ? null
          : _patronymic.text.trim(),
      phone: _phone.text.trim(),
    );
    try {
      await context.read<AuthNotifier>().register(input);
    } on ValidationException catch (e) {
      final emailError = e.errors['email'];
      if (emailError != null) {
        setState(() => _emailServerError = emailError);
        return;
      }
      rethrow;
    }
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return EntityFormScaffold(
      title: 'Регистрация покупателя',
      isDirty: false,
      saveLabel: 'Зарегистрироваться',
      onSave: _submit,
      fields: [
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Почта',
            border: const OutlineInputBorder(),
            errorText: _emailServerError,
          ),
          validator: Validators.combine([
            Validators.required(),
            Validators.email(),
          ]),
          onChanged: (_) => setState(() => _emailServerError = null),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Пароль',
            border: OutlineInputBorder(),
          ),
          validator: Validators.password(),
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
        const SizedBox(height: 24),
        const Text('Личные данные', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _lastName,
          decoration: const InputDecoration(
            labelText: 'Фамилия',
            border: OutlineInputBorder(),
          ),
          validator: Validators.combine([
            Validators.required(),
            Validators.maxLength(100),
          ]),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _firstName,
          decoration: const InputDecoration(
            labelText: 'Имя',
            border: OutlineInputBorder(),
          ),
          validator: Validators.combine([
            Validators.required(),
            Validators.maxLength(100),
          ]),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _patronymic,
          decoration: const InputDecoration(
            labelText: 'Отчество (необязательно)',
            border: OutlineInputBorder(),
          ),
          validator: Validators.maxLength(100),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Телефон',
            border: OutlineInputBorder(),
          ),
          validator: Validators.combine([
            Validators.required(),
            Validators.lengthRange(5, 20),
          ]),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Уже есть аккаунт? Войти'),
        ),
      ],
    );
  }
}
