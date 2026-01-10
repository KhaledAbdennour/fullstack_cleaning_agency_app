import 'dart:io';
import '../utils/json_safe.dart';

/// Debug logger that writes to console, in-memory ring buffer, and file
/// Safe for logging Firestore types (FieldValue, Timestamp, etc.)
class DebugLogger {
  static const int _maxBufferSize = 500;
  static final List<String> _buffer = [];
  static const String _logFilePath =
      r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log';

  /// Log a debug message with tag, message, and optional data
  static void log(String tag, String message, {Map<String, dynamic>? data}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final logEntry = {
      'timestamp': timestamp,
      'tag': tag,
      'message': message,
      if (data != null) 'data': data,
    };

    // Console output - use JsonSafe to handle FieldValue/Timestamp
    final consoleMsg = data != null
        ? '[$tag] $message | ${JsonSafe.encode(data)}'
        : '[$tag] $message';
    print(consoleMsg);

    // In-memory buffer (NDJSON format) - sanitize before encoding
    final sanitizedEntry = {
      'timestamp': timestamp,
      'tag': tag,
      'message': message,
      if (data != null) 'data': JsonSafe.sanitize(data),
    };
    final logLine = JsonSafe.encode(sanitizedEntry);
    _buffer.add(logLine);

    // Keep only last _maxBufferSize lines (ring buffer)
    if (_buffer.length > _maxBufferSize) {
      _buffer.removeAt(0);
    }

    // Write to file (append mode, NDJSON format) - async but don't await
    _writeToFile(logLine);
  }

  /// Write log line to file (async, fire-and-forget)
  static void _writeToFile(String logLine) {
    try {
      final file = File(_logFilePath);
      file
          .writeAsString('$logLine\n', mode: FileMode.append)
          .catchError((_) {});
    } catch (e) {
      // Silently fail if file write fails (e.g., permissions)
    }
  }

  /// Log an error with stack trace
  static void error(
    String tag,
    String message,
    Object error,
    StackTrace stack, {
    Map<String, dynamic>? data,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final logEntry = {
      'timestamp': timestamp,
      'tag': tag,
      'message': message,
      'error': error.toString(),
      'stack': stack.toString(),
      if (data != null) 'data': data,
    };

    // Console output
    print('[$tag] ERROR: $message | $error');
    print('[$tag] Stack: $stack');

    // In-memory buffer (NDJSON format) - sanitize before encoding
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

    // Keep only last _maxBufferSize lines (ring buffer)
    if (_buffer.length > _maxBufferSize) {
      _buffer.removeAt(0);
    }

    // Write to file (append mode, NDJSON format) - async but don't await
    _writeToFile(logLine);
  }

  /// Dump all logs as a single string (NDJSON format, one line per log entry)
  static String dump() {
    return _buffer.join('\n');
  }

  /// Clear the log buffer
  static void clear() {
    _buffer.clear();
  }

  /// Get current buffer size
  static int get bufferSize => _buffer.length;
}
