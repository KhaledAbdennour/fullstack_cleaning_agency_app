/// Debug flags for controlling debug logging
class DebugFlags {
  /// Enable debug logging with emoji prefixes (🔔, 🔧, etc.)
  /// Set to false in production
  static const bool enableDebugLogs = false;
  
  /// Enable detailed diagnostics in UI (dev mode only)
  /// Set to false in production
  static const bool enableUIDiagnostics = false;
  
  /// Debug print helper - only prints if enableDebugLogs is true
  static void debugPrint(String message) {
    if (enableDebugLogs) {
      print(message);
    }
  }
}

