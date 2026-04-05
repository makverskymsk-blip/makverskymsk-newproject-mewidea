import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/community.dart';
import '../../models/enums.dart';

import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';


class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

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
    _tabController = TabController(length: 2, vsync: this);
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
                            color: AppColors.borderLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
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
                  decoration: BoxDecoration(
                    color: AppColors.of(context).cardBg.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.of(context).borderLight.withValues(alpha: 0.5)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFFB800)],
                      ),
                      borderRadius: BorderRadius.circular(12),
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
                                  borderRadius: BorderRadius.circular(10),
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
    if (debtors.isEmpty) {
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
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: debtors.length,
        itemBuilder: (ctx, i) => _debtorTile(
          debtors[i],
          community,
          isOwner,
          isAdmin,
          communityProv,
          auth,
        ),
      ),
    );
  }

  // ── Debtor tile with settle button ──
  Widget _debtorTile(
    UserProfile user,
    Community community,
    bool isOwner,
    bool isAdmin,
    CommunityProvider communityProv,
    AuthProvider auth,
  ) {
    final debtAmount = user.balance.abs();
    const warningRed = Color(0xFFFF4D4D);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: warningRed.withValues(alpha: 0.05),
        border: Border.all(
          color: warningRed.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: warningRed.withValues(alpha: 0.06),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    warningRed.withValues(alpha: 0.3),
                    warningRed.withValues(alpha: 0.1),
                  ],
                ),
                border:
                    Border.all(color: warningRed.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: warningRed,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name + debt
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.of(context).textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.trending_down_rounded,
                          size: 14, color: warningRed),
                      const SizedBox(width: 4),
                      Text(
                        '−${debtAmount.toInt()} ₽',
                        style: TextStyle(
                          color: warningRed,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Settle button
            if (isOwner || isAdmin)
              GestureDetector(
                onTap: () => _confirmSettle(user, communityProv, auth),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E676), Color(0xFF00C853)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E676).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet_rounded,
                          size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Settle',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmSettle(
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
          title: const Text('Подтвердить расчёт'),
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
                  color: AppColors.backgroundCard.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.borderLight.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Долг участника',
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
                'Баланс участника будет обнулён, а сумма зачислена в кассу.',
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
                  user.balance = 0;
                  if (user.id == auth.uid) {
                    await auth.updateBalance(user.balance.abs());
                  }
                  _loadMembers();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${user.name} — расчёт завершён (+${debtAmount.toInt()} ₽ в банк)'),
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

  Widget _roleBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: paidBg,
        border: Border.all(color: paidBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: roleColor.withValues(alpha: 0.1),
                    border: Border.all(
                      color: roleColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: t.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUserOwner) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.star_rounded,
                              size: 14, color: Color(0xFFFFB800)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Role badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: roleColor.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(roleIcon, size: 10, color: roleColor),
                                const SizedBox(width: 3),
                                Text(roleLabel,
                                  style: TextStyle(
                                    color: roleColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasSubscription) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: const Color(0xFF22C55E).withValues(alpha: 0.2)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded,
                                      size: 10, color: Color(0xFF22C55E)),
                                  SizedBox(width: 3),
                                  Text('Активен',
                                    style: TextStyle(
                                      color: Color(0xFF22C55E),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            '${user.balance.toInt()} \u20BD',
                            style: TextStyle(
                              color: user.balance >= 0
                                  ? AppColors.textSecondary
                                  : AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action menu
                if (isOwner || isAdmin)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded,
                        color: t.textHint, size: 20),
                    color: t.dialogBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                    ],
                    onSelected: (value) => _onMenuAction(
                      value, user, communityProv, auth,
                    ),
                  ),
              ],
            ),

            // Subscription months
            if (userSubs.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(height: 1, color: AppColors.borderLight.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      size: 13, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: userSubs.map((sub) {
                        final now = DateTime.now();
                        final isCurrent =
                            sub.month == now.month && sub.year == now.year;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.accent.withValues(alpha: 0.08)
                                : Colors.grey.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.accent.withValues(alpha: 0.25)
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Text(
                            '${_monthShort(sub.month)} ${sub.year % 100}',
                            style: TextStyle(
                              color: isCurrent
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ],
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
                style: const TextStyle(
                    color: Colors.white, fontSize: 22),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                      color: Colors.black.withValues(alpha: 0.1)),
                  suffixText: '₽',
                  suffixStyle: TextStyle(
                      color: color, fontWeight: FontWeight.w700),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color:
                            AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: color),
                  ),
                  filled: true,
                  fillColor:
                      AppColors.backgroundCard.withValues(alpha: 0.6),
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
