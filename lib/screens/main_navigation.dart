import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/community_provider.dart';
import '../providers/matches_provider.dart';
import '../theme/app_colors.dart';
import 'home/home_screen.dart';
import 'schedule/schedule_screen.dart';
import 'training/training_hub_screen.dart';
import 'profile/profile_screen.dart';
import '../widgets/bottom_nav_bar.dart';

class MainNavigation extends StatefulWidget {
  final String? inviteCode;
  const MainNavigation({super.key, this.inviteCode});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  bool _inviteHandled = false;

  final List<Widget> _screens = const [
    HomeScreen(),
    ScheduleScreen(),
    TrainingHubScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Обработка invite code из URL после построения виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInviteCode();
    });
  }

  Future<void> _handleInviteCode() async {
    if (_inviteHandled || widget.inviteCode == null || widget.inviteCode!.isEmpty) return;
    _inviteHandled = true;

    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;

    final code = widget.inviteCode!;
    debugPrint('INVITE: handling invite code: $code');

    // Показываем диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        title: const Row(
          children: [
            Icon(Icons.group_add_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: 10),
            Text('Приглашение'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Вас пригласили в сообщество!',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.vpn_key_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    code,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена', style: TextStyle(color: AppColors.textHint)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: const Text('Вступить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Вступаем в сообщество
    try {
      final communityProv = context.read<CommunityProvider>();
      final success = await communityProv.joinCommunityFirestore(code, auth.uid!);

      if (!mounted) return;

      if (success) {
        await auth.addCommunityToUser(communityProv.activeCommunity!.id);
        // Загружаем матчи и подписки нового сообщества
        if (communityProv.activeCommunity != null) {
          final cid = communityProv.activeCommunity!.id;
          if (!mounted) return;
          final matchesProv = context.read<MatchesProvider>();
          await Future.wait([
            matchesProv.loadMatches(cid, auth.currentUser?.communityIds ?? [cid]),
            communityProv.loadSubscriptions(cid),
          ]);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Вы вступили в сообщество!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Сообщество не найдено. Проверьте ссылку.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при вступлении: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    // Очищаем URL от ?join= параметра (на вебе)
    _clearUrlParams();
  }

  void _clearUrlParams() {
    try {
      // Используем SystemNavigator для очистки URL в веб-версии
      final cleanUrl = Uri.base.replace(queryParameters: {}).toString();
      SystemNavigator.routeInformationUpdated(uri: Uri.parse(cleanUrl));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
