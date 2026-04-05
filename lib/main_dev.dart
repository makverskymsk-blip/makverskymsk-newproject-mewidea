/// Entry point для Development-окружения.
///
/// Запуск:
///   flutter run -t lib/main_dev.dart
///   flutter build apk -t lib/main_dev.dart
///
library;

import 'config/app_config.dart';
import 'main.dart' as app;

Future<void> main() async {
  AppConfig.init(Environment.dev);
  await app.appMain();
}
