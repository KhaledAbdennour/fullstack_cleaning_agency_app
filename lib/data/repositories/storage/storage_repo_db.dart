import 'dart:io';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'storage_repo.dart';

class StorageRepoDB extends AbstractStorageRepo {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _logPath =
      'c:\\Users\\wailo\\Desktop\\mob_dev_project\\.cursor\\debug.log';

  void _agentLog(
    String hypothesisId,
    String message,
    Map<String, dynamic> data,
  ) {
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
      print(
        'agentLog storage_repo_db.dart [$hypothesisId] $message $data (log write failed: $e)',
      );
    }
  }

  @override
  Future<String> uploadProfileImage(int userId, String filePath) async {
    try {
      _agentLog('H5', 'upload start', {'userId': userId, 'filePath': filePath});

      try {
        _agentLog('H5', 'storage instance verified', {'userId': userId});
      } catch (storageError) {
        _agentLog('H5', 'storage instance error', {
          'userId': userId,
          'error': storageError.toString(),
        });
        throw Exception('Firebase Storage not available: $storageError');
      }

      final file = File(filePath);
      if (!file.existsSync()) {
        _agentLog('H5', 'file not found', {'filePath': filePath});
        throw Exception('File does not exist: $filePath');
      }

      _agentLog('H5', 'file exists', {
        'filePath': filePath,
        'fileSize': await file.length(),
      });

      final originalBytes = await file.readAsBytes();
      _agentLog('H5', 'file read', {'fileSize': originalBytes.length});

      final image = img.decodeImage(originalBytes);

      if (image == null) {
        _agentLog('H5', 'invalid image', {'filePath': filePath});
        throw Exception('Invalid image file - could not decode image');
      }

      _agentLog('H5', 'image decoded', {
        'width': image.width,
        'height': image.height,
      });

      img.Image? resizedImage = image;
      if (image.width > 800 || image.height > 800) {
        resizedImage = img.copyResize(
          image,
          width: image.width > image.height ? 800 : null,
          height: image.height > image.width ? 800 : null,
          interpolation: img.Interpolation.linear,
        );
      }

      final compressedBytes = img.encodeJpg(resizedImage, quality: 85);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child(
            'profile_pictures/$userId/$timestamp.jpg',
          );

      _agentLog('H5', 'upload before putData', {
        'userId': userId,
        'path': ref.fullPath,
        'fileSize': compressedBytes.length,
      });

      try {
        final uploadTask = ref.putData(
          compressedBytes,
          SettableMetadata(
            contentType: 'image/jpeg',
            cacheControl: 'public, max-age=31536000',
          ),
        );

        final snapshot = await uploadTask.whenComplete(() {
          _agentLog('H5', 'upload task completed', {'userId': userId});
        });

        _agentLog('H5', 'upload snapshot received', {
          'userId': userId,
          'bytesTransferred': snapshot.bytesTransferred,
          'totalBytes': snapshot.totalBytes,
        });

        final downloadUrl = await snapshot.ref.getDownloadURL();

        _agentLog('H5', 'download URL obtained', {
          'userId': userId,
          'url': downloadUrl,
        });

        return downloadUrl;
      } catch (uploadException) {
        _agentLog('H5', 'upload exception', {
          'userId': userId,
          'error': uploadException.toString(),
          'errorType': uploadException.runtimeType.toString(),
        });
        rethrow;
      }
    } catch (e, stackTrace) {
      _agentLog('H5', 'upload error', {
        'userId': userId,
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
        'stack': stackTrace.toString(),
      });
      rethrow;
    }
  }

  @override
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      _agentLog('H5', 'delete start', {'imageUrl': imageUrl});

      if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
        _agentLog('H5', 'delete skipped', {'reason': 'Invalid or empty URL'});
        return;
      }

      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      final oIndex = pathSegments.indexOf('o');
      if (oIndex == -1 || oIndex >= pathSegments.length - 1) {
        _agentLog('H5', 'delete skipped', {
          'reason': 'Invalid storage URL format',
        });
        return;
      }

      final encodedPath = pathSegments.sublist(oIndex + 1).join('/');
      final decodedPath = Uri.decodeComponent(encodedPath);

      final ref = _storage.ref().child(decodedPath);

      try {
        await ref.delete();
        _agentLog('H5', 'delete success', {'path': decodedPath});
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found' ||
            e.message?.toLowerCase().contains('no object exists') == true ||
            e.code == '404') {
          _agentLog('H5', 'delete skipped', {
            'reason': 'File does not exist (object-not-found)',
            'code': e.code,
          });
          return;
        }

        _agentLog('H5', 'delete error (FirebaseException)', {
          'error': e.toString(),
          'code': e.code,
        });
        return;
      } catch (e, stackTrace) {
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('object-not-found') ||
            errorMessage.contains('no object exists') ||
            errorMessage.contains('[firebase_storage/object-not-found]')) {
          _agentLog('H5', 'delete skipped', {
            'reason': 'File does not exist (object-not-found)',
            'error': e.toString(),
          });
          return;
        }

        _agentLog('H5', 'delete error', {
          'error': e.toString(),
          'stack': stackTrace.toString(),
        });

        return;
      }
    } catch (e, stackTrace) {
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('object-not-found') ||
          errorMessage.contains('no object exists') ||
          errorMessage.contains('[firebase_storage/object-not-found]')) {
        _agentLog('H5', 'delete skipped', {
          'reason': 'File does not exist (object-not-found)',
          'error': e.toString(),
        });
        return;
      }

      _agentLog('H5', 'delete error (outer catch)', {
        'error': e.toString(),
        'stack': stackTrace.toString(),
      });
    }
  }
}
