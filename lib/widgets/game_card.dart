import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

class GameCard extends StatelessWidget {
  final String format;
  final String time;
  final String date;
  final String location;
  final String? communityName;
  final String? communityLogoUrl;
  final bool isExternal;
  final String price;
  final int currentPlayers;
  final int totalCapacity;
  final bool isUserRegistered;
  final VoidCallback onParticipate;
  final VoidCallback? onTap;

  const GameCard({
    super.key,
    required this.format,
    required this.time,
    required this.date,
    required this.location,
    this.communityName,
    this.communityLogoUrl,
    this.isExternal = false,
    required this.price,
    required this.currentPlayers,
    required this.totalCapacity,
    required this.isUserRegistered,
    required this.onParticipate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    double fillPercent = currentPlayers / totalCapacity;
    Color progressColor = fillPercent < 0.6
        ? AppColors.success
        : (fillPercent < 1.0 ? AppColors.warning : AppColors.error);

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            Row(
              children: [
                _buildTag(format),
                if (isExternal) ...[
                  const SizedBox(width: 8),
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1),
                    ),
                    child: const Text(
                      'Внешнее',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            time,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 14, color: t.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$date • $location',
                  style: TextStyle(color: t.textSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (communityName != null && communityName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (communityLogoUrl != null && communityLogoUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      communityLogoUrl!,
                      width: 20, height: 20,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.groups_outlined,
                          size: 16, color: t.textHint),
                    ),
                  ),
                ] else ...[
                  Icon(Icons.groups_outlined,
                      size: 16, color: t.textHint),
                ],
                const SizedBox(width: 6),
                Text(
                  communityName!,
                  style: TextStyle(color: t.textHint, fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Участники',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.textPrimary),
              ),
              const Spacer(),
              Text(
                '$currentPlayers / $totalCapacity',
                style: TextStyle(
                  color: progressColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fillPercent,
              backgroundColor: t.borderLight,
              valueColor: AlwaysStoppedAnimation(progressColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onParticipate,
                     borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isUserRegistered
                          ? null
                          : AppColors.primaryGradient,
                      color: isUserRegistered
                          ? AppColors.error.withValues(alpha: 0.12)
                          : null,
                      borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isUserRegistered
                          ? AppColors.error.withValues(alpha: 0.5)
                          : Colors.transparent,
                      width: isUserRegistered ? 1.5 : 1,
                    ),
                    boxShadow: isUserRegistered
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: -2,
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isUserRegistered
                            ? Icons.close_rounded
                            : Icons.check_circle_rounded,
                        size: 18,
                        color: isUserRegistered
                            ? AppColors.error
                            : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isUserRegistered ? 'Отменить запись' : 'Участвовать',
                        style: TextStyle(
                          color: isUserRegistered
                              ? AppColors.error
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildTag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.borderLight, width: 1),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      );
}
