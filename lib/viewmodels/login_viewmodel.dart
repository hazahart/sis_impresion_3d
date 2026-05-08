import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sis_impresion_3d/viewmodels/registro_viewmodel.dart' show authRepositoryProvider;
import '../models/usuario.dart';

class LoginState {
  final bool guardando;
  final String? errorGlobal;

  const LoginState({this.guardando = false, this.errorGlobal});

  LoginState copyWith({
    bool? guardando,
    String? errorGlobal,
    bool limpiarError = false,
  }) => LoginState(
    guardando: guardando ?? this.guardando,
    errorGlobal: limpiarError ? null : (errorGlobal ?? this.errorGlobal),
  );
}

final loginViewModelProvider =
NotifierProvider<LoginViewModel, LoginState>(() => LoginViewModel());

class LoginViewModel extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<Usuario> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    state = state.copyWith(guardando: true, limpiarError: true);
    try {
      final usuario = await ref.read(authRepositoryProvider).iniciarSesion(
        correo: correo,
        contrasena: contrasena,
      );
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
      final resultado = await ref.read(authRepositoryProvider).signInConGoogle();
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