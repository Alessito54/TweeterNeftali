import 'dart:ui';

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

      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Palette
  static const Color _bgStart = Color(0xFF0B1020);
  static const Color _bgMid = Color(0xFF3B0F6F);
  static const Color _accent = Color(0xFFFF6BB5);
  static const Color _mutedCard = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background gradient and decorative shapes
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_bgStart, _bgMid, _accent],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),
          Positioned(
            right: -80,
            top: -60,
            child: Transform.rotate(
              angle: -0.4,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Colors.white.withOpacity(0.06), Colors.transparent]),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: isWide ? _buildWide(context) : _buildNarrow(context),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left illustration / brand
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              _BrandBlock(isLarge: true),
              const SizedBox(height: 20),
              Text(
                'Conecta con tus series, comparte fanarts, y descubre comunidades afines.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 28),
              // Decorative placeholder
              Container(
                width: 420,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withOpacity(0.025),
                  border: Border.all(color: Colors.white.withOpacity(0.03)),
                ),
                child: Center(
                  child: Icon(Icons.auto_awesome, size: 96, color: Colors.white24),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 28),
        // Right form card
        Expanded(flex: 4, child: _buildForm(context)),
      ],
    );
  }

  Widget _buildNarrow(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 6),
        const _BrandBlock(isLarge: false),
        const SizedBox(height: 12),
        _buildForm(context),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode selector
            _ModeSelector(
              isRegister: _isRegisterMode,
              onToggle: (v) {
                if (_isLoading) return;
                setState(() {
                  _isRegisterMode = v;
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(height: 12),
            // Inputs
            _CustomField(
              controller: _usernameController,
              hint: 'Usuario',
              icon: Icons.account_circle_outlined,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 12),
            _CustomField(
              controller: _passwordController,
              hint: 'Contraseña',
              icon: Icons.lock_outline,
              obscure: true,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 12),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade800.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [Icon(Icons.error_outline, color: Colors.red.shade300), const SizedBox(width: 8), Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade200))) ]),
              ),
              const SizedBox(height: 12),
            ],
            // Primary action
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.black.withOpacity(0.18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Ink(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [_bgMid, _accent]),
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            _isRegisterMode ? 'Crear cuenta' : 'Iniciar sesión',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Secondary actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
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
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.06)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_isRegisterMode ? 'Ir a login' : 'Crear cuenta', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(shape: const CircleBorder(), backgroundColor: Colors.white.withOpacity(0.04)),
                    child: const Icon(Icons.login, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Features compact
            _CompactFeatures(),
          ],
        ),
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  final bool isLarge;
  const _BrandBlock({this.isLarge = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: isLarge ? 96 : 72,
          height: isLarge ? 96 : 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFF7A35C8), Color(0xFFFF6BB5)]),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 18, offset: Offset(0, 8))],
          ),
          child: const Center(child: Icon(Icons.auto_awesome, color: Colors.white, size: 40)),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AnimeNexus', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Tu comunidad anime', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
        ])
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final bool isRegister;
  final ValueChanged<bool> onToggle;
  const _ModeSelector({required this.isRegister, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onToggle(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: isRegister ? null : const LinearGradient(colors: [Color(0xFF7A35C8), Color(0xFFFF6BB5)]),
              ),
              child: Center(child: Text('Entrar', style: TextStyle(color: isRegister ? Colors.white70 : Colors.white, fontWeight: FontWeight.w800))),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: GestureDetector(
            onTap: () => onToggle(true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: isRegister ? const LinearGradient(colors: [Color(0xFF7A35C8), Color(0xFFFF6BB5)]) : null,
              ),
              child: Center(child: Text('Crear', style: TextStyle(color: isRegister ? Colors.white : Colors.white70, fontWeight: FontWeight.w800))),
            ),
          ),
        ),
      ]),
    );
  }
}

class _CustomField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final bool enabled;
  const _CustomField({required this.controller, required this.hint, required this.icon, this.obscure = false, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          width: 40,
          height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class _CompactFeatures extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 6),
        Row(children: [
          _FeatureChip(icon: Icons.brush, text: 'Fanarts'),
          const SizedBox(width: 8),
          _FeatureChip(icon: Icons.forum, text: 'Hilos'),
          const SizedBox(width: 8),
          _FeatureChip(icon: Icons.flash_on, text: 'Rápido'),
        ])
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white.withOpacity(0.02)),
      child: Row(children: [
        Container(width: 28, height: 28, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF7A35C8), Color(0xFFFF6BB5)])), child: Icon(icon, size: 16, color: Colors.white)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
