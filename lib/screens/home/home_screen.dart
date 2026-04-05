import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../models/subscription.dart';
import '../../providers/auth_provider.dart';
import '../../providers/matches_provider.dart';
import '../../providers/community_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/helpers.dart';
import '../community/subscription_screen.dart';
import '../community/event_manage_screen.dart';
import '../../widgets/game_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final matchesProv = context.watch<MatchesProvider>();
    final authProv = context.watch<AuthProvider>();
    final communityProv = context.watch<CommunityProvider>();
    final user = authProv.currentUser;

    final category = SportCategory.values[_selectedCategoryIndex];
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
                _buildHeader(user?.balance ?? 0, activeCommunity?.name),
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
                      final isSubscriber =
                          communityProv.hasSubscriptionForEventDate(
                              userId, match.dateTime) &&
                          communityProv.activeCommunity != null;
                      final effectivePrice =
                          isSubscriber ? 0.0 : match.price;
                      final isRegistered = match.registeredPlayerIds.contains(userId);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GameCard(
                          format: match.format,
                          time: Helpers.formatTime(match.dateTime),
                          date: Helpers.getRelativeDate(match.dateTime),
                          location: match.location,
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
                          onParticipate: () {
                            final wasRegistered = match.registeredPlayerIds.contains(userId);
                            matchesProv.toggleRegistration(match,
                                userId: user?.id,
                                userName: user?.name);
                            if (!wasRegistered) {
                              authProv.updateBalance(-effectivePrice);
                            } else {
                              authProv.updateBalance(effectivePrice);
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

  Widget _buildHeader(double balance, String? communityName) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.sports_soccer, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SPORTS CLUB',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              if (communityName != null)
                Text(
                  communityName,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: (balance < 0 ? AppColors.error : AppColors.accent).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.card_membership, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      buttonText,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
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
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: SportCategory.values.length,
        itemBuilder: (context, index) {
          final cat = SportCategory.values[index];
          bool isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  Icon(cat.icon, size: 17,
                      color: isSelected ? Colors.white : AppColors.primary),
                  const SizedBox(width: 7),
                  Text(
                    cat.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
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
