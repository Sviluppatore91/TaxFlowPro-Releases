import 'package:tax_flow_pro/utils/logger.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class WindowsAuthService {
  // Sostituisci questi valori con quelli che otterrai dalla Google Cloud Console
  // Tipo: Applicazione Desktop
  static const String _clientIdStr = '573034076947-jp9h2ai1m65ak9p091t92n8pfrq75l51.apps.googleusercontent.com';
  static const String _clientSecretStr = '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';

  static Future<AuthClient?> loginWithGoogle() async {
    if (_clientIdStr == 'INSERISCI_QUI_IL_TUO_CLIENT_ID') {
      throw Exception('Configurazione OAuth per PC mancante. Il programmatore deve inserire il Client ID in windows_auth_service.dart');
    }

    var clientId = ClientId(_clientIdStr, _clientSecretStr);
    
    // Gli scope richiesti: Drive, e quelli per l'autenticazione Firebase (email, profilo, openid)
    var scopes = [
      drive.DriveApi.driveAppdataScope,
      'email',
      'profile',
      'openid',
    ];

    try {
      // clientViaUserConsent avvierà un server HTTP locale e aspetterà il redirect.
      var client = await clientViaUserConsent(clientId, scopes, (url) async {
        String authUrl = url;
        // Forza la schermata di selezione account su Google
        if (!authUrl.contains('prompt=')) {
          authUrl += '${authUrl.contains('?') ? '&' : '?'}prompt=select_account';
        }
        final uri = Uri.parse(authUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          throw Exception('Impossibile aprire il browser all\'indirizzo: $authUrl');
        }
      });

      // Firebase login usando i token appena ottenuti
      // Passiamo SOLO l'accessToken per aggirare l'errore "invalid-credential" 
      // causato dall'utilizzo di un Client ID Desktop invece che Web.
      final credential = GoogleAuthProvider.credential(
        accessToken: client.credentials.accessToken.data,
        // idToken: client.credentials.idToken, // RIMOSSO PER EVITARE UNKNOWN ERROR SU FIREBASE
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      return client;
    } catch (e) {
      appLogger.e('Errore in WindowsAuthService: $e');
      rethrow;
    }
  }
}
