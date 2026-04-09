import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';
import 'glass_button.dart';

class GameCard extends StatelessWidget {
  final String format;
  final String time;
  final String date;
  final String location;
  final String? communityName;
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    ),
                    child: const Text(
                      'Внешнее',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
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
                Icon(Icons.groups_outlined,
                    size: 14, color: t.textHint),
                const SizedBox(width: 4),
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
            child: GlassButton(
              text: isUserRegistered ? 'Отменить запись' : 'Участвовать',
              color: isUserRegistered ? AppColors.error : AppColors.primary,
              icon: isUserRegistered ? Icons.close : Icons.check_circle_outline,
              onPressed: onParticipate,
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
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
}
