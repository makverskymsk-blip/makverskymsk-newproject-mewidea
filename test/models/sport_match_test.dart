import 'package:flutter_test/flutter_test.dart';
import 'package:new_idea_works/models/sport_match.dart';
import 'package:new_idea_works/models/enums.dart';

void main() {
  group('EventTeam', () {
    test('addPlayer prevents duplicates', () {
      final team = EventTeam(id: 't1', name: 'Red', colorValue: 0xFFFF0000);
      team.addPlayer('p1', 'Player1');
      team.addPlayer('p1', 'Player1');
      expect(team.playerIds.length, 1);
    });

    test('removePlayer also removes captain', () {
      final team = EventTeam(id: 't1', name: 'Red', colorValue: 0xFFFF0000);
      team.addPlayer('p1', 'Player1');
      team.addCaptain('p1', 'Player1');
      expect(team.isCaptain('p1'), true);

      team.removePlayer('p1');
      expect(team.playerIds, isEmpty);
      expect(team.captainIds, isEmpty);
    });

    test('addCaptain limited to 2', () {
      final team = EventTeam(id: 't1', name: 'Red', colorValue: 0xFFFF0000);
      expect(team.addCaptain('p1', 'P1'), true);
      expect(team.addCaptain('p2', 'P2'), true);
      expect(team.addCaptain('p3', 'P3'), false);
      expect(team.captainIds.length, 2);
    });

    test('addCaptain prevents duplicate captain', () {
      final team = EventTeam(id: 't1', name: 'Red', colorValue: 0xFFFF0000);
      expect(team.addCaptain('p1', 'P1'), true);
      expect(team.addCaptain('p1', 'P1'), false);
      expect(team.captainIds.length, 1);
    });

    test('toJson / fromJson roundtrip', () {
      final team = EventTeam(
        id: 't1',
        name: 'Красные',
        colorValue: 0xFFE53935,
        playerIds: ['p1', 'p2'],
        playerNames: ['Player1', 'Player2'],
        captainIds: ['p1'],
        captainNames: ['Player1'],
        ratingsSubmitted: true,
      );
      final json = team.toJson();
      final restored = EventTeam.fromJson(json);

      expect(restored.id, team.id);
      expect(restored.name, team.name);
      expect(restored.colorValue, team.colorValue);
      expect(restored.playerIds, team.playerIds);
      expect(restored.captainIds, team.captainIds);
      expect(restored.ratingsSubmitted, true);
    });
  });

  group('InnerMatch', () {
    test('winnerIndex for completed match', () {
      final match = InnerMatch(id: 'm1', team1Index: 0, team2Index: 1);
      expect(match.winnerIndex, -2); // not completed

      match.isCompleted = true;
      match.team1Score = 3;
      match.team2Score = 1;
      expect(match.winnerIndex, 0); // team1 wins

      match.team1Score = 1;
      match.team2Score = 3;
      expect(match.winnerIndex, 1); // team2 wins

      match.team1Score = 2;
      match.team2Score = 2;
      expect(match.winnerIndex, -1); // draw
    });

    test('toJson / fromJson roundtrip', () {
      final match = InnerMatch(
        id: 'im1',
        team1Index: 0,
        team2Index: 1,
        team1Score: 3,
        team2Score: 2,
        isCompleted: true,
      );
      final json = match.toJson();
      final restored = InnerMatch.fromJson(json);

      expect(restored.id, match.id);
      expect(restored.team1Index, match.team1Index);
      expect(restored.team1Score, 3);
      expect(restored.isCompleted, true);
    });
  });

  group('SportMatch', () {
    test('unassignedPlayers returns players not in any team', () {
      final match = SportMatch(
        id: 'e1',
        category: SportCategory.football,
        format: '5v5',
        dateTime: DateTime(2026, 5, 1),
        location: 'Arena',
        price: 1000,
        totalCapacity: 10,
        registeredPlayerIds: ['p1', 'p2', 'p3'],
        registeredPlayerNames: ['Player1', 'Player2', 'Player3'],
        eventTeams: [
          EventTeam(
            id: 't1',
            name: 'Red',
            colorValue: 0xFFFF0000,
            playerIds: ['p1'],
            playerNames: ['Player1'],
          ),
        ],
      );

      final unassigned = match.unassignedPlayers;
      expect(unassigned.length, 2);
      expect(unassigned.map((e) => e.key), containsAll(['p2', 'p3']));
    });

    test('allCaptainsRated is true when all teams rated', () {
      final match = SportMatch(
        id: 'e1',
        category: SportCategory.football,
        format: '5v5',
        dateTime: DateTime(2026, 5, 1),
        location: 'Arena',
        price: 1000,
        totalCapacity: 10,
        eventTeams: [
          EventTeam(
            id: 't1', name: 'Red', colorValue: 0xFFFF0000,
            playerIds: ['p1'], playerNames: ['P1'],
            ratingsSubmitted: true,
          ),
          EventTeam(
            id: 't2', name: 'Blue', colorValue: 0xFF0000FF,
            playerIds: ['p2'], playerNames: ['P2'],
            ratingsSubmitted: false,
          ),
        ],
      );

      expect(match.allCaptainsRated, false);

      match.eventTeams[1].ratingsSubmitted = true;
      expect(match.allCaptainsRated, true);
    });

    test('allCaptainsRated skips empty teams', () {
      final match = SportMatch(
        id: 'e1',
        category: SportCategory.football,
        format: '5v5',
        dateTime: DateTime(2026, 5, 1),
        location: 'Arena',
        price: 1000,
        totalCapacity: 10,
        eventTeams: [
          EventTeam(
            id: 't1', name: 'Red', colorValue: 0xFFFF0000,
            playerIds: ['p1'], playerNames: ['P1'],
            ratingsSubmitted: true,
          ),
          EventTeam(
            id: 't2', name: 'Blue', colorValue: 0xFF0000FF,
            // empty team — no players
          ),
        ],
      );

      expect(match.allCaptainsRated, true); // empty team is ignored
    });

    test('getStandings calculates correct tournament table', () {
      final match = SportMatch(
        id: 'e1',
        category: SportCategory.football,
        format: '5v5',
        dateTime: DateTime(2026, 5, 1),
        location: 'Arena',
        price: 1000,
        totalCapacity: 10,
        eventTeams: [
          EventTeam(id: 't0', name: 'Red', colorValue: 0xFFFF0000),
          EventTeam(id: 't1', name: 'Blue', colorValue: 0xFF0000FF),
          EventTeam(id: 't2', name: 'Green', colorValue: 0xFF00FF00),
        ],
        innerMatches: [
          // Red 3:1 Blue → Red wins
          InnerMatch(
            id: 'm1', team1Index: 0, team2Index: 1,
            team1Score: 3, team2Score: 1, isCompleted: true,
          ),
          // Blue 2:2 Green → Draw
          InnerMatch(
            id: 'm2', team1Index: 1, team2Index: 2,
            team1Score: 2, team2Score: 2, isCompleted: true,
          ),
          // Red 1:0 Green → Red wins
          InnerMatch(
            id: 'm3', team1Index: 0, team2Index: 2,
            team1Score: 1, team2Score: 0, isCompleted: true,
          ),
          // Not completed — should be ignored
          InnerMatch(
            id: 'm4', team1Index: 0, team2Index: 1,
            team1Score: 5, team2Score: 0, isCompleted: false,
          ),
        ],
      );

      final standings = match.getStandings();

      // Red: 2W 0D 0L = 6pts, GF=4 GA=1 GD=+3
      expect(standings[0].teamName, 'Red');
      expect(standings[0].points, 6);
      expect(standings[0].wins, 2);
      expect(standings[0].goalDifference, 3);

      // Blue: 0W 1D 1L = 1pt, GF=3 GA=5 GD=-2
      // Green: 0W 1D 1L = 1pt, GF=2 GA=3 GD=-1
      // Green has better GD → Green second
      expect(standings[1].teamName, 'Green');
      expect(standings[1].points, 1);
      expect(standings[2].teamName, 'Blue');
      expect(standings[2].points, 1);
    });
  });
}
