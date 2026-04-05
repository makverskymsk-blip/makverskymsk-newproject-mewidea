/// Entry point для Production-окружения.
///
/// Запуск:
///   flutter run -t lib/main_prod.dart
///   flutter build apk -t lib/main_prod.dart
///
library;

import 'config/app_config.dart';
import 'main.dart' as app;

Future<void> main() async {
  AppConfig.init(Environment.prod);
  await app.appMain();
}
