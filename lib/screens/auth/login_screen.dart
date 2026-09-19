import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../state/auth_notifier.dart';
import '../../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.from});

  final String? from;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _saving = false;
  String? _formError;
  String? _logoutReason;

  @override
  void initState() {
    super.initState();
    _logoutReason = context.read<AuthNotifier>().consumeLogoutReason();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthNotifier>().login(
        _username.text.trim(),
        _password.text,
      );
      if (!mounted) return;
      context.go(widget.from ?? '/');
    } on UnauthorizedException catch (e) {
      setState(() => _formError = e.message);
    } on ApiException catch (e) {
      setState(() => _formError = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final restoreError = context.read<AuthNotifier>().restoreError;
    return Scaffold(
      appBar: AppBar(title: const Text('Вход')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Оружейный магазин',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  if (_logoutReason != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_logoutReason!),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (restoreError != null) ...[
                    Text(
                      restoreError,
                      style: const TextStyle(color: Colors.orange),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_formError != null) ...[
                    Text(
                      _formError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _username,
                    decoration: const InputDecoration(labelText: 'Логин'),
                    validator: Validators.required(),
                    onChanged: (_) => setState(() => _formError = null),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: 'Пароль'),
                    obscureText: true,
                    validator: Validators.required(),
                    onChanged: (_) => setState(() => _formError = null),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Войти'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text(
                      'Нет аккаунта? Зарегистрироваться как покупатель',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
