import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_card.dart';
import 'members_screen.dart';
import 'subscription_screen.dart';
import 'community_chat_screen.dart';
import 'community_directory_screen.dart';
import '../../widgets/avatar_viewer.dart';

class CommunityManageScreen extends StatefulWidget {
  const CommunityManageScreen({super.key});

  @override
  State<CommunityManageScreen> createState() => _CommunityManageScreenState();
}

class _CommunityManageScreenState extends State<CommunityManageScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final communityProv = context.watch<CommunityProvider>();
    final communities = communityProv.communities;
    final active = communityProv.activeCommunity;

    return Scaffold(
      body: Stack(
        children: [
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
                            color: AppColors.of(context).borderLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Мои сообщества',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
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
                        // Active communities
                        if (communities.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 60),
                              child: Column(
                                children: [
                                  Icon(Icons.groups_outlined,
                                      size: 80,
                                      color:
                                          AppColors.borderLight),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Вы не состоите ни в одном сообществе',
                                    style:
                                        TextStyle(color: AppColors.of(context).textHint),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...communities.map((c) => _communityTile(
                                c.name,
                                c.sport.displayName,
                                'Код: ${c.inviteCode} • ${c.totalMembers} уч.',
                                inviteCode: c.inviteCode,
                                isActive: c.id == active?.id,
                                isOwner: c.ownerId == auth.uid,
                                logoUrl: c.logoUrl,
                                communityId: c.id,
                                onTap: () {
                                  communityProv.setActiveCommunity(c);
                                  Navigator.pop(context);
                                },
                                onLeave: () =>
                                    _confirmLeave(context, c.id, c.name,
                                        c.ownerId == auth.uid, auth, communityProv),
                              )),

                        // Bank card + members (only if active community exists)
                        if (active != null) ...[
                          // Bank card for admins
                          if (active.isAdmin(auth.uid ?? '')) ...[
                            const SizedBox(height: 16),
                            _buildBankCard(active.bankBalance, communityProv, auth),
                          ],

                          const SizedBox(height: 20),

                          // ── Horizontal tab bar ──
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _tabChip(Icons.people_alt_rounded, 'Участники',
                                    () => Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => const MembersScreen()))),
                                const SizedBox(width: 10),
                                _tabChip(Icons.chat_rounded, 'Чат',
                                    () => Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => const CommunityChatScreen()))),
                                // Join requests tab (admin only)
                                if (active.isAdmin(auth.uid ?? ''))
                                  _tabChipWithBadge(
                                    Icons.person_add_alt_1_rounded,
                                    'Запросы',
                                    communityProv.pendingRequestCount,
                                    () => Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => const CommunityDirectoryScreen())),
                                  ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(IconData icon, String title, VoidCallback onTap) {
    final t = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: t.cardBg,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: t.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: t.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: t.borderLight, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _tabChipWithBadge(IconData icon, String title, int count, VoidCallback onTap) {
    final t = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: count > 0
              ? AppColors.primary.withValues(alpha: 0.08)
              : t.cardBg,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: count > 0
                ? AppColors.primary.withValues(alpha: 0.4)
                : t.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: count > 0 ? AppColors.primary : t.textSecondary,
                size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    color: count > 0 ? AppColors.primary : t.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: t.borderLight, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  Widget _communityTile(
    String name,
    String sport,
    String subtitle, {
    required String inviteCode,
    required bool isActive,
    required bool isOwner,
    required VoidCallback onTap,
    required VoidCallback onLeave,
    String? logoUrl,
    required String communityId,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.of(context).cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.of(context).borderLight.withValues(alpha: 0.5),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo / avatar
            GestureDetector(
              onTap: () {
                if (logoUrl != null && logoUrl.isNotEmpty) {
                  openAvatarViewer(
                    context,
                    avatarUrl: logoUrl,
                    heroTag: 'community_logo_$communityId',
                    userName: name,
                    onUpload: isOwner ? () => _pickAndUploadLogo(communityId) : null,
                  );
                } else if (isOwner) {
                  _pickAndUploadLogo(communityId);
                }
              },
              child: Hero(
                tag: 'community_logo_$communityId',
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.of(context).borderLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: logoUrl != null && logoUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.network(
                            logoUrl,
                            width: 48, height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.groups_rounded,
                              color: isActive ? AppColors.primary : AppColors.of(context).textHint,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.groups_rounded,
                          color: isActive ? AppColors.primary : AppColors.of(context).textHint,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1),
                          ),
                          child: const Text('Активно',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3)),
                        ),
                      if (isOwner) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.35), width: 1),
                          ),
                          child: const Text('Владелец',
                              style: TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$sport • $subtitle',
                          style: TextStyle(
                              color: AppColors.of(context).textHint, fontSize: 12),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _shareInviteLink(context, inviteCode),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.35), width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.share_rounded,
                                  color: AppColors.accent, size: 10),
                              SizedBox(width: 4),
                              Text('Поделиться',
                                  style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onLeave,
              child: Icon(Icons.exit_to_app_rounded,
                  color: AppColors.error.withValues(alpha: 0.5), size: 22),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _pickAndUploadLogo(String communityId) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 80);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last.toLowerCase();
      final validExt = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Загрузка логотипа...'), duration: Duration(seconds: 2)),
      );

      final prov = context.read<CommunityProvider>();
      final ok = await prov.uploadLogo(communityId, bytes, validExt);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Логотип обновлён!' : 'Ошибка загрузки'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('LOGO PICK ERROR: $e');
    }
  }

  void _confirmLeave(
    BuildContext context,
    String communityId,
    String communityName,
    bool isOwner,
    AuthProvider auth,
    CommunityProvider communityProv,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.of(context).dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.borderLight),
          ),
          title: const Text('Выйти из сообщества?'),
          content: Text(
            isOwner
                ? 'Вы владелец «$communityName». Если вы выйдете, сообщество останется без владельца.'
                : 'Вы уверены, что хотите покинуть «$communityName»?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await communityProv.leaveCommunity(communityId, auth.uid!);
                  auth.currentUser!.communityIds.remove(communityId);
                  if (context.mounted) {
                    if (auth.currentUser!.communityIds.isEmpty) {
                      // No communities left, go to hub
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Вы покинули сообщество'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка при выходе: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Выйти',
                  style: TextStyle(color: AppColors.error)),
            ),
          ],
    ),
    );
  }

  void _showCreateDialog(
    BuildContext context,
    AuthProvider auth,
    CommunityProvider communityProv,
  ) {
    final nameCtrl = TextEditingController();


    SportCategory sport = SportCategory.football;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDState) => AlertDialog(
            backgroundColor: AppColors.of(context).dialogBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: AppColors.borderLight),
            ),
            title: const Text('Новое сообщество'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(nameCtrl, 'Название', Icons.group_rounded),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SportCategory>(
                    dropdownColor: Colors.white,
                    initialValue: sport,
                    decoration: _dropdownDecor('Вид спорта'),
                    items: SportCategory.values
                        .map((c) => DropdownMenuItem(
                            value: c, child: Text(c.displayName)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDState(() => sport = v);
                    },
                  ),


                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  await communityProv.createCommunityFirestore(
                    name: nameCtrl.text.trim(),
                    sport: sport,
                    ownerId: auth.uid!,

                  );
                  await auth
                      .addCommunityToUser(communityProv.activeCommunity!.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Сообщество создано!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: const Text('Создать',
                    style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
      ),
    );
  }

  void _showJoinDialog(
    BuildContext context,
    AuthProvider auth,
    CommunityProvider communityProv,
  ) {
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.of(context).dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.borderLight),
          ),
          title: const Text('Вступить по коду'),
          content: _dialogField(
              codeCtrl, 'Код приглашения', Icons.vpn_key_rounded),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                if (codeCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  final ok = await communityProv.joinCommunityFirestore(
                    codeCtrl.text.trim(),
                    auth.uid!,
                  );
                  if (context.mounted) {
                    if (ok) {
                      await auth.addCommunityToUser(
                          communityProv.activeCommunity!.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Вы вступили в сообщество!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Сообщество не найдено'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка при вступлении: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Вступить',
                  style: TextStyle(color: AppColors.accent)),
            ),
          ],
    ),
    );
  }

  Widget _dialogField(
      TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false}) {
    final t = AppColors.of(context);
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: t.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }

  InputDecoration _dropdownDecor(String label) {
    return InputDecoration(
      labelText: label,
    );
  }

  // ============ КАССА СООБЩЕСТВА ============

  Widget _buildBankCard(double bankBalance,
      CommunityProvider communityProv, AuthProvider auth) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4AA), Color(0xFF00B894)],
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Касса сообщества',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              // Subscription button in header
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.card_membership_rounded,
                          color: AppColors.accent, size: 14),
                      SizedBox(width: 4),
                      Text('Абонемент',
                          style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Payment tab button
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MembersScreen(initialTab: 1)),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payments_rounded,
                          color: AppColors.error, size: 14),
                      SizedBox(width: 4),
                      Text('Оплата',
                          style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Compact balance + buttons row
          Row(
            children: [
              // Balance
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        bankBalance >= 0
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : AppColors.error.withValues(alpha: 0.12),
                        AppColors.of(context).surfaceBg,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: bankBalance >= 0
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : AppColors.error.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Баланс',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${bankBalance.toInt()} ₽',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: bankBalance >= 0
                              ? AppColors.accent
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Top up
              GestureDetector(
                onTap: () => _showBankBalanceDialog(
                  isTopUp: true,
                  communityProv: communityProv,
                  auth: auth,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.add_circle_outline_rounded,
                      color: AppColors.accent, size: 20),
                ),
              ),
              const SizedBox(width: 6),
              // Withdraw
              GestureDetector(
                onTap: () => _showBankBalanceDialog(
                  isTopUp: false,
                  communityProv: communityProv,
                  auth: auth,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.remove_circle_outline_rounded,
                      color: AppColors.error, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBankBalanceDialog({
    required bool isTopUp,
    required CommunityProvider communityProv,
    required AuthProvider auth,
  }) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final color = isTopUp ? AppColors.accent : AppColors.error;
    final title = isTopUp ? 'Пополнить кассу' : 'Списать из кассы';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.of(context).cardBg,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                    color: AppColors.of(context).borderLight),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
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

                // Title
                Row(
                  children: [
                    Icon(
                      isTopUp
                          ? Icons.add_circle_outline_rounded
                          : Icons.remove_circle_outline_rounded,
                      color: color,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Amount field
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: TextStyle(
                      color: AppColors.of(context).textPrimary, fontSize: 24),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                        color: AppColors.of(context).borderLight),
                    suffixText: '₽',
                    suffixStyle: TextStyle(
                        color: color, fontWeight: FontWeight.w700),
                    labelText: 'Сумма',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: BorderSide(
                          color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: BorderSide(color: color),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Quick amounts
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [1000, 5000, 10000, 50000]
                      .map((v) => GestureDetector(
                            onTap: () =>
                                amountCtrl.text = v.toString(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(8),
                                border: Border.all(
                                    color:
                                        color.withValues(alpha: 0.2)),
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
                const SizedBox(height: 14),

                // Description field
                TextField(
                  controller: descCtrl,
                  style: TextStyle(color: AppColors.of(context).textPrimary),
                  decoration: InputDecoration(
                    hintText:
                        isTopUp ? 'Причина пополнения' : 'Причина списания',
                    hintStyle: TextStyle(
                        color: AppColors.textHint),
                    prefixIcon: Icon(Icons.description_outlined,
                        color: color.withValues(alpha: 0.5), size: 18),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: BorderSide(
                          color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: BorderSide(color: color),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Confirm button
                GestureDetector(
                  onTap: () async {
                    final amount =
                        double.tryParse(amountCtrl.text);
                    if (amount == null || amount <= 0) return;
                    Navigator.pop(ctx);

                    final desc = descCtrl.text.isNotEmpty
                        ? descCtrl.text
                        : (isTopUp
                            ? 'Ручное пополнение'
                            : 'Ручное списание');

                    bool ok;
                    if (isTopUp) {
                      ok = await communityProv.topUpCommunityBalance(
                        requesterId: auth.uid!,
                        amount: amount,
                        description: desc,
                      );
                    } else {
                      ok = await communityProv.deductCommunityBalance(
                        requesterId: auth.uid!,
                        amount: amount,
                        description: desc,
                      );
                    }

                    if (ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isTopUp
                              ? 'Касса пополнена на ${amount.toInt()} ₽'
                              : 'Списано ${amount.toInt()} ₽ из кассы'),
                          backgroundColor: isTopUp
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: isTopUp
                          ? const LinearGradient(
                              colors: [AppColors.accent, Color(0xFF00B894)])
                          : null,
                      color: isTopUp
                          ? null
                          : AppColors.error.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(100),
                      border: isTopUp
                          ? null
                          : Border.all(
                              color:
                                  AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      isTopUp ? 'Пополнить' : 'Списать',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isTopUp ? Colors.white : AppColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
        ),
      ),
    );
  }

  /// Поделиться ссылкой-приглашением
  void _shareInviteLink(BuildContext context, String inviteCode) {
    // Генерируем deep link
    final baseUrl = Uri.base.origin + Uri.base.path;
    final link = '$baseUrl?join=$inviteCode';

    Clipboard.setData(ClipboardData(text: link));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ссылка скопирована!',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(link,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
