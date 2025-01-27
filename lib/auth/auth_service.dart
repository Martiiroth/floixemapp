import 'dart:developer';
import 'dart:io';
import 'dart:js' as js; // Para integración con JavaScript en Flutter Web
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:floixemapp/models/user.dart'; // Tu modelo User
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar si es web

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard(scopes: [drive.DriveApi.driveFileScope]);

  AuthService() {
    _setPersistence(); // Configurar la persistencia
    if (kIsWeb) {
      _setupBeforeUnloadListener(); // Configurar el listener para el cierre de la pestaña
    }
  }

  /// Obtener la caja de Hive ya abierta
  Box<User> get _userBox => Hive.box<User>('userBox');

  /// Configurar la persistencia de Firebase
  Future<void> _setPersistence() async {
    if (kIsWeb) {
      await _auth.setPersistence(firebase_auth.Persistence.SESSION); // Sesión solo en la web
    } else {
      await _auth.setPersistence(firebase_auth.Persistence.LOCAL); // Persistencia local en móviles
    }
  }

  /// Configurar el listener para el cierre de la pestaña (solo en la web)
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

  /// Obtener datos del usuario almacenados localmente desde Hive
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
        log("Inicio de sesión cancelado por el usuario.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebase_auth.UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await saveUserLocally(user); // Guardar datos localmente en Hive
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
      await _auth.signOut(); // Cerrar sesión en Firebase
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut(); // Cerrar sesión en Google
      }
      await _userBox.delete('currentUser'); // Borrar datos locales del usuario
      if (kIsWeb) {
        _deleteCookies(); // Borrar cookies solo en la web
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

  /// Refrescar el token de acceso de Google
  Future<void> refreshGoogleToken() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        final googleUser = await _googleSignIn.signInSilently();
        if (googleUser != null) {
          final googleAuth = await googleUser.authentication;
          log("Token de acceso refrescado: ${googleAuth.accessToken}");
        }
      }
    } catch (e, stackTrace) {
      log("Error al refrescar el token de Google: $e", stackTrace: stackTrace);
      throw Exception("Error al refrescar el token de Google.");
    }
  }

  /// Subir un archivo a Google Drive
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

      const folderName = 'FloixemApp';
      final folderQuery = "name = '$folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
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

      final fileMetadata = drive.File()
        ..name = 'archivo_${DateTime.now().millisecondsSinceEpoch}.jpg'
        ..parents = [folderId];

      final media = drive.Media(file.openRead(), file.lengthSync());
      final uploadedFile = await driveApi.files.create(fileMetadata, uploadMedia: media);

      await driveApi.permissions.create(
        drive.Permission()
          ..type = 'anyone'
          ..role = 'reader',
        uploadedFile.id!,
      );

      final publicUrl = 'https://drive.google.com/uc?export=view&id=${uploadedFile.id}';
      return publicUrl;
    } catch (e, stackTrace) {
      log("Error al subir archivo a Google Drive: $e", stackTrace: stackTrace);
      throw Exception("Error al subir el archivo a Google Drive.");
    }
  }
}

/// Cliente personalizado para autenticar las solicitudes a la API de Google Drive
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