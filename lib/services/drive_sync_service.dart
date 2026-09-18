import 'package:tax_flow_pro/utils/logger.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class DriveSyncService {
  static const String _dbFileName = 'taxflowpro_backup.db';

  /// Ritorna un client Drive autenticato usando l'account Google SignIn
  static Future<drive.DriveApi?> getDriveApi(GoogleSignInAccount account) async {
    final headers = await account.authHeaders;
    final client = GoogleAuthClient(headers);
    return drive.DriveApi(client);
  }

  /// Verifica se esiste un backup su Google Drive
  static Future<String?> checkBackupExists(drive.DriveApi driveApi) async {
    try {
      final fileList = await driveApi.files.list(
        q: "name = '$_dbFileName' and trashed = false",
        spaces: 'appDataFolder',
        $fields: 'files(id, name)',
      );
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      }
    } catch (e) {
      appLogger.e('Errore durante il controllo del backup su Drive: $e');
    }
    return null;
  }

  /// Scarica il database da Google Drive al percorso locale
  static Future<bool> downloadBackup(drive.DriveApi driveApi, String fileId, String localPath) async {
    try {
      final drive.Media media = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final file = File(localPath);
      final sink = file.openWrite();
      await media.stream.pipe(sink);
      await sink.close();
      return true;
    } catch (e) {
      appLogger.e('Errore durante il download del backup: $e');
      return false;
    }
  }

  /// Carica/Aggiorna il database locale su Google Drive
  static Future<bool> uploadBackup(drive.DriveApi driveApi, String localPath) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) return false;

      final existingFileId = await checkBackupExists(driveApi);
      
      final driveFile = drive.File();
      driveFile.name = _dbFileName;
      driveFile.parents = ['appDataFolder'];

      final media = drive.Media(file.openRead(), file.lengthSync());

      if (existingFileId != null) {
        // Aggiorna file esistente
        await driveApi.files.update(drive.File(), existingFileId, uploadMedia: media);
      } else {
        // Crea nuovo file
        await driveApi.files.create(driveFile, uploadMedia: media);
      }
      return true;
    } catch (e) {
      appLogger.e('Errore durante l\'upload del backup: $e');
      return false;
    }
  }
}
