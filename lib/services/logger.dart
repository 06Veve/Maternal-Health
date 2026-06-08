/// Centralized logging service for the application
/// Replaces scattered print statements with consistent logging
class AppLogger {
  static const String _prefix = '[MaternalHealth]';

  /// Log informational messages
  static void info(String message, {String? tag}) {
    final tagStr = tag != null ? '[$tag]' : '';
    print('$_prefix$tagStr ℹ️ $message');
  }

  /// Log warning messages
  static void warning(String message, {String? tag}) {
    final tagStr = tag != null ? '[$tag]' : '';
    print('$_prefix$tagStr ⚠️ $message');
  }

  /// Log error messages
  static void error(String message, {String? tag, dynamic exception, StackTrace? stackTrace}) {
    final tagStr = tag != null ? '[$tag]' : '';
    print('$_prefix$tagStr ❌ $message');
    if (exception != null) {
      print('$_prefix$tagStr Exception: $exception');
    }
    if (stackTrace != null) {
      print('$_prefix$tagStr StackTrace: $stackTrace');
    }
  }

  /// Log debug messages (development only)
  static void debug(String message, {String? tag}) {
    final tagStr = tag != null ? '[$tag]' : '';
    print('$_prefix$tagStr 🔍 $message');
  }

  /// Log success messages
  static void success(String message, {String? tag}) {
    final tagStr = tag != null ? '[$tag]' : '';
    print('$_prefix$tagStr ✅ $message');
  }
}
