
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


/// Запуск напрямую (по умолчанию — prod).
Future<void> main() async {
  AppConfig.init(Environment.prod);
  await appMain();
}

/// Общая точка входа, вызываемая из main_dev / main_prod.
Future<void> appMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cfg = AppConfig.instance;
  await Supabase.initialize(
    url: cfg.supabaseUrl,
    anonKey: cfg.supabaseAnonKey,
  );

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
      ],
      child: const SportsClubApp(),
    ),
  );
}
