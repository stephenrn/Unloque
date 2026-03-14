import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:unloque/services/storage/firebase_storage_file_service.dart';

class ApplicationAttachmentStorageService {
  static Future<void> deleteByDownloadUrl(String downloadUrl) async {
    await FirebaseStorageFileService.deleteByDownloadUrl(downloadUrl);
  }

  static Future<String> uploadApplicationAttachment({
    required String uid,
    required String applicationId,
    required String fieldLabel,
    required File file,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final fileName = path.basename(file.path);
    final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';

    return FirebaseStorageFileService.uploadFile(
      storagePath: 'users/$uid/applications/$applicationId/$fieldLabel/$uniqueFileName',
      file: file,
      customMetadata: {
        'picked-file-path': file.path,
      },
      timeout: timeout,
    );
  }
}
