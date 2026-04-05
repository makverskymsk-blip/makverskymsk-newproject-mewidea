import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/player_fifa_card.dart';
import '../stats/player_stats_screen.dart';
import '../community/community_manage_screen.dart';
import '../../models/enums.dart';
import '../../models/achievement.dart';
import '../community/members_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const _positionData = {
    'Нападающий': ('ST', 'Нападающий', Icons.sports_soccer, Color(0xFFE53935)),
    'Защитник': ('DF', 'Защитник', Icons.shield_rounded, Color(0xFF1E88E5)),
    'Полузащитник': ('MF', 'Полузащитник', Icons.swap_horiz_rounded, Color(0xFF43A047)),
    'Вратарь': ('GK', 'Вратарь', Icons.sports_handball_rounded, Color(0xFFFF8F00)),
    'Универсал': ('UNI', 'Универсал', Icons.person_rounded, Color(0xFF8E24AA)),
  };

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _statsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_statsLoaded) {
      _statsLoaded = true;
      final auth = context.read<AuthProvider>();
      if (auth.uid != null) {
        context.read<StatsProvider>().loadPlayerStatsFromDb(auth.uid!);
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
    final overall = statsProv.getPlayerStats(user?.id ?? '');
    final achievements = statsProv.getAchievements(user?.id ?? '');
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;

    final posRecord = ProfileScreen._positionData[user?.position];
    final posAbbr = posRecord?.$1 ?? 'ST';
    final posFull = posRecord?.$2 ?? 'Нападающий';
    final posIcon = posRecord?.$3 ?? Icons.sports_soccer;
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
              const SizedBox(height: 20),

              // ─── Stats Card ───
              PlayerFifaCard(
                playerName: user?.name ?? 'Игрок',
                position: posAbbr,
                positionFull: posFull,
                stats: overall,
                isPremium: user?.isPremium ?? false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlayerStatsScreen()),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Last Matches ───
              _buildLastMatches(
                statsProv.getMatchHistoryRecords(user?.id ?? '')),
              const SizedBox(height: 16),

              // ─── Achievements ───
              _buildAchievements(achievements, unlockedCount),
              const SizedBox(height: 16),

              // ─── Balance ───
              _buildBalance(user?.balance ?? 0),
              const SizedBox(height: 16),

              // ─── Community ───
              if (community.activeCommunity != null)
                _buildCommunityCard(context, community)
              else
                _buildNoCommunity(context),
              const SizedBox(height: 16),

              // ─── Subscription ───
              if (sub != null) _buildSubscription(sub),
              if (sub != null) const SizedBox(height: 16),

              // ─── Menu ───
              _buildMenu(context, auth),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────── HEADER ───────────

  Widget _buildHeader(
      dynamic user, String posAbbr, String posFull, IconData posIcon, Color posColor) {
    final t = AppColors.of(context);
    return Row(
      children: [
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: posColor.withValues(alpha: 0.1),
            border: Border.all(color: posColor.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              (user?.name ?? 'И').substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: posColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Name + ID
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
              Text(
                'ID: ${(user?.id ?? "0000").substring((user?.id ?? "0000").length - 4)}',
                style: TextStyle(color: t.textHint, fontSize: 12),
              ),
            ],
          ),
        ),
        // Position tag (enhanced)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: posColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: posColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(posIcon, size: 14, color: posColor),
              const SizedBox(width: 5),
              Text(
                posAbbr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: posColor,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────── LAST MATCHES ───────────

  Widget _buildLastMatches(List<Map<String, dynamic>> realHistory) {
    // Build display data: use real if available, mock otherwise
    List<_MatchResult> displayMatches;
    if (realHistory.isNotEmpty) {
      displayMatches = realHistory.take(5).map((r) {
        if (r['is_win'] == true) return _MatchResult.win;
        if (r['is_draw'] == true) return _MatchResult.draw;
        return _MatchResult.loss;
      }).toList();
    } else {
      displayMatches = [
        _MatchResult.win, _MatchResult.loss, _MatchResult.win,
        _MatchResult.draw, _MatchResult.win,
      ];
    }

    final wins = displayMatches.where((m) => m == _MatchResult.win).length;
    final total = displayMatches.length;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              const Text('Последние матчи',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$winsВ из $total',
                  style: const TextStyle(
                    color: Color(0xFF43A047), fontSize: 11, fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: displayMatches.map((m) {
              return Column(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: m.color.withValues(alpha: 0.1),
                      border: Border.all(color: m.color.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(m.letter,
                          style: TextStyle(color: m.color,
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(m.label,
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.textHint,
                          fontWeight: FontWeight.w500)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─────────── ACHIEVEMENTS ───────────

  Widget _buildAchievements(List<Achievement> achievements, int unlockedCount) {
    // "Almost done" mock achievements
    final almostDone = [
      _NearAchievement(
        name: 'Железный человек',
        icon: Icons.fitness_center_rounded,
        progress: 8,
        target: 10,
        description: 'Сыграйте 10 матчей',
        rarity: AchievementRarity.common,
      ),
      _NearAchievement(
        name: 'Снайпер',
        icon: Icons.gps_fixed_rounded,
        progress: 7,
        target: 10,
        description: 'Забейте 10 голов',
        rarity: AchievementRarity.common,
      ),
    ];

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
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$unlockedCount / ${achievements.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          // Near completion section
          const SizedBox(height: 14),
          const Text(
            'Почти выполнено',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...almostDone.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: a.rarity.color.withValues(alpha: 0.1),
                        border: Border.all(
                            color: a.rarity.color.withValues(alpha: 0.3)),
                      ),
                      child: Icon(a.icon,
                          size: 16, color: a.rarity.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(a.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  )),
                              const Spacer(),
                              Text(
                                '${a.progress}/${a.target}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: a.rarity.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: a.progress / a.target,
                              backgroundColor: AppColors.borderLight,
                              valueColor: AlwaysStoppedAnimation(
                                  a.rarity.color),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),

          // Horizontal scrollable trophy shelf
          const SizedBox(height: 8),
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
              separatorBuilder: (_, _) => const SizedBox(width: 10),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (balance >= 0 ? AppColors.accent : AppColors.error)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: balance >= 0 ? AppColors.accent : AppColors.error,
              size: 22,
            ),
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
      BuildContext context, CommunityProvider community) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CommunityManageScreen())),
      child: GlassCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.groups_rounded,
                  color: AppColors.primary, size: 22),
            ),
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
                  MaterialPageRoute(builder: (_) => const MembersScreen())),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.people_alt_rounded,
                    color: AppColors.primary, size: 16),
              ),
            ),
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
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showCreateDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Создать',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showJoinDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded,
                            color: AppColors.primary, size: 18),
                        SizedBox(width: 6),
                        Text('Вступить',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────── SUBSCRIPTION ───────────

  Widget _buildSubscription(dynamic sub) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.card_membership_rounded,
                color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Абонемент',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  'Записано: ${sub.entries.length} чел. • Аренда: ${Helpers.formatCurrency(sub.totalRent)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── MENU ───────────

  Widget _buildMenu(BuildContext context, AuthProvider auth) {
    final themeProv = context.watch<ThemeProvider>();
    final t = AppColors.of(context);

    return Column(
      children: [
        // Dark mode toggle
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: t.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.borderLight),
          ),
          child: Row(
            children: [
              Icon(
                themeProv.isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: themeProv.isDark
                    ? const Color(0xFFFFB800)
                    : const Color(0xFF546E7A),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  themeProv.isDark ? 'Тёмная тема' : 'Светлая тема',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
              ),
              Switch.adaptive(
                value: themeProv.isDark,
                activeTrackColor: AppColors.primary,
                onChanged: (_) => themeProv.toggle(),
              ),
            ],
          ),
        ),
        _menuTile(Icons.edit_rounded, 'Изменить позицию',
            () => _showPositionDialog(context, auth)),
        _menuTile(Icons.add_circle_outline_rounded, 'Создать сообщество',
            () => _showCreateDialog(context)),
        _menuTile(Icons.login_rounded, 'Вступить по коду',
            () => _showJoinDialog(context)),
        _menuTile(Icons.notifications_none_rounded, 'Уведомления', () {}),
        Divider(
            color: t.borderLight.withValues(alpha: 0.5), height: 24),
        _menuTile(Icons.logout_rounded, 'Выйти', () => auth.logout(),
            isDestructive: true),
      ],
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

  // ─────────── DIALOGS ───────────

  void _showPositionDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.of(context).borderLight),
        ),
        title: const Text('Выберите позицию'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ProfileScreen._positionData.entries.map((e) {
            final name = e.key;
            final abbr = e.value.$1;
            final icon = e.value.$3;
            final color = e.value.$4;
            return ListTile(
              title: Text(name),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
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
              onTap: () {
                auth.updatePosition(name);
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
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.of(context).borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
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
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
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

class _NearAchievement {
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
