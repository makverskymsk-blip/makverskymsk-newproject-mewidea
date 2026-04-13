import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/matches_provider.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/player_fifa_card.dart';
import '../../widgets/avatar_viewer.dart';
import '../community/direct_chat_screen.dart';
import 'profile_screen.dart';

/// Screen for viewing another user's profile.
/// Shows FIFA card, position, last matches, and achievements
/// only if users are mutual followers (friends).
class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  UserProfile? _targetUser;
  bool _isLoading = true;
  String? _followStatus; // null, 'pending', 'accepted'
  bool _isMutual = false;
  SportCategory _selectedSport = SportCategory.football;
  final SupabaseService _db = SupabaseService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      _targetUser = await _db.getUser(widget.userId);
      final myUid = context.read<AuthProvider>().uid;
      if (myUid != null && _targetUser != null) {
        _followStatus = await _db.getFollowStatus(myUid, widget.userId);
        _isMutual = await _db.areMutualFollowers(myUid, widget.userId);

        // Load stats for target user
        if (_isMutual) {
          await context.read<StatsProvider>().loadPlayerStatsFromDb(widget.userId);
        }
      }
    } catch (e) {
      debugPrint('PUBLIC_PROFILE: Error loading: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final myUid = context.read<AuthProvider>().uid;
    final isOwnProfile = myUid == widget.userId;

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        backgroundColor: t.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: t.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _targetUser?.name ?? 'Профиль',
          style: TextStyle(
            color: t.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _targetUser == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_off_rounded,
                          size: 48, color: t.textHint),
                      const SizedBox(height: 12),
                      Text('Пользователь не найден',
                          style: TextStyle(color: t.textHint)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildProfileHeader(t),
                      const SizedBox(height: 20),

                      // Follow button (only if not own profile)
                      if (!isOwnProfile) ...[
                        _buildFollowButton(t),
                        if (_isMutual)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DirectChatScreen(
                                    targetUserId: widget.userId,
                                    targetUserName: _targetUser?.name ?? '',
                                    targetUserAvatar: _targetUser?.avatarUrl,
                                  ),
                                ),
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.of(context).textHint.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.chat_bubble_outline_rounded,
                                        color: AppColors.of(context).textSecondary,
                                        size: 16),
                                    const SizedBox(width: 8),
                                    Text('Написать',
                                        style: TextStyle(
                                          color: AppColors.of(context).textSecondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          letterSpacing: 0.3,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],

                      // Content — visible only to mutual followers
                      if (_isMutual || isOwnProfile) ...[
                        // Sport selector
                        _buildSportSelector(t),
                        const SizedBox(height: 16),

                        // FIFA Card
                        _buildFifaCard(t),
                        const SizedBox(height: 16),

                        // Last Matches
                        _buildLastMatches(t),
                        const SizedBox(height: 16),

                        // Achievements
                        _buildAchievements(t),
                      ] else ...[
                        // Locked content message
                        _buildLockedContent(t),
                      ],

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader(dynamic t) {
    final user = _targetUser!;
    final sportPosName =
        user.getPositionForSport(_selectedSport.name);
    final posRecord = ProfileScreen.findPosition(sportPosName);
    final posColor = posRecord?.$4 ?? AppColors.primary;

    return Row(
      children: [
        // Avatar
        GestureDetector(
          onTap: () {
            if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
              openAvatarViewer(
                context,
                avatarUrl: user.avatarUrl!,
                heroTag: 'public_avatar_${user.id}',
                userName: user.name,
              );
            }
          },
          child: Hero(
            tag: 'public_avatar_${user.id}',
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: posColor.withValues(alpha: 0.1),
                border: Border.all(color: posColor.withValues(alpha: 0.3)),
              ),
              child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        user.avatarUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            user.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: posColor,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        user.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: posColor,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Name + position
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.of(context).textPrimary,
                  )),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (posRecord != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: posColor.withValues(alpha: 0.35),
                            width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(posRecord.$3, size: 11, color: posColor),
                          const SizedBox(width: 5),
                          Text(posRecord.$2,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: posColor,
                                letterSpacing: 0.5,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (user.isPublicProfile)
                    Icon(Icons.public_rounded,
                        size: 14,
                        color: AppColors.of(context).textHint)
                  else
                    Icon(Icons.lock_rounded,
                        size: 14,
                        color: AppColors.of(context).textHint),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton(dynamic t) {
    final friendsProv = context.read<FriendsProvider>();
    final myUid = context.read<AuthProvider>().uid!;

    String label;
    IconData icon;
    Color color;
    VoidCallback? onTap;

    if (_followStatus == 'accepted') {
      if (_isMutual) {
        label = 'Друзья ✓';
        icon = Icons.people_rounded;
        color = AppColors.success;
        onTap = () => _confirmUnfollow(friendsProv, myUid);
      } else {
        label = 'Вы подписаны';
        icon = Icons.check_rounded;
        color = AppColors.primary;
        onTap = () => _confirmUnfollow(friendsProv, myUid);
      }
    } else if (_followStatus == 'pending') {
      label = 'Запрос отправлен';
      icon = Icons.hourglass_top_rounded;
      color = AppColors.warning;
      onTap = () async {
        await friendsProv.unfollowUser(myUid, widget.userId);
        await _loadProfile();
      };
    } else {
      label = 'Подписаться';
      icon = Icons.person_add_rounded;
      color = AppColors.primary;
      onTap = () async {
        await friendsProv.followUser(myUid, widget.userId);
        await _loadProfile();
      };
    }

    final bool isActive = _followStatus == null; // subscribe CTA

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          // Subscribe → subtle gradient; else → ghost/outline
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.85),
                  ],
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? null
              : Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 1,
                ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isActive ? Colors.white : color,
                size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  color: isActive ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.3,
                )),
          ],
        ),
      ),
    );
  }

  void _confirmUnfollow(FriendsProvider prov, String myUid) {
    final t = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Отписаться?',
            style: TextStyle(color: t.textPrimary)),
        content: Text(
          'Вы уверены, что хотите отписаться от ${_targetUser?.name}?',
          style: TextStyle(color: t.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена', style: TextStyle(color: t.textHint)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await prov.unfollowUser(myUid, widget.userId);
              await _loadProfile();
            },
            child: const Text('Отписаться',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSportSelector(dynamic t) {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: SportCategory.values.map((sport) {
          final isSelected = _selectedSport == sport;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedSport = sport);
              if (_isMutual) {
                context
                    .read<StatsProvider>()
                    .loadPlayerStatsForSport(widget.userId, sport);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient:
                    isSelected ? AppColors.primaryGradient : null,
                color: isSelected
                    ? null
                    : AppColors.of(context).cardBg,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.of(context).borderLight,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(sport.icon,
                      size: 13,
                      color: isSelected
                          ? Colors.white
                          : AppColors.of(context).textHint),
                  const SizedBox(width: 5),
                  Text(sport.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : AppColors.of(context).textSecondary,
                      )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFifaCard(dynamic t) {
    final user = _targetUser!;
    final sportPosName =
        user.getPositionForSport(_selectedSport.name);
    final posRecord = ProfileScreen.findPosition(sportPosName);
    final posAbbr = posRecord?.$1 ?? '—';
    final posFull = posRecord?.$2 ?? 'Не указана';

    final statsProv = context.watch<StatsProvider>();
    final overall = statsProv.getPlayerStatsForSport(
        user.id, _selectedSport);

    return PlayerFifaCard(
      playerName: user.name,
      position: posAbbr,
      positionFull: posFull,
      stats: overall,
      sport: _selectedSport,
      isPremium: user.isPremium,
    );
  }

  Widget _buildLastMatches(dynamic t) {
    // Show last completed inner matches for this user
    final matchesProv = context.watch<MatchesProvider>();
    final completedEvents = matchesProv.completedEvents
        .where((e) => e.category == _selectedSport)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    int userTeamIdx = -1;
    int winsCount = 0;
    int lossCount = 0;
    int drawCount = 0;

    for (final event in completedEvents.take(10)) {
      userTeamIdx = -1;
      for (int ti = 0; ti < event.eventTeams.length; ti++) {
        if (event.eventTeams[ti].hasPlayer(widget.userId)) {
          userTeamIdx = ti;
          break;
        }
      }
      if (userTeamIdx < 0) continue;

      for (final im in event.innerMatches) {
        if (!im.isCompleted) continue;
        if (im.team1Index != userTeamIdx && im.team2Index != userTeamIdx) {
          continue;
        }
        final isTeam1 = im.team1Index == userTeamIdx;
        final myScore = isTeam1 ? im.team1Score : im.team2Score;
        final oppScore = isTeam1 ? im.team2Score : im.team1Score;
        if (myScore > oppScore) {
          winsCount++;
        } else if (myScore < oppScore) {
          lossCount++;
        } else {
          drawCount++;
        }
      }
    }

    final total = winsCount + lossCount + drawCount;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Icon(Icons.history_rounded,
                    size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Последние матчи',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.of(context).textPrimary,
                    )),
              ),
              if (total > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.of(context)
                        .surfaceBg
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: AppColors.of(context).borderLight),
                  ),
                  child: Text(
                    '$total игр',
                    style: TextStyle(
                      color: AppColors.of(context).textHint,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (total == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Column(
                  children: [
                    Icon(Icons.sports_score_rounded,
                        size: 40,
                        color: AppColors.of(context)
                            .textHint
                            .withValues(alpha: 0.2)),
                    const SizedBox(height: 8),
                    Text('Нет сыгранных матчей',
                        style: TextStyle(
                            color: AppColors.of(context).textHint,
                            fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _matchStatBadge('$winsCount', 'Победы',
                    const Color(0xFF00E676)),
                _matchStatBadge('$drawCount', 'Ничьи',
                    const Color(0xFFFFB300)),
                _matchStatBadge('$lossCount', 'Поражения',
                    const Color(0xFFFF5252)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _matchStatBadge(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
                fontFamily: 'monospace',
              )),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.of(context).textHint,
            )),
      ],
    );
  }

  Widget _buildAchievements(dynamic t) {
    final statsProv = context.watch<StatsProvider>();
    final achievements = statsProv.getAchievementsForSport(
        widget.userId, _selectedSport);
    final unlocked = achievements.where((a) => a.isUnlocked).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded,
                  size: 18, color: AppColors.of(context).textSecondary),
              const SizedBox(width: 8),
              Text('Достижения',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.of(context).textPrimary,
                  )),
              const Spacer(),
              Text('${unlocked.length}/${achievements.length}',
                  style: TextStyle(
                    color: AppColors.of(context).textHint,
                    fontSize: 12,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          if (unlocked.isEmpty)
            Center(
              child: Text('Нет разблокированных достижений',
                  style: TextStyle(
                      color: AppColors.of(context).textHint, fontSize: 13)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: unlocked.take(6).map((a) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(a.icon, size: 14, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Text(a.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildLockedContent(dynamic t) {
    final isPrivate = !(_targetUser?.isPublicProfile ?? true);
    return Container(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Icon(
            isPrivate ? Icons.lock_rounded : Icons.person_add_rounded,
            size: 56,
            color: AppColors.of(context).textHint.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _followStatus == 'pending'
                ? 'Запрос отправлен'
                : 'Подпишитесь, чтобы увидеть профиль',
            style: TextStyle(
              color: AppColors.of(context).textHint,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _isMutual
                ? ''
                : 'Карточка игрока, матчи и достижения доступны только для взаимных подписчиков',
            style: TextStyle(
              color: AppColors.of(context).textHint.withValues(alpha: 0.6),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
