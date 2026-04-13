import 'package:flutter_test/flutter_test.dart';
import 'package:new_idea_works/models/app_notification.dart';

void main() {
  group('AppNotification', () {
    test('timeAgo returns "сейчас" for recent notification', () {
      final n = AppNotification(
        id: 'n1',
        type: NotificationType.eventCreated,
        title: 'Test',
        body: 'Body',
        createdAt: DateTime.now(),
      );
      expect(n.timeAgo, 'сейчас');
    });

    test('timeAgo returns minutes', () {
      final n = AppNotification(
        id: 'n1',
        type: NotificationType.eventCreated,
        title: 'Test',
        body: 'Body',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );
      expect(n.timeAgo, '30 мин.');
    });

    test('timeAgo returns hours', () {
      final n = AppNotification(
        id: 'n1',
        type: NotificationType.eventCreated,
        title: 'Test',
        body: 'Body',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      );
      expect(n.timeAgo, '5 ч.');
    });

    test('timeAgo returns days', () {
      final n = AppNotification(
        id: 'n1',
        type: NotificationType.eventCreated,
        title: 'Test',
        body: 'Body',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(n.timeAgo, '3 дн.');
    });

    test('timeAgo returns date for old notifications', () {
      final n = AppNotification(
        id: 'n1',
        type: NotificationType.eventCreated,
        title: 'Test',
        body: 'Body',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      );
      // Should be a date like "3.04"
      expect(n.timeAgo, isNot('сейчас'));
      expect(n.timeAgo, contains('.'));
    });

    test('default isRead is false', () {
      final n = AppNotification(
        id: 'n1',
        type: NotificationType.balanceTopUp,
        title: 'Пополнение',
        body: '+1000₽',
      );
      expect(n.isRead, false);
    });

    test('NotificationType has correct labels', () {
      expect(NotificationType.eventCreated.label, 'Новое событие');
      expect(NotificationType.balanceTopUp.label, 'Пополнение');
      expect(NotificationType.balanceCharge.label, 'Списание');
      expect(NotificationType.achievementUnlock.label, 'Достижение');
    });
  });
}
