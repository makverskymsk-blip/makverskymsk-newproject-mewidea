/// Типы событий матча
enum MatchEventType {
  goal('goal', '⚽', 'Гол'),
  assist('assist', '🅰️', 'Ассист'),
  save('save', '🧤', 'Сейв'),
  foul('foul', '🟡', 'Фол'),
  ownGoal('own_goal', '⚽🔴', 'Автогол');

  final String value;
  final String emoji;
  final String label;
  const MatchEventType(this.value, this.emoji, this.label);

  static MatchEventType fromString(String s) =>
      MatchEventType.values.firstWhere((e) => e.value == s, orElse: () => goal);
}

/// Событие внутри матча (гол, ассист, сейв, фол, автогол)
class MatchEvent {
  final String id;
  final String matchId;
  final String communityId;
  final String playerId;
  final String playerName;
  final String recordedBy;
  final String recordedByName;
  final MatchEventType eventType;
  final int? teamIndex;
  final String? innerMatchId;
  final DateTime createdAt;

  MatchEvent({
    required this.id,
    required this.matchId,
    required this.communityId,
    required this.playerId,
    required this.playerName,
    required this.recordedBy,
    required this.recordedByName,
    required this.eventType,
    this.teamIndex,
    this.innerMatchId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    return MatchEvent(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      communityId: json['community_id'] as String,
      playerId: json['player_id'] as String,
      playerName: json['player_name'] as String? ?? '',
      recordedBy: json['recorded_by'] as String,
      recordedByName: json['recorded_by_name'] as String? ?? '',
      eventType: MatchEventType.fromString(json['event_type'] as String),
      teamIndex: json['team_index'] as int?,
      innerMatchId: json['inner_match_id'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'match_id': matchId,
    'community_id': communityId,
    'player_id': playerId,
    'player_name': playerName,
    'recorded_by': recordedBy,
    'recorded_by_name': recordedByName,
    'event_type': eventType.value,
    'team_index': teamIndex,
    'inner_match_id': innerMatchId,
  };
}
