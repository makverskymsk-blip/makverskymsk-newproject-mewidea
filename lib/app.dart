import 'package:new_idea_works/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/community_provider.dart';
import 'providers/matches_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/training_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/auth/login_screen.dart';

import 'screens/main_navigation.dart';
import 'screens/splash_screen.dart';

import 'theme/app_theme.dart';

class SportsClubApp extends StatelessWidget {
  const SportsClubApp({super.key});

  /// Извлекает код приглашения из URL (?join=CODE)
  static String? _extractInviteCode() {
    if (!kIsWeb) return null;
    try {
      final uri = Uri.base;
      return uri.queryParameters['join'];
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inviteCode = _extractInviteCode();
    final themeProv = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Performance Lab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProv.themeMode,
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          appLog('APP: isLoading=${auth.isLoading}, isLoggedIn=${auth.isLoggedIn}, user=${auth.currentUser?.name}, communityIds=${auth.currentUser?.communityIds}');
          
          // Loading state
          if (auth.isLoading) {
            return const SplashScreen(message: 'Инициализация...');
          }

          // Not logged in — передаём inviteCode чтобы после логина сразу вступить
          if (!auth.isLoggedIn) {
            return const LoginScreen();
          }

          // Logged in — load communities
          if (auth.currentUser!.communityIds.isEmpty) {
            // Init training provider and load global matches even without community
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final tp = context.read<TrainingProvider>();
              final mp = context.read<MatchesProvider>();
              final np = context.read<NotificationProvider>();
              final user = auth.currentUser!;
              auth.setNotificationProvider(np);
              mp.setNotificationProvider(np);
              tp.init(user.id, initialXp: user.trainingXp, initialLevel: user.trainingLevel);
              mp.loadMatches(null, []); // No community — only personal events
            });
            return MainNavigation(inviteCode: inviteCode);
          }

          return _MainWithCommunityLoader(
            communityIds: auth.currentUser!.communityIds,
            inviteCode: inviteCode,
          );
        },
      ),
    );
  }
}

/// Loads communities before showing MainNavigation.
class _MainWithCommunityLoader extends StatefulWidget {
  final List<String> communityIds;
  final String? inviteCode;
  const _MainWithCommunityLoader({required this.communityIds, this.inviteCode});

  @override
  State<_MainWithCommunityLoader> createState() =>
      _MainWithCommunityLoaderState();
}

class _MainWithCommunityLoaderState extends State<_MainWithCommunityLoader> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  Future<void> _loadCommunities() async {
    try {
      final communityProv = context.read<CommunityProvider>();
      final authProv = context.read<AuthProvider>();
      final notifProv = context.read<NotificationProvider>();
      authProv.setNotificationProvider(notifProv);
      await communityProv
          .loadUserCommunities(widget.communityIds)
          .timeout(const Duration(seconds: 5));

      // Очистить communityIds от удалённых/несуществующих сообществ
      final loadedIds = communityProv.communities.map((c) => c.id).toSet();
      final staleIds = widget.communityIds
          .where((id) => !loadedIds.contains(id))
          .toList();
      if (staleIds.isNotEmpty) {
        appLog('APP: removing stale communityIds: $staleIds');
        await authProv.removeStaleCommunityIds(staleIds);
      }

      // Load matches and subscriptions for the active community
      if (communityProv.activeCommunity != null) {
        final cid = communityProv.activeCommunity!.id;
        if (!mounted) return;
        final matchesProv = context.read<MatchesProvider>();
        matchesProv.setNotificationProvider(notifProv);
        await Future.wait([
          matchesProv.loadMatches(cid, widget.communityIds).timeout(const Duration(seconds: 5)),
          communityProv.loadSubscriptions(cid).timeout(const Duration(seconds: 5)),
        ]);
      }

      // Init training provider
      if (!mounted) return;
      final trainingProv = context.read<TrainingProvider>();
      final user = authProv.currentUser;
      if (user != null) {
        await trainingProv.init(
          user.id,
          initialXp: user.trainingXp,
          initialLevel: user.trainingLevel,
        );
      }
    } catch (e) {
      appLog('LOAD ERROR: $e');
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SplashScreen(
        message: 'Загрузка сообщества...',
      );
    }
    return MainNavigation(inviteCode: widget.inviteCode);
  }
}
