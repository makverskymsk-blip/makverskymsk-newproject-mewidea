import 'package:flutter/material.dart';
import '../models/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  static const int _maxNotifications = 50;
  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool get hasUnread => unreadCount > 0;

  /// Add a notification (FIFO — oldest removed when over limit)
  void add({
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) {
    _notifications.insert(
      0,
      AppNotification(
        id: 'n_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        title: title,
        body: body,
        payload: payload,
      ),
    );
    // Trim old
    if (_notifications.length > _maxNotifications) {
      _notifications.removeRange(_maxNotifications, _notifications.length);
    }
    notifyListeners();
  }

  void markAsRead(String id) {
    final n = _notifications.where((n) => n.id == id).firstOrNull;
    if (n != null && !n.isRead) {
      n.isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    bool changed = false;
    for (final n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void remove(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
