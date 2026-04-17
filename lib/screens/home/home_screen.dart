import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../providers/sport_prefs_provider.dart';
import '../../models/subscription.dart';
import '../../providers/auth_provider.dart';
import '../../providers/matches_provider.dart';
import '../../providers/community_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/helpers.dart';
import '../community/subscription_screen.dart';
import '../community/event_manage_screen.dart';
import '../../widgets/game_card.dart';
import '../../widgets/pl_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SportCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final matchesProv = context.watch<MatchesProvider>();
    final authProv = context.watch<AuthProvider>();
    final communityProv = context.watch<CommunityProvider>();
    final sportPrefs = context.watch<SportPrefsProvider>();
    final user = authProv.currentUser;

    // Default to first visible sport if not set or hidden
    final visibleSports = sportPrefs.visibleSports;
    final category = (_selectedCategory != null && visibleSports.contains(_selectedCategory))
        ? _selectedCategory!
        : visibleSports.first;
    final filteredMatches = matchesProv.getByCategory(category);
    final activeCommunity = communityProv.activeCommunity;

    return Container(
      color: AppColors.of(context).scaffoldBg,
      child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(user?.balance ?? 0, activeCommunity?.name, activeCommunity?.logoUrl),
                const SizedBox(height: 28),

                // Subscription banner
                if (activeCommunity != null)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SubscriptionScreen()),
                    ),
                    child: _buildSubscriptionBanner(
                      communityProv.getOpenSubscription(),
                      communityProv.isSignedUpForOpenSubscription(user?.id ?? ''),
                      communityProv.isSubscribed(user?.id ?? ''),
                    ),
                  ),
                if (activeCommunity != null)
                  const SizedBox(height: 24),

                Text(
                  'Ближайшие игры',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                _buildCategorySelector(),
                const SizedBox(height: 20),

                if (filteredMatches.isEmpty)
                  _buildEmptyState(category)
                else
                  ...filteredMatches.map(
                    (match) {
                      final userId = user?.id ?? '';
                      final userCommunityId = communityProv.activeCommunity?.id;
                      final isOwnCommunity = match.communityId != null &&
                          match.communityId == userCommunityId;
                      final isSubscriber = isOwnCommunity &&
                          communityProv.hasSubscriptionForEventDate(
                              userId, match.dateTime);
                      final effectivePrice =
                          isSubscriber ? 0.0 : match.price;
                      final isRegistered = match.registeredPlayerIds.contains(userId);
                      final isExternal = !isOwnCommunity;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GameCard(
                          format: match.format,
                          time: Helpers.formatTime(match.dateTime),
                          date: Helpers.getRelativeDate(match.dateTime),
                          location: match.location,
                          communityName: isOwnCommunity
                              ? communityProv.activeCommunity?.name
                              : (match.communityId != null ? 'Внешнее сообщество' : 'Личное событие'),
                          communityLogoUrl: isOwnCommunity
                              ? communityProv.activeCommunity?.logoUrl
                              : null,
                          isExternal: isExternal,
                          price: isSubscriber
                              ? 'Абонемент ✓'
                              : Helpers.formatCurrency(match.price),
                          currentPlayers: match.registeredPlayerIds.length,
                          totalCapacity: match.totalCapacity,
                          isUserRegistered: isRegistered,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EventManageScreen(matchId: match.id),
                            ),
                          ),
                          onParticipate: () async {
                            final wasRegistered = match.registeredPlayerIds.contains(userId);
                            final success = await matchesProv.toggleRegistration(match,
                                userId: user?.id,
                                userName: user?.name);
                            if (success && effectivePrice > 0) {
                              if (!wasRegistered) {
                                // Registering — charge user
                                authProv.updateBalance(-effectivePrice);
                                // Route money to destination
                                if (isOwnCommunity) {
                                  // Own community → bank
                                  communityProv.topUpCommunityBalance(
                                    requesterId: 'system',
                                    amount: effectivePrice,
                                    description: 'Оплата за событие: ${match.format}',
                                  );
                                } else if (match.creatorId != null) {
                                  // External/personal → creator wallet
                                  matchesProv.routePaymentToCreator(
                                    match.creatorId!, effectivePrice, communityId: match.communityId);
                                }
                              } else {
                                // Unregistering — refund user
                                authProv.updateBalance(effectivePrice);
                                // Reverse routing
                                if (isOwnCommunity) {
                                  communityProv.deductCommunityBalance(
                                    requesterId: 'system',
                                    amount: effectivePrice,
                                    description: 'Возврат за отмену: ${match.format}',
                                  );
                                } else if (match.creatorId != null) {
                                  matchesProv.routePaymentToCreator(
                                    match.creatorId!, -effectivePrice, communityId: match.communityId);
                                }
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 120),
              ],
            ),
          ),
      ),
    );
  }

  Widget _buildHeader(double balance, String? communityName, String? communityLogoUrl) {
    return Row(
      children: [
        const PLLogo(size: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PERFORMANCE LAB',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              if (communityName != null)
                Row(
                  children: [
                    if (communityLogoUrl != null && communityLogoUrl.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Image.network(
                          communityLogoUrl,
                          width: 20, height: 20,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Flexible(
                      child: Text(
                        communityName,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: (balance < 0 ? AppColors.error : AppColors.accent).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: (balance < 0 ? AppColors.error : AppColors.accent).withValues(alpha: 0.3)),
          ),
          child: Text(
            Helpers.formatCurrency(balance),
            style: TextStyle(
              color: balance < 0 ? AppColors.error : AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionBanner(
      MonthlySubscription? openSub, bool isSignedUp, bool hasActiveSub) {
    String title;
    String subtitle;
    Color accentColor;
    String buttonText;

    if (openSub != null) {
      const months = [
        '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
        'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
      ];
      title = 'Абонемент на ${months[openSub.month]}';
      if (isSignedUp) {
        subtitle = 'Вы записаны • ${openSub.subscriberCount} чел.';
        accentColor = AppColors.accent;
        buttonText = 'Подробнее';
      } else {
        subtitle = 'Запись открыта • ${openSub.subscriberCount} чел.';
        accentColor = AppColors.primary;
        buttonText = 'Записаться';
      }
    } else if (hasActiveSub) {
      title = 'Абонемент активен';
      subtitle = 'Бесплатный вход на события';
      accentColor = AppColors.accent;
      buttonText = 'Подробнее';
    } else {
      title = 'Абонемент';
      subtitle = 'Ожидайте открытия записи';
      accentColor = AppColors.textHint;
      buttonText = 'Подробнее';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Icon(Icons.card_membership, color: accentColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      buttonText,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: accentColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildCategorySelector() {
    final t = AppColors.of(context);
    final visibleSports = context.watch<SportPrefsProvider>().visibleSports;
    final currentCategory = (_selectedCategory != null && visibleSports.contains(_selectedCategory))
        ? _selectedCategory!
        : visibleSports.first;
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: visibleSports.length,
        itemBuilder: (context, index) {
          final cat = visibleSports[index];
          bool isSelected = currentCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : t.cardBg,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected ? Colors.transparent : t.borderLight,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: t.isDark
                              ? Colors.black.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Icon(cat.icon, size: 13,
                      color: isSelected ? Colors.white : t.textHint),
                  const SizedBox(width: 5),
                  Text(
                    cat.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: isSelected ? Colors.white : t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(SportCategory category) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(category.icon, size: 80, color: AppColors.borderLight),
            const SizedBox(height: 16),
            Text(
              'Игр по категории "${category.displayName}"\nпока не запланировано',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}
