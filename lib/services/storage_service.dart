import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService._();

  static FirebaseStorage get _storage =>
      FirebaseStorage.instanceFor(bucket: 'voolo-ad416.firebasestorage.app');

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
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('users/$userId/profile_$stamp.jpg');
      debugPrint('StorageService: Target Path: ${ref.fullPath}');
      debugPrint('StorageService: Target Bucket: ${ref.bucket}');

      final contentType = () {
        final lower = filePath.toLowerCase();
        if (lower.endsWith('.png')) return 'image/png';
        if (lower.endsWith('.webp')) return 'image/webp';
        if (lower.endsWith('.gif')) return 'image/gif';
        if (lower.endsWith('.heic')) return 'image/heic';
        if (lower.endsWith('.heif')) return 'image/heif';
        return 'image/jpeg';
      }();

      if (fileBytes != null) {
        debugPrint('StorageService: Byte count: ${fileBytes.length}');
        debugPrint('StorageService: Starting putData...');
        final task = await ref.putData(
          fileBytes,
          SettableMetadata(contentType: contentType),
        );
        debugPrint('StorageService: putData finished. State: ${task.state}');
      } else {
        final file = File(filePath);
        if (!file.existsSync()) {
          debugPrint('StorageService: File not found at $filePath');
          return null;
        }
        debugPrint('StorageService: Starting putFile...');
        final task = await ref.putFile(
          file,
          SettableMetadata(contentType: contentType),
        );
        debugPrint('StorageService: putFile finished. State: ${task.state}');
      }

      debugPrint('StorageService: Requesting download URL...');
      final url = await ref.getDownloadURL();
      debugPrint('StorageService: URL received: $url');
      return url;
    } on FirebaseException catch (e) {
      debugPrint(
          'StorageService: FirebaseException catch-all! Code: ${e.code}, Message: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('StorageService: General Error: $e');
      return null;
    }
  }

  static Future<void> deleteUserPhoto(String? photoPath) async {
    if (photoPath == null || photoPath.trim().isEmpty) return;

    try {
      if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
        await _storage.refFromURL(photoPath).delete();
        return;
      }
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // best effort cleanup
    }
  }
}
