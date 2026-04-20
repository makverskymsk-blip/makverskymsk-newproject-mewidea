import 'package:flutter/foundation.dart';

/// Безопасный логгер — выводит только в debug mode.
/// В release (включая web production) ничего не выводится.
void appLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
