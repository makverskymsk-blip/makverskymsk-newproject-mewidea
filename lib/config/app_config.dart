/// Описание окружения приложения (dev, prod).
enum Environment { dev, prod }

/// Конфигурация приложения, зависящая от окружения.
///
/// Ключи Supabase передаются через --dart-define или --dart-define-from-file:
///   flutter run --dart-define-from-file=.env
///   flutter build web --dart-define-from-file=.env
class AppConfig {
  final Environment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String appTitle;

  const AppConfig._({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.appTitle,
  });

  /// Текущая активная конфигурация (устанавливается при старте приложения).
  static late final AppConfig instance;

  // ─── Ключи из переменных окружения (--dart-define) ─────
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _key = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Инициализация конфигурации. Вызывать ДО runApp().
  static void init(Environment env) {
    assert(_url.isNotEmpty, 'SUPABASE_URL не задан! Используйте --dart-define-from-file=.env');
    assert(_key.isNotEmpty, 'SUPABASE_ANON_KEY не задан! Используйте --dart-define-from-file=.env');

    instance = switch (env) {
      Environment.dev => _dev,
      Environment.prod => _prod,
    };
  }

  bool get isDev => environment == Environment.dev;
  bool get isProd => environment == Environment.prod;

  // ─── Production ──────────────────────────────────────────
  static const _prod = AppConfig._(
    environment: Environment.prod,
    supabaseUrl: _url,
    supabaseAnonKey: _key,
    appTitle: 'Performance Lab',
  );

  // ─── Development ─────────────────────────────────────────
  static const _dev = AppConfig._(
    environment: Environment.dev,
    supabaseUrl: _url,
    supabaseAnonKey: _key,
    appTitle: 'Performance Lab [DEV]',
  );
}
