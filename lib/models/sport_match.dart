import 'enums.dart';

/// Команда внутри события
class EventTeam {
  final String id;
  String name;
  final int colorValue; // Material color value
  final List<String> playerIds;
  final List<String> playerNames;

  EventTeam({
    required this.id,
    required this.name,
    required this.colorValue,
    List<String>? playerIds,
    List<String>? playerNames,
  })  : playerIds = playerIds ?? [],
        playerNames = playerNames ?? [];

  int get playerCount => playerIds.length;

  void addPlayer(String id, String name) {
    if (!playerIds.contains(id)) {
      playerIds.add(id);
      playerNames.add(name);
    }
  }

  void removePlayer(String id) {
    final idx = playerIds.indexOf(id);
    if (idx != -1) {
      playerIds.removeAt(idx);
      if (idx < playerNames.length) playerNames.removeAt(idx);
    }
  }

  bool hasPlayer(String id) => playerIds.contains(id);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
    'playerIds': playerIds,
    'playerNames': playerNames,
  };

  static EventTeam fromJson(Map<String, dynamic> json) => EventTeam(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    colorValue: json['colorValue'] ?? 0xFFE53935,
    playerIds: List<String>.from(json['playerIds'] ?? []),
    playerNames: List<String>.from(json['playerNames'] ?? []),
  );
}

/// Матч между двумя командами внутри события
class InnerMatch {
  final String id;
  final int team1Index;
  final int team2Index;
  int team1Score;
  int team2Score;
  bool isCompleted;

  InnerMatch({
    required this.id,
    required this.team1Index,
    required this.team2Index,
    this.team1Score = 0,
    this.team2Score = 0,
    this.isCompleted = false,
  });

  /// Индекс команды-победителя (-1 = ничья, -2 = не завершён)
  int get winnerIndex {
    if (!isCompleted) return -2;
    if (team1Score > team2Score) return team1Index;
    if (team2Score > team1Score) return team2Index;
    return -1; // ничья
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'team1Index': team1Index,
    'team2Index': team2Index,
    'team1Score': team1Score,
    'team2Score': team2Score,
    'isCompleted': isCompleted,
  };

  static InnerMatch fromJson(Map<String, dynamic> json) => InnerMatch(
    id: json['id'] ?? '',
    team1Index: json['team1Index'] ?? 0,
    team2Index: json['team2Index'] ?? 0,
    team1Score: json['team1Score'] ?? 0,
    team2Score: json['team2Score'] ?? 0,
    isCompleted: json['isCompleted'] ?? false,
  );
}

/// Результат команды в таблице (для итогов)
class TeamStanding {
  final int teamIndex;
  final String teamName;
  final int colorValue;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;

  TeamStanding({
    required this.teamIndex,
    required this.teamName,
    required this.colorValue,
  });

  int get played => wins + draws + losses;
  int get points => wins * 3 + draws;
  int get goalDifference => goalsFor - goalsAgainst;
}

class SportMatch {
  final String id;
  final String? communityId;
  final SportCategory category;
  final String format;
  final DateTime dateTime;
  final String location;
  final double price;
  final int totalCapacity;
  int currentPlayers;
  bool isUserRegistered;
  final MatchType matchType;
  final List<String> registeredPlayerIds;
  final List<String> registeredPlayerNames;
  final List<EventTeam> eventTeams;
  final List<InnerMatch> innerMatches;
  bool isCompleted;

  SportMatch({
    required this.id,
    this.communityId,
    required this.category,
    required this.format,
    required this.dateTime,
    required this.location,
    required this.price,
    required this.totalCapacity,
    this.currentPlayers = 0,
    this.isUserRegistered = false,
    this.matchType = MatchType.single,
    List<String>? registeredPlayerIds,
    List<String>? registeredPlayerNames,
    List<EventTeam>? eventTeams,
    List<InnerMatch>? innerMatches,
    this.isCompleted = false,
  })  : registeredPlayerIds = registeredPlayerIds ?? [],
        registeredPlayerNames = registeredPlayerNames ?? [],
        eventTeams = eventTeams ?? [],
        innerMatches = innerMatches ?? [];

  /// Получить нераспределённых игроков (не в командах)
  List<MapEntry<String, String>> get unassignedPlayers {
    final assignedIds = <String>{};
    for (final team in eventTeams) {
      assignedIds.addAll(team.playerIds);
    }
    final result = <MapEntry<String, String>>[];
    for (int i = 0; i < registeredPlayerIds.length; i++) {
      final id = registeredPlayerIds[i];
      if (!assignedIds.contains(id)) {
        final name = i < registeredPlayerNames.length
            ? registeredPlayerNames[i]
            : 'Игрок';
        result.add(MapEntry(id, name));
      }
    }
    return result;
  }

  /// Рассчитать турнирную таблицу
  List<TeamStanding> getStandings() {
    final standings = <int, TeamStanding>{};
    for (int i = 0; i < eventTeams.length; i++) {
      standings[i] = TeamStanding(
        teamIndex: i,
        teamName: eventTeams[i].name,
        colorValue: eventTeams[i].colorValue,
      );
    }

    for (final match in innerMatches) {
      if (!match.isCompleted) continue;
      final s1 = standings[match.team1Index];
      final s2 = standings[match.team2Index];
      if (s1 == null || s2 == null) continue;

      s1.goalsFor += match.team1Score;
      s1.goalsAgainst += match.team2Score;
      s2.goalsFor += match.team2Score;
      s2.goalsAgainst += match.team1Score;

      if (match.team1Score > match.team2Score) {
        s1.wins++;
        s2.losses++;
      } else if (match.team2Score > match.team1Score) {
        s2.wins++;
        s1.losses++;
      } else {
        s1.draws++;
        s2.draws++;
      }
    }

    final list = standings.values.toList();
    list.sort((a, b) {
      final cmp = b.points.compareTo(a.points);
      if (cmp != 0) return cmp;
      return b.goalDifference.compareTo(a.goalDifference);
    });
    return list;
  }
}
