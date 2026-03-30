import 'dart:io';
import '../utils/json_safe.dart';

class DebugLogger {
  static const int _maxBufferSize = 500;
  static final List<String> _buffer = [];
  static const String _logFilePath =
      r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log';

  static void log(String tag, String message, {Map<String, dynamic>? data}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final consoleMsg = data != null
        ? '[$tag] $message | ${JsonSafe.encode(data)}'
        : '[$tag] $message';
    print(consoleMsg);

    final sanitizedEntry = {
      'timestamp': timestamp,
      'tag': tag,
      'message': message,
      if (data != null) 'data': JsonSafe.sanitize(data),
    };
    final logLine = JsonSafe.encode(sanitizedEntry);
    _buffer.add(logLine);

    if (_buffer.length > _maxBufferSize) {
      _buffer.removeAt(0);
    }

    _writeToFile(logLine);
  }

  static void _writeToFile(String logLine) {
    try {
      final file = File(_logFilePath);
      file
          .writeAsString('$logLine\n', mode: FileMode.append)
          .catchError((_) => File(_logFilePath));
    } catch (e) {}
  }

  static void error(
    String tag,
    String message,
    Object error,
    StackTrace stack, {
    Map<String, dynamic>? data,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    print('[$tag] ERROR: $message | $error');
    print('[$tag] Stack: $stack');

    final sanitizedEntry = {
      'timestamp': timestamp,
      'tag': tag,
      'message': message,
      'error': error.toString(),
      'stack': stack.toString(),
      if (data != null) 'data': JsonSafe.sanitize(data),
    };
    final logLine = JsonSafe.encode(sanitizedEntry);
    _buffer.add(logLine);

    if (_buffer.length > _maxBufferSize) {
      _buffer.removeAt(0);
    }

    _writeToFile(logLine);
  }

  static String dump() {
    return _buffer.join('\n');
  }

  static void clear() {
    _buffer.clear();
  }

  static int get bufferSize => _buffer.length;
}
