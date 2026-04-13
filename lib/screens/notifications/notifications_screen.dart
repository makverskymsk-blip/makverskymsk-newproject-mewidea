import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotificationProvider>();
    final t = AppColors.of(context);
    final items = prov.notifications;

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          if (prov.hasUnread)
            TextButton(
              onPressed: prov.markAllAsRead,
              child: const Text('Прочитать все',
                  style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_rounded,
                      size: 64, color: t.borderLight),
                  const SizedBox(height: 16),
                  Text('Пока тихо',
                      style: TextStyle(
                          color: t.textHint,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Здесь появятся уведомления',
                      style: TextStyle(color: t.textHint, fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final n = items[index];
                return _NotificationTile(
                  notification: n,
                  onTap: () => prov.markAsRead(n.id),
                  onDismiss: () => prov.remove(n.id),
                );
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final n = notification;
    final isUnread = !n.isRead;

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 22),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread
                ? n.type.color.withValues(alpha: 0.06)
                : t.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? n.type.color.withValues(alpha: 0.2)
                  : t.borderLight.withValues(alpha: 0.5),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: n.type.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(n.type.icon, color: n.type.color, size: 20),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 14,
                              color: t.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          n.timeAgo,
                          style: TextStyle(
                              color: t.textHint, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      n.body,
                      style: TextStyle(
                        color: t.textSecondary,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Unread dot
              if (isUnread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: n.type.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
