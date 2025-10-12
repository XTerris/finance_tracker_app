import 'package:finance_tracker_app/services/api_exceptions.dart';
import 'package:flutter/material.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'Максим');
  final _emailController = TextEditingController(text: 'test@mail.com');
  final _passwordController = TextEditingController(text: 'password');
  bool _obscurePassword = true;
  bool _registrationMode = false;
  String? _errorMessage;
  late UserProvider _userProvider;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _errorMessage = null;
    });

    try {
      await _userProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } on UnauthorizedException {
      setState(() {
        _errorMessage = 'Неверная почта или пароль';
      });
    } on NetworkException {
      setState(() {
        _errorMessage = 'Нет подключения к интернету. Проверьте соединение и попробуйте снова.';
      });
    } on Exception catch (e) {
      setState(() {
        _errorMessage = 'Не удалось войти. Проверьте подключение к интернету.';
      });
      debugPrint('Login error: $e');
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await _userProvider.createUser(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
    } on UserEmailConflictException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } on NetworkException {
      setState(() {
        _errorMessage = 'Нет подключения к интернету. Проверьте соединение и попробуйте снова.';
      });
    } on Exception {
      setState(() {
        _errorMessage = 'Не удалось зарегистрироваться. Проверьте подключение к интернету.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(scrollbars: false),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // App logo
                _buildAppLogo(),
                const SizedBox(height: 60),

                // Login form
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUnfocus,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFormTitle(context),
                        const SizedBox(height: 32),

                        if (_registrationMode) ...[
                          // Username field
                          _buildUsernameField(),
                          const SizedBox(height: 16),
                        ],

                        // Email field
                        _buildEmailField(),
                        const SizedBox(height: 16),

                        // Password field
                        _buildPasswordField(),
                        const SizedBox(height: 24),

                        // Error message
                        if (_errorMessage != null) ...[
                          _buildErrorMessage(context),
                          const SizedBox(height: 16),
                        ],

                        // Login button
                        _buildProceedButton(context),

                        const SizedBox(height: 16),

                        // Registration link
                        _buildSwitchModeButton(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return Column(
      children: [
        Icon(
          Icons.account_balance_wallet,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Finance Tracker',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Управляйте своими финансами',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Text _buildFormTitle(BuildContext context) {
    return Text(
      _registrationMode ? 'Регистрация' : 'Вход в систему',
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  String? _usernameValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Пожалуйста, введите имя пользователя';
    }
    if (value.trim().length < 3) {
      return 'Имя пользователя должно содержать не менее 3 символов';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Пожалуйста, введите email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Пожалуйста, введите корректный email';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    int minPasswordLength = 8;

    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите пароль';
    }
    if (value.length < minPasswordLength) {
      return 'Пароль должен содержать не менее $minPasswordLength символов';
    }
    return null;
  }

  TextFormField _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: 'Имя пользователя',
        hintText: 'Введите имя пользователя',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      validator: _usernameValidator,
    );
  }

  TextFormField _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Электронная почта',
        hintText: 'Введите ваш email',
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      validator: _emailValidator,
    );
  }

  TextFormField _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Пароль',
        hintText: 'Введите ваш пароль',
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      validator: _passwordValidator,
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProceedButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        _showLoadingDialog(context);
        final navigator = Navigator.of(context);
        if (_registrationMode) {
          await _register();
        } else {
          await _login();
        }
        navigator.pop(); // Close the loading dialog
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        _registrationMode ? 'Зарегистрироваться' : 'Войти',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  TextButton _buildSwitchModeButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        setState(() {
          _registrationMode = !_registrationMode;
          _errorMessage = null;
          _usernameController.clear();
          _emailController.clear();
          _passwordController.clear();
          _formKey.currentState?.reset();
        });
      },
      child: Text(
        _registrationMode
            ? 'Уже есть аккаунт? Войти'
            : 'Нет аккаунта? Зарегистрироваться',
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
