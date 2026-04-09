import 'package:flutter/material.dart';
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
import '../../models/achievement.dart';
import '../community/members_screen.dart';
import '../../providers/matches_provider.dart';
import '../../widgets/avatar_viewer.dart';
import '../wallet/wallet_screen.dart';
import 'gender_selector_screen.dart';

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
      SportCategory.esports => _esportsPositions,
    };
  }

  /// Lookup position across all sports
  static (String, String, IconData, Color)? findPosition(String? position) {
    if (position == null) return null;
    return _footballPositions[position] ??
           _hockeyPositions[position] ??
           _tennisPositions[position] ??
           _esportsPositions[position];
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _statsLoaded = false;
  SportCategory _selectedSport = SportCategory.football;
  bool _isTrainingMode = false;

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

              // ─── Content depends on mode ───
              if (_isTrainingMode) ...[
                // Training Athlete Card placeholder (Sprint 3)
                _buildTrainingCard(user),
                const SizedBox(height: 16),
              ] else ...[
                // ─── Stats Card (sport-aware) ───
                PlayerFifaCard(
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
                ),
                const SizedBox(height: 16),

                // ─── Last Matches (sport-specific) ───
                _buildLastMatches(
                  statsProv.getMatchHistoryForSport(user?.id ?? '', _selectedSport)),
                const SizedBox(height: 16),

                // ─── Achievements (sport-specific) ───
                _buildAchievements(achievements, unlockedCount),
                const SizedBox(height: 16),
              ],

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

  // ─────────── SPORT SELECTOR ───────────

  Widget _buildSportSelector() {
    final t = AppColors.of(context);
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Sport categories
          ...SportCategory.values.map((sport) {
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
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : t.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : t.borderLight,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      sport.icon,
                      size: 16,
                      color: isSelected ? Colors.white : t.textHint,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sport.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: isSelected ? Colors.white : t.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
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
                borderRadius: BorderRadius.circular(14),
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

    return Container(
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
                  borderRadius: BorderRadius.circular(8),
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
        Stack(
          children: [
            GestureDetector(
              onTap: () {
                if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
                  openAvatarViewer(
                    context,
                    avatarUrl: user.avatarUrl!,
                    heroTag: 'profile_avatar_${user.id}',
                    userName: user.name,
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
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () => _pickAndUploadAvatar(context),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: t.cardBg, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, size: 10, color: Colors.white),
                ),
              ),
            ),
          ],
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
    if (realHistory.isEmpty) {
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
                size: 40, color: AppColors.of(context).textHint.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text('Нет сыгранных матчей',
                style: TextStyle(
                    color: AppColors.of(context).textHint, fontSize: 13)),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    final displayMatches = realHistory.take(5).map((r) {
      if (r['is_win'] == true) return _MatchResult.win;
      if (r['is_draw'] == true) return _MatchResult.draw;
      return _MatchResult.loss;
    }).toList();

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
                  '${wins}В из $total', // ignore: unnecessary_brace_in_string_interps
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
        _menuTile(Icons.directions_run_rounded, 'Моя дистанция',
            () => _showDistanceSheet(context)),
        _menuTile(Icons.account_balance_wallet_rounded, 'Кошелёк',
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WalletScreen()))),
        _menuTile(Icons.person_outline_rounded, 'Физические данные',
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const GenderSelectorScreen()))),
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
                borderRadius: BorderRadius.circular(10),
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
    for (final match in widget.completedMatches) {
      final km = await widget.db.getPlayerDistance(match.id, widget.userId);
      _savedDistances[match.id] = km;
      _controllers[match.id] = TextEditingController(
        text: km > 0 ? km.toStringAsFixed(1) : '',
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
        borderRadius: BorderRadius.circular(14),
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
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: t.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: t.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
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
                borderRadius: BorderRadius.circular(10),
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
