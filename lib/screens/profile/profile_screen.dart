import 'package:new_idea_works/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/match_stats.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/player_fifa_card.dart';
import '../stats/player_stats_screen.dart';
import '../community/community_manage_screen.dart';
import '../../models/enums.dart';
import '../../providers/sport_prefs_provider.dart';
import 'manage_sports_screen.dart';
import '../../models/achievement.dart';
import '../community/members_screen.dart';
import '../community/community_directory_screen.dart';
import '../../providers/matches_provider.dart';
import '../../widgets/avatar_viewer.dart';
import '../wallet/wallet_screen.dart';
import 'gender_selector_screen.dart';
import '../../widgets/theme_switch.dart';
import '../../providers/notification_provider.dart';
import '../notifications/notifications_screen.dart';
import '../../providers/friends_provider.dart';
import 'friends_screen.dart';
import '../community/community_chat_screen.dart';
import 'direct_messages_screen.dart';
import '../../providers/chat_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  // ═══ Позиции по видам спорта ═══
  static const _footballPositions = {
    'Нападающий': ('ST', 'Нападающий', Icons.sports_soccer, Color(0xFFE53935)),
    'Защитник': ('DF', 'Защитник', Icons.shield_rounded, Color(0xFF1E88E5)),
    'Полузащитник': ('MF', 'Полузащитник', Icons.swap_horiz_rounded, Color(0xFF43A047)),
    'Вратарь': ('GK', 'Вратарь', Icons.sports_handball_rounded, Color(0xFFFF8F00)),
    'Универсал': ('UNI', 'Универсал', Icons.person_rounded, Color(0xFF8E24AA)),
  };

  static const _hockeyPositions = {
    'Центральный': ('C', 'Центральный', Icons.sports_hockey, Color(0xFFE53935)),
    'Крайний': ('W', 'Крайний', Icons.speed_rounded, Color(0xFF43A047)),
    'Защитник': ('D', 'Защитник', Icons.shield_rounded, Color(0xFF1E88E5)),
    'Вратарь': ('G', 'Вратарь', Icons.sports_handball_rounded, Color(0xFFFF8F00)),
    'Универсал': ('UNI', 'Универсал', Icons.person_rounded, Color(0xFF8E24AA)),
  };

  static const _tennisPositions = {
    'Бэйслайнер': ('BL', 'Бэйслайнер', Icons.sports_tennis, Color(0xFF43A047)),
    'Сёрв-воллейер': ('SV', 'Сёрв-воллейер', Icons.flash_on_rounded, Color(0xFFE53935)),
    'Универсал': ('UNI', 'Универсал', Icons.person_rounded, Color(0xFF8E24AA)),
  };

  static const _padelPositions = {
    'Драйв': ('DR', 'Драйв', Icons.sports_tennis, Color(0xFF43A047)),
    'Ревес': ('RV', 'Ревес', Icons.swap_horiz_rounded, Color(0xFFE53935)),
    'Универсал': ('UNI', 'Универсал', Icons.person_rounded, Color(0xFF8E24AA)),
  };

  static const _esportsPositions = {
    // ─── MOBA (Dota 2) ───
    'Керри': ('P1', 'Керри', Icons.auto_awesome_rounded, Color(0xFFFFB300)),
    'Мидер': ('P2', 'Мидер', Icons.flash_on_rounded, Color(0xFFE53935)),
    'Оффлейнер': ('P3', 'Оффлейнер', Icons.shield_rounded, Color(0xFF1E88E5)),
    'Семи-саппорт': ('P4', 'Семи-саппорт', Icons.swap_calls_rounded, Color(0xFF43A047)),
    'Фулл-саппорт': ('P5', 'Фулл-саппорт', Icons.favorite_rounded, Color(0xFFAB47BC)),
    // ─── FPS (CS2) ───
    'IGL': ('IGL', 'Капитан', Icons.campaign_rounded, Color(0xFFFF6D00)),
    'Энтри': ('ENT', 'Энтри', Icons.directions_run_rounded, Color(0xFFE53935)),
    'Снайпер': ('AWP', 'Снайпер', Icons.gps_fixed_rounded, Color(0xFF1E88E5)),
    'Люркер': ('LRK', 'Люркер', Icons.visibility_rounded, Color(0xFF607D8B)),
    'Саппорт': ('SUP', 'Саппорт', Icons.support_agent_rounded, Color(0xFF43A047)),
    'Якорь': ('ANC', 'Якорь', Icons.anchor_rounded, Color(0xFF8D6E63)),
  };

  static Map<String, (String, String, IconData, Color)> positionsForSport(SportCategory sport) {
    return switch (sport) {
      SportCategory.football => _footballPositions,
      SportCategory.hockey => _hockeyPositions,
      SportCategory.tennis => _tennisPositions,
      SportCategory.padel => _padelPositions,
      SportCategory.esports => _esportsPositions,
    };
  }

  /// Lookup position across all sports
  static (String, String, IconData, Color)? findPosition(String? position) {
    if (position == null) return null;
    return _footballPositions[position] ??
           _hockeyPositions[position] ??
           _tennisPositions[position] ??
           _padelPositions[position] ??
           _esportsPositions[position];
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _statsLoaded = false;
  SportCategory _selectedSport = SportCategory.football;
  bool _isTrainingMode = false;
  List<String> _widgetOrder = _defaultOrder.toList();
  bool _showAllMatches = false;

  static const _defaultOrder = [
    'fifa_card', 'last_matches', 'achievements', 'balance', 'community',
  ];

  static const _prefsKey = 'profile_widget_order';

  @override
  void initState() {
    super.initState();
    _loadWidgetOrder();
  }

  Future<void> _loadWidgetOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey);
    if (saved != null && saved.length == _defaultOrder.length) {
      setState(() => _widgetOrder = saved);
    }
  }

  Future<void> _saveWidgetOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _widgetOrder);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_statsLoaded) {
      _statsLoaded = true;
      final auth = context.read<AuthProvider>();
      if (auth.uid != null) {
        context.read<StatsProvider>().loadPlayerStatsFromDb(auth.uid!);
        context.read<FriendsProvider>().loadCounts(auth.uid!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final community = context.watch<CommunityProvider>();
    final statsProv = context.watch<StatsProvider>();
    final user = auth.currentUser;
    final sub = community.getCurrentSubscription();
    final overall = statsProv.getPlayerStatsForSport(user?.id ?? '', _selectedSport);
    final achievements = statsProv.getAchievementsForSport(user?.id ?? '', _selectedSport);
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;

    // Sport-specific position
    final sportPosName = user?.getPositionForSport(_selectedSport.name) ?? 'Не указана';
    final posRecord = ProfileScreen.findPosition(sportPosName);
    final posAbbr = posRecord?.$1 ?? '—';
    final posFull = posRecord?.$2 ?? 'Не указана';
    final posIcon = posRecord?.$3 ?? Icons.help_outline_rounded;
    final posColor = posRecord?.$4 ?? AppColors.primary;
    final t = AppColors.of(context);

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ─── Header ───
              _buildHeader(user, posAbbr, posFull, posIcon, posColor),
              const SizedBox(height: 16),

              // ─── Sport Selector ───
              _buildSportSelector(),
              const SizedBox(height: 20),

              // ─── Reorderable content widgets ───
              if (_isTrainingMode) ...[
                _buildTrainingCard(user),
                const SizedBox(height: 16),
              ] else ...[
                ..._buildOrderedWidgets(
                  context, user, community, sub, statsProv,
                  posAbbr, posFull, overall, achievements, unlockedCount,
                ),
              ],

              // ─── Menu ───
              _buildMenu(context, auth),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityChip() {
    final t = AppColors.of(context);
    final communityProv = context.watch<CommunityProvider>();
    final communities = communityProv.communities;
    final active = communityProv.activeCommunity;

    if (communities.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: communities.length > 1
          ? () => _showCommunitySwitcher(communities, active)
          : null,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.borderLight, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active?.logoUrl != null && active!.logoUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  active.logoUrl!,
                  width: 18, height: 18,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                active?.name ?? '',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: t.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (communities.length > 1) ...[
              const SizedBox(width: 2),
              Icon(Icons.unfold_more_rounded,
                  size: 12, color: t.textHint),
            ],
          ],
        ),
      ),
    );
  }

  void _showCommunitySwitcher(List<dynamic> communities, dynamic active) {
    final t = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: t.dialogBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: t.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Icon(Icons.swap_horiz_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Выберите сообщество',
                    style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: t.textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            ...communities.map((c) {
              final isActive = c.id == active?.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    if (!isActive) {
                      final prov = context.read<CommunityProvider>();
                      prov.setActiveCommunity(c);
                      prov.loadSubscriptions(c.id);
                      context.read<MatchesProvider>().loadMatches(
                        c.id,
                        context.read<AuthProvider>().currentUser?.communityIds ?? [c.id],
                      );
                    }
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : t.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : t.borderLight,
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : t.borderLight.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: c.logoUrl != null && c.logoUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: Image.network(
                                    c.logoUrl!,
                                    width: 40, height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(
                                        c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: isActive ? AppColors.primary : t.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: isActive ? AppColors.primary : t.textSecondary,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isActive ? AppColors.primary : t.textPrimary,
                                  )),
                              const SizedBox(height: 2),
                              Text(
                                '${c.sport.displayName} • ${c.memberIds.length + c.adminIds.length + 1} участников',
                                style: TextStyle(color: t.textHint, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (isActive)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary, size: 22),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─────────── SPORT SELECTOR ───────────

  Widget _buildSportSelector() {
    final t = AppColors.of(context);
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Sport categories
          ...context.watch<SportPrefsProvider>().visibleSports.map((sport) {
            final isSelected = !_isTrainingMode && _selectedSport == sport;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _isTrainingMode = false;
                  _selectedSport = sport;
                });
                final uid = context.read<AuthProvider>().uid;
                if (uid != null) {
                  context.read<StatsProvider>().loadPlayerStatsForSport(uid, sport);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : t.cardBg,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : t.borderLight,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: t.isDark
                                ? Colors.black.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    Icon(
                      sport.icon,
                      size: 13,
                      color: isSelected ? Colors.white : t.textHint,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      sport.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: isSelected ? Colors.white : t.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          // Settings gear
          GestureDetector(
            onTap: () => ManageSportsScreen.show(context),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: t.surfaceBg,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: t.borderLight),
              ),
              child: Icon(Icons.tune_rounded, size: 14, color: t.textHint),
            ),
          ),
          // Training tab
          GestureDetector(
            onTap: () => setState(() => _isTrainingMode = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: _isTrainingMode
                    ? const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
                      )
                    : null,
                color: _isTrainingMode ? null : t.cardBg,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: _isTrainingMode ? Colors.transparent : t.borderLight,
                ),
                boxShadow: _isTrainingMode
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    size: 16,
                    color: _isTrainingMode ? Colors.white : t.textHint,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Тренировка',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: _isTrainingMode ? Colors.white : t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── TRAINING CARD (Sprint 3 placeholder) ───────────

  Widget _buildTrainingCard(dynamic user) {
    final t = AppColors.of(context); // ignore: unused_local_variable
    final level = user?.trainingLevel ?? 1;
    final xp = user?.trainingXp ?? 0;
    final rank = user?.trainingRank ?? 'Новичок';
    final xpNeeded = user?.xpForNextLevel ?? 500;
    final progress = user?.xpProgress ?? 0.0;

    return Stack(
      children: [
        Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
            const Color(0xFF0F3460).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Level + XP header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'LVL $level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                rank.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                'XP $xp / $xpNeeded',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // XP progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 20),
          // Radar chart placeholder
          Container(
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.radar_rounded,
                      size: 48,
                      color: const Color(0xFF00FF88).withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  Text(
                    'Radar Chart',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Спринт 3',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Body heatmap placeholder
          Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.accessibility_new_rounded,
                      size: 40,
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  Text(
                    'Body Heatmap',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
        ),
        // ─── "В разработке" badge ───
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
              ),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.construction_rounded,
                    size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'В разработке',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────── AVATAR UPLOAD ───────────

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();
    final cardBg = AppColors.of(context).cardBg;
    final textPrimary = AppColors.of(context).textPrimary;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Выберите фото', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: textPrimary,
              )),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: Text('Камера', style: TextStyle(color: textPrimary)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: Text('Галерея', style: TextStyle(color: textPrimary)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
      if (picked == null) return;

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Загрузка аватара...')),
      );

      final bytes = await picked.readAsBytes();
      final ext = picked.path.split('.').last.toLowerCase();
      final validExt = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';

      final userId = auth.currentUser?.id;
      if (userId == null) return;

      final db = SupabaseService();
      final url = await db.uploadAvatar(userId, bytes, validExt);

      if (url != null) {
        await auth.updateAvatar(url);
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Аватар обновлён! ✓'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  // ─────────── HEADER ───────────

  Widget _buildHeader(
      dynamic user, String posAbbr, String posFull, IconData posIcon, Color posColor) {
    final t = AppColors.of(context);
    return Row(
      children: [
        // Avatar
        GestureDetector(
          onTap: () {
            if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
              openAvatarViewer(
                context,
                avatarUrl: user.avatarUrl!,
                heroTag: 'profile_avatar_${user.id}',
                userName: user.name,
                onUpload: () => _pickAndUploadAvatar(context),
              );
            } else {
              _pickAndUploadAvatar(context);
            }
          },
          child: Hero(
            tag: 'profile_avatar_${user?.id ?? 'none'}',
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: posColor.withValues(alpha: 0.1),
                border: Border.all(color: posColor.withValues(alpha: 0.3)),
              ),
              child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        user.avatarUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (c1, e1, st1) => Center(
                          child: Text(
                            (user.name).substring(0, 1).toUpperCase(),
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: posColor),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        (user?.name ?? 'И').substring(0, 1).toUpperCase(),
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: posColor),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Name + ID + Community + Position
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.name ?? 'Игрок',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  _buildCommunityChip(),
                  const SizedBox(width: 6),
                  // Position badge (inline, small)
                  GestureDetector(
                    onTap: () => _showPositionDialog(context, context.read<AuthProvider>()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: posColor.withValues(alpha: 0.35), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(posIcon, size: 10, color: posColor),
                          const SizedBox(width: 4),
                          Text(
                            posAbbr,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: posColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Follower / Following counters
              _buildFollowCounters(),
            ],
          ),
        ),
        const ThemeSwitch(),
      ],
    );
  }

  // ─────────── FOLLOW COUNTERS ───────────

  Widget _buildFollowCounters() {
    final friendsProv = context.watch<FriendsProvider>();
    final t = AppColors.of(context);
    final auth = context.read<AuthProvider>();

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const FriendsScreen())),
      child: Row(
        children: [
          Text(
            '${friendsProv.followersCount}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            _pluralFollowers(friendsProv.followersCount),
            style: TextStyle(color: t.textHint, fontSize: 12),
          ),
          const SizedBox(width: 12),
          Text(
            '${friendsProv.followingCount}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            _pluralFollowing(friendsProv.followingCount),
            style: TextStyle(color: t.textHint, fontSize: 12),
          ),
          if (friendsProv.pendingCount > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4), width: 1),
              ),
              child: Text(
                '+${friendsProv.pendingCount}',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
          // Privacy icon
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _toggleProfileVisibility(auth),
            child: Icon(
              (auth.currentUser?.isPublicProfile ?? true)
                  ? Icons.public_rounded
                  : Icons.lock_rounded,
              size: 14,
              color: t.textHint,
            ),
          ),
          // DM inbox
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DirectMessagesScreen())),
            child: Icon(
              Icons.mail_outline_rounded,
              size: 16,
              color: t.textHint,
            ),
          ),
        ],
      ),
    );
  }

  String _pluralFollowers(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'подписчик';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
      return 'подписчика';
    }
    return 'подписчиков';
  }

  String _pluralFollowing(int _) => 'подписок';

  void _toggleProfileVisibility(AuthProvider auth) async {
    final current = auth.currentUser?.isPublicProfile ?? true;
    final newVal = !current;
    auth.currentUser?.isPublicProfile = newVal;
    setState(() {}); // trigger UI rebuild
    try {
      await SupabaseService().updateUser(auth.uid!, {
        'isPublicProfile': newVal,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newVal
                ? 'Профиль открыт — подписка без одобрения'
                : 'Профиль закрыт — подписка по запросу'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      appLog('PROFILE: toggle visibility error: $e');
    }
  }

  // ─────────── LAST MATCHES ───────────

  Widget _buildLastMatches(BuildContext context) {
    final matchesProv = context.watch<MatchesProvider>();
    final uid = context.read<AuthProvider>().uid ?? '';
    final completedEvents = matchesProv.completedEvents
        .where((e) => e.category == _selectedSport)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    // Extract each inner match result individually
    final innerResults = <_InnerMatchResult>[];
    for (final event in completedEvents) {
      // Check if user participated at all
      final isRegistered = event.registeredPlayerIds.contains(uid);

      // Find user's team index
      int userTeamIdx = -1;
      for (int t = 0; t < event.eventTeams.length; t++) {
        if (event.eventTeams[t].hasPlayer(uid)) {
          userTeamIdx = t;
          break;
        }
      }

      // Skip if user wasn't registered AND isn't in any team
      if (userTeamIdx < 0 && !isRegistered) continue;

      if (userTeamIdx >= 0 && event.innerMatches.isNotEmpty) {
        // User is in a team — show each inner match individually
        for (final im in event.innerMatches) {
          if (!im.isCompleted) continue;
          if (im.team1Index != userTeamIdx && im.team2Index != userTeamIdx) continue;

          final isTeam1 = im.team1Index == userTeamIdx;
          final myScore = isTeam1 ? im.team1Score : im.team2Score;
          final oppScore = isTeam1 ? im.team2Score : im.team1Score;
          final oppTeamIdx = isTeam1 ? im.team2Index : im.team1Index;
          final myTeamName = event.eventTeams[userTeamIdx].name;
          final oppTeamName = oppTeamIdx < event.eventTeams.length
              ? event.eventTeams[oppTeamIdx].name
              : '?';
          final myColor = Color(event.eventTeams[userTeamIdx].colorValue);
          final oppColor = oppTeamIdx < event.eventTeams.length
              ? Color(event.eventTeams[oppTeamIdx].colorValue)
              : Colors.grey;

          _MatchResult result;
          if (myScore > oppScore) {
            result = _MatchResult.win;
          } else if (myScore < oppScore) {
            result = _MatchResult.loss;
          } else {
            result = _MatchResult.draw;
          }

          innerResults.add(_InnerMatchResult(
            myTeamName: myTeamName,
            oppTeamName: oppTeamName,
            myScore: myScore,
            oppScore: oppScore,
            result: result,
            myColor: myColor,
            oppColor: oppColor,
          ));
        }
      } else if (isRegistered) {
        // Fallback: user registered but not in a team — show event-level result
        final standings = event.getStandings();
        if (standings.length >= 2) {
          final s1 = standings[0];
          final s2 = standings[1];
          final team1Name = s1.teamName.isNotEmpty ? s1.teamName : 'Команда 1';
          final team2Name = s2.teamName.isNotEmpty ? s2.teamName : 'Команда 2';
          final isDraw = s1.points == s2.points;
          innerResults.add(_InnerMatchResult(
            myTeamName: team1Name,
            oppTeamName: team2Name,
            myScore: s1.goalsFor,
            oppScore: s2.goalsFor,
            result: isDraw
                ? _MatchResult.draw
                : (s1.points > s2.points ? _MatchResult.win : _MatchResult.loss),
            myColor: Color(s1.colorValue),
            oppColor: Color(s2.colorValue),
          ));
        }
      }
    }

    final t = AppColors.of(context);

    if (innerResults.isEmpty) {
      return GlassCard(
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                const Text('Последние матчи',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 20),
            Icon(Icons.sports_score_outlined,
                size: 40, color: t.textHint.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text('Нет сыгранных матчей',
                style: TextStyle(color: t.textHint, fontSize: 13)),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    final maxVisible = _showAllMatches ? 10 : 5;
    final display = innerResults.take(maxVisible).toList();
    final hasMore = innerResults.length > 5;
    final wins = display.where((m) => m.result == _MatchResult.win).length;
    final draws = display.where((m) => m.result == _MatchResult.draw).length;
    final losses = display.where((m) => m.result == _MatchResult.loss).length;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded,
                  size: 18, color: t.textSecondary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Последние матчи',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: const Color(0xFF43A047).withValues(alpha: 0.35)),
                ),
                child: Text(
                  '${wins}В ${draws}Н ${losses}П',
                  style: const TextStyle(
                    color: Color(0xFF43A047),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...display.map((m) {
            final Color resultColor;
            final IconData resultIcon;
            if (m.result == _MatchResult.win) {
              resultColor = const Color(0xFF00E676);
              resultIcon = Icons.emoji_events_rounded;
            } else if (m.result == _MatchResult.draw) {
              resultColor = const Color(0xFFFFB300);
              resultIcon = Icons.handshake_rounded;
            } else {
              resultColor = const Color(0xFFFF5252);
              resultIcon = Icons.trending_down_rounded;
            }
            final isWin = m.result == _MatchResult.win;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: t.cardBg.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: t.isDark
                              ? Colors.black.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Neon edge
                        Container(
                          width: 3,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                resultColor.withValues(alpha: 0.8),
                                resultColor.withValues(alpha: 0.2),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: resultColor.withValues(alpha: 0.35),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // My team avatar
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: m.myColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Center(
                            child: Text(
                              m.myTeamName.isNotEmpty
                                  ? m.myTeamName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: m.myColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Team names
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _capitalize(m.myTeamName),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: t.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  Icon(resultIcon,
                                      size: 10,
                                      color: resultColor.withValues(alpha: 0.7)),
                                  const SizedBox(width: 3),
                                  Text(
                                    'vs ${_capitalize(m.oppTeamName)}',
                                    style: TextStyle(
                                      color: t.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'monospace',
                                      letterSpacing: 0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Score capsule — flat, no border
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '${m.myScore}:${m.oppScore}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: resultColor,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Win gradient overlay
                  if (isWin)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: RadialGradient(
                            center: Alignment.topLeft,
                            radius: 1.5,
                            colors: [
                              resultColor.withValues(alpha: 0.04),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          // ─── Show more / collapse button ───
          if (hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () => setState(() => _showAllMatches = !_showAllMatches),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: t.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.borderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showAllMatches
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: t.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _showAllMatches
                            ? 'Свернуть'
                            : 'Показать ещё (${(innerResults.length > 10 ? 10 : innerResults.length) - 5})',
                        style: TextStyle(
                          color: t.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  // ─────────── ACHIEVEMENTS ───────────

  Widget _buildAchievements(List<Achievement> achievements, int unlockedCount) {
    // Empty state for new players
    if (achievements.isEmpty) {
      return GlassCard(
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: Color(0xFFFFB300), size: 20),
                const SizedBox(width: 8),
                const Text('Достижения',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 20),
            Icon(Icons.emoji_events_outlined,
                size: 40, color: AppColors.of(context).textHint.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text('Сыграйте матчи, чтобы открыть достижения',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.of(context).textHint, fontSize: 13)),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: Color(0xFFFFB300), size: 20),
              const SizedBox(width: 8),
              const Text('Достижения',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.of(context).textSecondary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$unlockedCount / ${achievements.length}',
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          // Horizontal scrollable trophy shelf
          const SizedBox(height: 14),
          const Text(
            'Витрина трофеев',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: achievements.length.clamp(0, 16),
              separatorBuilder: (c, i) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final a = achievements[i];
                final locked = !a.isUnlocked;
                final color = a.rarity.color;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: locked
                            ? Colors.grey.withValues(alpha: 0.05)
                            : color.withValues(alpha: 0.1),
                        border: Border.all(
                          color: locked
                              ? Colors.grey.withValues(alpha: 0.12)
                              : color.withValues(alpha: 0.4),
                          width: locked ? 1 : 1.5,
                        ),
                      ),
                      child: Icon(
                        locked ? Icons.lock_rounded : a.icon,
                        size: 18,
                        color: locked
                            ? Colors.grey.withValues(alpha: 0.2)
                            : color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 50,
                      child: Text(
                        locked ? '???' : a.name,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: locked
                              ? Colors.grey.withValues(alpha: 0.35)
                              : AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }



  // ─────────── BALANCE ───────────

  Widget _buildBalance(double balance) {
    return GlassCard(
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            color: balance >= 0 ? AppColors.accent : AppColors.error,
            size: 26,
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Баланс',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                Helpers.formatCurrency(balance),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: balance < 0 ? AppColors.error : AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────── COMMUNITY ───────────

  Widget _buildCommunityCard(
      BuildContext context, CommunityProvider community, dynamic sub, String? userId) {
    final t = AppColors.of(context);
    
    // Watch ChatProvider for unread badge updates
    final chatProv = context.watch<ChatProvider>();
    if (community.activeCommunity != null && userId != null) {
      // Start background listener (post-frame to avoid build-phase async)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        chatProv.startBackgroundListener(
          chatId: community.activeCommunity!.id,
          myUserId: userId,
        );
      });
    }
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CommunityManageScreen())),
      child: GlassCard(
        child: Column(
          children: [
            // ─── Community row ───
            Row(
              children: [
                community.activeCommunity!.logoUrl != null &&
                        community.activeCommunity!.logoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Image.network(
                          community.activeCommunity!.logoUrl!,
                          width: 42, height: 42,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.groups_rounded,
                              color: AppColors.primary, size: 26),
                        ),
                      )
                    : const Icon(Icons.groups_rounded,
                        color: AppColors.primary, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(community.activeCommunity!.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        'Код: ${community.activeCommunity!.inviteCode} • ${community.activeCommunity!.totalMembers} уч.',
                        style: const TextStyle(
                            color: AppColors.textHint, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CommunityChatScreen())),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                              color: t.borderLight),
                        ),
                        child: Icon(Icons.chat_rounded,
                            color: t.textSecondary, size: 16),
                      ),
                      if (community.activeCommunity != null &&
                          chatProv.unreadCountFor(community.activeCommunity!.id) > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '${chatProv.unreadCountFor(community.activeCommunity!.id) > 9 ? "9+" : chatProv.unreadCountFor(community.activeCommunity!.id)}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MembersScreen())),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: t.borderLight),
                    ),
                    child: Icon(Icons.people_alt_rounded,
                        color: t.textSecondary, size: 16),
                  ),
                ),
                // Join requests icon (admin only, with badge)
                if (community.activeCommunity!.isAdmin(userId ?? '') &&
                    community.pendingRequestCount > 0) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CommunityManageScreen())),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded,
                              color: AppColors.primary, size: 16),
                        ),
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '${community.pendingRequestCount}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            // ─── Subscription row (personalized) ───
            if (sub != null && userId != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Builder(builder: (_) {
                  final isSignedUp = sub.hasUser(userId);
                  final entryCount = sub.entries.length;
                  final perPlayer = entryCount > 0
                      ? sub.effectiveRent / entryCount
                      : sub.effectiveRent;
                  final _matches = sub.entries
                      .where((e) => e.userId == userId)
                      .toList();
                  final userEntry = _matches.isNotEmpty ? _matches.first : null;
                  final isPaid = userEntry?.paymentStatus == SubscriptionPaymentStatus.paid;
                  final isCalculated = sub.isCalculated;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: t.borderLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSignedUp
                              ? Icons.check_circle_rounded
                              : Icons.card_membership_rounded,
                          color: isSignedUp ? AppColors.primary : t.textHint,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSignedUp ? 'Абонемент' : 'Не записан',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: isSignedUp ? t.textPrimary : t.textHint,
                          ),
                        ),
                        if (isSignedUp) ...[
                          Text(
                            ' • ',
                            style: TextStyle(color: t.textHint, fontSize: 11),
                          ),
                          if (isCalculated && isPaid)
                            Text('Оплачено ✓',
                                style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600))
                          else if (isCalculated)
                            Text('К оплате',
                                style: TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600))
                          else
                            Text('$entryCount чел.',
                                style: TextStyle(
                                    color: t.textHint,
                                    fontSize: 11)),
                        ],
                        const Spacer(),
                        Text(
                          '~${Helpers.formatCurrency(perPlayer)}',
                          style: TextStyle(
                            color: isSignedUp ? t.textPrimary : t.textHint,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }


  // ─────────── NO COMMUNITY ───────────

  Widget _buildNoCommunity(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.groups_rounded,
                color: AppColors.textSecondary, size: 20),
            SizedBox(width: 8),
            Text('Сообщество',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          const Text(
            'Вы не состоите ни в одном сообществе',
            style: TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CommunityDirectoryScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.explore_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text('Найти сообщество',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ─────────── WIDGET ORDER HELPERS ───────────

  Widget _widgetForKey(
    String key,
    BuildContext context,
    dynamic user,
    CommunityProvider community,
    dynamic sub,
    StatsProvider statsProv,
    String posAbbr,
    String posFull,
    PlayerOverallStats overall,
    List<Achievement> achievements,
    int unlockedCount,
  ) {
    switch (key) {
      case 'fifa_card':
        return PlayerFifaCard(
          playerName: user?.name ?? 'Игрок',
          position: posAbbr,
          positionFull: posFull,
          stats: overall,
          sport: _selectedSport,
          isPremium: user?.isPremium ?? false,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlayerStatsScreen()),
          ),
        );
      case 'last_matches':
        return _buildLastMatches(context);
      case 'achievements':
        return _buildAchievements(achievements, unlockedCount);
      case 'balance':
        return _buildBalance(user?.balance ?? 0);
      case 'community':
        return community.activeCommunity != null
            ? _buildCommunityCard(context, community, sub, user?.id)
            : _buildNoCommunity(context);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Widgets in saved order — long-press to drag and reorder
  List<Widget> _buildOrderedWidgets(
    BuildContext context,
    dynamic user,
    CommunityProvider community,
    dynamic sub,
    StatsProvider statsProv,
    String posAbbr,
    String posFull,
    PlayerOverallStats overall,
    List<Achievement> achievements,
    int unlockedCount,
  ) {
    final widgets = <Widget>[];
    for (final key in _widgetOrder) {
      widgets.add(
        LongPressDraggable<String>(
          data: key,
          axis: Axis.vertical,
          hapticFeedbackOnStart: true,
          feedback: Material(
            color: Colors.transparent,
            elevation: 12,
            shadowColor: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 40,
              child: Opacity(
                opacity: 0.9,
                child: _widgetForKey(
                  key, context, user, community, sub, statsProv,
                  posAbbr, posFull, overall, achievements, unlockedCount,
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _widgetForKey(
              key, context, user, community, sub, statsProv,
              posAbbr, posFull, overall, achievements, unlockedCount,
            ),
          ),
          onDragEnd: (_) => _saveWidgetOrder(),
          child: DragTarget<String>(
            onWillAcceptWithDetails: (details) => details.data != key,
            onAcceptWithDetails: (details) {
              final oldIndex = _widgetOrder.indexOf(details.data);
              final newIndex = _widgetOrder.indexOf(key);
              if (oldIndex == -1 || newIndex == -1) return;
              setState(() {
                _widgetOrder.removeAt(oldIndex);
                _widgetOrder.insert(newIndex, details.data);
              });
              _saveWidgetOrder();
            },
            builder: (ctx, candidateData, rejectedData) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: candidateData.isNotEmpty
                    ? (Matrix4.identity()..scale(0.97, 0.97))
                    : Matrix4.identity(),
                transformAlignment: Alignment.center,
                child: _widgetForKey(
                  key, context, user, community, sub, statsProv,
                  posAbbr, posFull, overall, achievements, unlockedCount,
                ),
              );
            },
          ),
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }
    return widgets;
  }


  // ─────────── MENU ───────────

  Widget _buildMenu(BuildContext context, AuthProvider auth) {
    final t = AppColors.of(context);

    return Column(
      children: [
        _menuTile(Icons.directions_run_rounded, 'Моя дистанция',
            () => _showDistanceSheet(context)),
        _menuTile(Icons.account_balance_wallet_rounded, 'Кошелёк',
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WalletScreen()))),
        _menuTile(Icons.person_outline_rounded, 'Физические данные',
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const GenderSelectorScreen()))),
        _menuTile(Icons.tune_rounded, 'Мои виды спорта',
            () => ManageSportsScreen.show(context)),
        _menuTile(Icons.people_outline_rounded, 'Друзья и подписки',
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FriendsScreen()))),
        _buildNotificationTile(context),
        Divider(
            color: t.borderLight.withValues(alpha: 0.5), height: 24),
        _menuTile(Icons.explore_rounded, 'Список сообществ',
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CommunityDirectoryScreen()))),
        _menuTile(Icons.add_circle_outline_rounded, 'Создать сообщество',
            () => _showCreateDialog(context)),
        _menuTile(Icons.login_rounded, 'Вступить по коду',
            () => _showJoinDialog(context)),
        Divider(
            color: t.borderLight.withValues(alpha: 0.5), height: 24),
        _menuTile(Icons.logout_rounded, 'Выйти', () => auth.logout(),
            isDestructive: true),
        const SizedBox(height: 8),
        _menuTile(Icons.delete_forever_rounded, 'Удалить аккаунт',
            () => _showDeleteAccountDialog(context, auth),
            isDestructive: true),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'ID: ${auth.currentUser?.id ?? "—"}',
            style: TextStyle(
              color: t.textHint.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthProvider auth) {
    final t = AppColors.of(context);
    final confirmCtrl = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: t.dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 24),
              SizedBox(width: 8),
              Text('Удалить аккаунт?',
                  style: TextStyle(color: AppColors.error)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Это действие необратимо!',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Будут удалены:\n'
                      '• Ваш профиль и аватар\n'
                      '• История матчей и статистика\n'
                      '• Все сообщения\n'
                      '• Транзакции и подписки\n'
                      '• Членство в сообществах',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Для подтверждения введите УДАЛИТЬ',
                style: TextStyle(
                  color: t.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                style: TextStyle(color: t.textPrimary),
                decoration: InputDecoration(
                  hintText: 'УДАЛИТЬ',
                  hintStyle: TextStyle(color: t.textHint),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: BorderSide(color: t.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  filled: true,
                  fillColor: t.cardBg,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                onChanged: (_) => setDState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(ctx),
              child: Text('Отмена',
                  style: TextStyle(
                      color: isDeleting ? t.textHint : t.textPrimary)),
            ),
            TextButton(
              onPressed: isDeleting ||
                      confirmCtrl.text.trim() != 'УДАЛИТЬ'
                  ? null
                  : () async {
                      setDState(() => isDeleting = true);
                      final error = await auth.deleteAccount();
                      if (error != null && ctx.mounted) {
                        setDState(() => isDeleting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      } else if (ctx.mounted) {
                        Navigator.pop(ctx);
                        // UI will auto-navigate to login screen
                      }
                    },
              child: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.error),
                    )
                  : Text(
                      'Удалить навсегда',
                      style: TextStyle(
                        color: confirmCtrl.text.trim() == 'УДАЛИТЬ'
                            ? AppColors.error
                            : t.textHint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context) {
    final t = AppColors.of(context);
    final notifProv = context.watch<NotificationProvider>();
    final unread = notifProv.unreadCount;
    return ListTile(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen())),
      contentPadding: EdgeInsets.zero,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_none_rounded,
              color: t.textSecondary, size: 22),
          if (unread > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text('Уведомления', style: TextStyle(color: t.textPrimary, fontSize: 14)),
      trailing: Icon(Icons.chevron_right_rounded, color: t.borderLight, size: 20),
    );
  }

  Widget _menuTile(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    final t = AppColors.of(context);
    final color = isDestructive ? AppColors.error : t.textPrimary;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon,
          color: isDestructive ? AppColors.error : t.textSecondary,
          size: 22),
      title: Text(title, style: TextStyle(color: color, fontSize: 14)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: t.borderLight, size: 20),
    );
  }

  // ─────────── DISTANCE SHEET ───────────

  void _showDistanceSheet(BuildContext context) {
    final t = AppColors.of(context);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final matchesProv = context.read<MatchesProvider>();
    final completed = matchesProv.completedEvents;
    final db = SupabaseService();

    showModalBottomSheet(
      context: context,
      backgroundColor: t.dialogBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DistanceSheet(
        completedMatches: completed,
        userId: userId,
        db: db,
      ),
    );
  }

  // ─────────── DIALOGS ───────────

  void _showPositionDialog(BuildContext context, AuthProvider auth) {
    final positions = ProfileScreen.positionsForSport(_selectedSport);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.of(context).borderLight),
        ),
        title: Row(
          children: [
            Icon(_selectedSport.icon, size: 20),
            const SizedBox(width: 8),
            Text('Позиция: ${_selectedSport.displayName}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: positions.entries.map((e) {
            final name = e.key;
            final abbr = e.value.$1;
            final icon = e.value.$3;
            final color = e.value.$4;
            final isSelected = auth.currentUser?.getPositionForSport(_selectedSport.name) == name;
            return ListTile(
              selected: isSelected,
              selectedTileColor: color.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              title: Text(name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? color : null,
                  )),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isSelected ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 12, color: color),
                    Text(abbr,
                        style: TextStyle(
                          color: color,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        )),
                  ],
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle_rounded, color: color, size: 20)
                  : null,
              onTap: () {
                auth.updateSportPosition(_selectedSport.name, name);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    SportCategory sport = SportCategory.football;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: AppColors.of(context).dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.of(context).borderLight),
          ),
          title: const Text('Новое сообщество'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nameCtrl, 'Название', Icons.group_rounded),
                const SizedBox(height: 12),
                DropdownButtonFormField<SportCategory>(
                  dropdownColor: AppColors.of(context).dialogBg,
                  initialValue: sport,
                  style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Вид спорта',
                    labelStyle: TextStyle(color: AppColors.of(context).textHint),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: BorderSide(color: AppColors.of(context).borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  items: SportCategory.values
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text(c.displayName)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDState(() => sport = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final auth = context.read<AuthProvider>();
                final communityProv = context.read<CommunityProvider>();
                await communityProv.createCommunityFirestore(
                  name: nameCtrl.text.trim(),
                  sport: sport,
                  ownerId: auth.uid!,
                );
                await auth
                    .addCommunityToUser(communityProv.activeCommunity!.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Сообщество создано!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Создать',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.of(context).borderLight),
        ),
        title: const Text('Вступить по коду'),
        content:
            _dialogField(codeCtrl, 'Код приглашения', Icons.vpn_key_rounded),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              if (codeCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final auth = context.read<AuthProvider>();
              final communityProv = context.read<CommunityProvider>();
              try {
                final ok = await communityProv.joinCommunityFirestore(
                  codeCtrl.text.trim(),
                  auth.uid!,
                );
                if (context.mounted) {
                  if (ok) {
                    await auth.addCommunityToUser(
                        communityProv.activeCommunity!.id);
                    if (communityProv.activeCommunity != null) {
                      await communityProv.loadSubscriptions(
                          communityProv.activeCommunity!.id);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Вы вступили в сообщество!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Сообщество не найдено'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Вступить',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
      TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false}) {
    final t = AppColors.of(context);
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: t.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: t.textHint),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(color: t.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: t.cardBg,
      ),
    );
  }
}

// ─── Helpers ───

enum _MatchResult {
  win('В', 'Победа', Color(0xFF43A047)),
  loss('П', 'Поражение', Color(0xFFE53935)),
  draw('Н', 'Ничья', Color(0xFF9E9E9E));

  final String letter;
  final String label;
  final Color color;

  const _MatchResult(this.letter, this.label, this.color);
}

class _InnerMatchResult {
  final String myTeamName;
  final String oppTeamName;
  final int myScore;
  final int oppScore;
  final _MatchResult result;
  final Color myColor;
  final Color oppColor;

  const _InnerMatchResult({
    required this.myTeamName,
    required this.oppTeamName,
    required this.myScore,
    required this.oppScore,
    required this.result,
    required this.myColor,
    required this.oppColor,
  });
}

class _NearAchievement { // ignore: unused_element
  final String name;
  final IconData icon;
  final int progress;
  final int target;
  final String description;
  final AchievementRarity rarity;

  const _NearAchievement({
    required this.name,
    required this.icon,
    required this.progress,
    required this.target,
    required this.description,
    required this.rarity,
  });
}

// ─── Distance Sheet Widget ───
class _DistanceSheet extends StatefulWidget {
  final List<dynamic> completedMatches;
  final String userId;
  final SupabaseService db;

  const _DistanceSheet({
    required this.completedMatches,
    required this.userId,
    required this.db,
  });

  @override
  State<_DistanceSheet> createState() => _DistanceSheetState();
}

class _DistanceSheetState extends State<_DistanceSheet> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, double> _savedDistances = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDistances();
  }

  Future<void> _loadDistances() async {
    final matches = widget.completedMatches;
    // Load all distances in parallel instead of sequentially
    final futures = matches.map((match) async {
      final km = await widget.db.getPlayerDistance(match.id, widget.userId);
      return MapEntry(match.id as String, km as double);
    });
    final results = await Future.wait(futures);
    for (final entry in results) {
      _savedDistances[entry.key] = entry.value;
      _controllers[entry.key] = TextEditingController(
        text: entry.value > 0 ? entry.value.toStringAsFixed(1) : '',
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.3,
      expand: false,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: t.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.directions_run_rounded,
                  color: Color(0xFF26A69A), size: 24),
                const SizedBox(width: 8),
                Text('Моя дистанция', style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                )),
              ],
            ),
            const SizedBox(height: 4),
            Text('Введите километры из вашего трекера (смарт-часы)',
              style: TextStyle(color: t.textHint, fontSize: 12)),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (widget.completedMatches.isEmpty)
              Center(child: Text('Нет завершённых матчей',
                style: TextStyle(color: t.textHint)))
            else
              Expanded(
                child: Builder(
                  builder: (ctx) {
                    final sorted = List.of(widget.completedMatches)
                      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
                    return ListView.separated(
                      controller: scrollCtrl,
                      itemCount: sorted.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final match = sorted[i];
                        return _matchDistanceTile(t, match);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _matchDistanceTile(AppThemeColors t, dynamic match) {
    final ctrl = _controllers[match.id]!;
    final saved = _savedDistances[match.id] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: t.borderLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${match.category.displayName} • ${match.format}',
                  style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${match.dateTime.day}.${match.dateTime.month}.${match.dateTime.year}',
                  style: TextStyle(color: t.textHint, fontSize: 11),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'км',
                hintStyle: TextStyle(color: t.textHint, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide(color: t.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide(color: t.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: const BorderSide(color: Color(0xFF26A69A)),
                ),
                filled: true,
                fillColor: t.surfaceBg,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final km = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;
              if (km <= 0) return;
              try {
                await widget.db.savePlayerDistance(match.id, widget.userId, km);
                setState(() => _savedDistances[match.id] = km);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('✅ Сохранено: ${km.toStringAsFixed(1)} км'),
                    backgroundColor: const Color(0xFF26A69A),
                    duration: const Duration(seconds: 1),
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Ошибка: $e'),
                    backgroundColor: AppColors.error,
                  ));
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: saved > 0
                    ? const Color(0xFF26A69A).withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                saved > 0 ? Icons.check_rounded : Icons.save_rounded,
                color: saved > 0 ? const Color(0xFF26A69A) : AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
