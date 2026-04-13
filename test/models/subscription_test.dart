import 'package:flutter_test/flutter_test.dart';
import 'package:new_idea_works/models/subscription.dart';
import 'package:new_idea_works/models/enums.dart';

void main() {
  group('MonthlySubscription', () {
    late MonthlySubscription sub;

    setUp(() {
      sub = MonthlySubscription(
        id: 'sub-1',
        communityId: 'comm-1',
        month: 5,
        year: 2026,
        totalRent: 100000,
        entries: [
          SubscriptionEntry(userId: 'p1', userName: 'Player1'),
          SubscriptionEntry(userId: 'p2', userName: 'Player2'),
          SubscriptionEntry(userId: 'p3', userName: 'Player3'),
          SubscriptionEntry(userId: 'p4', userName: 'Player4'),
        ],
      );
    });

    test('effectiveRent subtracts compensation', () {
      expect(sub.effectiveRent, 100000);

      sub.compensationAmount = 20000;
      expect(sub.effectiveRent, 80000);

      // Cannot go below 0
      sub.compensationAmount = 150000;
      expect(sub.effectiveRent, 0);
    });

    test('perPlayerAmount is 0 when not calculated', () {
      expect(sub.perPlayerAmount, 0);

      sub.isCalculated = true;
      // 100000 / 4 = 25000
      expect(sub.perPlayerAmount, 25000);
    });

    test('perPlayerAmount with compensation', () {
      sub.isCalculated = true;
      sub.compensationAmount = 20000;
      // (100000 - 20000) / 4 = 20000
      expect(sub.perPlayerAmount, 20000);
    });

    test('estimatedPerPlayerAmount works before calculation', () {
      // 100000 / 4 = 25000
      expect(sub.estimatedPerPlayerAmount, 25000);
    });

    test('estimatedPerPlayerAmount handles empty entries', () {
      sub = MonthlySubscription(
        id: 'sub-1',
        communityId: 'comm-1',
        month: 5,
        year: 2026,
        totalRent: 100000,
      );
      expect(sub.estimatedPerPlayerAmount, 0);
    });

    test('hasUser checks entries', () {
      expect(sub.hasUser('p1'), true);
      expect(sub.hasUser('p2'), true);
      expect(sub.hasUser('unknown'), false);
    });

    test('subscriberCount and subscriberNames', () {
      expect(sub.subscriberCount, 4);
      expect(sub.subscriberNames, ['Player1', 'Player2', 'Player3', 'Player4']);
    });

    test('isActiveForDate checks month and year', () {
      expect(sub.isActiveForDate(DateTime(2026, 5, 15)), true);
      expect(sub.isActiveForDate(DateTime(2026, 5, 1)), true);
      expect(sub.isActiveForDate(DateTime(2026, 6, 1)), false);
      expect(sub.isActiveForDate(DateTime(2025, 5, 1)), false);
    });

    test('toMap / fromMap roundtrip', () {
      sub.isCalculated = true;
      sub.compensationAmount = 15000;
      sub.calculationDate = DateTime(2026, 5, 25);
      sub.paymentDeadline = DateTime(2026, 5, 31, 23, 59, 59);
      sub.entries[0].calculatedAmount = 21250;
      sub.entries[0].paymentStatus = SubscriptionPaymentStatus.paid;

      final map = sub.toMap();
      final restored = MonthlySubscription.fromMap('sub-1', map);

      expect(restored.communityId, sub.communityId);
      expect(restored.month, 5);
      expect(restored.year, 2026);
      expect(restored.totalRent, 100000);
      expect(restored.compensationAmount, 15000);
      expect(restored.isCalculated, true);
      expect(restored.entries.length, 4);
      expect(restored.entries[0].calculatedAmount, 21250);
      expect(restored.entries[0].paymentStatus, SubscriptionPaymentStatus.paid);
    });
  });

  group('SubscriptionEntry', () {
    test('toMap / fromMap roundtrip', () {
      final entry = SubscriptionEntry(
        userId: 'u1',
        userName: 'Test',
        calculatedAmount: 25000,
        paymentStatus: SubscriptionPaymentStatus.pending,
      );
      final map = entry.toMap();
      final restored = SubscriptionEntry.fromMap(map);

      expect(restored.userId, 'u1');
      expect(restored.userName, 'Test');
      expect(restored.calculatedAmount, 25000);
      expect(restored.paymentStatus, SubscriptionPaymentStatus.pending);
    });

    test('default payment status is notPaid', () {
      final entry = SubscriptionEntry(userId: 'u1', userName: 'Test');
      expect(entry.paymentStatus, SubscriptionPaymentStatus.notPaid);
    });
  });
}
