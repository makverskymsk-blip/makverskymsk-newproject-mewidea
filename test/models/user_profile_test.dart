import 'package:flutter_test/flutter_test.dart';
import 'package:new_idea_works/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    late UserProfile user;

    setUp(() {
      user = UserProfile(
        id: 'test-uid-123',
        name: 'Тестовый Игрок',
        email: 'test@example.com',
        balance: 5000,
        trainingXp: 250,
        trainingLevel: 3,
      );
    });

    test('default values are set correctly', () {
      final u = UserProfile(id: 'id', name: 'Name');
      expect(u.balance, 0);
      expect(u.debt, 0);
      expect(u.communityIds, isEmpty);
      expect(u.isPremium, false);
      expect(u.gamesPlayed, 0);
      expect(u.goalsScored, 0);
      expect(u.sportPositions, isEmpty);
      expect(u.position, 'Не указана');
      expect(u.trainingXp, 0);
      expect(u.trainingLevel, 1);
    });

    test('xpForNextLevel scales with level', () {
      // Level 1: 500 * 1^1.5 = 500
      user.trainingLevel = 1;
      expect(user.xpForNextLevel, 500);

      // Level 4: 500 * 4^1.5 = 500 * 8 = 4000
      user.trainingLevel = 4;
      expect(user.xpForNextLevel, 4000);

      // Level 10: 500 * 10^1.5 ≈ 15811
      user.trainingLevel = 10;
      expect(user.xpForNextLevel, closeTo(15811, 1));
    });

    test('xpProgress returns correct fraction', () {
      user.trainingLevel = 1; // need 500 XP
      user.trainingXp = 250;
      expect(user.xpProgress, 0.5);

      user.trainingXp = 0;
      expect(user.xpProgress, 0.0);

      user.trainingXp = 500;
      expect(user.xpProgress, 1.0);

      // Clamped at 1.0
      user.trainingXp = 999;
      expect(user.xpProgress, 1.0);
    });

    test('trainingRank returns correct rank for level ranges', () {
      user.trainingLevel = 1;
      expect(user.trainingRank, 'Новичок');

      user.trainingLevel = 10;
      expect(user.trainingRank, 'Любитель');

      user.trainingLevel = 25;
      expect(user.trainingRank, 'Продвинутый');

      user.trainingLevel = 40;
      expect(user.trainingRank, 'Ветеран');

      user.trainingLevel = 60;
      expect(user.trainingRank, 'Элита');

      user.trainingLevel = 80;
      expect(user.trainingRank, 'Легенда');
    });

    test('getPositionForSport falls back to general position', () {
      user.position = 'Нападающий';
      expect(user.getPositionForSport('hockey'), 'Нападающий');

      user.sportPositions['hockey'] = 'Вратарь';
      expect(user.getPositionForSport('hockey'), 'Вратарь');
      expect(user.getPositionForSport('tennis'), 'Нападающий'); // fallback
    });

    test('setPositionForSport syncs football with legacy position', () {
      user.setPositionForSport('football', 'Защитник');
      expect(user.sportPositions['football'], 'Защитник');
      expect(user.position, 'Защитник'); // legacy sync

      // Other sports don't sync
      user.setPositionForSport('hockey', 'Вратарь');
      expect(user.position, 'Защитник'); // unchanged
    });
  });
}
