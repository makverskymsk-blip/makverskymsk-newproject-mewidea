import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/match_event.dart';
import '../../models/sport_match.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/match_events_provider.dart';
import '../../providers/matches_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';

class MatchLiveScreen extends StatefulWidget {
  final SportMatch match;
  const MatchLiveScreen({super.key, required this.match});

  @override
  State<MatchLiveScreen> createState() => _MatchLiveScreenState();
}

class _MatchLiveScreenState extends State<MatchLiveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchEventsProvider>().loadEvents(widget.match.id);
    });
  }

  @override
  void dispose() {
    // Don't clear — let provider persist while navigating
    super.dispose();
  }

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  String get _currentUserName =>
      context.read<AuthProvider>().currentUser?.name ?? 'Игрок';

  bool get _isAdmin {
    final communityProv = context.read<CommunityProvider>();
    final active = communityProv.activeCommunity;
    if (active == null) return false;
    return active.isAdmin(_currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final eventsProv = context.watch<MatchEventsProvider>();
    final match = widget.match;

    return Scaffold(
      body: Stack(
        children: [
          Container(color: t.scaffoldBg),
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(t),
                // Score board
                _buildScoreBoard(t, match, eventsProv),
                // Action buttons
                _buildActionButtons(t, match),
                // Event feed
                Expanded(
                  child: _buildEventFeed(t, eventsProv),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppThemeColors t) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: t.borderLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚡ Live — ${widget.match.category.displayName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  widget.match.format,
                  style: TextStyle(color: t.textHint, fontSize: 12),
                ),
              ],
            ),
          ),
          // Live indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fiber_manual_record, color: AppColors.error, size: 10),
                SizedBox(width: 4),
                Text('LIVE', style: TextStyle(
                  color: AppColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard(AppThemeColors t, SportMatch match, MatchEventsProvider eventsProv) {
    // Show scores for each inner match
    if (match.innerMatches.isEmpty || match.eventTeams.length < 2) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: match.innerMatches.map<Widget>((im) {
          final t1 = match.eventTeams[im.team1Index];
          final t2 = match.eventTeams[im.team2Index];
          final scores = eventsProv.getScoreForInnerMatch(im.id);
          final s1 = scores[im.team1Index] ?? 0;
          final s2 = scores[im.team2Index] ?? 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Team 1
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: Color(t1.colorValue).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.shield_rounded,
                                  color: Color(t1.colorValue), size: 20),
                              ),
                              const SizedBox(height: 6),
                              Text(t1.name, style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              )),
                            ],
                          ),
                        ),
                        // Score
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: t.surfaceBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Text('$s1', style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              )),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(':', style: TextStyle(
                                  color: t.textHint,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w300,
                                )),
                              ),
                              Text('$s2', style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              )),
                            ],
                          ),
                        ),
                        // Team 2
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: Color(t2.colorValue).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.shield_rounded,
                                  color: Color(t2.colorValue), size: 20),
                              ),
                              const SizedBox(height: 6),
                              Text(t2.name, style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Complete match button
                    if (!im.isCompleted && _isAdmin)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: GestureDetector(
                          onTap: () => _confirmCompleteMatch(im, s1, s2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline_rounded,
                                  color: AppColors.accent, size: 16),
                                SizedBox(width: 6),
                                Text('Завершить матч', style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (im.isCompleted)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('✅ Матч завершён', style: TextStyle(
                          color: t.textHint, fontSize: 11)),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons(AppThemeColors t, SportMatch match) {
    final actions = [
      _EventAction(MatchEventType.goal, AppColors.success, Icons.sports_soccer_rounded),
      _EventAction(MatchEventType.assist, AppColors.primary, Icons.handshake_rounded),
      _EventAction(MatchEventType.save, AppColors.accent, Icons.sports_handball_rounded),
      _EventAction(MatchEventType.foul, AppColors.warning, Icons.warning_amber_rounded),
      _EventAction(MatchEventType.ownGoal, AppColors.error, Icons.gpp_bad_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions.map((a) => _actionChip(t, a, match)).toList(),
      ),
    );
  }

  Widget _actionChip(AppThemeColors t, _EventAction action, SportMatch match) {
    return GestureDetector(
      onTap: () => _showPlayerPicker(action.type, match),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: action.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, color: action.color, size: 18),
            const SizedBox(width: 6),
            Text(action.type.label, style: TextStyle(
              color: action.color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            )),
          ],
        ),
      ),
    );
  }

  void _showPlayerPicker(MatchEventType eventType, SportMatch match) {
    // First pick inner match (round), then player
    if (match.innerMatches.length == 1) {
      _showPlayerList(eventType, match, match.innerMatches.first);
    } else if (match.innerMatches.isNotEmpty) {
      _showInnerMatchPicker(eventType, match);
    }
  }

  void _showInnerMatchPicker(MatchEventType eventType, SportMatch match) {
    final t = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: t.dialogBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Text('Выберите раунд', style: TextStyle(
              color: t.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 12),
            ...match.innerMatches.map((im) {
              final t1 = match.eventTeams[im.team1Index].name;
              final t2 = match.eventTeams[im.team2Index].name;
              return ListTile(
                title: Text('$t1 vs $t2', style: TextStyle(color: t.textPrimary)),
                subtitle: im.isCompleted
                    ? Text('Завершён', style: TextStyle(color: t.textHint, fontSize: 12))
                    : Text('В процессе', style: TextStyle(color: AppColors.success, fontSize: 12)),
                leading: Icon(Icons.sports, color: t.textSecondary),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPlayerList(eventType, match, im);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPlayerList(MatchEventType eventType, SportMatch match, InnerMatch innerMatch) {
    final t = AppColors.of(context);
    // Get players from both teams in this inner match
    final team1 = match.eventTeams[innerMatch.team1Index];
    final team2 = match.eventTeams[innerMatch.team2Index];

    showModalBottomSheet(
      context: context,
      backgroundColor: t.dialogBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
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
              Text('${eventType.emoji} ${eventType.label} — кому?', style: TextStyle(
                color: t.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              )),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  children: [
                    _teamSection(t, team1, innerMatch, eventType, ctx),
                    const SizedBox(height: 12),
                    _teamSection(t, team2, innerMatch, eventType, ctx),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamSection(AppThemeColors t, EventTeam team, InnerMatch innerMatch,
      MatchEventType eventType, BuildContext ctx) {
    final match = widget.match;
    final teamIdx = match.eventTeams.indexOf(team);
    // For own goals, record under the OPPONENT's team so score goes to them
    final opponentIdx = innerMatch.team1Index == teamIdx
        ? innerMatch.team2Index
        : innerMatch.team1Index;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                color: Color(team.colorValue),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(team.name, style: TextStyle(
              color: t.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            )),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(team.playerIds.length, (i) {
          final pid = team.playerIds[i];
          final pname = i < team.playerNames.length ? team.playerNames[i] : 'Игрок';
          return ListTile(
            dense: true,
            title: Text(pname, style: TextStyle(color: t.textPrimary)),
            leading: CircleAvatar(
              backgroundColor: Color(team.colorValue).withValues(alpha: 0.2),
              child: Text(pname.isNotEmpty ? pname[0] : '?',
                style: TextStyle(color: Color(team.colorValue), fontWeight: FontWeight.w700)),
            ),
            onTap: () {
              Navigator.pop(ctx);
              _recordEvent(
                eventType: eventType,
                playerId: pid,
                playerName: pname,
                // For own goals, credit goes to opponent team
                teamIndex: eventType == MatchEventType.ownGoal ? opponentIdx : teamIdx,
                innerMatchId: innerMatch.id,
              );
            },
          );
        }),
      ],
    );
  }

  Future<void> _recordEvent({
    required MatchEventType eventType,
    required String playerId,
    required String playerName,
    required int teamIndex,
    required String innerMatchId,
  }) async {
    final communityProv = context.read<CommunityProvider>();
    final communityId = communityProv.activeCommunity?.id ?? '';

    final event = MatchEvent(
      id: '', // DB generates
      matchId: widget.match.id,
      communityId: communityId,
      playerId: playerId,
      playerName: playerName,
      recordedBy: _currentUserId,
      recordedByName: _currentUserName,
      eventType: eventType,
      teamIndex: teamIndex,
      innerMatchId: innerMatchId,
    );

    try {
      await context.read<MatchEventsProvider>().addEvent(event);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${eventType.emoji} ${eventType.label}: $playerName'),
          backgroundColor: AppColors.success,
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
  }

  Widget _buildEventFeed(AppThemeColors t, MatchEventsProvider eventsProv) {
    final events = eventsProv.events.reversed.toList(); // newest first

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_soccer_outlined, size: 60, color: t.borderLight),
            const SizedBox(height: 12),
            Text('Событий пока нет', style: TextStyle(
              color: t.textHint, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Нажмите на кнопку выше, чтобы записать', style: TextStyle(
              color: t.textHint, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: events.length,
      itemBuilder: (ctx, i) => _eventTile(t, events[i]),
    );
  }

  Widget _eventTile(AppThemeColors t, MatchEvent event) {
    final canDelete = event.recordedBy == _currentUserId || _isAdmin;
    final color = _colorForType(event.eventType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(event.eventType.emoji, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: event.playerName,
                        style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: ' — ${event.eventType.label}',
                        style: TextStyle(
                          color: t.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'записал: ${event.recordedByName}',
                  style: TextStyle(color: t.textHint, fontSize: 11),
                ),
              ],
            ),
          ),
          if (canDelete)
            GestureDetector(
              onTap: () => _confirmDelete(event),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.delete_outline_rounded,
                  color: AppColors.error.withValues(alpha: 0.5), size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Color _colorForType(MatchEventType type) {
    switch (type) {
      case MatchEventType.goal: return AppColors.success;
      case MatchEventType.assist: return AppColors.primary;
      case MatchEventType.save: return AppColors.accent;
      case MatchEventType.foul: return AppColors.warning;
      case MatchEventType.ownGoal: return AppColors.error;
    }
  }

  void _confirmDelete(MatchEvent event) {
    final t = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: t.borderLight),
        ),
        title: const Text('Удалить событие?'),
        content: Text(
          '${event.eventType.emoji} ${event.eventType.label}: ${event.playerName}',
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
              try {
                await context.read<MatchEventsProvider>().deleteEvent(event.id);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Ошибка: $e'),
                    backgroundColor: AppColors.error,
                  ));
                }
              }
            },
            child: const Text('Удалить', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmCompleteMatch(InnerMatch im, int s1, int s2) {
    final t = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: t.borderLight),
        ),
        title: const Text('Завершить матч?'),
        content: Text(
          'Счёт будет зафиксирован: $s1 : $s2',
          style: TextStyle(color: t.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена', style: TextStyle(color: t.textHint)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final matchesProv = context.read<MatchesProvider>();
              // Save live score into inner match
              matchesProv.updateInnerMatchScore(
                widget.match.id, im.id, s1, s2);
              // Mark as completed
              matchesProv.completeInnerMatch(
                widget.match.id, im.id);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('✅ Матч завершён'),
                backgroundColor: AppColors.accent,
                duration: Duration(seconds: 1),
              ));
            },
            child: const Text('Завершить',
              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _EventAction {
  final MatchEventType type;
  final Color color;
  final IconData icon;
  const _EventAction(this.type, this.color, this.icon);
}
