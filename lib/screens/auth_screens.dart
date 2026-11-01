import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../state/auth_notifier.dart';
import '../validation/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthNotifier>().login(
        _username.text.trim(),
        _password.text,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Вход в библиотеку',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (auth.logoutReason != null)
                    Card(
                      color: theme.colorScheme.secondaryContainer,
                      child: ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: Text(auth.logoutReason!),
                      ),
                    ),
                  if (_error != null)
                    Card(
                      color: theme.colorScheme.errorContainer,
                      child: ListTile(
                        leading: const Icon(Icons.error_outline),
                        title: Text(_error!),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _username,
                    decoration: const InputDecoration(
                      labelText: 'Логин',
                      border: OutlineInputBorder(),
                    ),
                    validator: requiredField,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Пароль',
                      border: OutlineInputBorder(),
                    ),
                    validator: requiredField,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: const Text('Войти'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Регистрация'),
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  Map<String, String> _serverErrors = {};

  @override
  void dispose() {
    for (final c in [_username, _fullName, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthNotifier>().register(
        username: _username.text.trim(),
        password: _password.text,
        email: _email.text.trim(),
        fullName: _fullName.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Учётная запись создана, войдите')),
      );
      context.go('/login');
    } on ValidationException catch (e) {
      setState(() => _serverErrors = e.errors);
      _formKey.currentState!.validate();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(
    TextEditingController c,
    String key,
    String label,
    Validator validator, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) => _serverErrors[key] ?? validator(v),
        onChanged: (_) {
          if (key == 'password') setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final password = _password.text;
    final checks = [
      ('Не короче восьми символов', passwordLength(password) == null),
      ('Есть цифра', passwordDigit(password) == null),
      ('Есть специальный символ', passwordSpecial(password) == null),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
        leading: IconButton(
          tooltip: 'Назад',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _field(
                    _username,
                    'username',
                    'Логин',
                    combine([requiredField, minLength(3), maxLength(30)]),
                  ),
                  _field(
                    _fullName,
                    'fullName',
                    'ФИО',
                    combine([requiredField, maxLength(100), personName]),
                  ),
                  _field(
                    _email,
                    'email',
                    'Электронная почта',
                    combine([requiredField, email]),
                  ),
                  _field(
                    _password,
                    'password',
                    'Пароль',
                    combine([
                      requiredField,
                      passwordLength,
                      passwordDigit,
                      passwordSpecial,
                    ]),
                    obscure: true,
                  ),
                  for (final (label, ok) in checks)
                    Row(
                      children: [
                        Icon(
                          ok
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color:
                              ok ? Colors.green : Theme.of(context).hintColor,
                        ),
                        const SizedBox(width: 8),
                        Text(label),
                      ],
                    ),
                  const SizedBox(height: 16),
                  _field(
                    _confirm,
                    'confirm',
                    'Повторите пароль',
                    (v) => v != _password.text ? 'Пароли не совпадают' : null,
                    obscure: true,
                  ),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: const Text('Зарегистрироваться'),
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
