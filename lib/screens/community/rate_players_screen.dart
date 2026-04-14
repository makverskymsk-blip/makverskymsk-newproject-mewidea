import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../models/sport_match.dart';
import '../../providers/matches_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/match_events_provider.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Экран оценки игроков после завершения события.
/// Капитан / админ выставляет оценки каждому участнику.
class RatePlayersScreen extends StatefulWidget {
  final SportMatch match;
  final String? teamId; // Если указан — оцениваем только эту команду

  const RatePlayersScreen({super.key, required this.match, this.teamId});

  @override
  State<RatePlayersScreen> createState() => _RatePlayersScreenState();
}

class _RatePlayersScreenState extends State<RatePlayersScreen> {
  final SupabaseService _db = SupabaseService();
  bool _saving = false;
  String? _mvpPlayerId;

  // Per-player data: playerId -> _PlayerRating
  final Map<String, _PlayerRating> _ratings = {};

  SportCategory get _sport => widget.match.category;

  @override
  void initState() {
    super.initState();
    _initRatings();
    _loadPlayerPositions();
    _loadLiveEventStats();
  }

  /// Pre-fill stats from live match events
  Future<void> _loadLiveEventStats() async {
    final eventsProv = context.read<MatchEventsProvider>();
    await eventsProv.loadEvents(widget.match.id);
    if (!mounted) return;
    for (final pid in _ratings.keys) {
      final stats = eventsProv.getPlayerEventStats(pid);
      setState(() {
        _ratings[pid]!.goals = stats['goals'] ?? 0;
        _ratings[pid]!.assists = stats['assists'] ?? 0;
        _ratings[pid]!.saves = stats['saves'] ?? 0;
      });
    }
  }

  /// Load positions from DB for all players
  Future<void> _loadPlayerPositions() async {
    final supabase = Supabase.instance.client;
    for (final pid in _ratings.keys) {
      try {
        final data = await supabase
            .from('users')
            .select('position')
            .eq('id', pid)
            .maybeSingle();
        if (data != null && data['position'] != null && mounted) {
          setState(() {
            _ratings[pid]!.position = data['position'] as String;
          });
        }
      } catch (_) {}
    }
  }

  void _initRatings() {
    final match = widget.match;
    // Determine win/draw/loss for each player based on standings
    final standings = match.getStandings();
    final topPoints = standings.isNotEmpty ? standings.first.points : 0;
    // Multiple teams could tie for first
    final winnerIndices = standings
        .where((s) => s.points == topPoints)
        .map((s) => s.teamIndex)
        .toSet();
    // It's a draw if there are no inner matches (topPoints==0) or multiple teams tied
    final isDraw = winnerIndices.length != 1;
    final winnerTeamIndex = (!isDraw && winnerIndices.isNotEmpty)
        ? winnerIndices.first
        : -1;

    // If teamId is specified, only rate that team's players
    final EventTeam? targetTeam = widget.teamId != null
        ? match.eventTeams.where((t) => t.id == widget.teamId).firstOrNull
        : null;

    final playerIds = targetTeam != null
        ? targetTeam.playerIds
        : match.registeredPlayerIds;
    final playerNames = targetTeam != null
        ? targetTeam.playerNames
        : match.registeredPlayerNames;

    for (int i = 0; i < playerIds.length; i++) {
      final pid = playerIds[i];
      final pname = i < playerNames.length
          ? playerNames[i]
          : 'Игрок';

      // Find which team this player is on
      int playerTeamIndex = -1;
      for (int t = 0; t < match.eventTeams.length; t++) {
        if (match.eventTeams[t].hasPlayer(pid)) {
          playerTeamIndex = t;
          break;
        }
      }

      bool isWin = false;
      bool isDrawResult = false;
      if (playerTeamIndex >= 0) {
        if (isDraw) {
          // Draw for all teams when tied or no matches played
          isDrawResult = true;
        } else if (playerTeamIndex == winnerTeamIndex) {
          isWin = true;
        }
        // else: loss (isWin=false, isDrawResult=false)
      }

      _ratings[pid] = _PlayerRating(
        name: pname,
        isWin: isWin,
        isDraw: isDrawResult,
      );
    }
  }

  // ============ SPORT-SPECIFIC LABELS ============

