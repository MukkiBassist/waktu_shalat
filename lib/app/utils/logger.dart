// lib/app/utils/logger.dart

// ignore_for_file: avoid_print

// Kode ANSI untuk warna
class LogColors {
  static const String reset = '\x1B[0m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String cyan = '\x1B[36m';
  static const String magenta = '\x1B[35m';
}

void logSuccess(String message) {
  print('${LogColors.green}✅ $message${LogColors.reset}');
}

void logWarning(String message) {
  print('${LogColors.yellow}⚠️ $message${LogColors.reset}');
}

void logError(String message) {
  print('${LogColors.red}❌ $message${LogColors.reset}');
}

void logInfo(String message) {
  print('${LogColors.cyan}ℹ️ $message${LogColors.reset}');
}

void logPermission(String message) {
  print('${LogColors.yellow}🔑 $message${LogColors.reset}');
}

void logLoading(String message) {
  print('${LogColors.blue}⏳ $message${LogColors.reset}');
}

void logSynced(String message) {
  print('${LogColors.blue}🔄 $message${LogColors.reset}');
}
