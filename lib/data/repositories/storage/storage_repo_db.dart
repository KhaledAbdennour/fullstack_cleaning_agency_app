import 'dart:io';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import '../../../core/config/firebase_config.dart';
import 'storage_repo.dart';

/// Firestore implementation of storage repository
class StorageRepoDB extends AbstractStorageRepo {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _logPath = 'c:\\Users\\wailo\\Desktop\\mob_dev_project\\.cursor\\debug.log';

  void _agentLog(String hypothesisId, String message, Map<String, dynamic> data) {
    // #region agent log
    try {
      final logFile = File(_logPath);
      logFile.parent.createSync(recursive: true);
      final logLine = jsonEncode({
        'sessionId': 'debug-session',
        'runId': 'run1',
        'hypothesisId': hypothesisId,
        'location': 'storage_repo_db.dart',
        'message': message,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      logFile.writeAsStringSync('$logLine\n', mode: FileMode.append);
    } catch (e) {
      print('agentLog storage_repo_db.dart [$hypothesisId] $message $data (log write failed: $e)');
    }
    // #endregion
  }

  @override
  Future<String> uploadProfileImage(int userId, String filePath) async {
    try {
      _agentLog('H5', 'upload start', {'userId': userId, 'filePath': filePath});

      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('File does not exist: $filePath');
      }

      // Compress image to reduce upload size (optional but recommended)
      final originalBytes = await file.readAsBytes();
      final image = img.decodeImage(originalBytes);
      
      if (image == null) {
        throw Exception('Invalid image file');
      }

      // Resize if too large (max 800px width/height)
      img.Image? resizedImage = image;
      if (image.width > 800 || image.height > 800) {
        resizedImage = img.copyResize(
          image,
          width: image.width > image.height ? 800 : null,
          height: image.height > image.width ? 800 : null,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode as JPEG with quality 85
      final compressedBytes = img.encodeJpg(resizedImage, quality: 85);

      // Upload to Firebase Storage with versioned path to avoid overwriting
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('profile_pictures/$userId/$timestamp.jpg');
      
      final uploadTask = ref.putData(
        compressedBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=31536000', // Cache for 1 year
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      _agentLog('H5', 'upload success', {'userId': userId, 'path': ref.fullPath, 'url': downloadUrl});
      return downloadUrl;
    } catch (e, stackTrace) {
      _agentLog('H5', 'upload error', {'userId': userId, 'error': e.toString(), 'stack': stackTrace.toString()});
      rethrow;
    }
  }

  @override
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      _agentLog('H5', 'delete start', {'imageUrl': imageUrl});
      
      // Skip if URL is empty or invalid
      if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
        _agentLog('H5', 'delete skipped', {'reason': 'Invalid or empty URL'});
        return;
      }
      
      // Extract file path from URL
      // URL format: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?alt=media&token={token}
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find 'o' segment and get path after it
      final oIndex = pathSegments.indexOf('o');
      if (oIndex == -1 || oIndex >= pathSegments.length - 1) {
        _agentLog('H5', 'delete skipped', {'reason': 'Invalid storage URL format'});
        return; // Don't throw, just return silently
      }
      
      // Reconstruct path (decode URL encoding)
      final encodedPath = pathSegments.sublist(oIndex + 1).join('/');
      final decodedPath = Uri.decodeComponent(encodedPath);
      
      // Try to delete the file
      // If file doesn't exist, Firebase will throw an error - we'll catch and ignore it
      final ref = _storage.ref().child(decodedPath);
      
      try {
        await ref.delete();
        _agentLog('H5', 'delete success', {'path': decodedPath});
      } on FirebaseException catch (e) {
        // Check if it's an object-not-found error (file doesn't exist)
        if (e.code == 'object-not-found' || 
            e.message?.toLowerCase().contains('no object exists') == true ||
            e.code == '404') {
          _agentLog('H5', 'delete skipped', {'reason': 'File does not exist (object-not-found)', 'code': e.code});
          return; // Silently return - file doesn't exist, which is fine
        }
        // For other Firebase errors, log but don't throw
        _agentLog('H5', 'delete error (FirebaseException)', {'error': e.toString(), 'code': e.code});
        return; // Don't throw - allow operation to continue
      } catch (e, stackTrace) {
        // Check if it's an object-not-found error (file doesn't exist)
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('object-not-found') || 
            errorMessage.contains('no object exists') ||
            errorMessage.contains('[firebase_storage/object-not-found]')) {
          _agentLog('H5', 'delete skipped', {'reason': 'File does not exist (object-not-found)', 'error': e.toString()});
          return; // Silently return - file doesn't exist, which is fine
        }
        
        _agentLog('H5', 'delete error', {'error': e.toString(), 'stack': stackTrace.toString()});
        // Don't throw - allow operation to continue even if delete fails
        // This prevents profile update from failing just because old image deletion fails
        return;
      }
    } catch (e, stackTrace) {
      // Catch any unexpected errors from the outer try block
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('object-not-found') || 
          errorMessage.contains('no object exists') ||
          errorMessage.contains('[firebase_storage/object-not-found]')) {
        _agentLog('H5', 'delete skipped', {'reason': 'File does not exist (object-not-found)', 'error': e.toString()});
        return; // Silently return - file doesn't exist, which is fine
      }
      
      _agentLog('H5', 'delete error (outer catch)', {'error': e.toString(), 'stack': stackTrace.toString()});
      // Don't throw - allow operation to continue even if delete fails
    }
  }
}

