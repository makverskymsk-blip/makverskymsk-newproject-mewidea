import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../theme/app_colors.dart';

class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final double size;

  const AchievementBadge({
    super.key,
    required this.achievement,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = !achievement.isUnlocked;
    final rarityColor = achievement.rarity.color;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isLocked
                ? Colors.grey.withValues(alpha: 0.08)
                : rarityColor.withValues(alpha: 0.15),
            border: Border.all(
              color: isLocked
                  ? Colors.grey.withValues(alpha: 0.15)
                  : rarityColor.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: isLocked
                ? []
                : [
                    BoxShadow(
                      color: rarityColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Icon(
            achievement.icon,
            size: size * 0.4,
            color: isLocked
                ? Colors.grey.withValues(alpha: 0.3)
                : rarityColor,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: size + 20,
          child: Text(
            achievement.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isLocked
                  ? Colors.grey.withValues(alpha: 0.5)
                  : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!isLocked)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              achievement.rarity.displayName,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: rarityColor,
              ),
            ),
          ),
      ],
    );
  }
}
