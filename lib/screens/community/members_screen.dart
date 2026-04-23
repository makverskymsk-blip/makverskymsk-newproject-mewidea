import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/community.dart';
import '../../models/enums.dart';
import '../../models/sport_match.dart';
import '../../models/subscription.dart';

import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/matches_provider.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_viewer.dart';
import '../profile/public_profile_screen.dart';


class MembersScreen extends StatefulWidget {
  final int initialTab;
  const MembersScreen({super.key, this.initialTab = 0});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseService _db = SupabaseService();
  List<UserProfile> _members = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _loadMembers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final communityProv = context.read<CommunityProvider>();
    final community = communityProv.activeCommunity;
    if (community == null) return;

    // Загружаем участников
    final users = await _db.getUsersByIds(community.allMemberIds);
    // Загружаем подписки
    await communityProv.loadSubscriptions(community.id);

    if (mounted) {
      setState(() {
        _members = users;
        _isLoading = false;
      });
    }
  }

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
    final isOwner = community.isOwner(currentUserId);
    final isAdmin = community.isAdmin(currentUserId);

    // Members with negative balance (for second tab)
    final debtors = _members.where((u) => u.balance < 0).toList()
      ..sort((a, b) => a.balance.compareTo(b.balance));

    return Scaffold(
      body: Stack(
        children: [
          // Background
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
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppColors.of(context).borderLight),
                          ),
                          child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.of(context).textPrimary,
                              size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Участники',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${community.name} • ${community.totalMembers} чел.',
                              style: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Tab Bar ──
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.of(context).cardBg.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFFB800)],
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.of(context).textSecondary,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    padding: const EdgeInsets.all(3),
                    tabs: [
                      const Tab(
                        height: 38,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_rounded, size: 16),
                            SizedBox(width: 6),
                            Text('Все'),
                          ],
                        ),
                      ),
                      Tab(
                        height: 38,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.payments_rounded, size: 16),
                            const SizedBox(width: 6),
                            const Text('Оплата'),
                            if (debtors.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  '${debtors.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Tab Views ──
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            // ── Tab 1: Все участники ──
                            _buildAllMembersTab(
                              community,
                              currentUserId,
                              isOwner,
                              isAdmin,
                              communityProv,
                              auth,
                            ),
                            // ── Tab 2: Ожидают оплаты ──
                            _buildDebtorsTab(
                              debtors,
                              community,
                              currentUserId,
                              isOwner,
                              isAdmin,
                              communityProv,
                              auth,
                            ),
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

  // ── Tab 1: All members ──
  Widget _buildAllMembersTab(
    Community community,
    String currentUserId,
    bool isOwner,
    bool isAdmin,
    CommunityProvider communityProv,
    AuthProvider auth,
  ) {
    return RefreshIndicator(
      onRefresh: _loadMembers,
      color: AppColors.primary,
      child: Column(
        children: [
          // Role legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _roleBadge('Владелец', AppColors.primaryLight),
                const SizedBox(width: 8),
                _roleBadge('Админ', AppColors.primary),
                const SizedBox(width: 8),
                _roleBadge('Игрок', AppColors.textHint),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Builder(builder: (ctx) {
              final sorted = List<UserProfile>.from(_members)
                ..sort((a, b) {
                  final aSubs = communityProv.subscriptions.any(
                      (s) => s.communityId == community.id && s.hasUser(a.id));
                  final bSubs = communityProv.subscriptions.any(
                      (s) => s.communityId == community.id && s.hasUser(b.id));
                  if (aSubs != bSubs) return aSubs ? -1 : 1;
                  final aRole = community.getUserRole(a.id).index;
                  final bRole = community.getUserRole(b.id).index;
                  return aRole.compareTo(bRole);
                });
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: sorted.length,
                itemBuilder: (ctx, i) => _memberTile(
                  sorted[i],
                  community,
                  currentUserId,
                  isOwner,
                  isAdmin,
                  communityProv,
                  auth,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Debtors ──
  Widget _buildDebtorsTab(
    List<UserProfile> debtors,
    Community community,
    String currentUserId,
    bool isOwner,
    bool isAdmin,
    CommunityProvider communityProv,
    AuthProvider auth,
  ) {
    // Collect unpaid subscription entries across all subscriptions
    final unpaidSubEntries = <({MonthlySubscription sub, SubscriptionEntry entry})>[];
    for (final sub in communityProv.subscriptions) {
      if (sub.communityId != community.id || !sub.isCalculated) continue;
      for (final entry in sub.entries) {
        if (entry.paymentStatus != SubscriptionPaymentStatus.paid) {
          unpaidSubEntries.add((sub: sub, entry: entry));
        }
      }
    }

    // Get all community matches for cross-referencing
    final matchesProv = context.read<MatchesProvider>();
    final allMatches = [...matchesProv.matches, ...matchesProv.completedEvents];

    final hasDebtors = debtors.isNotEmpty;
    final hasUnpaidSubs = unpaidSubEntries.isNotEmpty;

    if (!hasDebtors && !hasUnpaidSubs) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.08),
                border:
                    Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
              ),
              child: Icon(Icons.check_circle_outline_rounded,
                  size: 48, color: AppColors.accent.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Все оплачено!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Нет участников с задолженностью',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // ── Subscription section ──
          if (hasUnpaidSubs) ...[
            _sectionHeader(
              icon: Icons.card_membership_rounded,
              title: 'Абонемент',
              color: AppColors.warning,
              count: unpaidSubEntries.length,
            ),
            const SizedBox(height: 8),
            ...unpaidSubEntries.map((record) => _subscriptionPaymentCard(
              record.sub,
              record.entry,
              isOwner,
              isAdmin,
              communityProv,
              auth,
            )),
            if (hasDebtors) const SizedBox(height: 16),
          ],

          // ── Events section ──
          if (hasDebtors) ...[
            _sectionHeader(
              icon: Icons.sports_rounded,
              title: 'За события',
              color: const Color(0xFFFF4D4D),
              count: debtors.length,
            ),
            const SizedBox(height: 8),
            ...debtors.map((user) => _debtorCard(
              user,
              community,
              isOwner,
              isAdmin,
              communityProv,
              auth,
              allMatches,
            )),
          ],
        ],
      ),
    );
  }

  /// Section header for payment tab
  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required Color color,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Subscription payment card (separate line, NOT going to bank)
  Widget _subscriptionPaymentCard(
    MonthlySubscription sub,
    SubscriptionEntry entry,
    bool isOwner,
    bool isAdmin,
    CommunityProvider communityProv,
    AuthProvider auth,
  ) {
    final amount = entry.calculatedAmount ?? sub.perPlayerAmount;
    const months = [
      '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
    ];
    final monthName = months[sub.month];
    final statusColor = entry.paymentStatus == SubscriptionPaymentStatus.overdue
        ? AppColors.error
        : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: statusColor.withValues(alpha: 0.04),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar / initial
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: 0.2),
                  statusColor.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(
                  color: statusColor.withValues(alpha: 0.3), width: 1),
            ),
            child: Center(
              child: Text(
                entry.userName.isNotEmpty
                    ? entry.userName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + month
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.userName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.of(context).textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.card_membership_rounded,
                        size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      '$monthName ${sub.year}',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '${amount.toInt()} ₽',
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Confirm button
          if (isOwner || isAdmin)
            GestureDetector(
              onTap: () => _confirmSubPayment(
                  sub, entry, communityProv, auth),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E676), Color(0xFF00C853)],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color:
                          const Color(0xFF00E676).withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded,
                        size: 14, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      'Оплачено',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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

  /// Confirm subscription payment dialog (no bank deposit)
  void _confirmSubPayment(
    MonthlySubscription sub,
    SubscriptionEntry entry,
    CommunityProvider communityProv,
    AuthProvider auth,
  ) {
    final amount = entry.calculatedAmount ?? sub.perPlayerAmount;
    const months = [
      '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
    ];
    final monthName = months[sub.month];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.of(context).dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.borderLight),
          ),
          title: const Text('Подтвердить оплату абонемента'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.userName,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.of(context).surfaceBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.borderLight.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.card_membership_rounded,
                            size: 18, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Абонемент — $monthName ${sub.year}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Сумма',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                        Text('${amount.toInt()} ₽',
                            style: const TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14, color: AppColors.primary),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Абонемент не зачисляется в банк сообщества',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
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
                Navigator.pop(ctx);
                final ok =
                    await communityProv.confirmSubscriptionPayment(
                  requesterId: auth.uid!,
                  targetUserId: entry.userId,
                  month: sub.month,
                  year: sub.year,
                );
                if (ok) {
                  await auth.refreshBalance();
                  await _loadMembers();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${entry.userName} — абонемент $monthName оплачен'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
              child: const Text('Подтвердить',
                  style: TextStyle(color: AppColors.success)),
            ),
          ],
      ),
    );
  }

  /// Card for each debtor showing their events
  Widget _debtorCard(
    UserProfile user,
    Community community,
    bool isOwner,
    bool isAdmin,
    CommunityProvider communityProv,
    AuthProvider auth,
    List<SportMatch> allMatches,
  ) {
    final debtAmount = user.balance.abs();
    const warningRed = Color(0xFFFF4D4D);

    // Find events this user is registered for in this community
    final userEvents = allMatches
        .where((m) =>
            m.communityId == community.id &&
            m.registeredPlayerIds.contains(user.id) &&
            m.price > 0)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: warningRed.withValues(alpha: 0.04),
        border: Border.all(
          color: warningRed.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // ── Header: avatar + name + total debt ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                // Avatar
                GestureDetector(
                  onTap: () {
                    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
                      openAvatarViewer(
                        context,
                        avatarUrl: user.avatarUrl!,
                        heroTag: 'debtor_avatar_${user.id}',
                        userName: user.name,
                      );
                    }
                  },
                  child: Hero(
                    tag: 'debtor_avatar_${user.id}',
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            warningRed.withValues(alpha: 0.25),
                            warningRed.withValues(alpha: 0.08),
                          ],
                        ),
                        border: Border.all(
                            color: warningRed.withValues(alpha: 0.35),
                            width: 1.5),
                      ),
                      child: user.avatarUrl != null &&
                              user.avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                user.avatarUrl!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                        color: warningRed,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                    color: warningRed,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + total debt
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.of(context).textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.trending_down_rounded,
                              size: 13, color: warningRed),
                          const SizedBox(width: 3),
                          Text(
                            'Долг: −${debtAmount.toInt()} ₽',
                            style: TextStyle(
                              color: warningRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Settle ALL button (secondary)
                if (isOwner || isAdmin)
                  GestureDetector(
                    onTap: () => _confirmSettleAll(user, communityProv, auth),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color:
                                const Color(0xFF00E676).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.done_all_rounded,
                              size: 14, color: Color(0xFF00E676)),
                          SizedBox(width: 4),
                          Text(
                            'Всё',
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Events list ──
          if (userEvents.isNotEmpty) ...[
            Container(
              height: 0.5,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: warningRed.withValues(alpha: 0.12),
            ),
            ...userEvents.map((match) => _eventPaymentTile(
                  match, user, isOwner, isAdmin, communityProv, auth)),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'Нет привязанных событий',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Individual event payment tile inside debtor card
  Widget _eventPaymentTile(
    SportMatch match,
    UserProfile user,
    bool isOwner,
    bool isAdmin,
    CommunityProvider communityProv,
    AuthProvider auth,
  ) {
    final isPast = match.dateTime.isBefore(DateTime.now());
    final dateStr = _formatEventDate(match.dateTime);
    final sportIcon = match.category.icon;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // Sport icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: (isPast
                      ? AppColors.primary
                      : AppColors.textHint)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(sportIcon,
                size: 16,
                color: isPast ? AppColors.primary : AppColors.textHint),
          ),
          const SizedBox(width: 10),

          // Event details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.format,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.of(context).textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isPast
                            ? AppColors.textSecondary
                            : AppColors.textHint,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isPast)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'Предстоит',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Price
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4D4D).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '${match.price.toInt()} ₽',
              style: const TextStyle(
                color: Color(0xFFFF4D4D),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Pay button
          if (isOwner || isAdmin)
            GestureDetector(
              onTap: () => _confirmSettleEvent(
                match, user, communityProv, auth),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E676), Color(0xFF00C853)],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded,
                        size: 14, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      'Оплачено',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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

  String _formatEventDate(DateTime dt) {
    const months = [
      '', 'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} $h:$m';
  }

  /// Confirm per-event payment
  void _confirmSettleEvent(
    SportMatch match,
    UserProfile user,
    CommunityProvider communityProv,
    AuthProvider auth,
  ) {
    final dateStr = _formatEventDate(match.dateTime);
    final amount = match.price;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.of(context).dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.borderLight),
          ),
          title: const Text('Подтвердить оплату'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.of(context).surfaceBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.borderLight.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(match.category.icon,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            match.format,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dateStr,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                        Text('${amount.toInt()} ₽',
                            style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 1,
                      color: AppColors.borderLight.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('В банк сообщества',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                        Text('+${amount.toInt()} ₽',
                            style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Баланс участника будет увеличен на ${amount.toInt()} ₽',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
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
                Navigator.pop(ctx);
                final ok = await communityProv.settleEventPayment(
                  requesterId: auth.uid!,
                  targetUserId: user.id,
                  amount: amount,
                  eventDescription: '${match.format} ($dateStr)',
                );
                if (ok) {
                  setState(() {
                    user.balance += amount;
                  });
                  if (user.id == auth.uid) {
                    await auth.refreshBalance();
                  }
                  await _loadMembers();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${user.name} — оплата за ${match.format} подтверждена (+${amount.toInt()} ₽)'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
              child: const Text('Подтвердить',
                  style: TextStyle(color: AppColors.success)),
            ),
          ],
      ),
    );
  }

  /// Confirm settle ALL (legacy — обнулить весь долг)
  void _confirmSettleAll(
    UserProfile user,
    CommunityProvider communityProv,
    AuthProvider auth,
  ) {
    final debtAmount = user.balance.abs();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.of(context).dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.borderLight),
          ),
          title: const Text('Рассчитать всё?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.of(context).surfaceBg,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: AppColors.borderLight.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Весь долг',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                        Text('${debtAmount.toInt()} ₽',
                            style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 1,
                      color: AppColors.borderLight.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('В банк сообщества',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                        Text('+${debtAmount.toInt()} ₽',
                            style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Баланс будет обнулён, вся сумма зачислена в кассу.',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
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
                Navigator.pop(ctx);
                final ok = await communityProv.settleUserBalance(
                  requesterId: auth.uid!,
                  targetUserId: user.id,
                  currentBalance: user.balance,
                );
                if (ok) {
                  setState(() {
                    user.balance = 0;
                  });
                  if (user.id == auth.uid) {
                    await auth.refreshBalance();
                  }
                  await _loadMembers();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${user.name} — полный расчёт (+${debtAmount.toInt()} ₽ в банк)'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
              child: const Text('Рассчитать всё',
                  style: TextStyle(color: AppColors.success)),
            ),
          ],
      ),
    );
  }

  Widget _roleBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _memberTile(
    UserProfile user,
    Community community,
    String currentUserId,
    bool isOwner,
    bool isAdmin,
    CommunityProvider communityProv,
    AuthProvider auth,
  ) {
    final role = community.getUserRole(user.id);
    final Color roleColor;
    final String roleLabel;
    final IconData roleIcon;

    switch (role) {
      case UserRole.owner:
        roleColor = AppColors.primaryLight;
        roleLabel = 'Владелец';
        roleIcon = Icons.star_rounded;
        break;
      case UserRole.admin:
        roleColor = AppColors.primary;
        roleLabel = 'Админ';
        roleIcon = Icons.shield_rounded;
        break;
      case UserRole.player:
        roleColor = AppColors.textHint;
        roleLabel = 'Игрок';
        roleIcon = Icons.person_rounded;
        break;
    }

    // Собираем абонементы пользователя
    final userSubs = communityProv.subscriptions
        .where((s) =>
            s.communityId == community.id && s.hasUser(user.id))
        .toList()
      ..sort((a, b) {
        final cmp = a.year.compareTo(b.year);
        return cmp != 0 ? cmp : a.month.compareTo(b.month);
      });

    final hasSubscription = userSubs.isNotEmpty;
    final isUserOwner = role == UserRole.owner;



    final t = AppColors.of(context);
    // Paid player highlight
    final paidBg = hasSubscription
        ? const Color(0xFF22C55E).withValues(alpha: 0.08)
        : t.cardBg;
    final paidBorder = hasSubscription
        ? const Color(0xFF22C55E).withValues(alpha: 0.2)
        : t.borderLight;

    return GestureDetector(
      onTap: () {
        // Don't navigate to own profile
        if (user.id != currentUserId) {
          Navigator.push(context,
            MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: user.id)));
        }
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: paidBg,
        border: Border.all(color: paidBorder, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            // Avatar (compact 36px)
            GestureDetector(
              onTap: () {
                if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
                  openAvatarViewer(
                    context,
                    avatarUrl: user.avatarUrl!,
                    heroTag: 'member_avatar_${user.id}',
                    userName: user.name,
                  );
                }
              },
              child: Hero(
                tag: 'member_avatar_${user.id}',
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: roleColor.withValues(alpha: 0.1),
                    border: Border.all(
                      color: roleColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            user.avatarUrl!,
                            width: 36, height: 36, fit: BoxFit.cover,
                            errorBuilder: (c2, e2, st2) => Center(
                              child: Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: TextStyle(color: roleColor, fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: TextStyle(color: roleColor, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Name + role/status row
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name row
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: t.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUserOwner) ...[
                        const SizedBox(width: 3),
                        const Icon(Icons.star_rounded,
                          size: 12, color: Color(0xFFFFB800)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Badges row
                  Row(
                    children: [
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: roleColor.withValues(alpha: 0.35), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(roleIcon, size: 9, color: roleColor),
                            const SizedBox(width: 3),
                            Text(roleLabel,
                              style: TextStyle(
                                color: roleColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasSubscription) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.35), width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded,
                                  size: 9, color: Color(0xFF22C55E)),
                              SizedBox(width: 3),
                              Text('Активен',
                                style: TextStyle(
                                  color: Color(0xFF22C55E),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Subscription month chips inline
                      if (userSubs.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.calendar_month_rounded,
                            size: 10, color: AppColors.textHint),
                        const SizedBox(width: 3),
                        ...userSubs.take(3).map((sub) {
                          final now = DateTime.now();
                          final isCurrent =
                              sub.month == now.month && sub.year == now.year;
                          return Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: isCurrent
                                      ? AppColors.accent.withValues(alpha: 0.35)
                                      : AppColors.borderLight,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '${_monthShort(sub.month)} ${sub.year % 100}',
                                style: TextStyle(
                                  color: isCurrent
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Balance
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                '${user.balance.toInt()} \u20BD',
                style: TextStyle(
                  color: user.balance >= 0
                      ? AppColors.textSecondary
                      : AppColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Action menu
            if (isOwner || isAdmin)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: t.textHint, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                color: t.dialogBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                  side: BorderSide(color: t.borderLight),
                ),
                itemBuilder: (ctx) => [
                  if (isAdmin || isOwner) ...[
                    const PopupMenuItem(
                      value: 'topup',
                      child: Row(children: [
                        Icon(Icons.add_circle_outline_rounded,
                            color: AppColors.accent, size: 18),
                        SizedBox(width: 8),
                        Text('Пополнить баланс'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'deduct',
                      child: Row(children: [
                        Icon(Icons.remove_circle_outline_rounded,
                            color: AppColors.error, size: 18),
                        SizedBox(width: 8),
                        Text('Списать средства'),
                      ]),
                    ),
                  ],
                  if (isOwner && user.id != currentUserId) ...[
                    PopupMenuItem(
                      value: role == UserRole.admin ? 'demote' : 'promote',
                      child: Row(children: [
                        Icon(
                          role == UserRole.admin
                              ? Icons.person_remove_alt_1_rounded
                              : Icons.admin_panel_settings_rounded,
                          color: role == UserRole.admin
                              ? AppColors.warning
                              : AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(role == UserRole.admin
                            ? 'Снять админа'
                            : 'Назначить админом'),
                      ]),
                    ),
                  ],
                  // Kick member (admin/owner, not self, not owner)
                  if ((isOwner || isAdmin) && user.id != currentUserId && role != UserRole.owner)
                    const PopupMenuItem(
                      value: 'kick',
                      child: Row(children: [
                        Icon(Icons.person_off_rounded,
                            color: AppColors.error, size: 18),
                        SizedBox(width: 8),
                        Text('Исключить', style: TextStyle(color: AppColors.error)),
                      ]),
                    ),
                ],
                onSelected: (value) => _onMenuAction(
                  value, user, communityProv, auth,
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  static String _monthShort(int month) {
    const m = [
      '', 'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн',
      'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек',
    ];
    return m[month];
  }

  void _onMenuAction(
    String action,
    UserProfile user,
    CommunityProvider communityProv,
    AuthProvider auth,
  ) {
    switch (action) {
      case 'topup':
        _showBalanceDialog(
          title: 'Пополнение баланса',
          subtitle: user.name,
          color: AppColors.accent,
          onConfirm: (amount) async {
            final ok = await communityProv.topUpUserBalance(
              requesterId: auth.uid!,
              targetUserId: user.id,
              amount: amount,
            );
            if (ok) {
              // Update local display
              user.balance += amount;
              if (user.id == auth.uid) {
                await auth.updateBalance(amount);
              }
              _loadMembers();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Баланс ${user.name} пополнен на ${amount.toInt()} ₽'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            }
          },
        );
        break;
      case 'deduct':
        _showBalanceDialog(
          title: 'Списание средств',
          subtitle: user.name,
          color: AppColors.error,
          onConfirm: (amount) async {
            final ok = await communityProv.deductUserBalance(
              requesterId: auth.uid!,
              targetUserId: user.id,
              amount: amount,
            );
            if (ok) {
              user.balance -= amount;
              if (user.id == auth.uid) {
                await auth.updateBalance(-amount);
              }
              _loadMembers();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'С баланса ${user.name} списано ${amount.toInt()} ₽'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            }
          },
        );
        break;
      case 'promote':
        _confirmAction(
          'Назначить администратором?',
          '${user.name} получит права на управление балансом участников.',
          () async {
            final ok = await communityProv.promoteToAdmin(
              requesterId: auth.uid!,
              targetUserId: user.id,
            );
            if (ok) {
              _loadMembers();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('${user.name} теперь администратор'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            }
          },
        );
        break;
      case 'demote':
        _confirmAction(
          'Снять администратора?',
          '${user.name} потеряет права на управление балансом.',
          () async {
            final ok = await communityProv.demoteFromAdmin(
              requesterId: auth.uid!,
              targetUserId: user.id,
            );
            if (ok) {
              _loadMembers();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${user.name} больше не администратор'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            }
          },
        );
        break;
      case 'kick':
        _confirmAction(
          'Исключить участника?',
          '${user.name} будет удалён из сообщества.',
          () async {
            try {
              final community = context.read<CommunityProvider>().activeCommunity;
              if (community == null) return;
              await communityProv.kickMember(community.id, user.id);
              setState(() {
                _members.removeWhere((m) => m.id == user.id);
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${user.name} исключён из сообщества'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
        );
        break;
    }
  }

  void _showBalanceDialog({
    required String title,
    required String subtitle,
    required Color color,
    required Function(double) onConfirm,
  }) {
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.of(context).dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
                color: AppColors.borderLight),
          ),
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: TextStyle(
                    color: AppColors.of(context).textPrimary, fontSize: 22),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                      color: AppColors.of(context).textHint),
                  suffixText: '₽',
                  suffixStyle: TextStyle(
                      color: color, fontWeight: FontWeight.w700),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: BorderSide(
                        color:
                            AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: BorderSide(color: color),
                  ),
                  filled: true,
                  fillColor:
                      AppColors.of(context).surfaceBg,
                ),
              ),
              const SizedBox(height: 12),
              // Quick buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [500, 1000, 2000, 5000]
                    .map((v) => GestureDetector(
                          onTap: () =>
                              amountCtrl.text = v.toString(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(8),
                              border: Border.all(
                                  color: color
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              '$v',
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                final amount =
                    double.tryParse(amountCtrl.text);
                if (amount == null || amount <= 0) return;
                Navigator.pop(ctx);
                onConfirm(amount);
              },
              child: Text('Подтвердить',
                  style: TextStyle(color: color)),
            ),
          ],
    ),
    );
  }

  void _confirmAction(
      String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.of(context).dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
                color: AppColors.borderLight),
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm();
              },
              child: const Text('Да',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
    ),
    );
  }
}
