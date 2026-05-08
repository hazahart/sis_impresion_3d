import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/usuario.dart';
import '../../viewmodels/login_viewmodel.dart';
import 'cuenta_en_revision_screen.dart';
import 'onboarding_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtr = TextEditingController();
  final _contrasenaCtr = TextEditingController();
  bool _verContrasena = false;

  @override
  void dispose() {
    _correoCtr.dispose();
    _contrasenaCtr.dispose();
    super.dispose();
  }

  String? _validarCorreo(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu correo electrónico.';
    final regex = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w{2,}$');
    if (!regex.hasMatch(v.trim())) return 'El formato del correo no es válido.';
    return null;
  }

  String? _validarContrasena(String? v) {
    if (v == null || v.isEmpty) return 'Ingresa tu contraseña.';
    return null;
  }

  void _navegarSegunUsuario(Usuario usuario, {bool esNuevo = false}) {
    if (esNuevo ||
        usuario.nombreCompleto == null ||
        usuario.nombreCompleto!.trim().isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OnboardingScreen(usuario: usuario)),
      );
      return;
    }
    if (usuario.estado == EstadoCuenta.pendienteAprobacion) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CuentaEnRevisionScreen()),
      );
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

  Future<void> _iniciarSesion() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vm = ref.read(loginViewModelProvider.notifier);
    try {
      final usuario = await vm.iniciarSesion(
        correo: _correoCtr.text.trim(),
        contrasena: _contrasenaCtr.text,
      );
      if (!mounted) return;
      _navegarSegunUsuario(usuario);
    } catch (_) {
      final error = ref.read(loginViewModelProvider).errorGlobal;
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _signInGoogle() async {
    final vm = ref.read(loginViewModelProvider.notifier);
    try {
      final resultado = await vm.signInConGoogle();
      if (!mounted) return;
      _navegarSegunUsuario(resultado.usuario, esNuevo: resultado.esNuevo);
    } catch (_) {
      final error = ref.read(loginViewModelProvider).errorGlobal;
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final guardando = ref.watch(loginViewModelProvider).guardando;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 32),
                  _buildCampoCorreo(),
                  const SizedBox(height: 14),
                  _buildCampoContrasena(),
                  const SizedBox(height: 24),
                  _buildBotonLogin(guardando),
                  const SizedBox(height: 16),
                  _buildDivisor(),
                  const SizedBox(height: 16),
                  _buildBotonGoogle(guardando),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: guardando
                          ? null
                          : () => Navigator.of(
                              context,
                            ).pushReplacementNamed('/registro'),
                      child: const Text(
                        '¿No tienes cuenta? Regístrate',
                        style: TextStyle(color: Color(0xFF1B396A)),
                      ),
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

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF1B396A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.print_outlined,
            color: Colors.white,
            size: 38,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'SisImpresion3D',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B396A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Inicia sesión para continuar',
          style: TextStyle(fontSize: 13, color: Color(0xFF807E82)),
        ),
      ],
    );
  }

  Widget _buildCampoCorreo() {
    return TextFormField(
      controller: _correoCtr,
      keyboardType: TextInputType.emailAddress,
      validator: _validarCorreo,
      decoration: _deco(
        label: 'Correo electrónico',
        icon: Icons.email_outlined,
      ),
    );
  }

  Widget _buildCampoContrasena() {
    return TextFormField(
      controller: _contrasenaCtr,
      obscureText: !_verContrasena,
      validator: _validarContrasena,
      decoration: _deco(
        label: 'Contraseña',
        icon: Icons.lock_outline,
        suffixIcon: IconButton(
          icon: Icon(
            _verContrasena
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFF807E82),
          ),
          onPressed: () => setState(() => _verContrasena = !_verContrasena),
        ),
      ),
    );
  }

  Widget _buildBotonLogin(bool guardando) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B396A),
          disabledBackgroundColor: const Color(0xFF1B396A).withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: guardando ? null : _iniciarSesion,
        child: guardando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'INICIAR SESIÓN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildDivisor() {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFCCCCCC))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o',
            style: TextStyle(color: Color(0xFF807E82), fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFCCCCCC))),
      ],
    );
  }

  Widget _buildBotonGoogle(bool guardando) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFCCCCCC)),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: guardando ? null : _signInGoogle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: 'G',
                    style: TextStyle(color: Color(0xFF4285F4)),
                  ),
                  TextSpan(
                    text: 'o',
                    style: TextStyle(color: Color(0xFFEA4335)),
                  ),
                  TextSpan(
                    text: 'o',
                    style: TextStyle(color: Color(0xFFFBBC05)),
                  ),
                  TextSpan(
                    text: 'g',
                    style: TextStyle(color: Color(0xFF4285F4)),
                  ),
                  TextSpan(
                    text: 'l',
                    style: TextStyle(color: Color(0xFF34A853)),
                  ),
                  TextSpan(
                    text: 'e',
                    style: TextStyle(color: Color(0xFFEA4335)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continuar con Google',
              style: TextStyle(
                color: Color(0xFF212121),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _deco({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: const Color(0xFF1B396A)),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF117533), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1B396A), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
