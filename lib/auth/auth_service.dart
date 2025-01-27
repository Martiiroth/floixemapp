import 'dart:developer';
import 'dart:io';
import 'dart:js' as js; // Para integración con JavaScript en Flutter Web

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:floixemapp/models/user.dart'; 
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  // Instancia de FirebaseAuth
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Getter para exponer la instancia si se necesita en otro lado
  firebase_auth.FirebaseAuth get auth => _auth;

  // GoogleSignIn con scope de Drive (opcional)
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard(
    scopes: [drive.DriveApi.driveFileScope],
  );

  AuthService() {
    _setPersistence(); 
    if (kIsWeb) {
      _setupBeforeUnloadListener();
    }
  }

  /// Caja de Hive para almacenar el usuario
  Box<User> get _userBox => Hive.box<User>('userBox');

  /// Configura la persistencia de la sesión en Firebase
  Future<void> _setPersistence() async {
    if (kIsWeb) {
      await _auth.setPersistence(firebase_auth.Persistence.SESSION);
    } else {
      await _auth.setPersistence(firebase_auth.Persistence.LOCAL);
    }
  }

  /// Listener para cuando el usuario cierra la pestaña (Web):
  /// borra cookies y fuerza el cierre de sesión
  void _setupBeforeUnloadListener() {
    js.context.callMethod('eval', [
      '''
      window.addEventListener('beforeunload', function(event) {
        // Borrar cookies de Firebase y Google Sign-In al cerrar la pestaña
        document.cookie = "firebase-auth-token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
        document.cookie = "firebase-auth-event=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
        document.cookie = "G_ENABLED_IDPS=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
        document.cookie = "G_AUTHUSER_=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
      });
      '''
    ]);
  }

  /// Guardar datos del usuario localmente en Hive
  Future<void> saveUserLocally(firebase_auth.User user) async {
    try {
      final hiveUser = User(
        displayName: user.displayName ?? '',
        email: user.email ?? '',
        uid: user.uid,
      );
      await _userBox.put('currentUser', hiveUser);
      log("Datos del usuario guardados localmente en Hive.");
    } catch (e, stackTrace) {
      log("Error al guardar datos localmente en Hive: $e", stackTrace: stackTrace);
      throw Exception("No se pudieron guardar los datos del usuario.");
    }
  }

  /// Borrar datos locales del usuario (si es que existen)
  Future<void> clearLocalUser() async {
    await _userBox.delete('currentUser');
  }

  /// Obtener datos del usuario almacenados localmente (modo offline)
  Future<User?> getUserFromLocal() async {
    try {
      final hiveUser = _userBox.get('currentUser');
      if (hiveUser != null) {
        log("Datos del usuario cargados desde Hive.");
        return hiveUser;
      }
      log("No se encontraron datos locales del usuario en Hive.");
      return null;
    } catch (e, stackTrace) {
      log("Error al cargar datos locales desde Hive: $e", stackTrace: stackTrace);
      return null;
    }
  }

  /// Comprobar si el usuario está autenticado offline
  Future<bool> isUserLoggedInOffline() async {
    final user = await getUserFromLocal();
    return user != null;
  }

  /// Comprobar si el usuario está autenticado en Firebase (online)
  Future<bool> isUserLoggedInOnline() async {
    final user = _auth.currentUser;
    return user != null;
  }

  /// Iniciar sesión con Google
  Future<firebase_auth.User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // El usuario canceló el flujo de autenticación
        log("Inicio de sesión cancelado por el usuario.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebase_auth.UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await saveUserLocally(user); 
        log("Inicio de sesión exitoso: ${user.displayName}");
      }
      return user;
    } catch (e, stackTrace) {
      log("Error en Google Sign-In: $e", stackTrace: stackTrace);
      throw Exception("Error durante el inicio de sesión con Google.");
    }
  }

  /// Cerrar sesión (y borrar datos locales)
  Future<void> signout() async {
    try {
      // Cerrar sesión en Firebase
      await _auth.signOut();

      // Cerrar sesión de Google si existe
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Borrar datos locales del usuario
      await _userBox.delete('currentUser');

      if (kIsWeb) {
        _deleteCookies();
      }
      log("Usuario desconectado y datos locales eliminados.");
    } catch (e, stackTrace) {
      log("Error al cerrar sesión: $e", stackTrace: stackTrace);
      throw Exception("Error durante el cierre de sesión.");
    }
  }

  /// Borrar cookies de Firebase y Google Sign-In (solo en la web)
  void _deleteCookies() {
    if (kIsWeb) {
      js.context.callMethod('eval', [
        '''
        document.cookie = "firebase-auth-token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
        document.cookie = "firebase-auth-event=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
        document.cookie = "G_ENABLED_IDPS=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
        document.cookie = "G_AUTHUSER_=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
        '''
      ]);
    }
  }

  /// Subir un archivo a Google Drive (requiere dart:io => no disponible en Web)
  Future<String?> uploadFileToDrive(File file) async {
    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) {
        throw Exception("No se pudo iniciar sesión con Google.");
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      if (accessToken == null) {
        throw Exception("Token de acceso no disponible.");
      }

      final authClient = GoogleAuthClient(accessToken);
      final driveApi = drive.DriveApi(authClient);

      // Verificar o crear la carpeta 'FloixemApp'
      const folderName = 'FloixemApp';
      final folderQuery = "name = '$folderName' "
          "and mimeType = 'application/vnd.google-apps.folder' "
          "and trashed = false";

      final folderResponse = await driveApi.files.list(q: folderQuery, spaces: 'drive');
      String folderId;

      if (folderResponse.files != null && folderResponse.files!.isNotEmpty) {
        folderId = folderResponse.files!.first.id!;
      } else {
        final folderMetadata = drive.File()
          ..name = folderName
          ..mimeType = 'application/vnd.google-apps.folder';
        final createdFolder = await driveApi.files.create(folderMetadata);
        folderId = createdFolder.id!;
      }

      // Configurar metadatos del archivo
      final fileMetadata = drive.File()
        ..name = 'archivo_${DateTime.now().millisecondsSinceEpoch}.jpg'
        ..parents = [folderId];

      // Subir archivo
      final media = drive.Media(file.openRead(), file.lengthSync());
      final uploadedFile = await driveApi.files.create(
        fileMetadata,
        uploadMedia: media,
      );

      // Dar permiso público de lectura
      await driveApi.permissions.create(
        drive.Permission()
          ..type = 'anyone'
          ..role = 'reader',
        uploadedFile.id!,
      );

      // Generar URL pública para ver el archivo
      final publicUrl = 'https://drive.google.com/uc?export=view&id=${uploadedFile.id}';
      return publicUrl;
    } catch (e, stackTrace) {
      log("Error al subir archivo a Google Drive: $e", stackTrace: stackTrace);
      throw Exception("Error al subir el archivo a Google Drive.");
    }
  }
}

/// Cliente personalizado para Google Drive
class GoogleAuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }
}
