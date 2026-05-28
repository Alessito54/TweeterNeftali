import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isRegisterMode = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegisterMode) {
        await _authService.register(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _authService.login(
          _usernameController.text.trim(),
          _passwordController.text,
        );
      }

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(_isRegisterMode ? 'Crear cuenta' : 'Iniciar sesión'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF4E9), Color(0xFFF7F7FB), Color(0xFFF7F7FB)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.motorcycle, size: 42, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Moto Tweeter',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRegisterMode
                            ? 'Crea una cuenta y comparte tu pasión por las motos'
                            : 'Entra y sigue la conversación sobre motos',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ModePill(
                        active: !_isRegisterMode,
                        icon: Icons.login,
                        label: 'Entrar',
                        onTap: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isRegisterMode = false;
                                  _errorMessage = null;
                                });
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ModePill(
                        active: _isRegisterMode,
                        icon: Icons.person_add,
                        label: 'Crear cuenta',
                        onTap: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isRegisterMode = true;
                                  _errorMessage = null;
                                });
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _usernameController,
                          enabled: !_isLoading,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Usuario',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          enabled: !_isLoading,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Colors.red.shade900),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Text(_isRegisterMode ? 'Crear cuenta' : 'Iniciar sesión'),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _isRegisterMode
                              ? 'No necesitas correo. Solo usuario y contraseña.'
                              : 'Usa tu cuenta para entrar al feed.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  color: Colors.white.withValues(alpha: 0.92),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Qué puedes hacer?',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        const _FeatureRow(
                          icon: Icons.auto_awesome,
                          text: 'Publicar tweets con fotos de tus motos',
                        ),
                        const SizedBox(height: 10),
                        const _FeatureRow(
                          icon: Icons.delete_outline,
                          text: 'Eliminar solo tus posts, o todo si eres admin',
                        ),
                        const SizedBox(height: 10),
                        const _FeatureRow(
                          icon: Icons.shield_outlined,
                          text: 'Entrar sin correo y con inicio rápido',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isRegisterMode = !_isRegisterMode;
                            _errorMessage = null;
                            _usernameController.clear();
                            _passwordController.clear();
                          });
                        },
                  child: Text(
                    _isRegisterMode
                        ? '¿Ya tienes cuenta? Cambia a login'
                        : '¿Nuevo aquí? Cambia a crear cuenta',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
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
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.active,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: active ? scheme.primary : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: active ? 0 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: active ? Colors.white : scheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
        ),
      ],
    );
  }
}
