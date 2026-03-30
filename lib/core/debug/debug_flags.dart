class DebugFlags {
  static const bool enableDebugLogs = false;

  static const bool enableUIDiagnostics = false;

  static void debugPrint(String message) {
    if (enableDebugLogs) {
      print(message);
    }
  }
}
