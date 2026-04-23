import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../models/subscription.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/glass_card.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  int _selectedMonthIndex = 0;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final community =
          context.read<CommunityProvider>().activeCommunity;
      if (community != null) {
        context
            .read<CommunityProvider>()
            .loadSubscriptions(community.id);
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  static const _months = [
    '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  static const _monthsShort = [
    '', 'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн',
    'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек',
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final communityProv = context.watch<CommunityProvider>();
    final community = communityProv.activeCommunity;

    if (community == null) {
      return const Scaffold(
        body: Center(child: Text('Нет активного сообщества')),
      );
    }

    final currentUserId = auth.uid ?? '';
    final currentUserName = auth.currentUser?.name ?? 'Игрок';
    final isAdmin = community.isAdmin(currentUserId);
    final now = DateTime.now();

    // Все открытые абонементы
    final openSubs = communityProv.getOpenSubscriptions();
    // Абонемент текущего месяца
    final currentSub = communityProv.getCurrentSubscription();
    final hasActiveCurrentMonth =
        currentSub != null && currentSub.hasUser(currentUserId);

    // Выбранный абонемент из списка открытых
    MonthlySubscription? selectedSub;
    if (openSubs.isNotEmpty) {
      if (_selectedMonthIndex >= openSubs.length) {
        _selectedMonthIndex = 0;
      }
      selectedSub = openSubs[_selectedMonthIndex];
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(color: AppColors.of(context).scaffoldBg),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
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
                              color: AppColors.of(context).cardBg,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: AppColors.of(context).borderLight),
                            ),
                            child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: AppColors.of(context).textPrimary),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Абонемент',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                community.name,
                                style: const TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Refresh button
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            if (community != null) { // ignore: unnecessary_null_comparison
                              final messenger = ScaffoldMessenger.of(context);
                              await communityProv.loadSubscriptions(community.id);
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Данные обновлены'),
                                  backgroundColor: AppColors.success,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.of(context).cardBg,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: AppColors.of(context).borderLight),
                            ),
                            child: Icon(Icons.refresh_rounded,
                                size: 20, color: AppColors.of(context).textSecondary),
                          ),
                        ),
                        // Admin: add month button
                        if (isAdmin)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: GestureDetector(
                              onTap: () => _showAddMonthDialog(
                                  communityProv, auth, now),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: const Icon(Icons.add_rounded,
                                    size: 20, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Active subscription badge
                          if (hasActiveCurrentMonth) ...[
                            _activeBadge(now),
                            const SizedBox(height: 16),
                          ],

                          // Month tabs
                          if (openSubs.isNotEmpty) ...[
                            _monthTabs(openSubs, currentUserId),
                            const SizedBox(height: 16),
                          ],

                          // Selected month content
                          if (selectedSub != null) ...[
                            _statusCard(selectedSub,
                                selectedSub.hasUser(currentUserId),
                                community.monthlyRent),
                            const SizedBox(height: 16),

                            // Subscribe button
                            if (selectedSub.isRegistrationOpen)
                              _subscribeButton(
                                isSubscribed:
                                    selectedSub.hasUser(currentUserId),
                                onTap: () {
                                  communityProv.toggleSubscription(
                                    currentUserId,
                                    currentUserName,
                                    month: selectedSub!.month,
                                    year: selectedSub.year,
                                  );
                                },
                              ),
                            const SizedBox(height: 24),

                            // Admin: compensation section
                            if (isAdmin &&
                                !selectedSub.isCalculated)
                              _adminCompensationSection(
                                  communityProv, auth, selectedSub),

                            // Admin: calculate
                            if (isAdmin &&
                                !selectedSub.isCalculated &&
                                selectedSub.entries.isNotEmpty)
                              _adminCalculateSection(communityProv,
                                  auth, selectedSub.month,
                                  selectedSub.year),

                            // Subscribers list
                            _subscribersSection(
                                selectedSub, isAdmin, communityProv,
                                auth),
                            const SizedBox(height: 16),

                            // Admin: delete subscription
                            if (isAdmin && !selectedSub.isCalculated)
                              _adminDeleteSection(
                                  communityProv, auth, selectedSub),
                            const SizedBox(height: 24),
                          ] else ...[
                            // No open subscriptions
                            _noOpenSubscription(isAdmin),
                            const SizedBox(height: 16),
                            if (isAdmin)
                              _createQuickButton(
                                  communityProv, auth, now),
                            const SizedBox(height: 24),
                          ],

                          _howItWorks(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ MONTH TABS ============

  Widget _monthTabs(
      List<MonthlySubscription> subs, String currentUserId) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: subs.length,
        itemBuilder: (ctx, i) {
          final sub = subs[i];
          final isSelected = _selectedMonthIndex == i;
          final isUserIn = sub.hasUser(currentUserId);

          return GestureDetector(
            onTap: () => setState(() => _selectedMonthIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected
                    ? null
                    : AppColors.borderLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : isUserIn
                          ? AppColors.accent.withValues(alpha: 0.3)
                          : AppColors.borderLight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _monthsShort[sub.month],
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isSelected
                          ? Colors.white
                          : isUserIn
                              ? AppColors.accent
                              : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isUserIn) ...[
                        Icon(
                          Icons.check_circle_rounded,
                          size: 10,
                          color: isSelected
                              ? Colors.white
                              : AppColors.accent,
                        ),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        '${sub.subscriberCount}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? AppColors.textSecondary
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddMonthDialog(
      CommunityProvider communityProv, AuthProvider auth, DateTime now) {
    // Generate available months (current + next 6)
    final List<MapEntry<int, int>> futureMonths = [];
    for (int i = 0; i <= 6; i++) {
      int m = now.month + i;
      int y = now.year;
      while (m > 12) {
        m -= 12;
        y++;
      }
      final exists = communityProv.getSubscription(m, y) != null;
      if (!exists) {
        futureMonths.add(MapEntry(m, y));
      }
    }

    if (futureMonths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Все доступные месяцы уже открыты'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.of(context).cardBg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                  color: AppColors.borderLight),
            ),
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
                    color: AppColors.of(context).borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Открыть запись на месяц',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Выберите месяц для открытия абонемента',
                style: TextStyle(
                    color: AppColors.textHint, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: futureMonths.map((entry) {
                  final m = entry.key;
                  final y = entry.value;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showRentInputDialog(
                        communityProv: communityProv,
                        auth: auth,
                        month: m,
                        year: y,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _months[m],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '$y',
                            style: TextStyle(
                              color:
                                  AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
    );
  }

  void _showRentInputDialog({
    required CommunityProvider communityProv,
    required AuthProvider auth,
    required int month,
    required int year,
  }) {
    final community = communityProv.activeCommunity;
    final rentCtrl = TextEditingController(
        text: '${community?.monthlyRent.toInt() ?? 100000}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.of(context).dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.borderLight),
          ),
          title: Text('${_months[month]} $year'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Укажите стоимость аренды на этот месяц',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rentCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: TextStyle(
                    color: AppColors.of(context).textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  suffixText: '₽',
                  suffixStyle: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                  labelText: 'Стоимость аренды',
                  prefixIcon: const Icon(Icons.attach_money,
                      color: AppColors.primary, size: 22),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                final rent = double.tryParse(rentCtrl.text);
                if (rent == null || rent <= 0) return;
                Navigator.pop(ctx);
                final ok =
                    await communityProv.openSubscriptionForMonth(
                  requesterId: auth.uid!,
                  month: month,
                  year: year,
                  totalRent: rent,
                );
                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Запись на ${_months[month]} $year открыта! (${rent.toInt()} ₽)'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Открыть запись',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
    ),
    );
  }

  // ============ STATUS CARD ============

  Widget _activeBadge(DateTime now) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Icon(Icons.verified_rounded,
                color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Абонемент активен',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.accent,
                  ),
                ),
                Text(
                  '${_months[now.month]} ${now.year} — бесплатный вход',
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(MonthlySubscription sub, bool isSignedUp,
      double monthlyRent) {
    final subscriberCount = sub.subscriberCount;
    final hasCompensation = sub.compensationAmount > 0;
    final estimatedPrice = subscriberCount > 0
        ? (sub.effectiveRent / subscriberCount)
        : monthlyRent;
    final originalPrice = subscriberCount > 0
        ? (monthlyRent / subscriberCount)
        : monthlyRent;
    final isCalculated = sub.isCalculated;
    final finalPrice = sub.perPlayerAmount;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSignedUp
                        ? [
                            AppColors.accent.withValues(alpha: 0.3),
                            AppColors.accent.withValues(alpha: 0.1)
                          ]
                        : [
                            AppColors.borderLight,
                            AppColors.of(context).surfaceBg
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isSignedUp
                      ? Icons.card_membership_rounded
                      : Icons.card_membership_outlined,
                  color:
                      isSignedUp ? AppColors.accent : AppColors.textHint,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSignedUp ? 'Вы записаны!' : 'Запись открыта',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSignedUp
                            ? AppColors.accent
                            : AppColors.primaryLight,
                      ),
                    ),
                    Text(
                      '${_months[sub.month]} ${sub.year}',
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: AppColors.borderLight.withValues(alpha: 0.5)),
          const SizedBox(height: 14),
          Row(
            children: [
              _statItem('Записалось', '$subscriberCount чел.',
                  Icons.people_alt_rounded),
              Container(
                  width: 1,
                  height: 36,
                  color: AppColors.borderLight.withValues(alpha: 0.5)),
              _statItem('Аренда', '${monthlyRent.toInt()} ₽',
                  Icons.home_work_rounded),
              Container(
                  width: 1,
                  height: 36,
                  color: AppColors.borderLight.withValues(alpha: 0.5)),
              _statItem(
                isCalculated ? 'Итого' : '~ Оценка',
                '${(isCalculated ? finalPrice : estimatedPrice).toInt()} ₽',
                Icons.calculate_rounded,
                highlight: isCalculated,
              ),
            ],
          ),
          // Блок компенсации
          if (hasCompensation && subscriberCount > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_rounded,
                          color: AppColors.accent, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Компенсация из банка',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        Helpers.formatCurrency(sub.compensationAmount),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Без компенсации: ${originalPrice.toInt()} ₽',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        'С компенсацией: ${estimatedPrice.toInt()} ₽',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (!isCalculated && subscriberCount > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.15)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.warning, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Финальная стоимость рассчитается 25-го числа',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon,
      {bool highlight = false}) {
    final t = AppColors.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon,
              size: 18,
              color: highlight ? AppColors.accent : t.textHint),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: highlight
                  ? AppColors.accent
                  : t.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: t.textHint, fontSize: 10)),
        ],
      ),
    );
  }

  // ============ SUBSCRIBE BUTTON ============

  Widget _subscribeButton(
      {required bool isSubscribed, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isSubscribed
              ? null
              : const LinearGradient(
                  colors: [AppColors.accent, Color(0xFF00B894)]),
          color: isSubscribed
              ? AppColors.error.withValues(alpha: 0.15)
              : null,
          borderRadius: BorderRadius.circular(16),
          border: isSubscribed
              ? Border.all(
                  color: AppColors.error.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSubscribed
                  ? Icons.person_remove_alt_1_rounded
                  : Icons.person_add_alt_1_rounded,
              color: isSubscribed ? AppColors.error : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isSubscribed
                  ? 'Отписаться от абонемента'
                  : 'Записаться на абонемент',
              style: TextStyle(
                color: isSubscribed ? AppColors.error : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ EMPTY STATE ============

  Widget _noOpenSubscription(bool isAdmin) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded,
              size: 48, color: AppColors.of(context).textHint.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const Text(
            'Запись на абонемент не открыта',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            isAdmin
                ? 'Нажмите + в шапке, чтобы открыть запись'
                : 'Ожидайте, пока владелец откроет запись',
            style:
                const TextStyle(color: AppColors.textHint, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _createQuickButton(
      CommunityProvider communityProv, AuthProvider auth, DateTime now) {
    int targetMonth = now.month;
    int targetYear = now.year;

    return GestureDetector(
      onTap: () {
        _showRentInputDialog(
          communityProv: communityProv,
          auth: auth,
          month: targetMonth,
          year: targetYear,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Открыть запись на ${_months[targetMonth]}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ ADMIN COMPENSATION ============

  Widget _adminCompensationSection(
      CommunityProvider communityProv,
      AuthProvider auth,
      MonthlySubscription sub) {
    final bankBalance = communityProv.activeCommunity?.bankBalance ?? 0;
    final maxCompensation = bankBalance.clamp(0, sub.totalRent).toDouble();
    final subscriberCount = sub.subscriberCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.account_balance_rounded,
                color: AppColors.accent, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Компенсация из банка',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Баланс банка: ${Helpers.formatCurrency(bankBalance)}',
          style: const TextStyle(color: AppColors.textHint, fontSize: 12),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: bankBalance > 0
              ? () => _showCompensationDialog(
                    communityProv, auth, sub, bankBalance, maxCompensation)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: bankBalance > 0
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : AppColors.of(context).surfaceBg,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: bankBalance > 0
                    ? AppColors.accent.withValues(alpha: 0.3)
                    : AppColors.borderLight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.savings_rounded,
                    color: bankBalance > 0
                        ? AppColors.accent
                        : AppColors.textHint,
                    size: 20),
                const SizedBox(width: 8),
                Text(
                  sub.compensationAmount > 0
                      ? 'Изменить компенсацию (${Helpers.formatCurrency(sub.compensationAmount)})'
                      : 'Добавить компенсацию из банка',
                  style: TextStyle(
                    color: bankBalance > 0
                        ? AppColors.accent
                        : AppColors.textHint,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (sub.compensationAmount > 0 && subscriberCount > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.accent.withValues(alpha: 0.7),
                    size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Экономия: ${(sub.estimatedPerPlayerWithoutCompensation - sub.estimatedPerPlayerAmount).toInt()} \u20BD на человека',
                    style: TextStyle(
                      color: AppColors.accent.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  void _showCompensationDialog(
      CommunityProvider communityProv,
      AuthProvider auth,
      MonthlySubscription sub,
      double bankBalance,
      double maxCompensation) {
    final controller = TextEditingController(
      text: sub.compensationAmount > 0
          ? sub.compensationAmount.toInt().toString()
          : '',
    );
    double previewAmount = sub.compensationAmount;
    final subscriberCount = sub.subscriberCount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final effectiveRent =
              (sub.totalRent - previewAmount).clamp(0, sub.totalRent);
          final previewPerPlayer = subscriberCount > 0
              ? effectiveRent / subscriberCount
              : 0.0;
          final originalPerPlayer = subscriberCount > 0
              ? sub.totalRent / subscriberCount
              : 0.0;

          return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.of(context).dialogBg.withValues(alpha: 0.97),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(
                        color: AppColors.of(context).borderLight),
                  ),
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
                          color: AppColors.of(context).textHint.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Компенсация из банка',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Доступно: ${Helpers.formatCurrency(bankBalance + sub.compensationAmount)}',
                      style: TextStyle(
                          color: AppColors.of(context).textHint, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // Input
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 20),
                      decoration: InputDecoration(
                        labelText: 'Сумма компенсации (\u20BD)',
                        labelStyle: TextStyle(
                            color: AppColors.of(context).textHint),
                        prefixIcon: const Icon(Icons.savings_rounded,
                            color: AppColors.accent),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(
                              color: AppColors.of(context).borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide:
                              const BorderSide(color: AppColors.accent),
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val) ?? 0;
                        setDialogState(() {
                          previewAmount = parsed.clamp(
                              0, bankBalance + sub.compensationAmount);
                          if (previewAmount > sub.totalRent) {
                            previewAmount = sub.totalRent;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quick amounts
                    Wrap(
                      spacing: 8,
                      children: [10000, 20000, 30000, 50000]
                          .where((a) => a <= bankBalance + sub.compensationAmount && a <= sub.totalRent)
                          .map((amount) => GestureDetector(
                                onTap: () {
                                  controller.text = amount.toString();
                                  setDialogState(() {
                                    previewAmount = amount.toDouble();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: previewAmount == amount
                                        ? AppColors.accent
                                            .withValues(alpha: 0.2)
                                        : AppColors.of(context).chipBg,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: previewAmount == amount
                                          ? AppColors.accent
                                              .withValues(alpha: 0.4)
                                          : AppColors.of(context).borderLight,
                                    ),
                                  ),
                                  child: Text(
                                    Helpers.formatCurrency(amount.toDouble()),
                                    style: TextStyle(
                                      color: previewAmount == amount
                                          ? AppColors.accent
                                          : AppColors.of(context).textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),

                    // Preview
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.of(context).surfaceBg.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: AppColors.of(context).borderLight.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          _previewRow('Аренда',
                              Helpers.formatCurrency(sub.totalRent)),
                          if (previewAmount > 0)
                            _previewRow('Компенсация',
                                '−${Helpers.formatCurrency(previewAmount)}',
                                color: AppColors.accent),
                          Divider(
                              color: AppColors.of(context).borderLight.withValues(alpha: 0.5),
                              height: 16),
                          _previewRow(
                            'Эффективная аренда',
                            Helpers.formatCurrency(effectiveRent.toDouble()),
                            bold: true,
                          ),
                          if (subscriberCount > 0) ...[
                            const SizedBox(height: 4),
                            _previewRow(
                              'На человека ($subscriberCount чел.)',
                              Helpers.formatCurrency(previewPerPlayer),
                              bold: true,
                              color: AppColors.accent,
                            ),
                            if (previewAmount > 0)
                              _previewRow(
                                'Экономия',
                                '${(originalPerPlayer - previewPerPlayer).toInt()} \u20BD',
                                color: AppColors.success,
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirm button
                    GestureDetector(
                      onTap: previewAmount > 0
                          ? () async {
                              Navigator.pop(ctx);
                              final ok =
                                  await communityProv.applyCompensation(
                                requesterId: auth.uid!,
                                amount: previewAmount,
                                month: sub.month,
                                year: sub.year,
                              );
                              if (ok && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Компенсация ${Helpers.formatCurrency(previewAmount)} применена!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } else if (!ok && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Не удалось применить компенсацию'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: previewAmount > 0
                              ? const LinearGradient(
                                  colors: [
                                      AppColors.accent,
                                      Color(0xFF00B894)
                                    ])
                              : null,
                          color: previewAmount > 0
                              ? null
                              : AppColors.of(context).borderLight.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: previewAmount > 0
                                    ? Colors.white
                                    : AppColors.of(context).textHint,
                                size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Применить компенсацию',
                              style: TextStyle(
                                color: previewAmount > 0
                                    ? Colors.white
                                    : AppColors.of(context).textHint,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
          );
        },
      ),
    );
  }

  Widget _previewRow(String label, String value,
      {bool bold = false, Color? color}) {
    final t = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: color ?? t.textSecondary,
                fontSize: 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              )),
          Text(value,
              style: TextStyle(
                color: color ?? t.textPrimary,
                fontSize: 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              )),
        ],
      ),
    );
  }

  // ============ ADMIN SECTION ============

  Widget _adminCalculateSection(CommunityProvider communityProv,
      AuthProvider auth, int month, int year) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Панель администратора',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryLight,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _isCalculating ? null : () async {
            setState(() => _isCalculating = true);
            try {
              await communityProv.calculateSubscription(
                requesterId: auth.uid!,
                month: month,
                year: year,
              );
              // Обновить локальный баланс текущего пользователя
              await auth.refreshBalance();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Стоимость абонемента рассчитана!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка расчёта: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            } finally {
              if (mounted) setState(() => _isCalculating = false);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(100),
            ),
            child: _isCalculating
                ? const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calculate_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Рассчитать стоимость',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
  // ============ ADMIN: DELETE SUBSCRIPTION ============

  Widget _adminDeleteSection(CommunityProvider communityProv,
      AuthProvider auth, MonthlySubscription sub) {
    return GestureDetector(
      onTap: () => _confirmDeleteSubscription(communityProv, auth, sub),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 18),
            SizedBox(width: 8),
            Text(
              'Удалить запись на абонемент',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSubscription(CommunityProvider communityProv,
      AuthProvider auth, MonthlySubscription sub) {
    final subCount = sub.subscriberCount;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.borderLight),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 24),
            SizedBox(width: 10),
            Text('Удалить абонемент'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_months[sub.month]} ${sub.year}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_rounded,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(
                        'Записалось: $subCount чел.',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (subCount > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Все записи участников будут аннулированы!',
                      style: TextStyle(
                        color: AppColors.error.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Это действие нельзя отменить.',
              style: TextStyle(
                  color: AppColors.textHint, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await communityProv.deleteSubscription(
                requesterId: auth.uid!,
                subscriptionId: sub.id,
              );
              if (ok && mounted) {
                setState(() {
                  _selectedMonthIndex = 0;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${_months[sub.month]} ${sub.year} — абонемент удалён'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Удалить',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // ============ SUBSCRIBERS ============

  Widget _subscribersSection(MonthlySubscription sub, bool isAdmin,
      CommunityProvider communityProv, AuthProvider auth) {
    final entries = sub.entries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Записавшиеся',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${entries.length} чел.',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  Icon(Icons.people_outline_rounded,
                      size: 48,
                      color: AppColors.borderLight),
                  const SizedBox(height: 10),
                  const Text('Пока никто не записался',
                      style: TextStyle(
                          color: AppColors.textHint, fontSize: 13)),
                ],
              ),
            ),
          )
        else
          ...entries.asMap().entries.map((e) => _subscriberTile(
                e.value,
                e.key,
                sub.isCalculated,
                isAdmin,
                communityProv,
                auth,
                sub.month,
                sub.year,
              )),
      ],
    );
  }

  Widget _subscriberTile(SubscriptionEntry entry, int index,
      bool isCalculated, bool isAdmin,
      CommunityProvider communityProv, AuthProvider auth,
      int month, int year) {
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (entry.paymentStatus) {
      case SubscriptionPaymentStatus.paid:
        statusColor = AppColors.accent;
        statusLabel = 'Оплачено';
        statusIcon = Icons.check_circle_rounded;
      case SubscriptionPaymentStatus.pending:
        statusColor = AppColors.warning;
        statusLabel = 'Ожидает';
        statusIcon = Icons.schedule_rounded;
      case SubscriptionPaymentStatus.overdue:
        statusColor = AppColors.error;
        statusLabel = 'Просрочен';
        statusIcon = Icons.error_rounded;
      case SubscriptionPaymentStatus.notPaid:
        statusColor = AppColors.textHint;
        statusLabel = isCalculated ? 'Не оплачено' : 'Записан';
        statusIcon = isCalculated
            ? Icons.hourglass_empty_rounded
            : Icons.person_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        borderRadius: 14,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Text('${index + 1}',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.userName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  if (isCalculated && entry.calculatedAmount != null)
                    Text('${entry.calculatedAmount!.toInt()} ₽',
                        style: const TextStyle(
                            color: AppColors.textHint, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (isAdmin &&
                isCalculated &&
                entry.paymentStatus !=
                    SubscriptionPaymentStatus.paid) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () =>
                    _confirmPayment(entry, communityProv, auth, month, year),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Icon(Icons.done_rounded,
                      color: AppColors.accent, size: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmPayment(SubscriptionEntry entry,
      CommunityProvider communityProv, AuthProvider auth,
      int month, int year) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.of(context).dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
                color: AppColors.borderLight),
          ),
          title: const Text('Подтвердить оплату?'),
          content: Text(
              '${entry.userName} — ${entry.calculatedAmount?.toInt() ?? 0} ₽'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok =
                    await communityProv.confirmSubscriptionPayment(
                  requesterId: auth.uid!,
                  targetUserId: entry.userId,
                  month: month,
                  year: year,
                );
                if (ok && mounted) {
                  // Обновить локальный баланс
                  await auth.refreshBalance();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Оплата ${entry.userName} подтверждена'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Подтвердить',
                  style: TextStyle(color: AppColors.accent)),
            ),
          ],
    ),
    );
  }

  // ============ HOW IT WORKS ============

  Widget _howItWorks() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline_rounded,
                  color: AppColors.primaryLight, size: 18),
              SizedBox(width: 8),
              Text('Как это работает?',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.primaryLight)),
            ],
          ),
          const SizedBox(height: 14),
          _stepItem(
              '1', 'Владелец открывает запись на нужные месяцы'),
          _stepItem('2',
              'Игроки выбирают месяц и записываются до 25-го числа'),
          _stepItem('3',
              '25 числа рассчитывается стоимость:\nаренда ÷ количество записавшихся'),
          _stepItem('4',
              'Оплачиваете — и ходите на все события этого месяца бесплатно!'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.error, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Каждый абонемент действует только на свой месяц. Апрельский абонемент не даёт бесплатный вход в мае.',
                    style: TextStyle(
                        color: AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(number,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}
