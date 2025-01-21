import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Guardar datos del usuario localmente
  Future<void> saveUserLocally(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('displayName', user.displayName ?? '');
      await prefs.setString('email', user.email ?? '');
      await prefs.setString('uid', user.uid);
      log("Datos del usuario guardados localmente.");
    } catch (e) {
      log("Error al guardar datos localmente: $e");
    }
  }

  /// Obtener datos del usuario almacenados localmente
  Future<Map<String, String>?> getUserFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final displayName = prefs.getString('displayName');
      final email = prefs.getString('email');
      final uid = prefs.getString('uid');

      if (displayName != null && email != null && uid != null) {
        log("Datos del usuario cargados desde almacenamiento local.");
        return {
          'displayName': displayName,
          'email': email,
          'uid': uid,
        };
      }
      log("No se encontraron datos locales del usuario.");
      return null;
    } catch (e) {
      log("Error al cargar datos locales: $e");
      return null;
    }
  }

  /// Comprobar si el usuario está autenticado offline
  Future<bool> isUserLoggedInOffline() async {
    final user = await getUserFromLocal();
    return user != null;
  }

  /// Iniciar sesión con Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        log("Inicio de sesión cancelado por el usuario.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        await saveUserLocally(user); // Guardar datos localmente
        log("Inicio de sesión exitoso: ${user.displayName}");
      }
      return user;
    } catch (e) {
      log("Error en Google Sign-In: $e");
      return null;
    }
  }

  /// Cerrar sesión (sin borrar datos locales)
  Future<void> signout() async {
    try {
      await _auth.signOut();
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      log("Usuario desconectado, pero los datos locales se mantienen.");
    } catch (e) {
      log("Error al cerrar sesión: $e");
    }
  }
}
