import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:new_idea_works/utils/app_logger.dart';
import '../models/enums.dart';
import '../models/subscription.dart';
import '../models/transaction.dart' as app_tx;
import 'base_repository.dart';

/// Repository for transactions, subscriptions, bank operations.
class FinanceRepository extends BaseRepository {
  static final FinanceRepository _instance = FinanceRepository._internal();
  factory FinanceRepository() => _instance;
  FinanceRepository._internal();

  // ───── Subscriptions ─────

  Future<String> saveSubscription(
      String communityId, MonthlySubscription sub) async {
    final map = <String, dynamic>{
      'community_id': communityId,
      'month': sub.month,
      'year': sub.year,
      'total_rent': sub.totalRent,
      'compensation_amount': sub.compensationAmount,
      'entries': sub.entries.map((e) => e.toMap()).toList(),
      'is_calculated': sub.isCalculated,
      'calculation_date': sub.calculationDate?.millisecondsSinceEpoch,
      'payment_deadline': sub.paymentDeadline?.millisecondsSinceEpoch,
    };

    final isRealUuid = sub.id.length == 36 && sub.id.contains('-');
    if (isRealUuid) {
      final result = await supabase
          .from('subscriptions')
          .update(map)
          .eq('id', sub.id)
          .select()
          .single();
      return result['id'].toString();
    }

    final result = await supabase
        .from('subscriptions')
        .upsert(map, onConflict: 'community_id,month,year')
        .select()
        .single();
    return result['id'].toString();
  }

  Future<List<MonthlySubscription>> getSubscriptions(
      String communityId) async {
    final response = await supabase
        .from('subscriptions')
        .select()
        .eq('community_id', communityId)
        .order('year', ascending: false)
        .order('month', ascending: false);

    return (response as List).map((d) => MonthlySubscription.fromMap(
      d['id'].toString(),
      {
        'communityId': d['community_id'] ?? '',
        'month': d['month'] ?? 1,
        'year': d['year'] ?? 2026,
        'totalRent': d['total_rent'] ?? 0,
        'compensationAmount': d['compensation_amount'] ?? 0,
        'entries': d['entries'] ?? [],
        'isCalculated': d['is_calculated'] ?? false,
        'calculationDate': d['calculation_date'],
        'paymentDeadline': d['payment_deadline'],
      },
    )).toList();
  }

  Future<MonthlySubscription?> getSubscriptionForMonth(
    String communityId,
    int month,
    int year,
  ) async {
    final response = await supabase
        .from('subscriptions')
        .select()
        .eq('community_id', communityId)
        .eq('month', month)
        .eq('year', year)
        .maybeSingle();

    if (response == null) return null;
    return MonthlySubscription.fromMap(response['id'].toString(), response);
  }

  Stream<MonthlySubscription?> watchSubscription(
    String communityId,
    int month,
    int year,
  ) {
    return supabase
        .from('subscriptions')
        .stream(primaryKey: ['id'])
        .eq('community_id', communityId)
        .map((list) {
      if (list.isEmpty) return null;
      final filtered = list.where((d) => d['month'] == month && d['year'] == year);
      if (filtered.isEmpty) return null;
      return MonthlySubscription.fromMap(filtered.first['id'].toString(), filtered.first);
    });
  }

  Future<void> deleteSubscription(String subscriptionId) async {
    await supabase.from('subscriptions').delete().eq('id', subscriptionId);
  }

  dynamic watchSubscriptionsChannel(String communityId, {required VoidCallback onChanged}) {
    final channel = supabase.channel('subs_$communityId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'subscriptions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'community_id',
          value: communityId,
        ),
        callback: (payload) {
          appLog('REALTIME: subscriptions changed — ${payload.eventType}');
          onChanged();
        },
      )
      .subscribe();
    return channel;
  }

  // ───── Transactions ─────

  Future<void> addTransaction(
      String communityId, app_tx.Transaction tx) async {
    await supabase.from('transactions').insert({
      'community_id': communityId,
      'user_id': tx.userId,
      'type': tx.type.index,
      'amount': tx.amount,
      'status': tx.status.index,
      'description': tx.description,
      'date_time': tx.dateTime.toIso8601String(),
    });
  }

  Stream<List<app_tx.Transaction>> watchTransactions(
      String communityId, String userId) {
    return supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('community_id', communityId)
        .map((list) => list
            .where((d) => d['user_id'] == userId)
            .map((d) => app_tx.Transaction(
                  id: d['id'].toString(),
                  userId: d['user_id'] ?? '',
                  communityId: communityId,
                  type: TransactionType.values[d['type'] ?? 0],
                  amount: (d['amount'] ?? 0).toDouble(),
                  status: TransactionStatus.values[d['status'] ?? 0],
                  description: d['description'] ?? '',
                  dateTime: DateTime.parse(d['date_time']),
                ))
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime)));
  }
}
