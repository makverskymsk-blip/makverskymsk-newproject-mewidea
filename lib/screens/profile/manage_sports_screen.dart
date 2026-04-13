import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../providers/sport_prefs_provider.dart';
import '../../theme/app_colors.dart';

/// Bottom sheet for managing sport tab order and visibility.
/// Uses ReorderableListView with switches.
class ManageSportsScreen extends StatelessWidget {
  const ManageSportsScreen({super.key});

  static void show(BuildContext context) {
    final t = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: t.dialogBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const ManageSportsScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<SportPrefsProvider>();
    final t = AppColors.of(context);
    final allSports = prefs.allSportsOrdered;
    final visibleCount = prefs.visibleSports.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // ─── Handle ───
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: t.textHint.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Header ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Мои виды спорта',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: t.textPrimary,
                        ),
                      ),
                      Text(
                        'Перетаскивайте для порядка • Переключайте видимость',
                        style: TextStyle(
                          fontSize: 11,
                          color: t.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── List ───
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              scrollController: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: allSports.length,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final elevation = Tween<double>(begin: 0, end: 8)
                        .animate(animation)
                        .value;
                    return Material(
                      color: Colors.transparent,
                      elevation: elevation,
                      borderRadius: BorderRadius.circular(16),
                      shadowColor: AppColors.primary.withValues(alpha: 0.3),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              onReorder: prefs.reorder,
              itemBuilder: (context, index) {
                final sport = allSports[index];
                final isOn = prefs.isVisible(sport);
                // Can't disable the last visible sport
                final canToggle = isOn ? visibleCount > 1 : true;

                return _SportTile(
                  key: ValueKey(sport.name),
                  sport: sport,
                  isOn: isOn,
                  canToggle: canToggle,
                  onToggle: () => prefs.toggleSport(sport),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SportTile extends StatelessWidget {
  final SportCategory sport;
  final bool isOn;
  final bool canToggle;
  final VoidCallback onToggle;

  const _SportTile({
    super.key,
    required this.sport,
    required this.isOn,
    required this.canToggle,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isOn ? 1.0 : 0.45,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: t.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOn
                ? AppColors.primary.withValues(alpha: 0.2)
                : t.borderLight.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: t.isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: _findIndex(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: t.textHint.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Sport icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isOn
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : t.surfaceBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                sport.icon,
                size: 20,
                color: isOn ? AppColors.primary : t.textHint,
              ),
            ),
            const SizedBox(width: 12),

            // Sport name
            Expanded(
              child: Text(
                sport.displayName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isOn ? FontWeight.w700 : FontWeight.w500,
                  color: isOn ? t.textPrimary : t.textHint,
                ),
              ),
            ),

            // Toggle switch
            Switch(
              value: isOn,
              activeTrackColor: AppColors.primary,
              onChanged: canToggle ? (_) => onToggle() : null,
            ),
          ],
        ),
      ),
    );
  }

  int _findIndex(BuildContext context) {
    final prefs = context.read<SportPrefsProvider>();
    return prefs.allSportsOrdered.indexOf(sport);
  }
}
