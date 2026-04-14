import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/pl_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() => _error = 'Заполните все поля');
      return;
    }
    if (!_isLogin && _nameController.text.trim().isEmpty) {
      setState(() => _error = 'Введите имя');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    String? result;

    if (_isLogin) {
      result = await auth.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } else {
      result = await auth.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }

    if (mounted) {
      if (result == 'EMAIL_CONFIRM') {
        setState(() => _isLoading = false);
        _showEmailConfirmDialog();
      } else {
        setState(() {
          _isLoading = false;
          _error = result;
        });
      }
    }
  }

  void _showEmailConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: 10),
            Text('Проверьте почту'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Мы отправили письмо на ${_emailController.text.trim()}.\n\nОткройте ссылку из письма для подтверждения аккаунта, затем вернитесь и войдите.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Проверьте папку «Спам» если письмо не пришло',
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isLogin = true);
            },
            child: const Text('Понятно', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/back.jpg', fit: BoxFit.cover),
          Container(color: AppColors.of(context).scaffoldBg),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const PLLogo(size: 88),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'PERFORMANCE LAB',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Управляй командой',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.of(context).textHint,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 50),

                    if (_error != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    GlassCard(
                      child: Column(
                        children: [
                          if (!_isLogin) ...[
                            _buildField(_nameController, 'Имя',
                                Icons.person_outline),
                            const SizedBox(height: 16),
                          ],
                          _buildField(
                              _emailController, 'Email', Icons.email_outlined),
                          const SizedBox(height: 16),
                          _buildField(_passwordController, 'Пароль',
                              Icons.lock_outline,
                              obscure: true),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isLogin
                                          ? 'Войти'
                                          : 'Зарегистрироваться',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLogin)
                      TextButton(
                        onPressed: () => _showResetPasswordDialog(context),
                        child: Text(
                          'Забыл пароль?',
                          style: TextStyle(
                            color: AppColors.primary.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() {
                        _isLogin = !_isLogin;
                        _error = null;
                      }),
                      child: Text(
                        _isLogin
                            ? 'Нет аккаунта? Зарегистрироваться'
                            : 'Уже есть аккаунт? Войти',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
      TextEditingController ctrl, String label, IconData icon,
      {bool obscure = false}) {
    final t = AppColors.of(context);
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: TextStyle(color: t.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Сброс пароля'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Введите email — мы отправим ссылку для сброса пароля',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              style: TextStyle(color: AppColors.of(context).textPrimary),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined,
                    color: AppColors.primary, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) return;
              final auth = context.read<AuthProvider>();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final error = await auth.resetPassword(email);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(error ??
                      'Письмо отправлено на $email'),
                  backgroundColor:
                      error == null ? AppColors.success : AppColors.error,
                ),
              );
            },
            child: const Text('Отправить',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
