/// Описание окружения приложения (dev, prod).
enum Environment { dev, prod }

/// Конфигурация приложения, зависящая от окружения.
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

  /// Инициализация конфигурации. Вызывать ДО runApp().
  static void init(Environment env) {
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
    supabaseUrl: 'https://wviyyqzbafdgmsawrpnv.supabase.co',
    supabaseAnonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2aXl5cXpiYWZkZ21zYXdycG52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzMDY0OTYsImV4cCI6MjA5MDg4MjQ5Nn0.18plYJSc4MgV72mkJTY0oWBewiuwrV33zfufkTGqiFg',
    appTitle: 'Performance Lab',
  );

  // ─── Development ─────────────────────────────────────────
  // TODO: Заменить URL и ключ на отдельный dev-проект Supabase.
  //       Сейчас dev и prod указывают на один и тот же инстанс!
  static const _dev = AppConfig._(
    environment: Environment.dev,
    supabaseUrl: 'https://wviyyqzbafdgmsawrpnv.supabase.co',
    supabaseAnonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2aXl5cXpiYWZkZ21zYXdycG52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzMDY0OTYsImV4cCI6MjA5MDg4MjQ5Nn0.18plYJSc4MgV72mkJTY0oWBewiuwrV33zfufkTGqiFg',
    appTitle: 'Performance Lab [DEV]',
  );
}