  _SportConfig get _config => _SportConfig.forSport(_sport);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.borderLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Оценка игроков',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(
                            widget.teamId != null
                                ? 'Оцените игроков команды'
                                : 'Выставьте оценки каждому участнику',
                            style: TextStyle(
                                color: AppColors.of(context).textHint, fontSize: 12)),
                      ],
                    ),
                  ),
                  // Sport badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_sport.icon, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(_sport.displayName,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Player list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _ratings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = _ratings.entries.elementAt(index);
                  return _buildPlayerCard(entry.key, entry.value);
                },
              ),
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveAndComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              widget.teamId != null
                                  ? 'Сохранить оценки команды'
                                  : 'Сохранить и завершить',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(String playerId, _PlayerRating rating) {
    final resultColor = rating.isWin
        ? const Color(0xFF43A047)
        : (rating.isDraw ? const Color(0xFF9E9E9E) : const Color(0xFFE53935));
    final resultLabel = rating.isWin
        ? 'Победа'
        : (rating.isDraw ? 'Ничья' : 'Поражение');
    final isMvp = _mvpPlayerId == playerId;
    final cfg = _config;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMvp
              ? const Color(0xFFFF6D00).withValues(alpha: 0.4)
              : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.of(context).shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + result + MVP
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: resultColor.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    rating.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: resultColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rating.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(resultLabel,
                        style: TextStyle(
                            color: resultColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              // MVP toggle
              GestureDetector(
                onTap: () {
                  setState(() {
                    _mvpPlayerId = isMvp ? null : playerId;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isMvp
                        ? const Color(0xFFFF6D00).withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isMvp
                          ? const Color(0xFFFF6D00).withValues(alpha: 0.4)
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 16,
                        color: isMvp
                            ? const Color(0xFFFF6D00)
                            : AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'MVP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isMvp
                              ? const Color(0xFFFF6D00)
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Live event stats from match (pre-recorded)
          if (rating.goals > 0 || rating.assists > 0 || rating.saves > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.fiber_manual_record, size: 8, color: AppColors.error),
                  const SizedBox(width: 4),
                  Text('Live:', style: TextStyle(
                    color: AppColors.of(context).textHint,
                    fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  if (rating.goals > 0)
                    _liveStatBadge(cfg.goalEmoji, rating.goals),
                  if (rating.assists > 0)
                    _liveStatBadge(cfg.assistEmoji, rating.assists),
                  if (rating.saves > 0)
                    _liveStatBadge(cfg.saveEmoji, rating.saves),
                ],
              ),
            ),

          // Counters: sport-specific
          _buildCounters(rating, cfg),

          const SizedBox(height: 14),

          // Sliders: sport-specific
          _sliderRow(cfg.slider1Label, rating.attackRating, cfg.slider1Color,
              (v) => setState(() => rating.attackRating = v)),
          _sliderRow(cfg.slider2Label, rating.defenseRating, cfg.slider2Color,
              (v) => setState(() => rating.defenseRating = v)),
          _sliderRow(cfg.slider3Label, rating.speedRating, cfg.slider3Color,
              (v) => setState(() => rating.speedRating = v)),

          const SizedBox(height: 6),

          // Overall
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Итого: ',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(
                rating.overallRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: rating.overallRating >= 8.0
                      ? const Color(0xFFE6A817)
                      : (rating.overallRating >= 6.0
                          ? AppColors.of(context).textPrimary
                          : const Color(0xFFE53935)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Badge for live event stat display
  Widget _liveStatBadge(String emoji, int count) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text('$emoji $count', style: const TextStyle(fontSize: 12)),
    );
  }

  /// Sport-specific counters
  Widget _buildCounters(_PlayerRating rating, _SportConfig cfg) {
    return Row(
      children: [
        _counterWidget(cfg.goalEmoji, cfg.goalLabel, rating.goals,
            (v) => setState(() => rating.goals = v)),
        const SizedBox(width: 12),
        _counterWidget(cfg.assistEmoji, cfg.assistLabel, rating.assists,
            (v) => setState(() => rating.assists = v)),
        if (cfg.showSaves) ...[
          const SizedBox(width: 12),
          _counterWidget(cfg.saveEmoji, cfg.saveLabel, rating.saves,
              (v) => setState(() => rating.saves = v)),
        ],
      ],
    );
  }

  Widget _counterWidget(
      String emoji, String label, int value, ValueChanged<int> onChanged) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                if (value > 0) onChanged(value - 1);
              },
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value > 0
                      ? AppColors.borderLight
                      : AppColors.borderLight.withValues(alpha: 0.3),
                ),
                child: const Icon(Icons.remove, size: 14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  Text(
                    value.toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 8, color: AppColors.textHint)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => onChanged(value + 1),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
                child: Icon(Icons.add, size: 14, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sliderRow(
      String label, double value, Color color, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: color,
                inactiveTrackColor: color.withValues(alpha: 0.15),
                thumbColor: color,
                overlayColor: color.withValues(alpha: 0.1),
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: value,
                min: 1,
                max: 10,
                divisions: 18,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, color: color),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndComplete() async {
    setState(() => _saving = true);

    try {
      final match = widget.match;
      final communityId = match.communityId ?? '';
      final sportStr = _sport.name;
      final statsList = <Map<String, dynamic>>[];

      for (final entry in _ratings.entries) {
        final pid = entry.key;
        final r = entry.value;

        statsList.add({
          'community_id': communityId,
          'match_id': match.id,
          'user_id': pid,
          'user_name': r.name,
          'goals': r.goals,
          'assists': r.assists,
          'saves': r.saves,
          'attack_rating': r.attackRating,
          'defense_rating': r.defenseRating,
          'speed_rating': r.speedRating,
          'overall_rating': r.overallRating,
          'is_win': r.isWin,
          'is_draw': r.isDraw,
          'is_mvp': _mvpPlayerId == pid,
          'sport_category': sportStr,
        });
      }

      // Save to Supabase
      await _db.saveMatchPlayerStats(statsList);

      if (mounted) {
        final matchesProv = context.read<MatchesProvider>();

        if (widget.teamId != null) {
          // Per-team mode: mark team as rated (auto-completes if all teams done)
          matchesProv.markTeamRated(match.id, widget.teamId!);

          // Refresh stats for rated players
          final statsProv = context.read<StatsProvider>();
          for (final pid in _ratings.keys) {
            await statsProv.loadPlayerStatsFromDb(pid);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Оценки команды сохранены!'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          // Old flow: complete entire event
          matchesProv.completeEvent(match.id);

          // Refresh stats for all players
          final statsProv = context.read<StatsProvider>();
          for (final pid in _ratings.keys) {
            await statsProv.loadPlayerStatsFromDb(pid);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Статистика сохранена! Событие завершено.'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PlayerRating {
  final String name;
  final bool isWin;
  final bool isDraw;
  String position = ''; // loaded from DB
  int goals = 0;
  int assists = 0;
  int saves = 0;
  double attackRating = 6.0;
  double defenseRating = 6.0;
  double speedRating = 6.0;

  _PlayerRating({
    required this.name,
    this.isWin = false,
    this.isDraw = false,
  });

  double get overallRating =>
      (attackRating + defenseRating + speedRating) / 3;
}

/// Sport-specific labels/emojis for rate screen
class _SportConfig {
  final String goalLabel;
  final String goalEmoji;
  final String assistLabel;
  final String assistEmoji;
  final String saveLabel;
  final String saveEmoji;
  final bool showSaves;

  final String slider1Label;
  final Color slider1Color;
  final String slider2Label;
  final Color slider2Color;
  final String slider3Label;
  final Color slider3Color;

  const _SportConfig({
    required this.goalLabel,
    required this.goalEmoji,
    required this.assistLabel,
    required this.assistEmoji,
    this.saveLabel = 'Сейвы',
    this.saveEmoji = '🧤',
    this.showSaves = true,
    required this.slider1Label,
    required this.slider1Color,
    required this.slider2Label,
    required this.slider2Color,
    required this.slider3Label,
    required this.slider3Color,
  });

  static _SportConfig forSport(SportCategory sport) {
    switch (sport) {
      case SportCategory.football:
        return const _SportConfig(
          goalLabel: 'Голы', goalEmoji: '⚽',
          assistLabel: 'Ассисты', assistEmoji: '🅰️',
          saveLabel: 'Сейвы', saveEmoji: '🧤',
          slider1Label: 'Атака', slider1Color: Color(0xFFE53935),
          slider2Label: 'Защита', slider2Color: Color(0xFF1E88E5),
          slider3Label: 'Скорость', slider3Color: Color(0xFF43A047),
        );
      case SportCategory.hockey:
        return const _SportConfig(
          goalLabel: 'Шайбы', goalEmoji: '🏒',
          assistLabel: 'Передачи', assistEmoji: '🅰️',
          saveLabel: 'Блоки', saveEmoji: '🛡️',
          slider1Label: 'Бросок', slider1Color: Color(0xFFE53935),
          slider2Label: 'Защита', slider2Color: Color(0xFF1E88E5),
          slider3Label: 'Катание', slider3Color: Color(0xFF43A047),
        );
      case SportCategory.tennis:
      case SportCategory.padel:
        return const _SportConfig(
          goalLabel: 'Эйсы', goalEmoji: '🎾',
          assistLabel: 'Виннеры', assistEmoji: '💥',
          showSaves: false,
          slider1Label: 'Подача', slider1Color: Color(0xFFE53935),
          slider2Label: 'Приём', slider2Color: Color(0xFF1E88E5),
          slider3Label: 'Выносл.', slider3Color: Color(0xFF43A047),
        );
      case SportCategory.esports:
        return const _SportConfig(
          goalLabel: 'Киллы', goalEmoji: '🎯',
          assistLabel: 'Ассисты', assistEmoji: '🤝',
          saveLabel: 'Клатчи', saveEmoji: '👑',
          slider1Label: 'Аим', slider1Color: Color(0xFFE53935),
          slider2Label: 'IGL', slider2Color: Color(0xFF1E88E5),
          slider3Label: 'Утилити', slider3Color: Color(0xFF43A047),
        );
    }
  }
}
