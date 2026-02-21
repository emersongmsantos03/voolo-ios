import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService._();

  static FirebaseStorage get _storage => FirebaseStorage.instanceFor(bucket: 'voolo-ad416.firebasestorage.app');

  static Future<String?> uploadUserPhoto({
    required String userId,
    required String filePath,
    Uint8List? fileBytes,
  }) async {
    if (userId.isEmpty) {
      debugPrint('StorageService: Error - userId is empty');
      return null;
    }

    try {
      final ref = _storage.ref().child('users/$userId/profile.jpg');
      debugPrint('StorageService: Target Path: ${ref.fullPath}');
      debugPrint('StorageService: Target Bucket: ${ref.bucket}');
      
      Uint8List? data = fileBytes;
      if (data == null) {
        final file = File(filePath);
        if (!file.existsSync()) {
          debugPrint('StorageService: File not found at $filePath');
          return null;
        }
        data = await file.readAsBytes();
      }

      debugPrint('StorageService: Byte count: ${data.length}');
      
      // Experiment: Try to upload first, then catch specific errors
      try {
        debugPrint('StorageService: Starting putData...');
        final task = await ref.putData(
          data, 
          SettableMetadata(contentType: 'image/jpeg')
        );
        debugPrint('StorageService: putData finished. State: ${task.state}');
      } on FirebaseException catch (e) {
        debugPrint('StorageService: putData FAILED! Code: ${e.code}, Msg: ${e.message}');
        rethrow;
      }

      debugPrint('StorageService: Requesting download URL...');
      final url = await ref.getDownloadURL();
      debugPrint('StorageService: URL received: $url');
      return url;
    } on FirebaseException catch (e) {
      debugPrint('StorageService: FirebaseException catch-all! Code: ${e.code}, Message: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('StorageService: General Error: $e');
      return null;
    }
  }
}
