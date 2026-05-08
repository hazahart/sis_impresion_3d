import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/auth_repository.dart';
import '../models/usuario.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());
final usuarioSesionProvider = StateProvider<Usuario?>((ref) => null);

class RegistroState {
  final bool guardando;
  final String? errorGlobal;

  const RegistroState({this.guardando = false, this.errorGlobal});

  RegistroState copyWith({
    bool? guardando,
    String? errorGlobal,
    bool limpiarError = false,
  }) => RegistroState(
    guardando: guardando ?? this.guardando,
    errorGlobal: limpiarError ? null : (errorGlobal ?? this.errorGlobal),
  );
}

final registroViewModelProvider =
    NotifierProvider<RegistroViewModel, RegistroState>(
      () => RegistroViewModel(),
    );

class RegistroViewModel extends Notifier<RegistroState> {
  @override
  RegistroState build() => const RegistroState();

  Future<Usuario> registrar({
    required String correo,
    required String contrasena,
  }) async {
    state = state.copyWith(guardando: true, limpiarError: true);
    try {
      final usuario = await ref
          .read(authRepositoryProvider)
          .registrar(correo: correo, contrasena: contrasena);
      ref.read(usuarioSesionProvider.notifier).state = usuario;
      return usuario;
    } catch (e) {
      final mensaje = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(guardando: false, errorGlobal: mensaje);
      rethrow;
    } finally {
      if (state.guardando) state = state.copyWith(guardando: false);
    }
  }

  Future<({Usuario usuario, bool esNuevo})> signInConGoogle() async {
    state = state.copyWith(guardando: true, limpiarError: true);
    try {
      final resultado = await ref
          .read(authRepositoryProvider)
          .signInConGoogle();
      ref.read(usuarioSesionProvider.notifier).state = resultado.usuario;
      return resultado;
    } catch (e) {
      final mensaje = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(guardando: false, errorGlobal: mensaje);
      rethrow;
    } finally {
      if (state.guardando) state = state.copyWith(guardando: false);
    }
  }
}

class OnboardingState {
  final bool guardando;
  final String? fotoPath;

  const OnboardingState({this.guardando = false, this.fotoPath});

  OnboardingState copyWith({
    bool? guardando,
    String? fotoPath,
    bool limpiarFoto = false,
  }) => OnboardingState(
    guardando: guardando ?? this.guardando,
    fotoPath: limpiarFoto ? null : (fotoPath ?? this.fotoPath),
  );
}

final onboardingViewModelProvider =
    NotifierProvider<OnboardingViewModel, OnboardingState>(
      () => OnboardingViewModel(),
    );

class OnboardingViewModel extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void setFotoPath(String? path) {
    if (path == null) {
      state = state.copyWith(limpiarFoto: true);
    } else {
      state = state.copyWith(fotoPath: path);
    }
  }

  Future<void> guardarInstitucional({
    required String uid,
    required String nombreCompleto,
    required String numeroControl,
    required String carrera,
    required int semestre,
    required String info,
    File? foto,
  }) async {
    state = state.copyWith(guardando: true);
    try {
      String? fotoUrl;
      if (foto != null) {
        fotoUrl = await ref
            .read(authRepositoryProvider)
            .guardarFotoLocal(uid: uid, foto: foto);
      }
      await ref
          .read(authRepositoryProvider)
          .guardarPerfilInstitucional(
            uid: uid,
            nombreCompleto: nombreCompleto,
            numeroControl: numeroControl,
            carrera: carrera,
            semestre: semestre,
            info: info,
            fotoUrl: fotoUrl,
          );
    } finally {
      state = state.copyWith(guardando: false);
    }
  }

  Future<void> guardarExterno({
    required String uid,
    required String nombreCompleto,
    required String info,
    File? foto,
  }) async {
    state = state.copyWith(guardando: true);
    try {
      String? fotoUrl;
      if (foto != null) {
        fotoUrl = await ref
            .read(authRepositoryProvider)
            .guardarFotoLocal(uid: uid, foto: foto);
      }
      await ref
          .read(authRepositoryProvider)
          .guardarPerfilExterno(
            uid: uid,
            nombreCompleto: nombreCompleto,
            info: info,
            fotoUrl: fotoUrl,
          );
    } finally {
      state = state.copyWith(guardando: false);
    }
  }
}
