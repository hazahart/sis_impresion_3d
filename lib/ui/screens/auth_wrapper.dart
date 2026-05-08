import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import 'cuenta_en_revision_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'registro_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Usuario?> _obtenerUsuario(String uid) async {
    for (int intento = 0; intento < 5; intento++) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();
      if (doc.exists) {
        return Usuario.fromMap(doc.data()!, id: uid);
      }
      // Esperar antes del siguiente intento
      await Future.delayed(const Duration(milliseconds: 600));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authSnap.hasData) return const RegistroScreen();

        final firebaseUser = authSnap.data!;

        return FutureBuilder<Usuario?>(
          future: _obtenerUsuario(firebaseUser.uid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Después de 5 intentos sigue sin existir
            // → construir desde Auth y mandar al onboarding
            if (!snap.hasData || snap.data == null) {
              final correo = firebaseUser.email ?? '';
              final usuarioMinimo = Usuario(
                id: firebaseUser.uid,
                correo: correo,
                rol: RolUsuario.operador,
                estado: Usuario.esInstitucional(correo)
                    ? EstadoCuenta.activo
                    : EstadoCuenta.pendienteAprobacion,
                fechaRegistro: DateTime.now(),
              );
              return OnboardingScreen(usuario: usuarioMinimo);
            }

            final usuario = snap.data!;

            if (usuario.nombreCompleto == null ||
                usuario.nombreCompleto!.trim().isEmpty) {
              return OnboardingScreen(usuario: usuario);
            }

            if (usuario.estado == EstadoCuenta.pendienteAprobacion) {
              return const CuentaEnRevisionScreen();
            }

            return const HomeScreen();
          },
        );
      },
    );
  }
}
