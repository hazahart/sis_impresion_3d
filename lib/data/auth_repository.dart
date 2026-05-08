import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/usuario.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Usuario> registrar({
    required String correo,
    required String contrasena,
  }) async {
    try {
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: contrasena,
      );

      final uid = credencial.user!.uid;
      final estado = Usuario.esInstitucional(correo)
          ? EstadoCuenta.activo
          : EstadoCuenta.pendienteAprobacion;

      final usuario = Usuario(
        id: uid,
        correo: correo.trim().toLowerCase(),
        rol: RolUsuario.operador,
        estado: estado,
        fechaRegistro: DateTime.now(),
      );

      await _firestore.collection('usuarios').doc(uid).set(usuario.toMap());
      return usuario;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mensajeAuth(e.code));
    } catch (_) {
      throw Exception('Error al registrar la cuenta. Inténtalo de nuevo.');
    }
  }

  Future<Usuario> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      final credencial = await _auth.signInWithEmailAndPassword(
        email: correo.trim(),
        password: contrasena,
      );

      final uid = credencial.user!.uid;
      final doc = await _firestore.collection('usuarios').doc(uid).get();

      if (!doc.exists) {
        throw Exception('No se encontró el perfil del usuario.');
      }

      return Usuario.fromMap(doc.data()!, id: uid);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mensajeAuth(e.code));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      throw Exception(msg);
    }
  }

  Future<({Usuario usuario, bool esNuevo})> signInConGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw Exception('Inicio de sesión cancelado.');

      final googleAuth = await googleUser.authentication;
      final credencial = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credencial);
      final uid = result.user!.uid;
      final correo = result.user!.email ?? googleUser.email;

      final docSnap = await _firestore.collection('usuarios').doc(uid).get();

      if (docSnap.exists) {
        final usuario = Usuario.fromMap(docSnap.data()!, id: uid);
        return (usuario: usuario, esNuevo: false);
      }

      final estado = Usuario.esInstitucional(correo)
          ? EstadoCuenta.activo
          : EstadoCuenta.pendienteAprobacion;

      final usuario = Usuario(
        id: uid,
        correo: correo.toLowerCase(),
        rol: RolUsuario.operador,
        estado: estado,
        fechaRegistro: DateTime.now(),
      );

      await _firestore.collection('usuarios').doc(uid).set(usuario.toMap());
      return (usuario: usuario, esNuevo: true);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mensajeAuth(e.code));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      throw Exception(msg);
    }
  }

  Future<String> guardarFotoLocal({
    required String uid,
    required File foto,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final carpeta = Directory('${appDir.path}/avatares');
      if (!await carpeta.exists()) await carpeta.create(recursive: true);

      final extension = path.extension(foto.path).isNotEmpty
          ? path.extension(foto.path)
          : '.jpg';
      final destino = File('${carpeta.path}/$uid$extension');

      await foto.copy(destino.path);
      return destino.path;
    } catch (_) {
      throw Exception('Error al guardar la foto de perfil.');
    }
  }

  Future<void> guardarPerfilInstitucional({
    required String uid,
    required String nombreCompleto,
    required String numeroControl,
    required String carrera,
    required int semestre,
    required String info,
    String? fotoUrl,
  }) async {
    try {
      await _firestore.collection('usuarios').doc(uid).update({
        'nombre_completo': nombreCompleto.trim(),
        'numero_control': numeroControl.trim(),
        'carrera': carrera,
        'semestre': semestre,
        'info': info.trim(),
        if (fotoUrl != null) 'foto_url': fotoUrl,
      });
    } catch (_) {
      throw Exception('Error al guardar el perfil. Inténtalo de nuevo.');
    }
  }

  Future<void> guardarPerfilExterno({
    required String uid,
    required String nombreCompleto,
    required String info,
    String? fotoUrl,
  }) async {
    try {
      await _firestore.collection('usuarios').doc(uid).update({
        'nombre_completo': nombreCompleto.trim(),
        'info': info.trim(),
        if (fotoUrl != null) 'foto_url': fotoUrl,
      });
    } catch (_) {
      throw Exception('Error al guardar el perfil. Inténtalo de nuevo.');
    }
  }

  String? get uidActual => _auth.currentUser?.uid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String _mensajeAuth(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'invalid-email':
        return 'El formato del correo no es válido.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'user-not-found':
        return 'Correo o contraseña incorrectos.';
      case 'wrong-password':
        return 'Correo o contraseña incorrectos.';
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde.';
      default:
        return 'Error de autenticación. Inténtalo de nuevo.';
    }
  }
}
