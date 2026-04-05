import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sport_match.dart';
import '../../providers/matches_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import 'rate_players_screen.dart';

class EventManageScreen extends StatefulWidget {
  final String matchId;
  const EventManageScreen({super.key, required this.matchId});

  @override
  State<EventManageScreen> createState() => _EventManageScreenState();
}

class _EventManageScreenState extends State<EventManageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchesProv = context.watch<MatchesProvider>();
    final match = matchesProv.getById(widget.matchId);

    if (match == null) {
      return const Scaffold(
        body: Center(child: Text('Событие не найдено')),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(color: AppColors.of(context).scaffoldBg),
          SafeArea(
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${match.category.displayName} • ${match.format}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${match.location} • ${match.registeredPlayerIds.length} уч.',
                              style: TextStyle(
                                  color: AppColors.of(context).textHint,
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (!match.isCompleted)
                        GestureDetector(
                          onTap: () => _completeEvent(matchesProv),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'Завершить',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Tab bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).cardBg.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabCtrl,
                    indicator: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.of(context).textSecondary,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: [
                      Tab(
                          text:
                              'Игроки (${match.registeredPlayerIds.length})'),
                      Tab(
                          text:
                              'Команды (${match.eventTeams.length})'),
                      Tab(
                          text:
                              'Матчи (${match.innerMatches.length})'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _playersTab(match, matchesProv),
                      _teamsTab(match, matchesProv),
                      _matchesTab(match, matchesProv),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======================== TAB 1: PLAYERS ========================

  Widget _playersTab(SportMatch match, MatchesProvider prov) {
    final unassigned = match.unassignedPlayers;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (unassigned.isNotEmpty) ...[
          _sectionTitle(
              'Нераспределённые', Icons.person_outline_rounded,
              count: unassigned.length),
          const SizedBox(height: 10),
          ...unassigned.map((p) => _playerTile(
                p.value,
                p.key,
                teamColor: null,
                teamName: null,
              )),
          const SizedBox(height: 20),
        ],

        for (final team in match.eventTeams) ...[
          _sectionTitle(
            team.name,
            Icons.groups_rounded,
            count: team.playerCount,
            color: Color(team.colorValue),
          ),
          const SizedBox(height: 10),
          if (team.playerIds.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: Text('Нет игроков',
                    style: TextStyle(
                        color: Color(team.colorValue).withValues(alpha: 0.5),
                        fontSize: 12)),
              ),
            )
          else
            ...team.playerIds.asMap().entries.map((e) {
              final name = e.key < team.playerNames.length
                  ? team.playerNames[e.key]
                  : 'Игрок';
              return _playerTile(
                name,
                e.value,
                teamColor: Color(team.colorValue),
                teamName: team.name,
              );
            }),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _playerTile(String name, String id,
      {Color? teamColor, String? teamName}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderRadius: 12,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (teamColor ?? AppColors.textHint)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person_rounded,
                  size: 16,
                  color: teamColor ?? AppColors.textHint),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  if (teamName != null)
                    Text(teamName,
                        style: TextStyle(
                            color: teamColor ?? AppColors.textHint,
                            fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================== TAB 2: TEAMS ========================

  Widget _teamsTab(SportMatch match, MatchesProvider prov) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Action buttons row
        Row(
          children: [
            if (match.eventTeams.length < 5)
              Expanded(
                child: _actionButton(
                  'Добавить команду',
                  Icons.group_add_rounded,
                  AppColors.primary,
                  () => prov.addEventTeam(widget.matchId),
                ),
              ),
            if (match.eventTeams.length < 5 &&
                match.registeredPlayerIds.isNotEmpty)
              const SizedBox(width: 10),
            if (match.eventTeams.isNotEmpty &&
                match.registeredPlayerIds.isNotEmpty)
              Expanded(
                child: _actionButton(
                  'Авто-разделение',
                  Icons.shuffle_rounded,
                  AppColors.accent,
                  () => prov.autoDistributePlayers(widget.matchId),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Team cards
        if (match.eventTeams.isEmpty)
          _emptyState(
              Icons.groups_outlined,
              'Нет команд',
              'Добавьте команды и распределите игроков')
        else
          ...match.eventTeams.asMap().entries.map((e) =>
              _teamCard(match, e.value, e.key, prov)),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _teamCard(
      SportMatch match, EventTeam team, int index, MatchesProvider prov) {
    final color = Color(team.colorValue);
    final unassigned = match.unassignedPlayers;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: color,
                        ),
                      ),
                      Text(
                        '${team.playerCount} игроков',
                        style: const TextStyle(
                            color: AppColors.textHint, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Add player
                if (unassigned.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showAddPlayerDialog(
                        match, team, prov),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.person_add_rounded,
                          color: color, size: 16),
                    ),
                  ),
                const SizedBox(width: 6),
                // Delete team
                GestureDetector(
                  onTap: () =>
                      prov.removeEventTeam(widget.matchId, team.id),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error, size: 16),
                  ),
                ),
              ],
            ),
            if (team.playerIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: team.playerIds.asMap().entries.map((e) {
                  final name = e.key < team.playerNames.length
                      ? team.playerNames[e.key]
                      : 'Игрок';
                  return GestureDetector(
                    onTap: () => prov.removePlayerFromTeam(
                        widget.matchId, team.id, e.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: color.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.close_rounded,
                              size: 12, color: color.withValues(alpha: 0.6)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddPlayerDialog(
      SportMatch match, EventTeam team, MatchesProvider prov) {
    final unassigned = match.unassignedPlayers;
    final color = Color(team.colorValue);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard.withValues(alpha: 0.95),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Добавить в «${team.name}»',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: unassigned.map((p) {
                    return GestureDetector(
                      onTap: () {
                        prov.assignPlayerToTeam(
                            widget.matchId, team.id, p.key, p.value);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: color.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person_add_rounded,
                                color: color, size: 18),
                            const SizedBox(width: 10),
                            Text(p.value,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
    );
  }

  // ======================== TAB 3: MATCHES ========================

  Widget _matchesTab(SportMatch match, MatchesProvider prov) {
    final standings = match.getStandings();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Add match button
        if (match.eventTeams.length >= 2 && !match.isCompleted)
          _actionButton(
            'Добавить матч',
            Icons.add_circle_outline_rounded,
            AppColors.primary,
            () => _showAddMatchDialog(match, prov),
          ),
        const SizedBox(height: 16),

        // Standings table
        if (standings.isNotEmpty && match.innerMatches.any((m) => m.isCompleted)) ...[
          _sectionTitle('Таблица', Icons.leaderboard_rounded),
          const SizedBox(height: 10),
          _standingsTable(standings),
          const SizedBox(height: 24),
        ],

        // Match list
        if (match.innerMatches.isEmpty)
          _emptyState(Icons.sports_score_outlined, 'Нет матчей',
              'Создайте команды и добавьте матчи')
        else ...[
          _sectionTitle('Матчи', Icons.sports_rounded,
              count: match.innerMatches.length),
          const SizedBox(height: 10),
          ...match.innerMatches.asMap().entries.map((e) {
            final im = e.value;
            final t1 = im.team1Index < match.eventTeams.length
                ? match.eventTeams[im.team1Index]
                : null;
            final t2 = im.team2Index < match.eventTeams.length
                ? match.eventTeams[im.team2Index]
                : null;
            if (t1 == null || t2 == null) return const SizedBox();
            return _innerMatchTile(
                im, t1, t2, e.key + 1, match, prov);
          }),
        ],

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _innerMatchTile(InnerMatch im, EventTeam t1, EventTeam t2,
      int number, SportMatch match, MatchesProvider prov) {
    final c1 = Color(t1.colorValue);
    final c2 = Color(t2.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 16,
        child: Column(
          children: [
            // Match number + status
            Row(
              children: [
                Text('Матч #$number',
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 10)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: im.isCompleted
                        ? AppColors.accent.withValues(alpha: 0.12)
                        : AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    im.isCompleted ? 'Завершён' : 'В процессе',
                    style: TextStyle(
                      color: im.isCompleted
                          ? AppColors.accent
                          : AppColors.warning,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!im.isCompleted && !match.isCompleted) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => prov.removeInnerMatch(
                        widget.matchId, im.id),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.error),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Score row
            Row(
              children: [
                // Team 1
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: c1, shape: BoxShape.circle),
                      ),
                      const SizedBox(height: 4),
                      Text(t1.name,
                          style: TextStyle(
                              color: c1,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ],
                  ),
                ),

                // Score
                GestureDetector(
                  onTap: match.isCompleted
                      ? null
                      : () => _showScoreDialog(
                            im, t1, t2, prov),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.borderLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              AppColors.borderLight),
                    ),
                    child: Text(
                      '${im.team1Score} : ${im.team2Score}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),

                // Team 2
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: c2, shape: BoxShape.circle),
                      ),
                      const SizedBox(height: 4),
                      Text(t2.name,
                          style: TextStyle(
                              color: c2,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showScoreDialog(
      InnerMatch im, EventTeam t1, EventTeam t2, MatchesProvider prov) {
    int s1 = im.team1Score;
    int s2 = im.team2Score;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx2, setDialogState) => AlertDialog(
            backgroundColor: AppColors.of(context).dialogBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                  color: AppColors.borderLight),
            ),
            title: const Text('Счёт матча',
                textAlign: TextAlign.center),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Team 1 score
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Color(t1.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(t1.name,
                        style: TextStyle(
                            color: Color(t1.colorValue),
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    _scoreCounter(
                      s1,
                      Color(t1.colorValue),
                      (v) => setDialogState(() => s1 = v),
                    ),
                  ],
                ),
                const Text(':',
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800)),
                // Team 2 score
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Color(t2.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(t2.name,
                        style: TextStyle(
                            color: Color(t2.colorValue),
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    _scoreCounter(
                      s2,
                      Color(t2.colorValue),
                      (v) => setDialogState(() => s2 = v),
                    ),
                  ],
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () {
                  prov.updateInnerMatchScore(
                      widget.matchId, im.id, s1, s2);
                  Navigator.pop(ctx);
                },
                child: const Text('Сохранить'),
              ),
              TextButton(
                onPressed: () {
                  prov.updateInnerMatchScore(
                      widget.matchId, im.id, s1, s2);
                  prov.completeInnerMatch(widget.matchId, im.id);
                  Navigator.pop(ctx);
                },
                child: const Text('Завершить',
                    style: TextStyle(color: AppColors.accent)),
              ),
            ],
          ),
      ),
    );
  }

  Widget _scoreCounter(int value, Color color, ValueChanged<int> onChanged) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => onChanged(value + 1),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.add_rounded, color: color, size: 20),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            if (value > 0) onChanged(value - 1);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.remove_rounded, color: color, size: 20),
          ),
        ),
      ],
    );
  }

  void _showAddMatchDialog(SportMatch match, MatchesProvider prov) {
    int? t1;
    int? t2;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx2, setDialogState) => AlertDialog(
            backgroundColor: AppColors.of(context).dialogBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                  color: AppColors.borderLight),
            ),
            title: const Text('Новый матч'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Выберите две команды',
                    style: TextStyle(
                        color: AppColors.textHint, fontSize: 13)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      match.eventTeams.asMap().entries.map((e) {
                    final team = e.value;
                    final idx = e.key;
                    final isSelected = t1 == idx || t2 == idx;
                    final color = Color(team.colorValue);

                    return GestureDetector(
                      onTap: () => setDialogState(() {
                        if (t1 == idx) {
                          t1 = null;
                        } else if (t2 == idx) {
                          t2 = null;
                        } else if (t1 == null) {
                          t1 = idx;
                        } else {
                          t2 ??= idx;
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.2)
                              : AppColors.borderLight.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : Colors.white
                                    .withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(team.name,
                                style: TextStyle(
                                    color: isSelected
                                        ? color
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: t1 != null && t2 != null
                    ? () {
                        prov.addInnerMatch(
                            widget.matchId, t1!, t2!);
                        Navigator.pop(ctx);
                      }
                    : null,
                child: const Text('Создать',
                    style: TextStyle(color: AppColors.accent)),
              ),
            ],
          ),
      ),
    );
  }

  // ======================== STANDINGS TABLE ========================

  Widget _standingsTable(List<TeamStanding> standings) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const SizedBox(width: 30),
              const Expanded(
                  child: Text('Команда',
                      style: TextStyle(
                          color: AppColors.textHint, fontSize: 10))),
              ...['И', 'В', 'Н', 'П', 'ГЗ', 'ГП', 'О'].map(
                (h) => SizedBox(
                  width: 28,
                  child: Text(h,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          Divider(
              color: AppColors.borderLight.withValues(alpha: 0.5),
              height: 16),

          // Rows
          ...standings.asMap().entries.map((e) {
            final s = e.value;
            final color = Color(s.colorValue);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${e.key + 1}',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(s.teamName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  ...[
                    s.played,
                    s.wins,
                    s.draws,
                    s.losses,
                    s.goalsFor,
                    s.goalsAgainst,
                    s.points
                  ].asMap().entries.map(
                        (v) => SizedBox(
                          width: 28,
                          child: Text(
                            '${v.value}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: v.key == 6
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: v.key == 6
                                  ? AppColors.accent
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ======================== COMPLETE EVENT ========================

  void _completeEvent(MatchesProvider prov) {
    final match = prov.getById(widget.matchId);
    if (match == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.of(context).dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
                color: AppColors.borderLight),
          ),
          title: const Text('Завершить событие?'),
          content: const Text(
              'Вы сможете оценить каждого игрока перед завершением. Продолжить?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // close dialog
                // Navigate to Rate Players screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RatePlayersScreen(match: match),
                  ),
                ).then((_) {
                  // After rating, go back if event was completed
                  if (match.isCompleted && mounted) {
                    Navigator.pop(context);
                  }
                });
              },
              child: const Text('Завершить',
                  style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
    );
  }

  // ======================== HELPERS ========================

  Widget _sectionTitle(String title, IconData icon,
      {int? count, Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppColors.primaryLight),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: color)),
        if (count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (color ?? AppColors.primaryLight)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$count',
                style: TextStyle(
                    color: color ?? AppColors.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ],
    );
  }

  Widget _actionButton(
      String text, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(text,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(icon,
                size: 56,
                color: AppColors.borderLight),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
