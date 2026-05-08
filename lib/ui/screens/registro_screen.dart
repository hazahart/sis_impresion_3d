import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/usuario.dart';
import '../../viewmodels/registro_viewmodel.dart';
import 'cuenta_en_revision_screen.dart';
import 'onboarding_screen.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtr = TextEditingController();
  final _contrasenaCtr = TextEditingController();
  final _confirmarCtr = TextEditingController();
  bool _verContrasena = false;
  bool _verConfirmar = false;

  @override
  void dispose() {
    _correoCtr.dispose();
    _contrasenaCtr.dispose();
    _confirmarCtr.dispose();
    super.dispose();
  }

  String? _validarCorreo(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu correo electrónico.';
    final regex = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w{2,}$');
    if (!regex.hasMatch(v.trim())) return 'El formato del correo no es válido.';
    return null;
  }

  String? _validarContrasena(String? v) {
    if (v == null || v.isEmpty) return 'Ingresa una contraseña.';
    if (v.length < 6) return 'Mínimo 6 caracteres.';
    return null;
  }

  String? _validarConfirmar(String? v) {
    if (v == null || v.isEmpty) return 'Confirma tu contraseña.';
    if (v != _contrasenaCtr.text) return 'Las contraseñas no coinciden.';
    return null;
  }

  Future<void> _registrar() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vm = ref.read(registroViewModelProvider.notifier);
    try {
      final usuario = await vm.registrar(
        correo: _correoCtr.text.trim(),
        contrasena: _contrasenaCtr.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OnboardingScreen(usuario: usuario)),
      );
    } catch (_) {
      final error = ref.read(registroViewModelProvider).errorGlobal;
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _signInGoogle() async {
    final vm = ref.read(registroViewModelProvider.notifier);
    try {
      final resultado = await vm.signInConGoogle();
      if (!mounted) return;
      if (resultado.esNuevo) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OnboardingScreen(usuario: resultado.usuario),
          ),
        );
      } else if (resultado.usuario.estado == EstadoCuenta.activo) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CuentaEnRevisionScreen()),
        );
      }
    } catch (_) {
      final error = ref.read(registroViewModelProvider).errorGlobal;
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final guardando = ref.watch(registroViewModelProvider).guardando;

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
                  const SizedBox(height: 14),
                  _buildCampoConfirmar(),
                  const SizedBox(height: 24),
                  _buildBotonCrear(guardando),
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
                            ).pushReplacementNamed('/login'),
                      child: const Text(
                        '¿Ya tienes cuenta? Inicia sesión',
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
          'Crear cuenta',
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

  Widget _buildCampoConfirmar() {
    return TextFormField(
      controller: _confirmarCtr,
      obscureText: !_verConfirmar,
      validator: _validarConfirmar,
      decoration: _deco(
        label: 'Confirmar contraseña',
        icon: Icons.lock_outline,
        suffixIcon: IconButton(
          icon: Icon(
            _verConfirmar
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFF807E82),
          ),
          onPressed: () => setState(() => _verConfirmar = !_verConfirmar),
        ),
      ),
    );
  }

  Widget _buildBotonCrear(bool guardando) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF117533),
          disabledBackgroundColor: const Color(0xFF117533).withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: guardando ? null : _registrar,
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
                'CREAR CUENTA',
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
