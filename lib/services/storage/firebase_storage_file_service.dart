import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageFileService {
  static Future<void> deleteByDownloadUrl(String downloadUrl) async {
    final ref = FirebaseStorage.instance.refFromURL(downloadUrl);
    await ref.delete();
  }

  static String guessContentType(String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';

    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }

    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }

    if (lower.endsWith('.ppt')) return 'application/vnd.ms-powerpoint';
    if (lower.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }

    if (lower.endsWith('.txt')) return 'text/plain';

    return 'application/octet-stream';
  }

  static Future<String> uploadFile({
    required String storagePath,
    required File file,
    String? contentType,
    Map<String, String>? customMetadata,
    Duration timeout = const Duration(minutes: 5),
    void Function(double percent)? onProgress,
  }) async {
    final ref = FirebaseStorage.instance.ref().child(storagePath);

    final fileName = path.basename(file.path);
    final metadata = SettableMetadata(
      contentType: contentType ?? guessContentType(fileName),
      customMetadata: customMetadata,
    );

    final uploadTask = ref.putFile(file, metadata);

    StreamSubscription<TaskSnapshot>? subscription;
    if (onProgress != null) {
      subscription = uploadTask.snapshotEvents.listen((snapshot) {
        final total = snapshot.totalBytes;
        if (total <= 0) return;
        onProgress((snapshot.bytesTransferred / total) * 100);
      });
    }

    try {
      final snapshot = await uploadTask.timeout(timeout, onTimeout: () {
        uploadTask.cancel();
        throw TimeoutException(
          'Upload timed out after ${timeout.inMinutes} minutes',
        );
      });

      return snapshot.ref.getDownloadURL();
    } finally {
      await subscription?.cancel();
    }
  }
}
