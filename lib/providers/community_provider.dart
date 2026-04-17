import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/community.dart';
import '../models/enums.dart';
import '../models/subscription.dart';
import '../models/transaction.dart';
import '../services/supabase_service.dart';

class CommunityProvider extends ChangeNotifier {
  final SupabaseService _db = SupabaseService();
  final List<Community> _communities = [];
  Community? _activeCommunity;
  final List<MonthlySubscription> _subscriptions = [];
  dynamic _subsRealtimeChannel;
  dynamic _communityRealtimeChannel;

  List<Community> get communities => _communities;
  Community? get activeCommunity => _activeCommunity;
  List<MonthlySubscription> get subscriptions => _subscriptions;

  static const _prefKey = 'active_community_id';

  void setActiveCommunity(Community community) async {
    _activeCommunity = community;
    _subscribeToCommunityRealtime(community.id);
    notifyListeners();
    // Persist selection
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, community.id);
  }

  Future<void> loadUserCommunities(List<String> communityIds) async {
    _communities.clear();
    final loaded = await _db.getUserCommunities(communityIds);
    _communities.addAll(loaded);
    if (_communities.isNotEmpty && _activeCommunity == null) {
      // Try to restore saved selection
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_prefKey);
      if (savedId != null) {
        final saved = _communities.where((c) => c.id == savedId);
        if (saved.isNotEmpty) {
          _activeCommunity = saved.first;
        }
      }
      // Fallback to first community
      _activeCommunity ??= _communities.first;
    }
    // Subscribe to realtime for the active community
    if (_activeCommunity != null) {
      _subscribeToCommunityRealtime(_activeCommunity!.id);
    }
    notifyListeners();
  }

  /// Upload community logo and update DB
  Future<bool> uploadLogo(String communityId, Uint8List bytes, String ext) async {
    try {
      final url = await _db.uploadCommunityLogo(communityId, bytes, ext);
      if (url == null) return false;
      await _db.updateCommunityLogoUrl(communityId, url);
      // Update local
      final idx = _communities.indexWhere((c) => c.id == communityId);
      if (idx != -1) _communities[idx].logoUrl = url;
      if (_activeCommunity?.id == communityId) _activeCommunity!.logoUrl = url;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('LOGO UPLOAD ERROR: $e');
      return false;
    }
  }

  // ===== COMMUNITY DIRECTORY =====

  List<Community> _allCommunities = [];
  List<Community> get allCommunities => _allCommunities;

  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> get pendingRequests => _pendingRequests;

  List<Map<String, dynamic>> _userRequests = [];
  List<Map<String, dynamic>> get userRequests => _userRequests;

  Future<void> loadAllCommunities() async {
    _allCommunities = await _db.getAllCommunities();
    notifyListeners();
  }

  Future<void> loadUserJoinRequests(String userId) async {
    _userRequests = await _db.getUserJoinRequests(userId);
    notifyListeners();
  }

  Future<void> loadPendingRequests(String communityId) async {
    _pendingRequests = await _db.getJoinRequestsForCommunity(communityId);
    notifyListeners();
  }

  /// Check if user already sent a request for a community
  String? getRequestStatus(String communityId) {
    final match = _userRequests.where((r) => r['community_id'] == communityId);
    if (match.isEmpty) return null;
    return match.first['status'] as String?;
  }

  Future<void> sendJoinRequest(String communityId, String userId) async {
    await _db.createJoinRequest(communityId, userId);
    await loadUserJoinRequests(userId);
  }

  Future<void> acceptJoinRequest(String requestId, String userId, String communityId) async {
    await _db.updateJoinRequestStatus(requestId, 'accepted');
    // Also add the user to the community
    await _db.joinCommunity(communityId, userId);
    // Reload
    if (_activeCommunity != null) {
      await loadPendingRequests(_activeCommunity!.id);
    }
  }

  Future<void> rejectJoinRequest(String requestId) async {
    await _db.updateJoinRequestStatus(requestId, 'rejected');
    if (_activeCommunity != null) {
      await loadPendingRequests(_activeCommunity!.id);
    }
  }

  /// Get pending request count for admin badge
  int get pendingRequestCount => _pendingRequests.length;

  /// Subscribe to Realtime changes for a community
  void _subscribeToCommunityRealtime(String communityId) {
    _communityRealtimeChannel?.unsubscribe();
    _communityRealtimeChannel = _db.watchCommunityChannel(
      communityId,
      onChanged: () => _refreshActiveCommunity(communityId),
    );
  }

  /// Refresh community data from DB when realtime event fires
  Future<void> _refreshActiveCommunity(String communityId) async {
    try {
      final freshList = await _db.getUserCommunities([communityId]);
      if (freshList.isNotEmpty) {
        final fresh = freshList.first;
        // Update in local list
        final idx = _communities.indexWhere((c) => c.id == communityId);
        if (idx != -1) {
          _communities[idx] = fresh;
        }
        if (_activeCommunity?.id == communityId) {
          _activeCommunity = fresh;
        }
        debugPrint('REALTIME: Community refreshed — ${fresh.memberIds.length + fresh.adminIds.length} members');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('REALTIME: Failed to refresh community: $e');
    }
  }

  Future<void> createCommunityFirestore({
    required String name,
    required SportCategory sport,
    required String ownerId,
    double monthlyRent = 100000,
    double singleGamePrice = 1200,
  }) async {
    final code =
        '${name.substring(0, 2).toUpperCase()}${DateTime.now().millisecondsSinceEpoch % 10000}';
    
    // Let PostgreSQL generate the UUID — insert and get back the ID
    final response = await _db.createCommunityAndReturn(
      name: name,
      sport: sport,
      inviteCode: code,
      ownerId: ownerId,
      monthlyRent: monthlyRent,
      singleGamePrice: singleGamePrice,
    );
    
    final community = Community(
      id: response['id'].toString(),
      name: name,
      sport: sport,
      inviteCode: code,
      ownerId: ownerId,
      adminIds: [ownerId],
      memberIds: [],
      monthlyRent: monthlyRent,
      singleGamePrice: singleGamePrice,
    );
    
    _communities.add(community);
    _activeCommunity = community;
    notifyListeners();
  }

  Future<bool> joinCommunityFirestore(String inviteCode, String userId) async {
    final community =
        await _db.getCommunityByInviteCode(inviteCode.toUpperCase());
    if (community == null) return false;
    if (community.isMember(userId)) {
      _activeCommunity = community;
      if (!_communities.any((c) => c.id == community.id)) {
        _communities.add(community);
      }
      notifyListeners();
      return true;
    }
    await _db.joinCommunity(community.id, userId);
    community.memberIds.add(userId);
    if (!_communities.any((c) => c.id == community.id)) {
      _communities.add(community);
    }
    _activeCommunity = community;
    notifyListeners();
    return true;
  }

  Future<void> leaveCommunity(String communityId, String userId) async {
    await _db.leaveCommunity(communityId, userId);
    _communities.removeWhere((c) => c.id == communityId);
    if (_activeCommunity?.id == communityId) {
      _activeCommunity = _communities.isNotEmpty ? _communities.first : null;
    }
    notifyListeners();
  }

  // ============================================================
  // АДМИНИСТРАТОРЫ — назначение / снятие (только для владельца)
  // ============================================================

  /// Назначить пользователя администратором (может только владелец)
  Future<bool> promoteToAdmin({
    required String requesterId,
    required String targetUserId,
  }) async {
    if (_activeCommunity == null) return false;
    if (!_activeCommunity!.canManageAdmins(requesterId)) return false;
    if (_activeCommunity!.isAdmin(targetUserId)) return false;

    _activeCommunity!.adminIds.add(targetUserId);
    _activeCommunity!.memberIds.remove(targetUserId);

    await _db.updateCommunityAdmins(
      _activeCommunity!.id,
      _activeCommunity!.adminIds,
      _activeCommunity!.memberIds,
    );
    notifyListeners();
    return true;
  }

  /// Снять пользователя с роли администратора (может только владелец)
  Future<bool> demoteFromAdmin({
    required String requesterId,
    required String targetUserId,
  }) async {
    if (_activeCommunity == null) return false;
    if (!_activeCommunity!.canManageAdmins(requesterId)) return false;
    if (_activeCommunity!.isOwner(targetUserId)) return false;

    _activeCommunity!.adminIds.remove(targetUserId);
    _activeCommunity!.memberIds.add(targetUserId);

    await _db.updateCommunityAdmins(
      _activeCommunity!.id,
      _activeCommunity!.adminIds,
      _activeCommunity!.memberIds,
    );
    notifyListeners();
    return true;
  }

  // ============================================================
  // БАЛАНС — пополнение / списание (владелец + админы)
  // ============================================================

  /// Пополнить баланс пользователя (может владелец или админ)
  Future<bool> topUpUserBalance({
    required String requesterId,
    required String targetUserId,
    required double amount,
  }) async {
    if (_activeCommunity == null || amount <= 0) return false;
    if (!_activeCommunity!.canManageBalance(requesterId)) return false;

    await _db.updateUserBalance(targetUserId, amount, communityId: _activeCommunity!.id);
    await _db.addTransaction(
      _activeCommunity!.id,
      Transaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        userId: targetUserId,
        communityId: _activeCommunity!.id,
        type: TransactionType.topUp,
        amount: amount,
        status: TransactionStatus.confirmed,
        description: 'Пополнение баланса администратором',
      ),
    );
    notifyListeners();
    return true;
  }

  /// Списать средства с баланса пользователя (может владелец или админ)
  Future<bool> deductUserBalance({
    required String requesterId,
    required String targetUserId,
    required double amount,
    String description = 'Списание средств',
  }) async {
    if (_activeCommunity == null || amount <= 0) return false;
    if (!_activeCommunity!.canManageBalance(requesterId)) return false;

    await _db.updateUserBalance(targetUserId, -amount, communityId: _activeCommunity!.id);
    await _db.addTransaction(
      _activeCommunity!.id,
      Transaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        userId: targetUserId,
        communityId: _activeCommunity!.id,
        type: TransactionType.withdrawal,
        amount: amount,
        status: TransactionStatus.confirmed,
        description: description,
      ),
    );
    notifyListeners();
    return true;
  }

  // ============================================================
  // РАСЧЁТ — обнуление долга участника и зачисление в банк
  // ============================================================

  /// Расчёт: обнулить отрицательный баланс пользователя,
  /// а абсолютную сумму долга добавить в банк сообщества.
  Future<bool> settleUserBalance({
    required String requesterId,
    required String targetUserId,
    required double currentBalance,
  }) async {
    if (_activeCommunity == null) return false;
    if (!_activeCommunity!.canManageBalance(requesterId)) return false;
    if (currentBalance >= 0) return false; // нечего списывать

    final settledAmount = currentBalance.abs();

    // 1. Обнулить баланс пользователя (прибавить |долг|)
    await _db.updateUserBalance(targetUserId, settledAmount, communityId: _activeCommunity!.id);

    // 2. Добавить в банк сообщества
    _activeCommunity!.bankBalance += settledAmount;
    await _db.updateCommunityBank(
        _activeCommunity!.id, _activeCommunity!.bankBalance);

    // 3. Зарегистрировать транзакцию
    await _db.addTransaction(
      _activeCommunity!.id,
      Transaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        userId: targetUserId,
        communityId: _activeCommunity!.id,
        type: TransactionType.topUp,
        amount: settledAmount,
        status: TransactionStatus.confirmed,
        description: 'Расчёт долга — оплата подтверждена',
      ),
    );

    notifyListeners();
    return true;
  }

  /// Расчёт за конкретное событие: частично погасить долг участника
  /// на сумму [amount] и зачислить в банк сообщества.
  Future<bool> settleEventPayment({
    required String requesterId,
    required String targetUserId,
    required double amount,
    required String eventDescription,
  }) async {
    if (_activeCommunity == null) return false;
    if (!_activeCommunity!.canManageBalance(requesterId)) return false;
    if (amount <= 0) return false;

    // 1. Погасить часть долга пользователя (прибавить amount к балансу)
    await _db.updateUserBalance(targetUserId, amount, communityId: _activeCommunity!.id);

    // 2. Добавить в банк сообщества
    _activeCommunity!.bankBalance += amount;
    await _db.updateCommunityBank(
        _activeCommunity!.id, _activeCommunity!.bankBalance);

    // 3. Зарегистрировать транзакцию
    await _db.addTransaction(
      _activeCommunity!.id,
      Transaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        userId: targetUserId,
        communityId: _activeCommunity!.id,
        type: TransactionType.topUp,
        amount: amount,
        status: TransactionStatus.confirmed,
        description: 'Оплата за: $eventDescription',
      ),
    );

    notifyListeners();
    return true;
  }

  // ============================================================
  // БАЛАНС СООБЩЕСТВА — ручное пополнение и списание
  // ============================================================

  /// Пополнить баланс сообщества вручную (владелец или админ)
  Future<bool> topUpCommunityBalance({
    required String requesterId,
    required double amount,
    String description = 'Ручное пополнение',
  }) async {
    if (_activeCommunity == null || amount <= 0) return false;
    if (!_activeCommunity!.canManageBalance(requesterId)) return false;

    _activeCommunity!.bankBalance += amount;
    await _db.updateCommunityBank(
        _activeCommunity!.id, _activeCommunity!.bankBalance);
    await _db.addTransaction(
      _activeCommunity!.id,
      Transaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        userId: requesterId,
        communityId: _activeCommunity!.id,
        type: TransactionType.topUp,
        amount: amount,
        status: TransactionStatus.confirmed,
        description: 'Касса: $description',
      ),
    );
    notifyListeners();
    return true;
  }

  /// Списать средства с баланса сообщества (владелец или админ)
  Future<bool> deductCommunityBalance({
    required String requesterId,
    required double amount,
    String description = 'Ручное списание',
  }) async {
    if (_activeCommunity == null || amount <= 0) return false;
    if (!_activeCommunity!.canManageBalance(requesterId)) return false;

    _activeCommunity!.bankBalance -= amount;
    await _db.updateCommunityBank(
        _activeCommunity!.id, _activeCommunity!.bankBalance);
    await _db.addTransaction(
      _activeCommunity!.id,
      Transaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        userId: requesterId,
        communityId: _activeCommunity!.id,
        type: TransactionType.withdrawal,
        amount: amount,
        status: TransactionStatus.confirmed,
        description: 'Касса: $description',
      ),
    );
    notifyListeners();
    return true;
  }

  // ============================================================
  // АБОНЕМЕНТ — создание, подписка, расчёт 25го числа
  // ============================================================

  /// Владелец/админ открывает запись на абонемент на конкретный месяц
  Future<bool> openSubscriptionForMonth({
    required String requesterId,
    required int month,
    required int year,
    double? totalRent,
  }) async {
    if (_activeCommunity == null) {
      debugPrint('SUB: BLOCKED - activeCommunity is null');
      return false;
    }
    if (!_activeCommunity!.canManageBalance(requesterId)) {
      debugPrint('SUB: BLOCKED - canManageBalance=false, requesterId=$requesterId, ownerId=${_activeCommunity!.ownerId}, adminIds=${_activeCommunity!.adminIds}');
      return false;
    }

    // Нельзя открыть на прошлый месяц
    final now = DateTime.now();
    if (year < now.year || (year == now.year && month < now.month)) {
      debugPrint('SUB: BLOCKED - past month: $month/$year vs now ${now.month}/${now.year}');
      return false;
    }

    // Проверяем, не создан ли уже
    final existing = _subscriptions
        .where((s) =>
            s.communityId == _activeCommunity!.id &&
            s.month == month &&
            s.year == year)
        .firstOrNull;
    if (existing != null) {
      debugPrint('SUB: BLOCKED - already exists: ${existing.id} for $month/$year, communityId=${existing.communityId}');
      return false;
    }

    final sub = MonthlySubscription(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      communityId: _activeCommunity!.id,
      month: month,
      year: year,
      totalRent: totalRent ?? _activeCommunity!.monthlyRent,
    );
    // Save to DB and get real UUID back
    final realId = await _db.saveSubscription(_activeCommunity!.id, sub);
    // Create subscription with correct DB id
    final savedSub = MonthlySubscription(
      id: realId,
      communityId: sub.communityId,
      month: sub.month,
      year: sub.year,
      totalRent: sub.totalRent,
    );
    _subscriptions.add(savedSub);
    debugPrint('SUB: CREATED subscription for $month/$year with rent=${sub.totalRent}, id=$realId');
    notifyListeners();
    return true;
  }

  /// Удалить абонемент (только для админов). Аннулирует запись и всех подписавшихся.
  Future<bool> deleteSubscription({
    required String requesterId,
    required String subscriptionId,
  }) async {
    if (_activeCommunity == null) return false;
    if (!_activeCommunity!.isAdmin(requesterId)) return false;

    try {
      await _db.deleteSubscription(subscriptionId);
      _subscriptions.removeWhere((s) => s.id == subscriptionId);
      debugPrint('SUB: DELETED subscription id=$subscriptionId');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('SUB: DELETE error: $e');
      return false;
    }
  }

  /// Получить ВСЕ абонементы с открытой записью (несколько месяцев)
  List<MonthlySubscription> getOpenSubscriptions() {
    if (_activeCommunity == null) return [];
    final list = _subscriptions
        .where((s) =>
            s.communityId == _activeCommunity!.id &&
            s.isRegistrationOpen &&
            !s.isCalculated)
        .toList();
    list.sort((a, b) {
      final cmp = a.year.compareTo(b.year);
      return cmp != 0 ? cmp : a.month.compareTo(b.month);
    });
    return list;
  }

  /// Получить первый открытый абонемент (для баннера на Home)
  MonthlySubscription? getOpenSubscription() {
    final list = getOpenSubscriptions();
    return list.isNotEmpty ? list.first : null;
  }

  /// Записаться / отписаться от абонемента на конкретный месяц
  void toggleSubscription(String userId, String userName,
      {int? month, int? year}) {
    if (_activeCommunity == null) return;

    MonthlySubscription? sub;
    if (month != null && year != null) {
      sub = _subscriptions
          .where((s) =>
              s.communityId == _activeCommunity!.id &&
              s.month == month &&
              s.year == year)
          .firstOrNull;
    } else {
      sub = getOpenSubscription();
    }
    if (sub == null || !sub.isRegistrationOpen) return;

    final existing = sub.entries.where((e) => e.userId == userId).firstOrNull;
    if (existing != null) {
      sub.entries.remove(existing);
    } else {
      sub.entries.add(SubscriptionEntry(userId: userId, userName: userName));
    }

    _db.saveSubscription(_activeCommunity!.id, sub);
    notifyListeners();
  }

  /// Проверяет, записан ли пользователь на хотя бы один открытый абонемент
  bool isSignedUpForOpenSubscription(String userId) {
    return getOpenSubscriptions().any((s) => s.hasUser(userId));
  }

  /// Проверяет, записан ли на конкретный месяц
  bool isSignedUpForMonth(String userId, int month, int year) {
    final sub = _subscriptions
        .where((s) =>
            s.communityId == _activeCommunity?.id &&
            s.month == month &&
            s.year == year)
        .firstOrNull;
    return sub?.hasUser(userId) ?? false;
  }

  /// Проверяет, есть ли у пользователя активный абонемент на ТЕКУЩИЙ месяц
  bool isSubscribed(String userId) {
    if (_activeCommunity == null) return false;
    final now = DateTime.now();
    return isSubscribedForMonth(userId, now.month, now.year);
  }

  /// Проверяет абонемент на конкретный месяц/год
  bool isSubscribedForMonth(String userId, int month, int year) {
    if (_activeCommunity == null) return false;
    final sub = _subscriptions
        .where((s) =>
            s.communityId == _activeCommunity!.id &&
            s.month == month &&
            s.year == year)
        .firstOrNull;
    final result = sub?.hasUser(userId) ?? false;
    if (!result) {
      debugPrint('SUB: no sub for month=$month/$year (have: ${_subscriptions.map((s) => '${s.month}/${s.year}').join(', ')})');
    }
    return result;
  }

  /// Проверяет, есть ли абонемент на дату конкретного события
  bool hasSubscriptionForEventDate(String userId, DateTime eventDate) {
    return isSubscribedForMonth(userId, eventDate.month, eventDate.year);
  }

  /// Получить текущий абонемент для активного сообщества (текущий месяц)
  MonthlySubscription? getCurrentSubscription() {
    if (_activeCommunity == null) return null;
    final now = DateTime.now();
    return _subscriptions
        .where((s) =>
            s.communityId == _activeCommunity!.id &&
            s.month == now.month &&
            s.year == now.year)
        .firstOrNull;
  }

  /// Получить абонемент на конкретный месяц
  MonthlySubscription? getSubscription(int month, int year) {
    if (_activeCommunity == null) return null;
    return _subscriptions
        .where((s) =>
            s.communityId == _activeCommunity!.id &&
            s.month == month &&
            s.year == year)
        .firstOrNull;
  }

  // ============================================================
  // КОМПЕНСАЦИЯ ИЗ БАНКА СООБЩЕСТВА
  // ============================================================

  /// Применить компенсацию из банка к абонементу
  /// Формула: (аренда - компенсация) / кол-во участников
  Future<bool> applyCompensation({
    required String requesterId,
    required double amount,
    required int month,
    required int year,
  }) async {
    if (_activeCommunity == null || amount <= 0) return false;
    if (!_activeCommunity!.canManageBalance(requesterId)) return false;

    final sub = _subscriptions
        .where((s) =>
            s.communityId == _activeCommunity!.id &&
            s.month == month &&
            s.year == year)
        .firstOrNull;
    if (sub == null) return false;

    // Проверка: не превышает ли баланс банка
    if (amount > _activeCommunity!.bankBalance) return false;

    // Проверка: итоговая сумма не отрицательная
    if (amount > sub.totalRent) return false;

    // Если уже была компенсация — вернуть старую в банк
    if (sub.compensationAmount > 0) {
      _activeCommunity!.bankBalance += sub.compensationAmount;
    }

    // Применить новую компенсацию
    sub.compensationAmount = amount;
    _activeCommunity!.bankBalance -= amount;

    // Обновить банк в БД
    await _db.updateCommunityBank(
        _activeCommunity!.id, _activeCommunity!.bankBalance);

    // Сохранить транзакцию
    await _db.addTransaction(
      _activeCommunity!.id,
      Transaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        userId: requesterId,
        communityId: _activeCommunity!.id,
        type: TransactionType.withdrawal,
        amount: amount,
        status: TransactionStatus.confirmed,
        description:
            'Компенсация абонемента ${_monthName(month)} $year из банка',
      ),
    );

    // Если абонемент уже рассчитан — пересчитать цены
    if (sub.isCalculated && sub.entries.isNotEmpty) {
      final perPlayer = sub.effectiveRent / sub.entries.length;
      for (final entry in sub.entries) {
        if (entry.paymentStatus != SubscriptionPaymentStatus.paid) {
          entry.calculatedAmount = perPlayer;
        }
      }
    }

    await _db.saveSubscription(_activeCommunity!.id, sub);
    notifyListeners();
    return true;
  }

  /// Расчёт абонемента (вызывается 25го числа или вручную админом)
  /// (аренда - компенсация) / количество записавшихся = стоимость на человека
  Future<void> calculateSubscription({
    required String requesterId,
    int? month,
    int? year,
  }) async {
    if (_activeCommunity == null) return;
    if (!_activeCommunity!.canManageBalance(requesterId)) return;

    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;

    // ★ Сначала загружаем свежие данные из БД, чтобы учесть всех записавшихся
    await loadSubscriptions(_activeCommunity!.id);

    final sub = _subscriptions
        .where((s) =>
            s.communityId == _activeCommunity!.id &&
            s.month == targetMonth &&
            s.year == targetYear)
        .firstOrNull;

    if (sub == null || sub.entries.isEmpty) return;

    final perPlayer = sub.effectiveRent / sub.entries.length;

    for (final entry in sub.entries) {
      entry.calculatedAmount = perPlayer;
      entry.paymentStatus = SubscriptionPaymentStatus.pending;

      // Списать стоимость абонемента с баланса каждого подписчика
      if (perPlayer > 0) {
        await _db.updateUserBalance(entry.userId, -perPlayer, communityId: _activeCommunity!.id);
        await _db.addTransaction(
          _activeCommunity!.id,
          Transaction(
            id: 'tx_${DateTime.now().millisecondsSinceEpoch}_${entry.userId.substring(0, 8)}',
            userId: entry.userId,
            communityId: _activeCommunity!.id,
            type: TransactionType.subscriptionPayment,
            amount: perPlayer,
            status: TransactionStatus.pending,
            description:
                'Абонемент ${_monthName(targetMonth)} $targetYear — ожидает оплаты',
          ),
        );
      }
    }

    sub.isCalculated = true;
    sub.calculationDate = DateTime.now();
    sub.paymentDeadline =
        DateTime(targetYear, targetMonth + 1, 0, 23, 59, 59);

    await _db.saveSubscription(_activeCommunity!.id, sub);
    notifyListeners();
  }

  /// Подтвердить оплату абонемента конкретным пользователем
  /// Когда админ подтверждает, что человек оплатил вживую:
  /// - возвращаем списанную сумму на баланс пользователя
  /// - добавляем сумму в банк сообщества
  Future<bool> confirmSubscriptionPayment({
    required String requesterId,
    required String targetUserId,
    int? month,
    int? year,
  }) async {
    if (_activeCommunity == null) return false;
    if (!_activeCommunity!.canManageBalance(requesterId)) return false;

    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;

    final sub = _subscriptions
        .where((s) =>
            s.communityId == _activeCommunity!.id &&
            s.month == targetMonth &&
            s.year == targetYear)
        .firstOrNull;

    if (sub == null) return false;

    final entry =
        sub.entries.where((e) => e.userId == targetUserId).firstOrNull;
    if (entry == null) return false;

    entry.paymentStatus = SubscriptionPaymentStatus.paid;

    final amount = entry.calculatedAmount ?? sub.perPlayerAmount;
    if (amount > 0) {
      // Вернуть списанную сумму на баланс пользователя (он оплатил вживую)
      await _db.updateUserBalance(targetUserId, amount, communityId: _activeCommunity!.id);
      await _db.addTransaction(
        _activeCommunity!.id,
        Transaction(
          id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
          userId: targetUserId,
          communityId: _activeCommunity!.id,
          type: TransactionType.subscriptionPayment,
          amount: amount,
          status: TransactionStatus.confirmed,
          description:
              'Оплата абонемента ${_monthName(targetMonth)} $targetYear подтверждена',
        ),
      );

      // Добавить в банк сообщества
      _activeCommunity!.bankBalance += amount;
      await _db.updateCommunityBank(
          _activeCommunity!.id, _activeCommunity!.bankBalance);
    }

    await _db.saveSubscription(_activeCommunity!.id, sub);
    notifyListeners();
    return true;
  }

  /// Загрузить абонементы сообщества из Supabase + подписка на Realtime
  Future<void> loadSubscriptions(String communityId) async {
    final loaded = await _db.getSubscriptions(communityId);
    _subscriptions.removeWhere((s) => s.communityId == communityId);
    _subscriptions.addAll(loaded);
    notifyListeners();
    _subscribeToSubscriptionsRealtime(communityId);
  }

  void _subscribeToSubscriptionsRealtime(String communityId) {
    _subsRealtimeChannel?.unsubscribe();
    _subsRealtimeChannel = _db.watchSubscriptionsChannel(
      communityId,
      onChanged: () async {
        final loaded = await _db.getSubscriptions(communityId);
        _subscriptions.removeWhere((s) => s.communityId == communityId);
        _subscriptions.addAll(loaded);
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subsRealtimeChannel?.unsubscribe();
    super.dispose();
  }

  /// Получить список пользователей, записанных на абонемент
  List<SubscriptionEntry> getSubscriptionEntries({int? month, int? year}) {
    final sub = (month != null && year != null)
        ? getSubscription(month, year)
        : getCurrentSubscription();
    return sub?.entries ?? [];
  }

  // ============================================================
  // ОПЛАТА СОБЫТИЙ — бесплатно по абонементу или разовая оплата
  // ============================================================

  /// Рассчитать стоимость входа на событие для пользователя
  double getEventPriceForUser(String userId, DateTime eventDate) {
    if (_activeCommunity == null) return 0;
    if (hasSubscriptionForEventDate(userId, eventDate)) {
      return 0; // абонемент — бесплатно
    }
    return _activeCommunity!.singleGamePrice; // разовый вход
  }

  /// Оплатить разовый вход на событие
  Future<bool> payForEvent({
    required String userId,
    required DateTime eventDate,
    required String eventDescription,
  }) async {
    if (_activeCommunity == null) return false;
    final price = getEventPriceForUser(userId, eventDate);

    if (price == 0) return true; // абонемент — бесплатно

    await _db.updateUserBalance(userId, -price, communityId: _activeCommunity!.id);
    await _db.addTransaction(
      _activeCommunity!.id,
      Transaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        communityId: _activeCommunity!.id,
        type: TransactionType.gamePayment,
        amount: price,
        status: TransactionStatus.confirmed,
        description: 'Разовый вход: $eventDescription',
      ),
    );

    _activeCommunity!.bankBalance += price;
    await _db.updateCommunityBank(
        _activeCommunity!.id, _activeCommunity!.bankBalance);

    notifyListeners();
    return true;
  }

  // ============================================================
  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ============================================================

  // _getOrCreateCurrentSubscription больше не нужен — владелец создаёт явно

  String _monthName(int month) {
    const months = [
      '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
    ];
    return months[month];
  }
}
