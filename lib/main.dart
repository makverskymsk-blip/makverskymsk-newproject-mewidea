
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/community_provider.dart';
import 'providers/matches_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/stats_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/match_events_provider.dart';
import 'providers/training_provider.dart';
import 'providers/sport_prefs_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/friends_provider.dart';
import 'providers/chat_provider.dart';


/// Запуск напрямую (по умолчанию — prod).
Future<void> main() async {
  AppConfig.init(Environment.prod);
  await appMain();
}

/// Глобальный обработчик ошибок — перехватывает все необработанные исключения.
void _setupErrorHandlers() {
  // Flutter framework errors (widget build, layout, rendering)
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('┌──── FLUTTER ERROR ────');
    debugPrint('│ ${details.exception}');
    debugPrint('│ ${details.stack?.toString().split('\n').take(5).join('\n│ ')}');
    debugPrint('└───────────────────────');
    // TODO: отправить в Sentry / Crashlytics
  };

  // Platform errors (async errors outside Flutter framework)
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('┌──── PLATFORM ERROR ────');
    debugPrint('│ $error');
    debugPrint('│ ${stack.toString().split('\n').take(5).join('\n│ ')}');
    debugPrint('└────────────────────────');
    // TODO: отправить в Sentry / Crashlytics
    return true; // prevent app crash
  };
}

/// Общая точка входа, вызываемая из main_dev / main_prod.
Future<void> appMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupErrorHandlers();

  final cfg = AppConfig.instance;
  try {
    await Supabase.initialize(
      url: cfg.supabaseUrl,
      anonKey: cfg.supabaseAnonKey,
    ).timeout(const Duration(seconds: 10));
    debugPrint('MAIN: Supabase initialized successfully');
  } catch (e) {
    debugPrint('MAIN: Supabase init error: $e');
    // Continue anyway — auth will handle offline state
  }

  // Push notifications migration needed (Supabase has different setup)
  /* if (!kIsWeb) {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  } */

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => MatchesProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MatchEventsProvider()),
        ChangeNotifierProvider(create: (_) => TrainingProvider()),
        ChangeNotifierProvider(create: (_) => SportPrefsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => FriendsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const SportsClubApp(),
    ),
  );
}
